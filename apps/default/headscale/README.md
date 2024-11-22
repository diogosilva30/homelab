# Headscale VPN

## Generate API key

```bash
kubectl exec -it -n headscale $(kubectl get pod -n headscale -l app.kubernetes.io/name=headscale -o jsonpath='{.items[0].metadata.name}') -- headscale apikeys create
```