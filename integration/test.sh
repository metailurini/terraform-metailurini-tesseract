#!/usr/bin/env bash

set -euo pipefail

echo "Running integration tests..."

script_path=$(realpath "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")
cd "$script_dir" || exit 1

echo "[+] Try to apply changes to terraform..."
terraform apply --auto-approve >> /tmp/integration_test

echo "[+] Destroying any existing containers..."
terraform destroy --auto-approve >> /tmp/integration_test

echo; bash "$script_dir/reset.sh"
