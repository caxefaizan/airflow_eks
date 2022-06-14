# Section 6 - Cluster Auto Scaler
## Prerequisites
> The Kubernetes Cluster Autoscaler automatically adjusts the number of nodes in your cluster when pods fail to launch due to lack of resources or when nodes in the cluster are underutilized and their pods can be rescheduled onto other nodes in the cluster.

Before deploying the Cluster Autoscaler, we must meet the following prerequisites:

The Cluster Autoscaler requires the following tags on our Auto Scaling groups so that they can be auto-discovered.

If we had used eksctl with `--asg-access` to create our node groups, these tags would have been automatically applied.

Since we didn't use eksctl with `--asg-access`, we must manually tag our Auto Scaling groups with the following tags.
```
k8s.io/cluster-autoscaler/airflow   owned

k8s.io/cluster-autoscaler/enabled	true
```
## Create Policy
```
cp Section6/yamls ./ -r -f
aws iam create-policy --policy-name AmazonEKSClusterAutoscalerPolicy --policy-document file://yamls/cluster-autoscaler-policy.json
```
Copy the ARN of policy to create service account
```
eksctl create iamserviceaccount --cluster=airflow --namespace=kube-system --name=cluster-autoscaler --attach-policy-arn=arn:aws:iam::YOUR_ACCOUNT_ID:policy/AmazonEKSClusterAutoscalerPolicy --override-existing-serviceaccounts --approve
```
## Deploy AutoScaler
```
curl -o ./yamls/cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
# Modify the YAML file and replace <YOUR CLUSTER NAME> with your cluster name

kubectl apply -f ./yamls/cluster-autoscaler-autodiscover.yaml

kubectl patch deployment cluster-autoscaler   -n kube-system   -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
```
## Edit the Cluster Autoscaler deployment
```
kubectl -n kube-system edit deployment.apps/cluster-autoscaler
```
> Edit the cluster-autoscaler container command to add the following options. `--balance-similar-node-groups` ensures that there is enough available compute across all availability zones. `--skip-nodes-with-system-pods=false` ensures that there are no problems with scaling to zero.
```
    spec:
      containers:
      - command
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/airflow
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
```
##  Set the Cluster Autoscaler Image related to our current EKS Cluster version
- Open https://github.com/kubernetes/autoscaler/releases
- Since our Cluster version is 1.21 and our cluster autoscaler version is 1.21.2 as per above releases link
```
kubectl set image deployment cluster-autoscaler -n kube-system cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.2
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
```
