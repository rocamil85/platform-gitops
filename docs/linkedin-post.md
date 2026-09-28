# Publicación de LinkedIn

Construí una plataforma CI/CD completa sobre Google Kubernetes Engine.

El objetivo no era solamente desplegar una aplicación, sino practicar cómo se separan responsabilidades en una plataforma moderna y reproducible.

La solución incluye:

✅ Jenkins Controller ejecutándose en GKE.

✅ Agentes efímeros de Kubernetes para cada pipeline.

✅ Validaciones de código con Ruff, Pytest y cobertura.

✅ Construcción de imágenes mediante Google Cloud Build.

✅ Publicación de imágenes en Artifact Registry.

✅ Autenticación sin llaves JSON mediante Workload Identity.

✅ Despliegues declarativos con Kustomize y Argo CD.

✅ Ambientes independientes de desarrollo y producción.

✅ Promoción del mismo artefacto mediante digests inmutables.

✅ RBAC, ServiceAccounts, ResourceQuota y LimitRange.

✅ NetworkPolicies con denegación predeterminada.

✅ Readiness probes, liveness probes y RollingUpdate.

Uno de los aprendizajes más importantes fue separar integración continua y entrega continua:

Jenkins valida y construye el artefacto.

Git declara qué versión debe ejecutarse.

Argo CD mantiene Kubernetes sincronizado con esa declaración.

También aparecieron problemas reales.

El frontend entró en CrashLoopBackOff porque Gunicorn escuchaba en el puerto 8080 mientras las probes consultaban el 8081. Los logs y eventos de Kubernetes permitieron identificar la diferencia. Después de corregir el manifiesto, Argo CD ejecutó el rollout y la aplicación volvió a estar Healthy.

También comprobé el funcionamiento de selfHeal reduciendo manualmente las réplicas de producción. Argo CD detectó la desviación y restauró automáticamente el estado declarado en Git.

El resultado final es una aplicación frontend/backend funcionando en dev y prod, con trazabilidad desde el commit hasta la imagen desplegada y una demostración automática para validar toda la plataforma.

Próximas mejoras:

- Activación automática del pipeline al fusionar cambios en main.
- Actualización automática del digest en el repositorio GitOps.
- Prometheus, Grafana y alertas.
- Ingress, dominio y TLS.
- Escaneo y firma de imágenes.
- Despliegues canary o blue-green.

Este proyecto me permitió unir mi experiencia en Google Cloud y Python con Kubernetes, CI/CD, seguridad y prácticas GitOps.

Repositorio GitOps:
https://github.com/rocamil85/platform-gitops

#PlatformEngineering #DevOps #Kubernetes #GKE #Jenkins #ArgoCD #GitOps #GoogleCloud #CloudBuild #Docker
