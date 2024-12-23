#!/bin/bash

print_green() {
    printf "\e[32m%s\e[0m\n" "$1"
}

# Add the git safe directory
git config --global --add safe.directory /workspace

# # Install pre-commit hooks
# pip install pre-commit > /dev/null && pre-commit install > /dev/null
# print_green "✅ Installed pre-commit hooks"

# Configure code as the default editor
git config --global core.editor "code --wait"
# Disable gpg signing
git config commit.gpgSign false

# Create alias for "tf"
echo "alias tf='terraform-backend-git git --config /workspace/terraform/terraform-backend-git.hcl terraform'" >> ~/.bashrc
source ~/.bashrc
echo "✅ Use 'tf' to run Terraform commands"