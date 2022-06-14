# Section 8 -  Enabling SSL
## Create Certificate for the Webserver
```
openssl genrsa -out ./helperChart/secrets/private.pem 2048
openssl req -new -x509 -key ./helperChart/secrets/private.pem -out ./helperChart/secrets/cacert.pem -days 1095
```
## Create Kubernetes Secret using Helper Chart as below 
```
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
```
aws acm import-certificate --certificate fileb://helperChart/secrets/cacert.pem --private-key fileb://helperChart/secrets/private.pem
```
Copy the ARN for use in `values.yaml.j2`
## Enable TLS in the Airflow Build
Add the following lines in `values.yaml.j2`
```
ingress:
  enabled: true
  web:
    annotations: {
      alb.ingress.kubernetes.io/scheme: internet-facing,
      alb.ingress.kubernetes.io/target-type: ip,
      ## SSL Settings
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:YOUR_ACCOUNT_ID:certificate/5c50eee6-4b60-43b9-9c74-cffb9bb8fd2a
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
```
./scripts/deploy.sh 
```
