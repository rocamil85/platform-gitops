# Decisiones técnicas y solución de problemas

Este documento registra problemas reales encontrados durante la construcción de la plataforma, su causa y la solución aplicada.

## 1. El frontend entraba en CrashLoopBackOff

### Síntoma

Los Pods del frontend no alcanzaban el estado Ready y Kubernetes los reiniciaba.

Los eventos mostraban:

    Liveness probe failed
    connect: connection refused

Los logs de Gunicorn indicaban:

    Listening at: http://0.0.0.0:8080

Sin embargo, el Deployment declaraba el puerto 8081.

### Causa

Las probes intentaban conectarse al puerto declarado como http, que apuntaba a 8081, pero Gunicorn escuchaba realmente en 8080.

### Solución

Se modificó el Deployment del frontend:

    containerPort: 8080

Después del merge, Argo CD detectó el cambio y realizó un nuevo rollout. Los Pods quedaron Running y Ready.

### Aprendizaje

El containerPort, las probes, el Service y el proceso del contenedor deben apuntar al puerto correcto.

---

## 2. Problemas de Git dentro de OneDrive

### Síntoma

Al cambiar de rama aparecieron mensajes como:

    Deletion of directory failed
    index.lock write error: Bad file descriptor

También aparecieron archivos modificados aunque el contenido no había cambiado.

### Causa

OneDrive podía mantener archivos abiertos mientras Git intentaba reemplazarlos. Además, la conversión entre LF y CRLF producía diferencias de finales de línea.

### Solución

Se cancelaron los reintentos de eliminación, se recuperaron los archivos desde HEAD y se configuró:

    git config --local core.autocrlf false
    git restore --source=HEAD --worktree -- base overlays

### Aprendizaje

No se deben confirmar eliminaciones accidentales. Antes de un commit siempre se debe revisar:

    git status
    git diff
    git diff --check

En un entorno profesional sería preferible mantener los repositorios fuera de carpetas sincronizadas por OneDrive.

---

## 3. Argo CD mostraba Progressing temporalmente

### Síntoma

Después de aplicar una Application, Argo CD mostraba:

    Synced
    Progressing

### Causa

Git y Kubernetes ya estaban sincronizados, pero los nuevos Pods todavía estaban iniciando o esperando sus readiness probes.

### Solución

Se esperó el rollout:

    kubectl rollout status deployment/platform-demo-frontend -n prod --timeout=180s

Luego la aplicación cambió a:

    Synced
    Healthy

### Aprendizaje

Synced y Healthy representan cosas diferentes:

- Synced: el estado del clúster coincide con Git.
- Healthy: los recursos están funcionando correctamente.

---

## 4. Uso de tags frente a digests

### Decisión

Cloud Build publica imágenes con un tag asociado al commit, pero Kubernetes despliega mediante digest SHA-256.

### Motivo

Un tag puede ser reutilizado o apuntar a otra imagen. Un digest identifica exactamente el contenido construido.

### Resultado

Los ambientes dev y prod pueden ejecutar exactamente el mismo artefacto:

    imagen@sha256:...

Esto permite promoción sin reconstrucción y mejora la trazabilidad.

---

## 5. Workload Identity en lugar de llaves JSON

### Decisión

El agente de Jenkins utiliza una Kubernetes ServiceAccount vinculada a una Google Service Account.

### Motivo

Guardar llaves JSON dentro de Jenkins o Kubernetes introduciría credenciales de larga duración.

### Resultado

Los Pods obtienen credenciales temporales para llamar a Google Cloud Build sin almacenar llaves en el repositorio.

---

## 6. NetworkPolicy con denegación predeterminada

### Decisión

Se implementó default-deny-all y luego se permitieron únicamente los flujos necesarios.

### Reglas habilitadas

- Resolución DNS.
- Entrada hacia el frontend.
- Salida del frontend.
- Comunicación frontend hacia backend.

### Trade-off

Esta estrategia ofrece mayor seguridad, pero una regla incompleta puede interrumpir la comunicación. Por eso fue necesario validar dev y prod mediante HTTP después del despliegue.

---

## 7. Disponibilidad durante RollingUpdate

### Decisión

Los Deployments utilizan:

    maxUnavailable: 0
    maxSurge: 1
    minReadySeconds: 5
    progressDeadlineSeconds: 120

### Motivo

Kubernetes debe crear un Pod nuevo y comprobar que está listo antes de eliminar el anterior.

### Trade-off

Durante la actualización se necesita capacidad temporal para un Pod adicional. Si el clúster no tiene CPU disponible, el rollout puede esperar mientras el autoscaler agrega capacidad.

---

## 8. Cambios manuales corregidos por Argo CD

### Prueba

Se redujo manualmente el frontend de producción a una réplica.

Argo CD detectó la desviación y restauró las dos réplicas declaradas en Git.

### Aprendizaje

Con GitOps, Git es la fuente de verdad. Los cambios manuales en el clúster no deben utilizarse como configuración permanente.

---

## 9. Comandos generales de diagnóstico

Estado de las aplicaciones:

    kubectl get applications -n argocd

Pods y servicios:

    kubectl get pods -n dev
    kubectl get pods -n prod
    kubectl get services -n dev
    kubectl get services -n prod

Logs:

    kubectl logs -n dev deployment/platform-demo-frontend --tail=100

Eventos:

    kubectl get events -n dev --sort-by=.lastTimestamp

Descripción de un Deployment:

    kubectl describe deployment platform-demo-frontend -n dev

Métricas:

    kubectl top pods -n dev
    kubectl top pods -n prod
    kubectl top nodes
