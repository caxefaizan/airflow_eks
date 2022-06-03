# Enabling Ingress for the UI
Run the following commands to create an AWS ALB load balancer Controller
```
# Create IAM Policy
curl -o ./yamls/iam-policy-ingress.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://yamls/iam-policy-ingress.json
```
Copy the Arn of the policy created above, as we have to use it in command below.
```
# Attach Policy
eksctl create iamserviceaccount --cluster=airflow --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::526742771915:policy/AWSLoadBalancerControllerIAMPolicy --approve
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