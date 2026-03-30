
# HTTP Testing for httpbin deployment

- [Return to main README.md](../../README.md)
- [Return to DEVELOPMENT Process](../../DEVELOPMENT.md)

scopre:
- `/get` - 200
- `status/200`, `status/404`, `status/503`,

```bash
# kubectl config use-context k3d-dev 
# 
kubectl apply -k load_test
#
kubectl  wait job/httpbin-smoke -n httpbin-production --for=condition=complete --timeout=60s
#
kubectl  logs -n httpbin-production job/httpbin-smoke -f  
#
kubectl  delete job httpbin-smoke -n httpbin-production
```
