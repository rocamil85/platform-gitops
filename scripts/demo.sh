#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " DEMOSTRACIÓN DE LA PLATAFORMA CI/CD"
echo "========================================"

echo
echo "Contexto actual de Kubernetes:"
kubectl config current-context

echo
echo "Estado de Argo CD:"
kubectl get applications -n argocd

for NAMESPACE in dev prod; do
  echo
  echo "========================================"
  echo " AMBIENTE: ${NAMESPACE}"
  echo "========================================"

  echo
  echo "Deployments:"
  kubectl get deployments -n "${NAMESPACE}"

  echo
  echo "Pods:"
  kubectl get pods -n "${NAMESPACE}"

  echo
  echo "Services:"
  kubectl get services -n "${NAMESPACE}"

  echo
  echo "Imagen del backend:"
  kubectl get deployment platform-demo-backend \
    -n "${NAMESPACE}" \
    -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

  echo
  echo "Imagen del frontend:"
  kubectl get deployment platform-demo-frontend \
    -n "${NAMESPACE}" \
    -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

  echo
  echo "Controles instalados:"
  kubectl get resourcequota,limitrange,networkpolicy \
    -n "${NAMESPACE}"

  echo
  echo "Validación RBAC del observador:"
  printf "Puede listar Pods: "
  kubectl auth can-i list pods \
    --as="system:serviceaccount:${NAMESPACE}:platform-observer" \
    -n "${NAMESPACE}"

  printf "Puede leer Secrets: "
  kubectl auth can-i get secrets \
    --as="system:serviceaccount:${NAMESPACE}:platform-observer" \
    -n "${NAMESPACE}" || true

  EXTERNAL_IP=$(kubectl get service platform-demo-frontend \
    -n "${NAMESPACE}" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

  echo
  if [[ -n "${EXTERNAL_IP}" ]]; then
    curl -fsS \
      -o /dev/null \
      -w "${NAMESPACE} respondió HTTP %{http_code}\n" \
      "http://${EXTERNAL_IP}"
  else
    echo "${NAMESPACE} todavía no tiene una IP externa."
  fi
done

echo
echo "========================================"
echo " DEMOSTRACIÓN FINALIZADA"
echo "========================================"
