# Extra Labs

1. Rebasing an image without application changes
2. Rebuilding on source code commit

### Rebase the image

Rebasing can be done without building a new application artifact. When we change the run image in the stack, this will trigger a rebuild for every image using any language. No more guessing or hunting around for affected images.
When we initially wrote the stack.yaml, we specified an older version `1.1.20` on purpose. We will now remove the version which will cause the latest image to be used.

```
$ cat stack-latest.yaml 
apiVersion: kpack.io/v1alpha1
kind: ClusterStack
metadata:
  name: base
spec:
  id: "io.buildpacks.stacks.bionic"
  buildImage:
    image: "paketobuildpacks/build:base-cnb"
  runImage:
    image: "paketobuildpacks/run:base-cnb"
```

```
$ diff stack.yaml stack-latest.yaml 
8c8
<     image: "paketobuildpacks/build:1.1.20-base-cnb"
---
>     image: "paketobuildpacks/build:base-cnb"
10c10
<     image: "paketobuildpacks/run:1.1.20-base-cnb"
---
>     image: "paketobuildpacks/run:base-cnb"
```

```shell
$ kubectl apply -f stack-latest.yaml
```

```
$ kubectl get builds
NAME                            IMAGE                                                                                                                SUCCEEDED
petclinic-image-build-1-bh9r4   index.docker.io/demosteveschmidt/petclinic@sha256:acb0f840391ab9072b3a6ffd6263e1f2bde3f34a42fedbe7e1da0d4c74be6e77   True
petclinic-image-build-2-xnpr6                                                                                                                        Unknown
```
After a short while you should see the build for petclinic starting. If you still have the hello-node image defined, this will start a new build as well.

```
$ kubectl get builds
NAME                            IMAGE                                                                                                                SUCCEEDED
petclinic-image-build-1-bh9r4   index.docker.io/demosteveschmidt/petclinic@sha256:acb0f840391ab9072b3a6ffd6263e1f2bde3f34a42fedbe7e1da0d4c74be6e77   True
petclinic-image-build-2-xnpr6   index.docker.io/demosteveschmidt/petclinic@sha256:0f966338f29facb1c19067f81bf376b0a9597da72a8c6860fe748cf5d9522016   True
```


```
$ kubectl get images
NAME              LATESTIMAGE                                                                                                          READY
petclinic-image   index.docker.io/demosteveschmidt/petclinic@sha256:0f966338f29facb1c19067f81bf376b0a9597da72a8c6860fe748cf5d9522016   True
```

When we look at the steps this build completed we see just rebase.
```
$ kubectl describe build petclinic-image-build-2-xnpr6
...
  Steps Completed:
    rebase
```

And now we take a look at the reason for the build when we changed the base image.
```
$ kubectl describe build petclinic-image-build-2-xnpr6 | grep " image.kpack.io/reason"
              image.kpack.io/reason: STACK
```

Compare this to the first build when we defined the image.
```
$ kubectl describe build petclinic-image-build-1-bh9r4
...
  Steps Completed:
    prepare
    detect
    analyze
    restore
    build
    export
```

Let's see the reason for the build was then.
```
$ kubectl describe build petclinic-image-build-1-bh9r4 | grep " image.kpack.io/reason"
              image.kpack.io/reason: CONFIG
```

### Rebuild on commit

We will update the image definition for the petclinic-image and change from a `commit sha` to the `main` branch.
After this change, every commit to the main branch will trigger a new build. Make sure to change the tag: and url: lines
to your values.

```
$ cat dockerhub-image-main.yaml 
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
      revision: main
```

Apply the changes to the petclinic build image

```
$ kubectl apply -f dockerhub-image-main.yaml
```

This will start a new build as we changed the image definition

```
$ kubectl get builds
NAME                            IMAGE                                                                                                                SUCCEEDED
petclinic-image-build-1-bh9r4   index.docker.io/demosteveschmidt/petclinic@sha256:acb0f840391ab9072b3a6ffd6263e1f2bde3f34a42fedbe7e1da0d4c74be6e77   True
petclinic-image-build-2-xnpr6   index.docker.io/demosteveschmidt/petclinic@sha256:0f966338f29facb1c19067f81bf376b0a9597da72a8c6860fe748cf5d9522016   True
petclinic-image-build-3-lkfm9                                                                                                                        False
petclinic-image-build-4-jcrmz                                                                                                                        Unknown
```

```
$ kubectl get pods
NAME                                      READY   STATUS       RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Completed    0          44m
petclinic-image-build-2-xnpr6-build-pod   0/1     Completed    0          15m
petclinic-image-build-3-lkfm9-build-pod   0/1     Init:Error   0          30s
petclinic-image-build-4-jcrmz-build-pod   0/1     Init:1/6     0          9s
```

```
$ kubectl describe build petclinic-image-build-4-jcrmz | grep  " image.kpack.io/reason"
              image.kpack.io/reason: COMMIT
```

```
$ kubectl get pods
NAME                                      READY   STATUS       RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Completed    0          46m
petclinic-image-build-2-xnpr6-build-pod   0/1     Completed    0          17m
petclinic-image-build-3-lkfm9-build-pod   0/1     Init:Error   0          2m30s
petclinic-image-build-4-jcrmz-build-pod   0/1     Completed    0          2m9s
```

We now have **much faster builds** since all the dependencies are cached.

```
$ ./logs.sh petclinic-image-build-4-jcrmz-build-pod > build-output-2.txt 
$ cat build-output-2.txt
```

### Change source code

On Github on your own fork of spring-petclinic, navigate to the application.properties file. Update the welcome message to your liking.
`spring-petclinic/src/main/resources/messages/messages.properties`

```
welcome=Techie Workshop Rocks! Sep 14th 2021
```

```
$ kubectl describe build petclinic-image-build-5-fgfph | grep " image.kpack.io/reason"
              image.kpack.io/reason: COMMIT
```

```
$ kubectl get pods
NAME                                      READY   STATUS       RESTARTS   AGE
petclinic-image-build-1-bh9r4-build-pod   0/1     Completed    0          54m
petclinic-image-build-2-xnpr6-build-pod   0/1     Completed    0          24m
petclinic-image-build-3-lkfm9-build-pod   0/1     Init:Error   0          10m
petclinic-image-build-4-jcrmz-build-pod   0/1     Completed    0          9m54s
petclinic-image-build-5-fgfph-build-pod   0/1     Completed    0          112s
```

```
$ ./logs.sh petclinic-image-build-5-fgfph-build-pod > build-output-3.txt
```

```
$ curl -s -S 'https://registry.hub.docker.com/v2/repositories/demosteveschmidt/petclinic/tags' | jq . | grep '"b'
      "name": "b5.20210318.182152",
      "name": "b4.20210318.181351",
      "name": "b2.20210318.175858",
      "name": "b1.20210318.172935",
```

A good practice in Kubernetes is to refer to the image includig a tag or a sha. To see your updated image with the new message, edit the deployment and change the image name to your latest image including the tag.
Kubernetes will spin up a new pod with that image.

```
$ kubectl edit deployment petclinic
...
      - image: index.docker.io/demosteveschmidt/petclinic:b5.20210318.182152
...
```

Wait until the pod is running, then refresh your browser tab for petclinic.

### Congratulations!

Hey! You made it through the workshop AND the extras. 
I hope you had fun and gained a good overview of buildpacks and kpack.
For more information and guides head over to tanzu.vmware.com/developer
