### rebase the image

We do so by patching the run image.

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
<     image: "paketobuildpacks/build:1.0.24-base-cnb"
---
>     image: "paketobuildpacks/build:base-cnb"
10c10
<     image: "paketobuildpacks/run:1.0.24-base-cnb"
---
>     image: "paketobuildpacks/run:base-cnb"
```

```
$ kubectl get builds
NAME                            IMAGE                                                                                                                SUCCEEDED
petclinic-image-build-1-bh9r4   index.docker.io/demosteveschmidt/petclinic@sha256:acb0f840391ab9072b3a6ffd6263e1f2bde3f34a42fedbe7e1da0d4c74be6e77   True
petclinic-image-build-2-xnpr6                                                                                                                        Unknown
```
After a short while

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

```
$ kubectl describe build petclinic-image-build-2-xnpr6
...
  Steps Completed:
    rebase
```

```
$ kubectl describe build petclinic-image-build-1-bh9r4 | grep " image.kpack.io/reason"
              image.kpack.io/reason: CONFIG
```

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

```
$ kubectl describe build petclinic-image-build-2-xnpr6 | grep " image.kpack.io/reason"
              image.kpack.io/reason: STACK
```


### rebuild on commit

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

```
We now have **much faster builds** since all the dependencies are cached.


```
$ ./logs.sh petclinic-image-build-4-jcrmz-build-pod > build-output-2.txt 
$ cat build-output-2.txt
```

### change source code

On Github on your own fork of spring-petclinic, navigate to the to the application.properties file. Update the welcome message to your liking.
`spring-petclinic/src/main/resources/messages/messages.properties`

```
welcome=Techie Workshop Rocks! Apr 21st 2021
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


