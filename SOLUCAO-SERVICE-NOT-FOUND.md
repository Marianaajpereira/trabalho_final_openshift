# Solução: Service Not Found

## ✅ Problema Identificado

O arquivo `openshift-deployment.yaml` estava **incompleto** e faltavam 3 componentes críticos:

1. ❌ **Secret** - Armazenava credenciais (DATABASE_PASSWORD, API_KEY)
2. ❌ **PersistentVolumeClaim (PVC)** - Armazenava logs e dados
3. ⚠️ **Service** - Existia, mas não podia ser criado se o Deployment falhasse

## 🔧 Correções Aplicadas

Adicionei ao arquivo os componentes faltantes:

```yaml
- Secret: app-secrets (com DATABASE_PASSWORD e API_KEY)
- PVC: aplicacao-pvc-logs (5Gi)
- PVC: aplicacao-pvc-data (10Gi)
```

## 📝 Passos para Deploy

### 1️⃣ Aplicar a configuração completa
```bash
oc apply -f openshift-deployment.yaml
```

### 2️⃣ Verificar se o Deployment foi criado
```bash
oc get deployment -n aplicacao
oc describe deployment aplicacao-deployment -n aplicacao
```

### 3️⃣ Verificar o Service
```bash
oc get svc -n aplicacao
oc describe svc aplicacao-service -n aplicacao
```

### 4️⃣ Verificar os Pods
```bash
oc get pods -n aplicacao
oc logs -f deployment/aplicacao-deployment -n aplicacao
```

### 5️⃣ Expor o Service (se necessário criar Route manualmente)
```bash
oc expose svc aplicacao-service -n aplicacao \
  --name=aplicacao-route \
  --hostname=aplicacao.apps.seu-cluster.com
```

### 6️⃣ Verificar a Route
```bash
oc get route -n aplicacao
oc describe route aplicacao-route -n aplicacao
```

## 🔐 Segurança: Atualizar o Secret

**IMPORTANTE**: Os valores padrão no Secret são placeholders!

```bash
# Editar o Secret
oc edit secret app-secrets -n aplicacao

# Ou criar um novo secret com valores reais
oc create secret generic app-secrets \
  --from-literal=DATABASE_PASSWORD='sua-senha-real' \
  --from-literal=API_KEY='sua-api-key-real' \
  -n aplicacao \
  --dry-run=client \
  -o yaml | oc apply -f -

# Reiniciar os Pods para usar o novo Secret
oc rollout restart deployment/aplicacao-deployment -n aplicacao
```

## 🐛 Troubleshooting

Se ainda tiver erro "service not found":

```bash
# Verificar status completo
oc get all -n aplicacao

# Ver eventos de erro
oc get events -n aplicacao --sort-by='.lastTimestamp'

# Descrever o pod para ver logs de erro
oc describe pod <pod-name> -n aplicacao

# Ver logs da aplicação
oc logs <pod-name> -n aplicacao
```

## ✨ Verificar conectividade

```bash
# Dentro de um pod de teste
oc run test-pod --image=alpine -it --rm -n aplicacao \
  -- wget -O- http://aplicacao-service/

# Ou usando curl
oc exec -it <pod-name> -n aplicacao \
  -- curl http://aplicacao-service/
```

## 📊 Próximas verificações

- [ ] Imagem Docker `seu-registry.azurecr.io/aplicacao:latest` existe?
- [ ] Registry está acessível do cluster?
- [ ] Ports 8080 e 9090 estão corretos?
- [ ] Probes (liveness/readiness) estão passando?
