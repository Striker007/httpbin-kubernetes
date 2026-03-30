# httpbin kubernetes deployment

"httpbin.org is a simple HTTP request and response service. 
It is a useful tool for testing HTTP clients and debugging webhooks. 
The service provides a variety of endpoints that return different types of data, such as headers, IP address, and user-agent."

This repo contains minimal and clean solution of Kubernetes deployment for `kennethreitz/httpbin` image,
and `mccutchen/go-httpbin` (it's modern counterpart - more secure, lightwaight)

## Table of Contents
- [Goal](#goal)
- [Architecture](#architecture)
- [Demo](#demo)
  - [prerequisites](#prerequisites)
  - [deployment test](#deployment-test)
  - [result](#result)
- [Docker image (CAUTION)](#docker-image-caution)
  - [Considerations !](#docker-image-caution)
  - [Detailed review](DEVELOPMENT.md#docker-image-review)
  - [Improvements](DEVELOPMENT.md#docker-image-improvements-best-practice)
- [DEVELOPMENT Process](DEVELOPMENT.md). 
  - include concerns, docker image review, [observability](DEVELOPMENT.md#observability) etc.


## Goal
- the goal is to provide simple but secure and reliable deployment for `kennethreitz/httpbin` application
- to follow Kubernetes, container, and security best practices
- deployment is evenly distributed across the cluster
- (assumptions) 
  - we need to keep availability (N+1)
  - we have cluster >= 3 "worker" nodes
  - public access is not expected, but we need provide some way for inter-app requiests
  - traffic - moderate, may be from other applications or users

## Architecture

- Deployment
    - 3 replicas by N+1 redundancy
    - topologySpreadConstraints - should help with "evenly distributed across the cluster" part
      - Pros: more agile and stable approach insted of pod anti-affinity
      - Assumption: we may have case 2 pods on one node (not distributed well), it's controlled by maxSkew + ScheduleAnyway
    - PodDisruptionBudget - availability in tough conditions
    - RollingUpdate - smooth update without downtime
- Access
  - Service
    - endpoint with ClusterIP
    - user access without ingress (port forward)
  - (Optional) Ingress - not required
- Capacity
   - limits and requests
     (it helps to schedule or eviction)
- Security
  - Container / Image
    - optimal image (base and multi stage), versioning ...
    - ideally mirrored to personal registry
    - scanned 
  - Kubernetes
    - capabilities , privilage, user, api tokens, ro fs
    - NetworkPolicy - no egress traffc, limited ingress
- (not done)
  - security admission
  - secrets 
- Docker image (notice)
  - [Considerations !](#docker-image-caution)
  - [DEVELOPMENT details](DEVELOPMENT.md#docker-image-review)

[up](#table-of-contents)


## Demo

#### Prerequisites 

| purpose | name | link |
|----------|----------|----------|
| Usage | | |
| | Helm | [Helm](https://helm.sh/) |
| | Kubectl | [kubectl](https://kubernetes.io/docs/tasks/tools/) |
| | Make | MacOS install if missed `xcode-select --install` |


#### deployment (test)
```bash
# helm/kubectl --context
export CONTEXT=my-test-cluster

# deploy
make deploy
# OR make deploy-go

# helm test (curl to svc inside cluster)
# make deploy-test

# Ensure the deployment is evenly distributed across the cluster. 
# Demonstrate that the container is up and running.
make pods-get
make service-get
make test

# clean
make uninstall 
```

#### result
container is up and running.
```bash
# deployment
NAME                       READY   STATUS    RESTARTS   AGE   IP          NODE              NOMINATED NODE   READINESS GATES
httpbin-6b546d6876-9p5bl   1/1     Running   0          31s   10.42.1.4   k3d-dev-agent-2   <none>           <none>
httpbin-6b546d6876-ltndw   1/1     Running   0          31s   10.42.2.3   k3d-dev-agent-0   <none>           <none>
httpbin-6b546d6876-rnbwl   1/1     Running   0          31s   10.42.4.3   k3d-dev-agent-1   <none>           <none>


# K6 test (part of outpur)
   ✓ checks.........................: 100.00% 6 out of 6
   ✓ http_req_failed................: 0.00%   0 out of 4
```

[up](#table-of-contents)


## Docker image (CAUTION)
- `kennethreitz/httpbin` image - it contains have working app but there are concerns regarding security and support
- the main purpose of this image is testing/debuggin http your http requests,
  it's unlikely to be used in production publicly accessible (except httpbin.org website) + it dosnt provide/store any sensitive data itself but Docker image may be improved
- this repo support few options "A"/"B", "D":
  - A) use original image as it is 
    - which is [kennethreitz/httpbin](https://github.com/kennethreitz/httpbin/blob/master/Dockerfile) 0.9.2 or [postmanlabs/httpbin](https://github.com/postmanlabs/httpbin) 0.10.2 ([pypi](https://pypi.org/project/httpbin/#history))
    - both are abandoned 7+ years ago
    - size=534MB
  - B) re-pack original `kennethreitz` code
    - use minimal runtime image (smaller security footprint)
    - apply Docker **Best practives** (whatever us possible in this case - we cant change a lot without updating code)
    - requires some time to check dependencies and requirements
    - done [Dockerfile](iac/docker/Dockerfile)
    - size 177MB
  - C) go with **pfs** fork
    - newer python, better image quality.
    - also abandoned 2 years ago
    - size=301MB
  - D) use Golang implementation (it looks as **best alternative** for me)
    - [mccutchen/go-httpbin](https://github.com/mccutchen/go-httpbin)
    - quick audit shows fewer high severity vulneraiblities 
    - activly supported
    - distroless image, single binary, new soft
    - size=20.5MB
  - E) update the original code original image [kennethreitz/httpbin](https://github.com/kennethreitz/httpbin/blob/master/Dockerfile)
    - a) rewrite
      - using latest secure base image
      - new python version and dependencies
      - (time) it require us updateing all related code
    - b) generate
      - there is Swagger info, so we can generate new code with openapi-generator
      - (time) to move logic (delays, stream etc.)

[up](#table-of-contents)

#### [>> DEVELOPMENT details](DEVELOPMENT.md)
