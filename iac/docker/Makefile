

.PHONY: get-sources build push all

# the latest known commit used in `kennethreitz/httpbin` image
HTTPBIN_COMMIT ?= f8ec666

get-sources:
	stat httpbin || (git clone https://github.com/kennethreitz/httpbin.git && git -C httpbin checkout $(HTTPBIN_COMMIT))

build: get-sources
	docker buildx build --file=Dockerfile  -t local-httpbin:v0.9.2 .

build-dev: get-sources
	docker buildx build --file=Dockerfile  -t local-httpbin:v0.9.2-dev . --target builder

# local registry
push: build
	docker tag local-httpbin:v0.9.2 localhost:5111/local-httpbin:v0.9.2
	docker push localhost:5111/local-httpbin:v0.9.2

push-dev: build
	docker tag local-httpbin:v0.9.2-dev localhost:5111/local-httpbin:v0.9.2-dev
	docker push localhost:5111/local-httpbin:v0.9.2-dev

run-dev:
	docker run -ti --rm -p 8083:8080 local-httpbin:v0.9.2-dev bash

run:
	docker run --rm -p 8083:8080 local-httpbin:v0.9.2
