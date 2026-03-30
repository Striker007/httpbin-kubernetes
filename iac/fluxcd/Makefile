NAMESPACE  ?= httpbin-production
CONTEXT    ?= k3d-dev
GITHUB_OWNER ?= Striker007

.PHONY: flux-cluster-check-pre
flux-cluster-check-pre:
	flux check --pre --context $(CONTEXT)

.PHONY: flux-cluster-bootstrap
flux-cluster-bootstrap:
	flux bootstrap github \
	--token-auth \
	--owner=${GITHUB_OWNER} \
	--repository=fluxcd_test \
	--branch=main \
	--path=clusters/my-cluster \
	--personal \
	--private=false \
	--context $(CONTEXT)

.PHONY: flux-deploy-podinfo
flux-deploy-podinfo:
	flux create source git podinfo \
	--url=https://github.com/stefanprodan/podinfo \
	--branch=master \
	--interval=1m \
	--export > ./fluxcd_test/clusters/my-cluster/podinfo-source.yaml \
	--context $(CONTEXT)
