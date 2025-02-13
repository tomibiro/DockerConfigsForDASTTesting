#!/bin/bash

main() {
  if [[ "${LOCAL_STACK}" == "true" ]]; then
    return
  fi

  variables=(
    "KUBERNETES_SERVICE_HOST"
    "KUBERNETES_SERVICE_PORT"
  )

  files=(
    "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    "/var/run/secrets/kubernetes.io/serviceaccount/namespace"
    "/var/run/secrets/kubernetes.io/serviceaccount/token"
  )
    
  for var in "${variables[@]}"; do
    if [ ! -v "$var" ]; then
      echo "[SaaS] Error: DXP Agent initialization has not succeeded and the reason of the error: ${var} was missing (please subsitute with the proper one(s))" >&2
      exit 1
    fi
  done

  for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
      echo "[SaaS] Error: DXP Agent initialization has not succeeded and the reason of the error: ${file} was missing (please subsitute with the proper one(s))" >&2
      exit 1
    fi
  done
}

main
