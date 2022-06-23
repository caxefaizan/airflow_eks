# Section 1 - Getting Started

## Cloning the Repository
>This might be a good time for you to create a Github Account if you dont have one. I highly recommend to create it for the course and it will be super useful throughout your course as well.

Visit the course repo [here](https://github.com/caxefaizan/airflow_eks) and on the top right corner click on the **`Fork`** button to clone the project in your github account.

## IDE
We will be using VS Code for the development . However you can use any IDE of your choice.
Based on your OS download the appropriate version from [here](https://code.visualstudio.com/download).

>**Note:** 
>
>* If you are on Windows, I'd recommend installing WSL2 for Windows to follow along in the course. Follow the [link](https://ubuntu.com/tutorials/install-ubuntu-on-wsl2-on-windows-10#1-overview) to get started.
>
>* After Ubuntu is installed on your WSL2, Open VS Code and open Extensions `(Ctrl+Shift+X)` and search for Remote - WSL and install it.
>
>* Now click on the Green Button on the bottom left corner to start a remote window (Ubuntu), click on `New WSL Window Using Distro` and finally select `Ubuntu 20.04`
>
>This opens a workspace in your Ubuntu WSL2

Create a Project Directory in the VS Code Workspace.

Open up a new terminal and follow the commands below.
## Setup Tools
Before getting started we need to install few tools to work with.

> We will first deploy Airflow on Minikube to understand the process and once we're comfortable with the workflow, then we shall proceed on EKS. This will help us reduce costs on AWS as some features of this course is not Free Tier eligible.
```
# minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```
```
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```
```
# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash  -s -- --version v3.8.2
```
```
# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```
Now that we have the repo forked into your git account, On the top right of your repo click on **`Code`** and under **`HTTPS`** copy the repo url. You can copy the scripts from the relevant sections.
```
# Clone the repo to your workspace
git clone https://github.com/YOUR_USERNAME/airflow_eks.git
cd airflow_eks
# Create a Virtual Env
python3 -m venv venv
source venv/bin/activate
# Install Packages
python3 -m pip install awscli
python3 -m pip install j2cli
```
