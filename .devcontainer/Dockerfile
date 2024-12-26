# This Dockerfile is used to build an image containing
# tools required for Kubernetes and Terraform/Terragrunt
# builds and workflows in the CI/CD pipeline.
# Use a specific Alpine Linux version
# Set default versions

# Find packages here: https://pkgs.alpinelinux.org/

# Kubernetes versions: https://kubernetes.io/releases/
# https://hub.docker.com/r/alpine/k8s/tags/
ARG K8S_VERSION=1.29.12

FROM alpine/k8s:${K8S_VERSION}

################################################################################

# Helm version - https://github.com/helm/helm/releases
ARG HELM_VERSION=3.16.3-r0

# Update package repositories and install necessary dependencies
RUN apk update && apk add --no-cache unzip helm=${HELM_VERSION} openssh docker nano

################################################################################

# Terraform and Terragrunt versions
# Cannot upgrade Terraform to 1.7.x due to this error:
# https://github.com/hashicorp/terraform/issues/34021#issuecomment-1752698805
ARG TERRAFORM_VERSION=1.5.7 

# Install terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/terraform \
    && chmod +x /usr/local/bin/terraform

################################################################################

# Install golang
RUN apk add --no-cache go
# Install https://github.com/plumber-cd/terraform-backend-git
RUN go install github.com/plumber-cd/terraform-backend-git@v0.1.8
# Add the go bin directory to the PATH
ENV PATH=$PATH:/root/go/bin

################################################################################

# Terragrunt - https://github.com/gruntwork-io/terragrunt/releases
ARG TERRAGRUNT_VERSION=0.54.22

# Install Terragrunt
RUN wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
    && mv terragrunt_linux_amd64 /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt

################################################################################

# ArgoCD AutoPilot version - https://github.com/argoproj-labs/argocd-autopilot/releases
ARG AUTOPILOT_VERSION=0.4.17

# Install argocd auto-pilot
RUN wget https://github.com/argoproj-labs/argocd-autopilot/releases/download/v${AUTOPILOT_VERSION}/argocd-autopilot-linux-amd64.tar.gz \
    && tar -xvf argocd-autopilot-linux-amd64.tar.gz \
    && mv argocd-autopilot-linux-amd64 /usr/local/bin/argocd-autopilot \
    && chmod +x /usr/local/bin/argocd-autopilot

################################################################################

# Terraform summarize - https://github.com/dineshba/tf-summarize/releases
ARG TFSUMMARIZE_VERSION=0.3.7

# Install Terraform summarize - https://github.com/dineshba/tf-summarize
RUN wget https://github.com/dineshba/tf-summarize/releases/download/v${TFSUMMARIZE_VERSION}/tf-summarize_linux_amd64.tar.gz \
    && tar -xvf tf-summarize_linux_amd64.tar.gz \
    && mv tf-summarize /usr/local/bin/tf-summarize \
    && chmod +x /usr/local/bin/tf-summarize

################################################################################

# Python and pip versions
ARG PYTHON_VERSION=3.12.8-r1
ARG PIP_VERSION=24.3.1

# Install Python
RUN apk add --no-cache python3=${PYTHON_VERSION} py3-pip \
    && pip3 install --upgrade --break-system-packages pip==${PIP_VERSION}

################################################################################
# Install Fly.io CTL
RUN curl -L https://fly.io/install.sh | sh
ENV PATH=$PATH:/root/.fly/bin

CMD ["/bin/bash"]
