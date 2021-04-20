# Hands-on Workshop

<img src=./images/WorkshopOverview.png>

## Sections

1. Installing kpack
2. Configuring kpack
3. Node example
4. Spring Boot Java example

## Installing kpack

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

## Configuring kpack

Now that the kpack is installed, we will configure the build service in our Kubernetes cluster.

### Verify docker login

Let's run a quick test to make sure we have the right credentials for kpack

```shell
$ eval $(minikube docker-env)
```

```shell
$ DOCKER_USERNAME='replace with your Docker ID'
$ DOCKER_PASSWORD='replace with your Docker password'
```

```shell
$ echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
WARNING! Your password will be stored unencrypted in /Users/sschmidt/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

### Configure credentials for kpack

Use the same credentials as for the `docker login` test above.
We will setup a service account that uses these credentials to allow kpack to store docker images.

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
  username: <DOCKER_USERNAME>        # replace with your Docker ID
  password: <DOCKER_PASSWORD>        # replace with your Docker password
```

```shell
$ kubectl apply -f dockerhub-registry-credentials.yaml
secret/dockerhub-registry-credentials created
```

Now we define the service account and link it to the credentials.

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

### Configure the store

The `store` defines our available buildpacks. 
Let's start with the simplest possible store that only contains the buildpacks for nodejs.
Your task later on will be to add buildpacks for many more languages.

The incomplete YAML file below defines the `store`for our build service.
See if you can complete the file with the following information:
- The API is `kpack.io/v1alpha1`
- Object kind is `ClusterStore`
- Named `default` as we will use it as the default clusterwide store
- Specifying just one image source for node.js `gcr.io/paketo-buildpacks/nodejs` we will expand the list later

```yaml
$ cat store.yaml
apiVersion: kpack.io/v1alpha1
kind: ClusterStore
metadata:
  name: ...
spec:
  sources:
  - image: ...
```

[Here you can compare your solution for store.yaml](./store.yaml)


```shell
$ kubectl apply -f store.yaml
clusterstore.kpack.io/default created
```

```shell
$ kubectl get clusterstore
NAME                            READY
clusterstore.kpack.io/default   True
```

To see what kpack did with the store definition describe the ClusterStore CRD

```shell
$ kubectl describe clusterstore
...
```

### Configure the stack

The `stack` specifies the `build` and `run` images.
As the names suggest one will be used while building our image, the other will be the base layer for our image that will be stored in the registry.

- The API is `kpack.io/v1alpha1`
- Object kind is `ClusterStack`
- Named `base` since we use the base images of the paketo buildpacks as the starting point for our clusterwide stack
- buildImage.image is the docker image for build `paketobuildpacks/build:1.0.24-base-cnb`
- runImage.image is the docker image for run `paketobuildpacks/run:1.0.24-base-cnb`

```yaml
$ cat stack.yaml
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
$ kubectl apply -f stack.yaml
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

### Create a builder for nodejs

The next step is to define our builder for this workshop. Again we define a minimal builder and you will enhance it later.
- The API is `kpack.io/v1alpha1`
- Object kind is `Builder`
- Named `ws-builder`
- You can define multiple builders in different namespaces. For simplicity, we run all in the default namespace.
- Note that we link the builder to the `dockerhub-service-account`
- Make sure you change the tag to your registry. My tag is `index.docker.io/demosteveschmidt/ws-builder`
- We reference our ClusterStack named `base` and our ClusterStore named `default`
- The last part defines the search order for the buildpacks. As we just have on buildpack defined at this time there is not much to sort out. 

```yaml
$ cat builder.yaml
apiVersion: kpack.io/v1alpha1
kind: Builder
metadata:
  name: ws-builder
  namespace: default
spec:
  serviceAccount: dockerhub-service-account
  tag: index.docker.io/<DOCKER_USERNAME>/ws-builder
  stack:
    name: base
    kind: ClusterStack
  store:
    name: default
    kind: ClusterStore
  order:
  - group:
    - id: paketo-buildpacks/nodejs
```


### Examine the objects and the builder image

We apply the YAML to create the Kubernetes objects and the builder image.

```shell
$ kubectl apply -f builder.yaml
builder.kpack.io/ws-builder created
```
__This concludes the setup of kpack as a build service for our workshop.__

Before we move on to build an image from source, let's examing the builder.
Once the builder image is created it will be store in your dockerhub account.

```shell
$ kubectl get builders
NAME         LATESTIMAGE                                                                                                           READY
ws-builder   index.docker.io/demosteveschmidt/ws-builder@sha256:2eb02b27cfc308295b8923c5b93447c0072f1749ea89fd22e5554ee53624d3b2   True
```

Comprehensive information about the builder can be displayed using kubectl describe.

```shell
$ kubectl describe builder ws-builder
...
```

You can examine the image on dockerhub with curl or with your browser.

```shell
$ curl -s -S 'https://registry.hub.docker.com/v2/repositories/<DOCKER_USERNAME>/' | jq .
{
...
    {
      "user": "demosteveschmidt",
      "name": "ws-builder",
...
```

## Node Example

We will run through the steps of defining and building a first image for a nodejs application.

### Define the image for nodejs

Now that kpack is ready to build our images, we can simply define source and destination for our builds.
As destination we will reuse our dockerhub account. 
For the first build we can use the nodejs source from my git account.
- The API is `kpack.io/v1alpha1`
- Object kind is `Image`
- Named `hello-node`
- You can choose your image to build in different namespaces. For simplicity, we stick with the default namespace.
- Make sure you change the tag for the application image to your registry. My tag is `index.docker.io/demosteveschmidt/cnb-hello-node`
- We reference our Builder named `ws-builder`
- The last part defines source code location `https://github.com/demosteveschmidt/node` and revision. Revision can be a branch, tag or commit sha.


```yaml
$ cat dockerhub-image-node.yaml
apiVersion: kpack.io/v1alpha1
kind: Image
metadata:
  name: hello-node
  namespace: default
spec:
  tag: index.docker.io/<DOCKER_USERNAME>/cnb-hello-node
  serviceAccount: dockerhub-service-account
  builder:
    name: ws-builder
    kind: Builder
  source:
    git:
      url: https://github.com/demosteveschmidt/node
      revision: main
```

### Define the image

This will create the image definition for kpack and trigger a build

```shell
$ kubectl apply -f dockerhub-image-node.yaml
image.kpack.io/hello-node created
```

### Create a helper to watch the logs

```shell
$ cat logs.sh
#!/bin/bash

if [ "$1" == "" ]
then
  echo "usage: $0 image-build-pod-name"
  exit 1
fi

BLUE="\033[0;36m"; NORM="\033[0m"

POD="$1"

CONTAINERS=$(kubectl get pod $POD -o json | jq ".spec.initContainers[].name" | tr -d '"')

for container in $CONTAINERS completion
do
  echo ""; echo -e "${BLUE}---- $container ----${NORM}"; echo ""
  kubectl logs $POD -c $container -f
  if [ $container != "completion" ]
  then
    read -p "[Enter to continue]" ans
  fi
done
```

Make it runnable

```shell
$ chmod 755 logs.sh
```

### Display the build pod, image status and logs

```shell
$ kubectl get pods
NAME                                     READY   STATUS     RESTARTS   AGE
pod/hello-node-build-1-69sdm-build-pod   0/1     Init:1/6   0          27s
$ kubectl describe image
...
  Latest Build Reason:            CONFIG
  Latest Build Ref:               hello-node-build-1-69sdm
  Latest Image:                   index.docker.io/demosteveschmidt/cnb-hello-node@sha256:ad90f528a5b2e0799a99517d817135fa9703905471c955a640340257f64300e8
...
```

```shell
$ ./logs.sh hello-node-build-1-69sdm-build-pod
...
```

### Deploy the image and test it

```shell
$ kubectl create deployment cnb-hello-node --image=demosteveschmidt/cnb-hello-node
$ kubectl expose deployment/cnb-hello-node --port 8080 --type LoadBalancer
$ minikube service cnb-hello-node
```

## A Java Example

Now that we've seen the different parts that make up our build service we will modify the simple example to cover more languages. For this we will run through a Spring Boot Java example. 

### Reconfigure the store

As promised earlier, we will now reconfigure our ClusterStore to have a larger list of buildpacks.
You can use the list below and be carefull with indentation - you know it's YAML.
Add the list to your `store.yaml` file.

```yaml
$ cat store.yaml
...
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

[If you get lost, you might want to take a look here](./store-full.yaml)

And apply the changes

```shell
$ kubectl apply -f store.yaml
```

### Update the builder to include java and other buildpacks

We will now modify the builder to cover many more languages and frameworks like Spring Boot Java. Then we configure an image for the world famous Spring Petclinic application.
Modify the `builder.yaml` file to include the buildpacks in the `spec.order` section (see list below):

```yaml
$ cat builder.yaml
...
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

[Here a link to a complete example](./builder-full.yaml)

```shell
$ kubectl apply -f builder.yaml
builder.kpack.io/ws-builder updated
```

```shell
$ curl -s -S 'https://registry.hub.docker.com/v2/repositories/demosteveschmidt/ws-builder/tags/' | jq .
{
  "count": 2,
...
```

### Fork Spring Petclinic

https://github.com/demosteveschmidt/spring-petclinic
The "fork" button is on the upper right hand corner, just below the bell in top bar.
You will make good use of your copy of the spring petclinic application in the extras labs.


### Define the petclinic image build

Make sure to change the `tag` and `url` lines to point to your docker registry and your git account respectively.
Choose the latest commit sha as `revision` (this should be the same in the example below)

```yaml
$ cat dockerhub-image.yaml
apiVersion: kpack.io/v1alpha1
kind: Image
metadata:
  name: petclinic-image
  namespace: default
spec:
  tag: index.docker.io/<DOCKER_USERNAME>/petclinic
  serviceAccount: dockerhub-service-account
  builder:
    name: ws-builder
    kind: Builder
  source:
    git:
      url: https://github.com/<GIT_USERNAME>/spring-petclinic
      revision: e2fbc561309d03d92a0958f3cf59219b1fc0d985
```

Create the image object. This will automatically trigger the build.
__NOTE: The first build will take longer as we download all the dependencies for the application. Subsequent builds will be very fast, as kpack is caching and will only create new layers that changed.__
As a nice side effect, we have enough time to watch the image building.

```shell
$ kubectl apply -f dockerhub-image.yaml
image.kpack.io/petclinic-image created
```

Watch the `build-pod` getting created

```shell
$ kubectl get pods
NAME                                      READY   STATUS     RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Init:1/6   0          14s
```

Have a look at our image status

```shell
$ kubectl get image
NAME              LATESTIMAGE   READY
petclinic-image                 Unknown
```

And the build status

```shell
$ kubectl get build
NAME                            IMAGE   SUCCEEDED
petclinic-image-build-1-bh9r4           Unknown
```

You can see that the status for the pod progresses through `Init:0/6` to `Init:6/6`

```shell
$ kubectl get pods
NAME                                      READY   STATUS     RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Init:4/6   0          3m8s
```

With some luck you will be able to catch the output of the build container while the pod is in `Init:4/6`

```shell
$ kubectl logs petclinic-image-build-1-bh9r4-build-pod -c build -f
```

```shell
$ kubectl get pods
NAME                                      READY   STATUS      RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Completed   0          9m7s
```

To help with the logs of all containers you can use the `logs.sh` script.
You pass the full name of your build-pod to the logs.sh script.

```shell
$ ./logs.sh petclinic-image-build-1-bh9r4-build-pod > build-output.txt
$ cat build-output.txt
```

Once the build is finished and succeeded, the image is pushed to your docker registry.
Use curl or your browser to confirm. 

```shell
$ curl -s -S 'https://registry.hub.docker.com/v2/repositories/<DOCKER_USERNAME>/' | jq .
...
      "user": "demosteveschmidt",
      "name": "ws-builder",
...
      "user": "demosteveschmidt",
      "name": "petclinic",
...
```

__All done for the MAIN part of the workshop__

You can now explore a bit what we've done so far or ...

[Continue with the EXTRAS part of the workshop](./EXTRAS.md)
