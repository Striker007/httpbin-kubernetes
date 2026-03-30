# httpbin-kubernetes

## Table of Contents
- [<< Return to main README.md](README.md)
-
- [Initial idea](#initial-idea)
- [Prerequisites](#prerequisites)
- [Deploy](#quick-start)
- [Plan and log](#plan-and-log)
  - [Starting app](#starting-app)
  - [Docker image review](#docker-image-review)
  - [Kubernetes deployment](#kubernetes-deployment)
  - [Testing](#testing)
  - [Summary](#summary)
  - [Observability](#observability)

## Initial idea
- Create a Kubernetes deployment using the public Docker image `kennethreitz/httpbin`.
- Ensure the deployment is evenly distributed across the cluster.
- Follow Kubernetes, container, and security best practices.
- Keep the solution minimal and clean.
- Demonstrate that the container is up and running.

## Prerequisites

| purpose | name | link |
|----------|----------|----------|
| Usage | | |
| | Helm | [Helm](https://helm.sh/) |
| | Kubectl | [kubectl](https://kubernetes.io/docs/tasks/tools/) |
| | Make | MacOS install if missed `xcode-select --install` |
| Local Cluster | (testing/development) | |
| | K3d | [K3d](https://k3d.io/stable/#installation) |
| | containers env (engine) | |
| | a) OrbStack | [OrbStack](https://orbstack.dev/download) | 
| | or | |
| | b) Docker | [Docker](https://docs.docker.com/engine/install/) |
| optional | | |
| | jq | Install [jq](https://jqlang.org/download/) |


(optional) VisualCode config (.bscode/settings.json)
```bash
{
    "yaml.schemas": {
        "./charts/httpbin/values.schema.json": [
            "charts/httpbin/values.yaml"
        ]
    }
}
```

[up](#httpbin-kubernetes)

## Quick start
```bash
# docker
cd iac/docker
make build
make run

# prepare
make cluster-create

# docker image
cd iac/docker
make build
# make run
make push
# we can check registry
# curl http://localhost:5111/v2/local-httpbin/tags/list
cd -
# 
make deploy

# curl to svc
# make deploy-test

# info
# Ensure the deployment is evenly distributed across the cluster. 
# Demonstrate that the container is up and running.
make pods-get
make service-get
make test

# clean
make uninstall 
make cluster-delete

# user requests (optional)
make port-forward-8080-start
make curl
make port-forward-8080-stop
```

[up](#httpbin-kubernetes)

## Plan and log
  
  - review docker registry for info about image
  - test app locally
  - find out source code of application and Dockerfile (for now it's blackbox)
  - check and scan docker image
  - prepare plain kubernetes configs (ns, deployment, pdb, service, maybe ingress, network policy)
  - helm chart
  - (not sure) argocd/fluxcd may be overhead "minimal and clean"

[up](#httpbin-kubernetes)

#### starting app
  - app returns HTML documentation - it seems this app helps with testing different HTTP scenarious, faking web app
  - there is few helpful **endpoints**
    - `/get` returns 200
    - `/status/{code}` to fake code
    - `/delay/{seconds}` to fake latency

[up](#httpbin-kubernetes)

#### docker image review
- **docker image** observing `kennethreitz/httpbin`
  - Check public information 
    - the only tag latest means we cant stick to version
      (+ digest looks not support for old images, the only way to be safe it's to have a coupy of this image in our registry)
    - latest update 7years ago
    - ubuntu:18.04 - looks risky (end of support 2023)
    - Python 3.6.6 (end-of-life on 2021)
    - code kennethreitz/httpbin - latest commit 8years ago 
      (it's some Python Flask app - entrypoint core.py)
  - Surity Audit (issues severity)
    - checking Docker image for CVE `trivy image kennethreitz/httpbin:latest` - app **8 high** , os **87 high** (total 2631)
    - checking code - `snyk code test kennethreitz_httpbin` - **3 high** issues XSS
    - additionally check with Grype and Syft
        - check
          - `syft kennethreitz_httpbin -o cyclonedx-json > sbom.json`
          - `grype sbom:sbom.json`
        - detected
          - **8 high**
  - Dockerfile review
    - source code `https://github.com/kennethreitz/httpbin` (probably)
    - Dockerfile [kennethreitz/httpbin](https://github.com/kennethreitz/httpbin/blob/master/Dockerfile)
    - there are NO
      - USER
      - version of apps are not specificed
      - multi stage build (we dont need build env at runtime, caches and tools)
      - health check
    - gunicorn app is used to allow async work (supervisor for processes), default settings
    - additionally we may check Dockerfile with linter `hadolint Dockerfile`

[up](#httpbin-kubernetes)

#### kubernetes deployment
  - Plain kubernetes manifests
    - the goal is to create IaC code - deployment and related parts (to keep things simple - helm could be enough)
    - to speed-up generate minimal manifests like deployment `kubectl create deployment`
      ( namespace, deployment, pdb, service, networkpolicy, (optionally) ingress)
    - possibly check with linter `kube-linter`
  - Helm chart
    - helm create httpbin
    - helm schema ( `helm plugin install https://github.com/losisin/helm-values-schema-json --verify=false` )

[up](#httpbin-kubernetes)

#### testing
  - non functional 
    - get pods deployed and healthy
    - get pods logs
    - check if all pods deployed on separate nodes
  - functional
    - make some HTTP request
  - disaster
    - one node fails
    - kill some nodes OR cordon/drain

[up](#httpbin-kubernetes)

#### summary
  - we have app working , but original docker image dosnt look secure/production ready
    (it may be forgotten in some cluster and used by bots/bad actors via supply chain etc.)
  - there is extra work to update this app and docker image, 
    so as optimal solution (for testing purpose) we have re-pack docker image [Dockerfile](iac/docker/Dockerfile)

[up](#httpbin-kubernetes)

----

#### Observability
- How to monitor this app (ides - not implemented in this scope)
  - what and how
    - httpbin - no metrics/agents included by default (except access logs)
    - resources default in many clusters is prometheus/victoria metrics
    - app logs vector agent (opensearch, elasticsearch)
    - app transactions/exceptions - datadog, sentry
    - golden signals (latency, traffic, errors, saturation)
      - gathering metrics from ingress
      - or adding some instruments to have this from the app
  - simple options (done)
    - (idea 1) to gather Ingeress metrics (requires traefik, nginx etc)
      - prometheus/victoria metrics to pull and show metrics
      - (done) use script [monitoring_sla](iac/monitoring_sla/README.md)
        - requires ingress
    - (idea 2) to use load testing like https://k6.io/
      - (done) [load tess](iac/load_test/README.md)


[Jump UP](#httpbin-kubernetes) or [Return to main README.md](README.md)
