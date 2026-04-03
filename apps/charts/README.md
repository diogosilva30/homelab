# Helm Charts

Minimal, production-ready Helm charts for deploying The Academic Editorial.

## Structure

```
charts/
├── backend/     # Django API (uvicorn on port 8000)
└── frontend/    # Vite app served via Nginx (port 80)
```

Each chart is **independently deployable** — no umbrella chart, no dependencies between charts.

## Prerequisites

- Kubernetes cluster with an ingress controller (e.g., nginx-ingress)
- External PostgreSQL database (provide `DATABASE_URL` via env)
- Helm 3.x

## Deploying from local charts

```bash
# Backend
helm upgrade --install backend ./charts/backend \
  --set image.repository=ghcr.io/diogosilva30/the-academic-editorial/backend \
  --set image.tag=1.0.0 \
  --set env[0].name=DATABASE_URL \
  --set env[0].value=postgres://user:pass@host:5432/db \
  --set env[1].name=DJANGO_SECRET_KEY \
  --set env[1].value=your-secret-key

# Frontend
helm upgrade --install frontend ./charts/frontend \
  --set image.repository=ghcr.io/diogosilva30/the-academic-editorial/frontend \
  --set image.tag=1.0.0
```

## Deploying from OCI registry (GHCR)

Charts are published as OCI artifacts on dedicated Helm releases:

- Backend chart tags: `helm-backend-vX.Y.Z`
- Frontend chart tags: `helm-frontend-vX.Y.Z`
- Chart versions are independent from backend/frontend application versions

Chart releases are automated by semantic-release and triggered only when commits
include changes under the corresponding chart directories:

- `charts/backend/**` for backend chart releases
- `charts/frontend/**` for frontend chart releases

```bash
# Pull a specific version
helm pull oci://ghcr.io/diogosilva30/the-academic-editorial/charts/backend --version 1.0.0
helm pull oci://ghcr.io/diogosilva30/the-academic-editorial/charts/frontend --version 1.0.0

# Install directly from OCI
helm upgrade --install backend \
  oci://ghcr.io/diogosilva30/the-academic-editorial/charts/backend \
  --version 1.0.0 \
  --set image.repository=ghcr.io/diogosilva30/the-academic-editorial/backend \
  --set image.tag=1.0.0
```

## Configuration

Both charts accept the same structure in `values.yaml`:

| Key | Description | Default |
|-----|-------------|---------|
| `image.repository` | Container image registry/name | `""` (must set) |
| `image.tag` | Container image tag | `""` (must set) |
| `image.pullPolicy` | Pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `ingress.enabled` | Enable ingress resource | `true` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `env` | Environment variables list | varies |
| `resources` | CPU/memory requests/limits | `{}` |

### Frontend-specific

| Key | Description | Default |
|-----|-------------|---------|
| `ingress.backendService.name` | Backend k8s service name | `backend` |
| `ingress.backendService.port` | Backend service port | `80` |
| `ingress.backendService.path` | API path to route to backend | `/api` |

## Health Checks

- **Backend**: `GET /ht/` on port 8000 — powered by [django-health-check](https://github.com/revsys/django-health-check), verifies database connectivity
- **Frontend**: `GET /health` on port 80 — nginx built-in health endpoint

## Assumptions

- **No database in charts** — PostgreSQL is external; provide `DATABASE_URL` as an env var
- **No secrets management** — sensitive values (`DJANGO_SECRET_KEY`, `DATABASE_URL`, `JWT_SECRET_KEY`) must be supplied via `--set` or an external Secret resource
- **Ingress controller required** — charts assume one is already installed in the cluster
- **Frontend references backend** — the frontend ingress routes `/api` to the backend service; defaults to service name `backend` (matching `helm upgrade --install backend ...`)
- **Frontend Docker target** — CI must build with `--target production` to produce the nginx image

## Backend LLM Proxy

The backend chart can optionally deploy an in-cluster `llm-proxy` service,
similar to the local Docker Compose setup.

Enable it with:

```bash
helm upgrade --install backend ./charts/backend \
  --set llmProxy.enabled=true \
  --set llmProxy.ghToken=YOUR_GH_TOKEN
```

For production, inject `GH_TOKEN` from an existing Kubernetes Secret:

```bash
helm upgrade --install backend ./charts/backend \
  --set llmProxy.enabled=true \
  --set llmProxy.ghTokenSecret.name=llm-proxy-secret \
  --set llmProxy.ghTokenSecret.key=GH_TOKEN
```

When enabled, backend gets `DJANGO_LLM_BASE_URL` automatically set to the internal
service URL (`http://<release>-backend-llm-proxy:4141/v1`).

Relevant backend values:

- `llmProxy.enabled` toggles deployment
- `llmProxy.accountType` sets `--account-type` (default `business`)
- `llmProxy.ghToken` sets `GH_TOKEN` inline (dev/local)
- `llmProxy.ghTokenSecret.name` and `llmProxy.ghTokenSecret.key` use Secret-based token injection
- `llmProxy.persistence.enabled` stores proxy data on a PVC

## Backend Profile Git Sync

Backend can optionally sync journal profiles from a Git repository into
`/profiles/official` inside the pod.

When enabled, the chart deploys:

- a `git-sync` init container (`--one-time`) before backend starts
- a `git-sync` sidecar with periodic refreshes

Example:

```bash
helm upgrade --install backend ./charts/backend \
  --set profiles.gitSync.enabled=true \
  --set profiles.gitSync.repo=https://github.com/your-org/your-profiles-repo.git \
  --set profiles.gitSync.branch=main
```

Relevant values:

- `profiles.gitSync.enabled`
- `profiles.gitSync.repo` (required when enabled)
- `profiles.gitSync.branch`
- `profiles.gitSync.depth`
- `profiles.gitSync.syncIntervalSeconds`
- `profiles.gitSync.mountPath` (default `/profiles/official`, managed via git-sync `--root` + `--link`)

Token auth for private repositories (HTTPS):

```bash
helm upgrade --install backend ./charts/backend \
  --set profiles.gitSync.enabled=true \
  --set profiles.gitSync.repo=https://github.com/your-org/your-profiles-repo.git \
  --set profiles.gitSync.auth.enabled=true \
  --set profiles.gitSync.auth.tokenSecretName=profiles-git-token \
  --set profiles.gitSync.auth.tokenKey=token \
  --set profiles.gitSync.auth.username=x-access-token
```
