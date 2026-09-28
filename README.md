# Plataforma CI/CD con Jenkins, GKE, Argo CD y GitOps

Proyecto práctico de Platform Engineering que implementa integración continua, construcción de imágenes, despliegue GitOps y controles operacionales sobre Google Kubernetes Engine.

## Arquitectura

Flujo principal:

Desarrollador → GitHub → Jenkins → Cloud Build → Artifact Registry

GitHub GitOps → Argo CD → GKE

## Repositorios

- platform-demo-backend: aplicación backend y pipeline CI.
- platform-demo-frontend: aplicación frontend y pipeline CI.
- platform-gitops: manifiestos Kubernetes y configuración de Argo CD.

## Flujo de entrega

1. Jenkins valida el código con Ruff y Pytest.
2. Cloud Build construye la imagen Docker.
3. Artifact Registry almacena la imagen con un tag asociado al commit.
4. El repositorio GitOps declara el digest que debe desplegarse.
5. Argo CD sincroniza el estado declarado con GKE.
6. Desarrollo y producción ejecutan artefactos inmutables.

## Ambientes

| Ambiente | Namespace | Administración |
| --- | --- | --- |
| Desarrollo | dev | Argo CD |
| Producción | prod | Argo CD y promoción mediante Pull Request |

## Controles implementados

- ServiceAccounts independientes.
- RBAC con privilegios mínimos.
- ResourceQuota y LimitRange.
- NetworkPolicies.
- Requests y limits.
- Readiness y liveness probes.
- Estrategia RollingUpdate.
- Recuperación automática con Argo CD selfHeal.

## Validación

Los siguientes comandos permiten comprobar la plataforma:

    kubectl get applications -n argocd
    kubectl get pods -n dev
    kubectl get pods -n prod
    kubectl get services -n dev
    kubectl get services -n prod

Resultado esperado para las aplicaciones:

    platform-demo-dev    Synced    Healthy
    platform-demo-prod   Synced    Healthy

## Tecnologías

- Google Kubernetes Engine
- Jenkins
- Google Cloud Build
- Artifact Registry
- Argo CD
- Kustomize
- Docker
- Python y Flask
- GitHub

## Estado

La plataforma CI/CD, los ambientes dev y prod, GitOps y los controles operacionales se encuentran implementados y funcionando.

## Documentación técnica

- [Arquitectura detallada](docs/architecture.md)
