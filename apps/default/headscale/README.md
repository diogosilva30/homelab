# Headscale VPN

## Tutorial

To expose the headscale service so we can connect to it from the internet, we will use a Fly.io proxy
service. This will be connected to the headscale service using wireguard tunnel for secure communication.

Steps:

1. Create a new Fly.io account and make sure fly ctl is installed (`curl -L https://fly.io/install.sh | sh`).
2. Login to fly.io using `fly auth login`.
3. Launch the fly instance using: `fly launch`. This will read the `fly.toml` file and create the instance.
4. Create SSH connection to the fly instance using `fly ssh console`.
5. Get the wireguard configuration file using `cat /etc/wireguard/peer1.conf`.
6. The content of this file should be added to the **wireguard-peer-conf** `SealedSecret` in `manifests/wireguard-peer.yaml`.
7. Verify access to `https://vpn.dsilva.dev/swagger`.

## Generate API key

```bash
kubectl exec -it -n headscale deploy/headscale -- headscale apikeys create -e 99y
```

Based on [this](https://www.youtube.com/watch?v=rGJ5RvB_aBg&t=373s) video and this [blog post](https://digitallyrefined.github.io/guides/Tailscale-Headscale-setup).
