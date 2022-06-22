# Section 8 -  Enabling SSL (Optional)
## Create Certificate for the Webserver
If you own a domain name, you can create a certificate for it, either yourself or through a certificate authority.
In case you want to create it yourself follow the commands below and enter the necessary details.
```
openssl genrsa -out ./helperChart/secrets/private.pem 2048
# If you own a domain name registered use that while creating the certificate
openssl req -new -x509 -key ./helperChart/secrets/private.pem -out ./helperChart/secrets/cacert.pem -days 1095
```
Now that you have the certificate and the associated private key generated, we can template it in our helperChart. 
## Create Kubernetes Secret using Helper Chart as below 
```
# add the following lines in helperChart/templates/secrets.yaml
---
apiVersion: v1
data:
  tls.crt: {{ .Files.Get "secrets/cacert.pem" | b64enc }}
  tls.key: {{ .Files.Get "secrets/private.pem" | b64enc }}
kind: Secret
metadata:
  name: httpssecret
  namespace: {{ .Values.cluster.namespace }}
  labels:
    app: {{ .Chart.Name }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    heritage: {{ .Release.Service }}
    release: {{ .Release.Name }}
type: kubernetes.io/tls
```
or 
```
cp Section8/helperChart ./ -r -f
```
## Upload Certificate to ACM
Now in order to use our certificate, we have to upload it to AWS - ACM
```
aws acm import-certificate --certificate fileb://helperChart/secrets/cacert.pem --private-key fileb://helperChart/secrets/private.pem
```
Copy the ARN for use in `values.yaml.j2`
## Enable TLS in the Airflow Build
Add the following lines in `values.yaml.j2` as annotations for the loadbalancer to enable it to use the certificate for HTTPS connections, and make sure to use your certificate arn.
Adding these annotations will also redirect http to https as described in `alb.ingress.kubernetes.io/actions.ssl-redirect`
```
ingress:
  enabled: true
  web:
    annotations: {
      alb.ingress.kubernetes.io/scheme: internet-facing,
      alb.ingress.kubernetes.io/target-type: ip,
      ## SSL Settings
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:YOUR_ACCOUNT_ID:certificate/5dsw34e6-4b60-43b9-9c74-cffb9bb8fd2a
      # SSL Redirect Setting
      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    }
    path: "/"
    pathType: "Prefix"
    ingressClassName: alb
    hosts: 
    - name: ""
      tls:
        enabled: true
        secretName: httpssecret
```
or
```
cp Section8/yamls/values.yaml.j2 ./yamls/
```
## Redeploy Airflow
Create Params in paramstore for certificate and its private key.
```
aws ssm put-parameter --name "/global/airflow/webserver/tls-certificate" --value "$(cat ./helperChart/secrets/cacert.pem)" --type "SecureString"
aws ssm put-parameter --name "/global/airflow/webserver/tls-key" --value "$(cat ./helperChart/secrets/private.pem)" --type "SecureString"
```
and include it in deploy script before the helperChart installation
```
# scripts/deploy.sh ...contd

aws ssm get-parameter --name "/global/airflow/webserver/tls-certificate"     --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/cacert.pem
aws ssm get-parameter --name "/global/airflow/webserver/tls-key" --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/private.pem

echo "Updating Helper Chart Deployment"
# ...contd
```
and finally redeploy airflow.
```
./scripts/deploy.sh 
```
