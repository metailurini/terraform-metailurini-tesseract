#!/usr/bin/env bash

set -euo pipefail

echo "Checking that the containers are running..."

script_path=$(realpath "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")
cd "$script_dir" || exit 1
namespace="$(
  grep -o 'namespace = "[^"]*' < main.tf \
  | sed 's/.*"//g'
)"

cd ..

status=0
apps=$(grep -rion 'image .*= *"[^"]*' | sed 's/.*"//g')
ps_logs=$(docker ps -a | grep 'Up')
position_status="50"
success="\e[${position_status}G\e[42;30m[✔]\e[0m"
failure="\e[${position_status}G\e[41m\e[30m[✘]\e[0m"
for app in $apps; do
  echo -n "[+] Checking "
  if echo "$ps_logs" | grep -q "$app"; then
    echo -e "for $app $success"
    continue
  fi

  echo -e "for $app $failure"
  status=1
done

echo
if [ "$status" -eq 0 ]; then
  echo ""
  echo -e "\e[42;30m [Test passed!] \e[0m"
else
  echo -e "\e[41m\e[30m [Test failed!] \e[0m"
fi

