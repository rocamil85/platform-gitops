# Guion de entrevista técnica

## Presentación del proyecto

Construí una plataforma CI/CD sobre Google Kubernetes Engine para desplegar una aplicación compuesta por frontend y backend.

Separé la solución en tres repositorios: frontend, backend y GitOps. Jenkins ejecuta la integración continua utilizando agentes efímeros de Kubernetes. Los pipelines validan el código con Ruff y Pytest, y luego solicitan a Google Cloud Build la construcción de las imágenes.

Las imágenes se almacenan en Artifact Registry y se identifican mediante el commit que las generó. Para el despliegue utilizo Kustomize y Argo CD. Los ambientes dev y prod se administran desde el repositorio GitOps mediante digests inmutables.

También implementé Workload Identity, RBAC, ServiceAccounts independientes, cuotas, límites, NetworkPolicies, probes y RollingUpdate.

## ¿Por qué separaste CI y CD?

Jenkins se ocupa de validar y construir el software. Argo CD se ocupa de desplegarlo.

Esta separación evita que Jenkins necesite permisos amplios para modificar directamente los Deployments. También permite que Git mantenga un historial revisable del estado deseado del clúster.

## ¿Por qué utilizaste agentes efímeros?

Cada ejecución de Jenkins crea un Pod agente temporal.

Esto permite:

- Aislar cada pipeline.
- Evitar dependencias acumuladas entre ejecuciones.
- Escalar la capacidad de ejecución.
- Mantener el Jenkins Controller fuera de la ejecución del código.
- Eliminar el agente cuando el trabajo termina.

## ¿Cómo evitaste guardar llaves de Google Cloud?

Utilicé Workload Identity.

La Kubernetes ServiceAccount del agente de Jenkins está vinculada con una Google Service Account. El Pod obtiene credenciales temporales y puede invocar Cloud Build sin utilizar archivos JSON de credenciales.

## ¿Cómo garantizas la trazabilidad?

Cada imagen se construye con un tag derivado del commit de Git.

Después se obtiene su digest SHA-256 y Kubernetes despliega utilizando ese digest. De esa manera se puede determinar exactamente qué código produjo la imagen desplegada.

## ¿Por qué desplegar mediante digest?

Los tags pueden cambiar o reutilizarse. Los digests son inmutables.

Si dev valida un digest específico, producción puede utilizar exactamente el mismo artefacto sin reconstruirlo.

## ¿Cómo funciona la promoción a producción?

El overlay de desarrollo se valida primero. Para promover una versión se actualiza el overlay de producción mediante una rama y un Pull Request.

Después del merge, Argo CD detecta el nuevo estado deseado y sincroniza producción.

## ¿Cómo realizarías un rollback?

Se revierte el commit del repositorio GitOps que modificó el digest o se crea un nuevo commit restaurando el digest anterior.

Argo CD detecta el cambio y vuelve a desplegar la versión anterior.

El rollback queda registrado en Git.

## ¿Qué controles de seguridad implementaste?

- ServiceAccounts separadas para frontend y backend.
- Desactivación del montaje automático del token cuando no es necesario.
- RBAC con permisos mínimos.
- NetworkPolicy con denegación predeterminada.
- Comunicación explícita entre frontend y backend.
- Workload Identity sin llaves JSON.
- Revisión mediante Pull Requests.
- Imágenes desplegadas mediante digests.

## ¿Qué controles de recursos implementaste?

Utilicé requests y limits en cada contenedor.

También añadí LimitRange para establecer valores predeterminados y ResourceQuota para controlar el consumo total de cada namespace.

Esto reduce el riesgo de que una aplicación consuma todos los recursos disponibles.

## ¿Cómo garantizas disponibilidad durante una actualización?

Los Deployments utilizan RollingUpdate con:

- maxUnavailable igual a cero.
- maxSurge igual a uno.
- readiness probes.
- liveness probes.
- minReadySeconds.
- progressDeadlineSeconds.

Kubernetes crea y valida un Pod nuevo antes de eliminar el anterior.

## Describe un problema real que resolviste

El frontend entraba en CrashLoopBackOff.

Las probes se conectaban al puerto 8081, pero Gunicorn escuchaba en el puerto 8080. Revisé los logs y los eventos, identifiqué la diferencia y corregí el containerPort.

Después del merge, Argo CD detectó el cambio, ejecutó un nuevo rollout y la aplicación quedó Healthy.

## ¿Cómo validaste GitOps?

Reduje manualmente las réplicas del frontend de producción.

Argo CD detectó que el clúster ya no coincidía con Git y restauró automáticamente las dos réplicas declaradas.

Esto comprobó el funcionamiento de selfHeal.

## ¿Cómo diagnosticas un despliegue con problemas?

Comienzo revisando:

1. Estado de la Application en Argo CD.
2. Deployments y Pods.
3. Eventos del namespace.
4. Descripción del recurso.
5. Logs actuales y anteriores.
6. Readiness y liveness probes.
7. Services y endpoints.
8. NetworkPolicies.
9. Uso de CPU y memoria.

## ¿Qué mejorarías para una plataforma productiva?

- Disparar Jenkins automáticamente al fusionar cambios en main.
- Automatizar la actualización del digest en el repositorio GitOps.
- Incorporar Prometheus, Grafana y alertas.
- Centralizar logs en Cloud Logging.
- Añadir Ingress, DNS y TLS.
- Escanear imágenes y dependencias.
- Firmar y verificar imágenes.
- Utilizar proyectos o clústeres separados para producción.
- Implementar despliegues canary o blue-green.
- Medir métricas DORA.

## Resumen corto

La idea principal del proyecto es que Jenkins construye y Argo CD despliega.

Jenkins produce un artefacto trazable, Git declara qué versión debe ejecutarse y Argo CD mantiene GKE sincronizado con esa declaración.
