# Prerequisites for the Hands On part of the Techie Workshop

We will setup a minikube cluster, use kubectl to interact with it, download some files with git and use some additional commands during the hands on.
You need also an account on github and an account on dockerhub to. You may want to create new (temporary) accounts for both sites.
Please test your setup of the minikube cluster before the workshop (see instructions below)

### Create an account on github

Go to github.com and create a new account.
Github will send you an email to verify your account.
We will clone a repository and make changes so you can trigger a container build.

### Create an account on dockerhub

Go to hub.docker.io and create a new account.
Docker will send you an email to activate the account.
We will use your new docker id and password to log in and push / pull images.

### CLI tools to install

Verify that you have the following tools handy on your system:
- minikube
- kubectl
- curl
- git
- jq

### Setup the minikube cluster

```
$ minikube start -p cnb
😄  [cnb] minikube v1.17.1 on Darwin 11.2.2
✨  Automatically selected the hyperkit driver. Other choices: virtualbox, ssh
👍  Starting control plane node cnb in cluster cnb
🔥  Creating hyperkit VM (CPUs=2, Memory=6000MB, Disk=20000MB) ...
🐳  Preparing Kubernetes v1.20.2 on Docker 20.10.2 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "cnb" cluster and "default" namespace by default
```

```
$ minikube profile cnb
✅  minikube profile was successfully set to cnb
```
```
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.64.9:8443
KubeDNS is running at https://192.168.64.9:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```
### Run a quick test

To make sure your cluster is up and running and you can pull images.

```
$ kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
deployment.apps/hello-server created
```

```
$ kubectl expose deployment hello-server --type LoadBalancer \
   --port 80 --target-port 8080
service/hello-server exposed
```

After a while the pod should be running. The loadbalancer will stay pending, don't worry.
```
$ kubectl get all
NAME                                READY   STATUS    RESTARTS   AGE
pod/hello-server-76d47868b4-bbjt4   1/1     Running   0          98s

NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/hello-server   LoadBalancer   10.102.8.226   <pending>     80:31052/TCP   5s
service/kubernetes     ClusterIP      10.96.0.1      <none>        443/TCP        10m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-server   1/1     1            1           98s

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-server-76d47868b4   1         1         1       98s
``` 

The next step should open up your browser and display the hello-server text.
```
$ minikube service hello-server
|-----------|--------------|-------------|---------------------------|
| NAMESPACE |     NAME     | TARGET PORT |            URL            |
|-----------|--------------|-------------|---------------------------|
| default   | hello-server |          80 | http://192.168.64.9:31052 |
|-----------|--------------|-------------|---------------------------|
🎉  Opening service default/hello-server in default browser...
```

Make sure to clean up before you move on.
```
$ kubectl delete svc/hello-server deployment/hello-server
```

