NAMESPACE      ?= httpbin-production
HELM_RELEASE   ?= httpbin
HELM_CHART     := ./charts/httpbin
VALUES_HTTPBIN := ./helm_values_prod_httpbin.yaml
VALUES_HTTPBIN_GO := ./helm_values_prod_go-httpbin.yaml
CONTEXT        ?= k3d-dev

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} \
	/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Deploy

.PHONY: deploy
deploy: ## Deploy kennethreitz/httpbin
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
	  -f $(VALUES_HTTPBIN) \
	  -n $(NAMESPACE) --create-namespace \
	  --kube-context $(CONTEXT) \
	  --force-conflicts

.PHONY: deploy-go
deploy-go: ## Deploy mccutchen/go-httpbin
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
	  -f $(VALUES_HTTPBIN_GO) \
	  -n $(NAMESPACE) --create-namespace \
	  --kube-context $(CONTEXT) \
	  --force-conflicts

.PHONY: deploy-test
deploy-test: ## Deploy mccutchen/go-httpbin
	helm test $(HELM_RELEASE) \
	  -n $(NAMESPACE) \
	  --kube-context $(CONTEXT)

.PHONY: uninstall
uninstall: ## Uninstall the helm release
	helm uninstall $(HELM_RELEASE) -n $(NAMESPACE) --kube-context $(CONTEXT)

.PHONY: deploy-tail-logs
deploy-tail-logs: ## Tail deploy logs
	@echo "press ctrl+c to stop"
	@kubectl --context $(CONTEXT) -n $(NAMESPACE) logs deployments/$(HELM_RELEASE) -f --since 1m
	@echo "\n\n"

##@ Cluster

.PHONY: cluster-create
cluster-create: ## Create k3d dev cluster
	k3d cluster create --config iac/cluster_local/k3d_local_cluster.yaml \
	  --volume $(CURDIR)/iac/cluster_local/traefik_gateway.yaml:/var/lib/rancher/k3s/server/manifests/traefik-gateway.yaml@server:0

.PHONY: cluster-delete
cluster-delete: ## Delete k3d dev cluster
	k3d cluster delete dev

##@ Verify

.PHONY: pods-get
pods-get: ## Show pod distribution across nodes
	kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=$(HELM_RELEASE) -o wide --context $(CONTEXT)

.PHONY: service-get
service-get: ## Show pod distribution across nodes
	kubectl get svc -n $(NAMESPACE) -l app.kubernetes.io/name=$(HELM_RELEASE) --context $(CONTEXT)	

.PHONY: test
test: ## Run k6 smoke test (Job)
	kubectl delete job httpbin-smoke -n $(NAMESPACE) --context $(CONTEXT) 2>/dev/null || true
	kubectl apply -k iac/load_test/ --context $(CONTEXT)
	@echo "waiting for job completion (max 60seconds)\n"
	kubectl wait job/httpbin-smoke -n $(NAMESPACE) --for=condition=complete --timeout=30s --context $(CONTEXT) && \
	kubectl logs -n $(NAMESPACE) job/httpbin-smoke --context $(CONTEXT)
	kubectl delete job httpbin-smoke -n $(NAMESPACE) --context $(CONTEXT) 2>/dev/null || true

.PHONY: port-forward-8080-start
port-forward-8080-start: ## Port-forward httpbin to localhost:8080
	kubectl -n $(NAMESPACE) port-forward svc/$(HELM_RELEASE) 8080:80 --context $(CONTEXT) &

.PHONY: port-forward-8080-stop
port-forward-8080-stop: ## Port-forward httpbin to localhost:8080
	pkill -f "port-forward svc/httpbin"

.PHONY: cluster-debug-pod
cluster-debug-pod:
	@echo "WARNGING creating debug pod in your cluster"
	@kubectl --context $(CONTEXT) -n $(NAMESPACE) run debug --rm -it --restart=Never --image=ubuntu:24.04 bash

.PHONY: curl
curl: ## Quick curl check via httpbin.local (no ingress so )
	@echo "\n port-forward-8080-start - required before start (port 8080 will be used)\n"
	@curl -i http://localhost:8080/get

##@ Monitoring

.PHONY: deploy-sla
deploy-sla:
	@echo "in development ..."
# 	@echo "\n reading metrics from ingress (traefik)"
# 	kubectl delete pod sla-monitor -n $(NAMESPACE) --context $(CONTEXT) || true
# 	kubectl apply -k iac/monitoring_sla/ --context $(CONTEXT)  && \
# 	kubectl -n $(NAMESPACE) port-forward svc/sla-monitor 8085:80 --context $(CONTEXT)

