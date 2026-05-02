# Troubleshooting - Guia de Diagnóstico de Problemas no OpenShift

## 1. Pod Não Inicia

### Verificar status do pod
```bash
oc get pods -n aplicacao
oc describe pod aplicacao-deployment-xyz -n aplicacao
oc logs aplicacao-deployment-xyz -n aplicacao
```

### Causas comuns:
- **ImagePullBackOff**: Imagem não encontrada ou credenciais inválidas
  ```bash
  # Verificar credenciais
  oc get secrets -n aplicacao
  oc describe secret app-secrets -n aplicacao
  
  # Testar acesso ao registry
  docker pull seu-registry.azurecr.io/aplicacao:latest
  ```

- **CrashLoopBackOff**: Aplicação crash ao iniciar
  ```bash
  # Ver logs detalhados
  oc logs -f aplicacao-deployment-xyz -n aplicacao
  oc logs --all-containers=true --tail=50 aplicacao-deployment-xyz -n aplicacao
  ```

- **Pending**: Pod não consegue ser agendado
  ```bash
  # Verificar recursos disponíveis
  oc describe nodes
  
  # Revisar limites de recursos
  oc describe quota -n aplicacao
  ```

## 2. Pod Restarting Continuamente

```bash
# Ver histórico de restarts
oc describe pod aplicacao-deployment-xyz -n aplicacao

# Aumentar limites de memória/CPU
oc set resources deployment aplicacao-deployment \
  -n aplicacao \
  --limits=memory=1Gi,cpu=1000m \
  --requests=memory=512Mi,cpu=500m

# Aumentar timeout de probe
oc patch deployment aplicacao-deployment -n aplicacao -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"aplicacao","livenessProbe":{"initialDelaySeconds":60}}]}}}}'
```

## 3. Aplicação Lenta/Timeout

### Diagnosticar:
```bash
# Verificar CPU e memória
oc top nodes
oc top pods -n aplicacao

# Ver throttling
oc describe pod aplicacao-deployment-xyz -n aplicacao | grep -i throttle
```

### Solução:
```bash
# Aumentar recursos
oc set resources deployment aplicacao-deployment \
  -n aplicacao \
  --limits=memory=2Gi,cpu=2000m \
  --requests=memory=1Gi,cpu=1000m

# Escalar replicas
oc scale deployment aplicacao-deployment --replicas=5 -n aplicacao
```

## 4. Problemas de Conectividade

### Testar conectividade entre pods
```bash
# Acessar pod
oc exec -it aplicacao-deployment-xyz -n aplicacao -- bash

# Dentro do pod, testar conexão
curl http://outro-pod:8080
telnet database.aplicacao.svc.cluster.local 5432
```

### Verificar NetworkPolicies
```bash
# Ver políticas aplicadas
oc get networkpolicies -n aplicacao
oc describe networkpolicy aplicacao-deny-all -n aplicacao

# Temporariamente desabilitar
oc delete networkpolicy aplicacao-deny-all -n aplicacao
```

## 5. Storage Issues

### Verificar PVCs
```bash
# Listar volumes
oc get pvc -n aplicacao
oc describe pvc backup-pvc -n aplicacao

# Ver eventos
oc describe pvc backup-pvc -n aplicacao | grep Events

# Aumentar tamanho
oc patch pvc backup-pvc -n aplicacao -p '{"spec":{"resources":{"requests":{"storage":"150Gi"}}}}'
```

## 6. Problemas de Secrets/ConfigMaps

### Verificar valores
```bash
# Verificar se Secret existe
oc get secrets -n aplicacao
oc describe secret app-secrets -n aplicacao

# Não mostra valores, mas mostra se Key existe
oc get secret app-secrets -o yaml -n aplicacao

# Decodificar valores (cuidado!)
oc get secret app-secrets -o jsonpath='{.data.DATABASE_PASSWORD}' -n aplicacao | base64 --decode
```

## 7. Problemas de Permission

### Ver logs de RBAC
```bash
# Testar permissões
oc auth can-i get pods --as=system:serviceaccount:aplicacao:aplicacao-sa -n aplicacao

# Aplicar role binding
oc create rolebinding aplicacao-edit \
  --clusterrole=edit \
  --serviceaccount=aplicacao:aplicacao-sa \
  -n aplicacao
```

## 8. Problemas de Deploy

### Rollout Status
```bash
# Ver status do deploy
oc rollout status deployment/aplicacao-deployment -n aplicacao

# Ver histórico
oc rollout history deployment/aplicacao-deployment -n aplicacao

# Reverter para versão anterior
oc rollout undo deployment/aplicacao-deployment -n aplicacao
```

## 9. Monitoramento e Métricas

```bash
# Ativar métricas se não estiverem
oc adm top nodes
oc adm top pods -n aplicacao

# Ver eventos recentes
oc get events -n aplicacao --sort-by='.lastTimestamp'

# Ver logs do sistema
oc logs -n openshift-monitoring pod/prometheus-k8s-0
```

## 10. Limpar Recursos

```bash
# Deletar pods problemáticos (será recriado)
oc delete pod aplicacao-deployment-xyz -n aplicacao

# Deletar e recriar deployment
oc delete deployment aplicacao-deployment -n aplicacao
oc apply -f openshift-deployment.yaml

# Limpar jobs completos
oc delete job --field-selector status.successful=1 -n aplicacao
```

## Debug Avançado

### Acessar shell do container
```bash
oc exec -it aplicacao-deployment-xyz -n aplicacao -- /bin/sh
oc debug pod/aplicacao-deployment-xyz -n aplicacao
```

### Copiar arquivos
```bash
# Do pod para local
oc cp aplicacao/aplicacao-deployment-xyz:/app/logs/app.log ./app.log

# De local para pod
oc cp ./config.yaml aplicacao/aplicacao-deployment-xyz:/app/config.yaml
```

### Port forwarding
```bash
# Acessar aplicação localmente
oc port-forward svc/aplicacao-service 8080:8080 -n aplicacao
# Acesse: http://localhost:8080
```

## Logs de Sistema

```bash
# Logs do OpenShift
oc logs -n openshift-apiserver deployment/apiserver
oc logs -n openshift-etcd etcd-<hostname>

# Events do cluster
oc get events --all-namespaces --sort-by='.lastTimestamp'
```
