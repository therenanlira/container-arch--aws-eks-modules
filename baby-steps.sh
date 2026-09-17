#!/bin/bash
set -euo pipefail

VPC_DIR="$HOME/git/container-arch--aws-eks-vpc/terraform"
EKS_DIR="$HOME/git/container-arch--aws-eks/terraform"

tf() {
  (cd "$1" && terraform "$2" -auto-approve -var-file=environment/prd/terraform.tfvars)
}

apply() {
  tf "$VPC_DIR" apply
  tf "$EKS_DIR" apply
  aws eks update-kubeconfig --name prd-ct-arch-eks --alias learning-account--prd-ct-arch-eks
}

destroy() {
  tf "$EKS_DIR" destroy
  tf "$VPC_DIR" destroy
}

case "${1:-}" in
  --apply | -A)
    apply
    ;;
  --destroy | -D)
    destroy
    ;;
  *)
    echo "Usage: $0 [--apply|-A] [--destroy|-D]"
    exit 1
    ;;
esac
