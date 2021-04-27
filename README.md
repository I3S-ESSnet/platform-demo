## Platform demo

This repository shows you how to configure a Kubernetes cluster on `Google Kubernetes Engine` (GKE) and deploy some shared applications.

* `gcloud` 
* `terraform` 
* `kubectl`
* `helm` 

### Create Google cloud project and service-account
#### Prerequisites

* Sign up for free on https://cloud.google.com/
* install Google Cloud SDK https://cloud.google.com/sdk/docs/install
* Fork this repo on Github https://github.com/I3S-ESSnet/platform-demo

```sh
$ cd gke
$ gcloud auth login
$ gcloud projects create i3s-ninja
$ gcloud config set project i3s-ninja
$ gcloud iam service-accounts create terraform
$ gcloud projects add-iam-policy-binding i3s-ninja --member "serviceAccount:terraform@i3s-$ $ ninja.iam.gserviceaccount.com" --role "roles/owner"
$ gcloud iam service-accounts keys create account.json --iam-account "terraform@i3s-$ ninja.iam.gserviceaccount.com"
```

Output : 
* `account.json`: key file for next step

### Create Kubernetes cluster
#### Prerequisites

* Install Terraform CLI https://www.terraform.io/downloads.html


```sh
$ terraform version
Terraform v0.15.0
on darwin_amd64
+ provider registry.terraform.io/hashicorp/google v3.65.0
+ provider registry.terraform.io/hashicorp/kubernetes v2.1.0

$ terraform init
$ terraform plan -out "run.plan"
$ terraform apply "run.plan"      #(wait approx 10 minutes)
```
:information_source: follow links in initial error messages to enable "Kubernetes Engine API". Even if it is FREE it requires av billing account.

Output : 
* `master ip`: the `apiserver` IP 
* `reserved_ip_address`: the ip that will be used for the reverse proxy

### Test Kubernetes cluster

#### Prerequisites
* Install `kubectl` https://kubernetes.io/docs/tasks/tools/#kubectl

Get credentials for `kubectl`
````sh
$ gcloud container clusters get-credentials i3s-standard-cluster --region europe-west1-b
Fetching cluster endpoint and auth data.
kubeconfig entry generated for i3s-standard-cluster.
````

List cluster nodes
````sh
$ kubectl get nodes  
NAME                                                  STATUS   ROLES    AGE     VERSION
gke-i3s-standard-clus-first-node-pool-5f706ef9-5gdh   Ready    <none>   7m42s   v1.18.16-gke.502
gke-i3s-standard-clus-first-node-pool-5f706ef9-s6r1   Ready    <none>   7m43s   v1.18.16-gke.502
````

### Install reverse proxy nginx-ingress with `Helm`

````sh
$ cd ../apps/nginx-ingress
$ helm dependencies update
````

Replace `<reserved_ip_address>`in `values.yaml`with the correct ip-address.

````sh
$ cat values.yaml
ingress-nginx:
 controller:
  publishService:
    enabled: true
  service:
    loadBalancerIP: <reserved_ip_address>
 rbac:
  create: true
````

````sh
$ helm install --create-namespace --namespace nginx-ingress nginx-ingress .

NAME: nginx-ingress
LAST DEPLOYED: Tue Apr 27 10:52:58 2021
NAMESPACE: nginx-ingress
STATUS: deployed
REVISION: 1
TEST SUITE: None
````

### Install IS2 with Helm on Kubernetes

#### Prerequisites
* install helm https://helm.sh/docs/intro/install/
* clone https://github.com/mecdcme/is2 (since we don't have en I3S helm catalog)

````sh
$ cd is2/helm
$ helm install --create-namespace --namespace is2 is2 .
NAME: is2
LAST DEPLOYED: Tue Apr 27 09:27:35 2021
NAMESPACE: is2
STATUS: deployed
REVISION: 1
````

Create a file e.g. `my-helm-values-is2.yaml` with this contents and replace  your `<reserved_ip_address>`
````sh
env:
  SPRING_DATASOURCE_DRIVERCLASSNAME: org.postgresql.Driver
  SPRING_DATASOURCE_PASSWORD: toto
  SPRING_DATASOURCE_PLATFORM: postgresql
  SPRING_DATASOURCE_URL: jdbc:postgresql://is2-db:5432/postgres?currentSchema=is2
  SPRING_DATASOURCE_USERNAME: postgres
ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
  enabled: true
  hosts:
  - host: is2.<reserved_ip_address>.xip.io
    paths:
    - /
````

:information_source: this example does not cover real DNS and TLS certificates, we just use https://xip.io/ which is a free wildcards DNS service.

Apply your values
````sh
$ helm upgrade --namespace is2 is2 . -f my-helm-values-is2.yaml
Release "is2" has been upgraded. Happy Helming!
NAME: is2
LAST DEPLOYED: Tue Apr 27 10:38:42 2021
NAMESPACE: is2
STATUS: deployed
REVISION: 2
```` 

Now you can vist `http://i2.<reserved_ip_address>.xip.io/is2/` Default username/password are posted in  [is2 README](https://github.com/mecdcme/is2/blob/master/README.md)
