#!/usr/bin/env bash

set -euo pipefail

echo "Reset integration tests..."

script_path=$(realpath "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")
cd "$script_dir" || exit 1

rm -rf .terraform*
rm -rf terraform.tfstate*
rm -rf cluster

echo "[+] Initializing terraform..."
terraform init > /tmp/integration_test

echo "[+] Creating containers..."
terraform apply --auto-approve >> /tmp/integration_test

echo; bash "$script_dir/verify.sh"