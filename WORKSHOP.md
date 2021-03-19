### installing kpack 

```shell
$ curl -LO https://github.com/pivotal/kpack/releases/download/v0.2.2/release-0.2.2.yaml
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   626  100   626    0     0   2196      0 --:--:-- --:--:-- --:--:--  2196
100 13818  100 13818    0     0  26675      0 --:--:-- --:--:-- --:--:-- 26675
```

```shell
$ kubectl get ns
NAME              STATUS   AGE
default           Active   17m
kube-node-lease   Active   17m
kube-public       Active   17m
kube-system       Active   17m
```

```shell
$ kubectl apply -f release-0.2.2.yaml 
namespace/kpack created
customresourcedefinition.apiextensions.k8s.io/builds.kpack.io created
customresourcedefinition.apiextensions.k8s.io/builders.kpack.io created
customresourcedefinition.apiextensions.k8s.io/clusterbuilders.kpack.io created
customresourcedefinition.apiextensions.k8s.io/clusterstores.kpack.io created
configmap/build-init-image created
configmap/build-init-windows-image created
configmap/rebase-image created
configmap/lifecycle-image created
configmap/completion-image created
configmap/completion-windows-image created
deployment.apps/kpack-controller created
serviceaccount/controller created
clusterrole.rbac.authorization.k8s.io/kpack-controller-admin created
clusterrolebinding.rbac.authorization.k8s.io/kpack-controller-admin-binding created
role.rbac.authorization.k8s.io/kpack-controller-local-config created
rolebinding.rbac.authorization.k8s.io/kpack-controller-local-config-binding created
customresourcedefinition.apiextensions.k8s.io/images.kpack.io created
service/kpack-webhook created
customresourcedefinition.apiextensions.k8s.io/sourceresolvers.kpack.io created
customresourcedefinition.apiextensions.k8s.io/clusterstacks.kpack.io created
Warning: admissionregistration.k8s.io/v1beta1 MutatingWebhookConfiguration is deprecated in v1.16+, unavailable in v1.22+; use admissionregistration.k8s.io/v1 MutatingWebhookConfiguration
mutatingwebhookconfiguration.admissionregistration.k8s.io/defaults.webhook.kpack.io created
Warning: admissionregistration.k8s.io/v1beta1 ValidatingWebhookConfiguration is deprecated in v1.16+, unavailable in v1.22+; use admissionregistration.k8s.io/v1 ValidatingWebhookConfiguration
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.kpack.io created
secret/webhook-certs created
deployment.apps/kpack-webhook created
serviceaccount/webhook created
role.rbac.authorization.k8s.io/kpack-webhook-certs-admin created
rolebinding.rbac.authorization.k8s.io/kpack-webhook-certs-admin-binding created
clusterrole.rbac.authorization.k8s.io/kpack-webhook-mutatingwebhookconfiguration-admin created
clusterrolebinding.rbac.authorization.k8s.io/kpack-webhook-certs-mutatingwebhookconfiguration-admin-binding created
```

```shell
$ kubectl get crds
NAME                       CREATED AT
builders.kpack.io          2021-03-18T15:47:57Z
builds.kpack.io            2021-03-18T15:47:57Z
clusterbuilders.kpack.io   2021-03-18T15:47:57Z
clusterstacks.kpack.io     2021-03-18T15:47:57Z
clusterstores.kpack.io     2021-03-18T15:47:57Z
images.kpack.io            2021-03-18T15:47:57Z
sourceresolvers.kpack.io   2021-03-18T15:47:57Z
```

```shell
$ kubectl get all -n kpack
NAME                                    READY   STATUS    RESTARTS   AGE
pod/kpack-controller-6d7b8f49ff-85qjt   1/1     Running   0          71s
pod/kpack-webhook-597484b97-rwckn       1/1     Running   0          71s

NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/kpack-webhook   ClusterIP   10.98.86.107   <none>        443/TCP   72s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kpack-controller   1/1     1            1           72s
deployment.apps/kpack-webhook      1/1     1            1           72s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/kpack-controller-6d7b8f49ff   1         1         1       72s
replicaset.apps/kpack-webhook-597484b97       1         1         1       72s
```

### verify docker login 

```shell
$ eval $(minikube docker-env)
```

```shell
$ DOCKER_USERNAME='replace with your docker id'
$ DOCKER_PASSWORD='replace with your password'
```

```shell
$ echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
WARNING! Your password will be stored unencrypted in /Users/sschmidt/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

### configure credentials for kpack 

```yaml
$ cat dockerhub-registry-credentials.yaml
apiVersion: v1
kind: Secret
metadata:
  name: dockerhub-registry-credentials
  annotations:
    kpack.io/docker: https://index.docker.io/v1/
type: kubernetes.io/basic-auth
stringData:
  username: <username>        # Docker ID
  password: <password>
```

```shell
$ kubectl apply -f dockerhub-registry-credentials.yaml 
secret/dockerhub-registry-credentials created
```

```yaml
$ cat dockerhub-service-account.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dockerhub-service-account
secrets:
- name: dockerhub-registry-credentials
imagePullSecrets:
- name: dockerhub-registry-credentials
```

```shell
$ kubectl apply -f dockerhub-service-account.yaml 
serviceaccount/dockerhub-service-account created
```

### configure the store 

```yaml
$ cat store.yaml 
apiVersion: kpack.io/v1alpha1
kind: ClusterStore
metadata:
  name: default
spec:
  sources:
  - image: gcr.io/paketo-buildpacks/java
  - image: gcr.io/paketo-buildpacks/graalvm
  - image: gcr.io/paketo-buildpacks/java-azure
  - image: gcr.io/paketo-buildpacks/nodejs
  - image: gcr.io/paketo-buildpacks/dotnet-core
  - image: gcr.io/paketo-buildpacks/go
  - image: gcr.io/paketo-buildpacks/php
  - image: gcr.io/paketo-buildpacks/nginx
```

```shell
$ kubectl apply -f store.yaml 
clusterstore.kpack.io/default created
```

```shell
$ kubectl get clusterstore
NAME                            READY
clusterstore.kpack.io/default   True
```

```shell
$ kubectl describe clusterstore
...
```

### configure the stack 

```yaml
$ cat stack-1.0.24.yaml 
apiVersion: kpack.io/v1alpha1
kind: ClusterStack
metadata:
  name: base
spec:
  id: "io.buildpacks.stacks.bionic"
  buildImage:
    image: "paketobuildpacks/build:1.0.24-base-cnb"
  runImage:
    image: "paketobuildpacks/run:1.0.24-base-cnb"
```

```shell
$ kubectl apply -f stack-1.0.24.yaml 
clusterstack.kpack.io/base created
```

```shell
$ kubectl get clusterstack
NAME                         READY
clusterstack.kpack.io/base   True
```

```shell
$ kubectl describe clusterstack
...
```

### apply a builder 

```yaml
$ cat builder.yaml 
apiVersion: kpack.io/v1alpha1
kind: Builder
metadata:
  name: ws-builder
  namespace: default
spec:
  serviceAccount: dockerhub-service-account
  tag: index.docker.io/demosteveschmidt/ws-builder
  stack:
    name: base
    kind: ClusterStack
  store:
    name: default
    kind: ClusterStore
  order:
  - group:
    - id: paketo-buildpacks/java
  - group:
    - id: paketo-buildpacks/java-azure
  - group:
    - id: paketo-buildpacks/graalvm
  - group:
    - id: paketo-buildpacks/nodejs
  - group:
    - id: paketo-buildpacks/dotnet-core
  - group:
    - id: paketo-buildpacks/go
  - group:
    - id: paketo-buildpacks/nginx
```

```shell
$ kubectl apply -f builder.yaml 
builder.kpack.io/ws-builder created
```

```shell
$ kubectl get builders
NAME         LATESTIMAGE                                                                                                           READY
ws-builder   index.docker.io/demosteveschmidt/ws-builder@sha256:2eb02b27cfc308295b8923c5b93447c0072f1749ea89fd22e5554ee53624d3b2   True
```

```shell
$ kubectl describe builder ws-builder
...
```

```shell
$ curl -s -S 'https://registry.hub.docker.com/v2/repositories/demosteveschmidt/' | jq .
{
...
    {
      "user": "demosteveschmidt",
      "name": "ws-builder",
...
```


### fork spring petclinic 

https://github.com/demosteveschmidt/spring-petclinic
The "fork" button is on the upper right hand corner, just below the bell in top bar.


### define the petclinic image build 

```yaml
$ cat dockerhub-image.yaml 
apiVersion: kpack.io/v1alpha1
kind: Image
metadata:
  name: petclinic-image
  namespace: default
spec:
  tag: index.docker.io/demosteveschmidt/petclinic
  serviceAccount: dockerhub-service-account
  builder:
    name: ws-builder
    kind: Builder
  source:
    git:
      url: https://github.com/demosteveschmidt/spring-petclinic
      revision: e2fbc561309d03d92a0958f3cf59219b1fc0d985
```

```shell
$ kubectl apply -f dockerhub-image.yaml 
image.kpack.io/petclinic-image created
```

```shell
$ kubectl get pods
NAME                                      READY   STATUS     RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Init:1/6   0          14s
```

```shell
$ kubectl get image
NAME              LATESTIMAGE   READY
petclinic-image                 Unknown
```

```shell
$ kubectl get build
NAME                            IMAGE   SUCCEEDED
petclinic-image-build-1-bh9r4           Unknown
```

```shell
$ kubectl get pods
NAME                                      READY   STATUS     RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Init:4/6   0          3m8s
```

```shell
$ kubectl logs petclinic-image-build-1-bh9r4-build-pod -c build -f
```

```shell
$ kubectl get pods
NAME                                      READY   STATUS      RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Completed   0          9m7s
```

```shell
$ ./logs.sh petclinic-image-build-1-bh9r4-build-pod > build-output.txt
$ cat build-output.txt
```

```shell
$ curl -s -S 'https://registry.hub.docker.com/v2/repositories/demosteveschmidt/' | jq .
...
      "user": "demosteveschmidt",
      "name": "ws-builder",
...
      "user": "demosteveschmidt",
      "name": "petclinic",
...
```
