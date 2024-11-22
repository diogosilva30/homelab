# Headscale VPN

## Generate API key

```bash
kubectl exec -it -n headscale deploy/headscale -- headscale apikeys create -e 99y
```

## Current issues

- https://github.com/cloudflare/cloudflared/issues/990
- https://github.com/cloudflare/cloudflared/issues/883
- https://github.com/juanfont/headscale/issues/1468#issuecomment-1967338278