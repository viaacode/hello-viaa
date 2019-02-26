## Introduction

This is an opinionated template Ruby app using Gitlab CI/Openshift/Docker.

## Conventions

### Git flow

[Git flow](https://danielkummer.github.io/git-flow-cheatsheet/) is used as a branching model. See .gitlab-ci.yml.

### RVM

RVM is used as a Ruby version manager. See .ruby-gemset and .ruby-version. Change gemset name to app name.

### Docker

Docker is used to build and run containers. See Dockerfile.

#### Commands

Build test image
```bash
docker build . -t test_hello_world --target Test
```
Build prd image
```bash
docker build . -t hello_world
```
Run tests
```bash
docker run --rm -it test_hello_world
```
Run server
```bash
docker run --rm -it -p 4567:4567 hello_world
```

### Gitlab CI

Gitlab CI is used to build and test Docker images and push them to the Gitlab registry.

To run it locally [install a gitlab runner or run it via docker](https://docs.gitlab.com/runner/install/):

```bash
docker run --rm -t -i gitlab/gitlab-runner --help
```

### Openshift

Openshift is based on kubernetes. It is used to deploy the Docker containers. The openshift/init.sh script initiates the Openshift environment. See [confluence](https://viaadocumentation.atlassian.net/wiki/spaces/SI/pages/938147860/Openshift+basics+for+application+developers).
