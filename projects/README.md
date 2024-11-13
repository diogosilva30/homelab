# Projects
This directory contains all of your `argocd-autopilot` projects. Projects provide a way to logically group applications and easily control things such as defaults and restrictions.

### Creating a new project
To create a new project run:
```bash
export GIT_TOKEN=<YOUR_TOKEN>
export GIT_REPO=<REPO_URL>

argocd-autopilot project create <PROJECT_NAME>
```

### Creating a new project on different cluster
You can create a project that deploys applications to a different cluster, instead of the cluster where Argo-CD is installed. To do that run:
```bash
export GIT_TOKEN=<YOUR_TOKEN>
export GIT_REPO=<REPO_URL>

argocd-autopilot project create <PROJECT_NAME> --dest-kube-context <CONTEXT_NAME>
```
Now all applications in this project that do not explicitly specify a different `--dest-server` will be created on the project's destination server.


### Sealed secrets

For using your own keys for Sealed Secrets. Check [this doc](https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md) for further documentation.

```shell
export PRIVATEKEY="private.key"
export PUBLICKEY="public.crt"
export NAMESPACE="sealed-secrets"
export SECRETNAME="keys"

openssl req -x509 -days 358000 -nodes -newkey rsa:4096 -keyout "$PRIVATEKEY" -out "$PUBLICKEY" -subj "/CN=sealed-secret/O=sealed-secret"

kubectl -n "$NAMESPACE" create secret tls "$SECRETNAME" --cert="$PUBLICKEY" --key="$PRIVATEKEY"
kubectl -n "$NAMESPACE" label secret "$SECRETNAME" sealedsecrets.bitnami.com/sealed-secrets-key=active
kubectl -n "$NAMESPACE" delete pod -l app.kubernetes.io/instance=sealed-secrets
kubectl -n "$NAMESPACE" logs -l app.kubernetes.io/instance=sealed-secrets
```

Example creating sealed secret. Let's say you have this secret (`pihole-password.yaml`):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pihole-password
type: Opaque
stringData:
  pihole_password: <my-password>
```
You can create a sealed secret from it by running:
```shell
kubeseal --cert "./${PUBLICKEY}" --scope cluster-wide --format yaml < pihole-password.yaml > sealed-pihole-password.yaml
```
You can then commit `sealed-pihole-password.yaml` to your repository instead of `pihole-password.yaml`.