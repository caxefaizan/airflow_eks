# Section 5 - Exposing the UI and Persisting Logs
## Enabling Ingress for the UI
Run the following commands to create an AWS ALB load balancer Controller
```
# Create IAM Policy
curl -o ./yamls/iam-policy-ingress.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://yamls/iam-policy-ingress.json
```
Copy the Arn of the policy created above, as we have to use it in command below.
```
# Attach Policy
eksctl create iamserviceaccount --cluster=airflow --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::YOUR_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy --approve
helm repo add eks https://aws.github.io/eks-charts
helm repo update
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=airflow --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl describe deploy/aws-load-balancer-controller -n kube-system
```
Now add the following ingress configuration in tyhe `values.yaml` file
```
ingress:
  enabled: true
  web:
    annotations: {
      alb.ingress.kubernetes.io/scheme: internet-facing,
      alb.ingress.kubernetes.io/target-type: ip
    }
    path: "/"
    pathType: "Prefix"
    ingressClassName: alb
```
And deploy Airflow again `./scripts/deploy.sh`

Now wait for a couple of minutes for the Load Balancer to spin up.

You can get the Airflow UI link from
```
kubectl get ingress -n airflow
```
Copy the address and open it in a web browser.

## Using EFS for RWX PVC
Create Policy for EFS
```
curl -o ./yamls/iam-policy-efs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.3.7/docs/iam-policy-example.json
aws iam create-policy --policy-name AmazonEKS_EFS_CSI_Driver_Policy --policy-document file://yamls/iam-policy-efs.json
```
Attach Policy to Cluster
```
eksctl create iamserviceaccount --cluster airflow --namespace kube-system --name efs-csi-controller-sa --attach-policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/AmazonEKS_EFS_CSI_Driver_Policy --approve --region us-east-1
```
## Deploy EFS Driver
```
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver --namespace kube-system --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver --set controller.serviceAccount.create=false --set controller.serviceAccount.name=efs-csi-controller-sa
kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-efs-csi-driver,app.kubernetes.io/instance=aws-efs-csi-driver"
```
## Create File System
``` 
vpc_id=$(aws eks describe-cluster --name airflow --query "cluster.resourcesVpcConfig.vpcId" --output text)

cidr_range=$(aws ec2 describe-vpcs --vpc-ids $vpc_id --query "Vpcs[].CidrBlock" --output text)

security_group_id=$(aws eks describe-cluster --name airflow --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)

# Authorize and create File System
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 2049 --cidr $cidr_range

file_system_id=$(aws efs create-file-system --region us-east-1 --performance-mode generalPurpose --query 'FileSystemId' --output text)
```
## Mount File System
```
# Filtering Subnets
TAG1=tag:alpha.eksctl.io/cluster-name
VALUE1=airflow
TAG2=tag:kubernetes.io/role/internal-elb
VALUE2=1
subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" "Name=$TAG1,Values=$VALUE1" "Name=$TAG2,Values=$VALUE2" | jq --raw-output '.Subnets[].SubnetId')

#  Mounting Subnets
for subnet in ${subnets[@]}; do echo "creating mount target in " $subnet; aws efs create-mount-target --file-system-id $file_system_id --subnet-id $subnet --security-groups $security_group_id; done

aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text
```
## Get PVC and Storage Class Template
```
# Change File system id in storageclass.yaml
curl -o ./yamls/storageclass.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/examples/kubernetes/dynamic_provisioning/specs/storageclass.yaml

curl -o ./yamls/pod.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/examples/kubernetes/dynamic_provisioning/specs/pod.yaml
```
## Copy Only the Storage Class and PVC kind into `helperChart/templates/efs.yaml` as shown below
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: YOUR_FILESYSTEM_ID
  directoryPerms: "700"
  gidRangeStart: "1000" # optional
  gidRangeEnd: "2000" # optional
  basePath: "/dynamic_provisioning" # optional
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
  namespace: {{ .Values.cluster.namespace }}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```
Use the PVC for logs(persisting K8s Logs) in values.yaml file by adding
```
logs:
  persistence:
    enabled: true
    existingClaim: efs-claim
```
> **Note: To use the new PVC we will have to uninstall Airflow and reinstall it.**
```
helm uninstall airflow -n airflow
cp Section5/yamls/values.yaml.j2 ./yamls/
cp Section5/helperChart ./ -r -f
./scripts/deploy.sh 
```
