NAMESPACE  ?= httpbin-production
CONTEXT    ?= k3d-dev

.PHONY: deploy-sla
deploy-sla:
	kubectl apply -k . --context $(CONTEXT)

.PHONY: deploy-sla-uninstall
deploy-sla-uninstall:
	kubectl delete -k . --context $(CONTEXT) 

.PHONY: deploy-sla-traefik-metrics-on
deploy-sla-traefik-metrics-on:
	@echo "access to Traefik metrics endpoint (svc)"
	kubectl expose deployment traefik \
	--name=traefik-metrics \
	--port=9100 --target-port=9100 \
	--namespace=kube-system \
	--context $(CONTEXT)

.PHONY: deploy-sla-traefik-metrics-off
deploy-sla-traefik-metrics-off:
	kubectl delete svc traefik-metrics -n kube-system --context $(CONTEXT)

.PHONY: deploy-sla-port-forward-8085
deploy-sla-port-forward-8085:
	kubectl -n $(NAMESPACE) port-forward svc/sla-monitor 8085:80 --context $(CONTEXT)

.PHONY: logs
logs:
	@echo "press ctrl+c to stop"
	kubectl logs pod/sla-monitor -n $(NAMESPACE) --context $(CONTEXT) -f --since 1m
