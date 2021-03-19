# Cloud Native Buildpacks

### What are Cloud Natvie Buildpacks?

CNB for short turn your code into OCI-compliant containers. They examine your source code, build it, and create a container image with all the required dependencies to run your application.

Language family buildpacks exist for Java, Java Native Image, Node.js, Go, Ruby, PHP, .Net Core, HTTPD, NGINX and more.

### Concepts and terms

<img src=https://buildpacks.io/images/buildpacks-logo.svg width=200>

A subset of the information from the CNB website is reproduced here to cover the main concepts and terms.
https://buildpacks.io/docs/concepts/

### Buildpack

A buildpack is a unit of work that inspects your app source code and formulates a plan to build and run your application.

### Stack

A stack is composed of two images that are intended to work together:

- The **build image** of a stack provides the base image from which the build environment is constructed. The build environment is the containerized environment in which the lifecycle (and thereby buildpacks) are executed.
- The **run image** of a stack provides the base image from which application images are built.

### Lifecycle

The lifecycle orchestrates buildpack execution, then assembles the resulting artifacts into a final app image.

Phases:
- Detection – Finds an ordered group of buildpacks to use during the build phase.
- Analysis – Restores files that buildpacks may use to optimize the build and export phases.
- Build – Transforms application source code into runnable artifacts that can be packaged into a container.
- Export – Creates the final OCI image.

### Builder

A builder is an image that contains all the components necessary to execute a build. A builder image is created by taking a build image and adding a lifecycle, buildpacks, and files that configure aspects of the build including the buildpack detection order and the location(s) of the run image

<img src=https://buildpacks.io/docs/concepts/components/create-builder.svg width=600>

A builder consists of the following components:
- Buildpacks
- Lifecycle
- Stack’s build image

### Building an image

Build is the process of executing one or more buildpacks against the app’s source code to produce a runnable OCI image. Each buildpack inspects the source code and provides relevant dependencies. An image is then generated from the app’s source code and these dependencies.

<img src=https://buildpacks.io/docs/concepts/operations/build.svg width=600>

### Rebasing an image

Rebase allows app developers or operators to rapidly update an app image when its stack's run image has changed. By using image layer rebasing, this command avoids the need to fully rebuild the app.

<img src=https://buildpacks.io/docs/concepts/operations/rebase.svg width=600>

### Platform

A platform uses a lifecycle, buildpacks (packaged in a builder), and application source code to produce an OCI image.

Examples of a platform might include:
- A local CLI tool that uses buildpacks to create OCI images. One such tool is the Pack CLI
- A plugin for a continuous integration service that uses buildpacks to create OCI images. One such plugin is the buildpacks plugin in Tekton
- A cloud application platform that uses buildpacks to build source code before deployment. One such platform is **kpack**
