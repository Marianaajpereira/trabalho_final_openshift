# 🔍 Diagnóstico: Service Not Found

## ❌ Problemas no Arquivo Original

### 1. **Dependências Não Satisfeitas**

O arquivo `openshift-deployment.yaml` tem dependências complexas que podem estar falhando:

```yaml
# PVCs com storageClassName que pode não existir
storageClassName: standard  # ⚠️ Pode não existir no seu cluster

# Imagem Docker é um placeholder
image: seu-registry.azurecr.io/aplicacao:latest  # ❌ Não existe
```

Se o Deployment não inicia, o Service fica "órfão" sem pods associados.

### 2. **Sequência de Criação Importante**

```
1. Namespace → 2. ConfigMap → 3. Secret → 4. ServiceAccount
    ↓
5. Deployment (cria pods) → 6. Service (encontra pods) → 7. Route
```

Se a etapa 5 (Deployment) falhar, a etapa 6 (Service) não consegue encontrar os pods!

---

## ✅ Solução: 2 Estratégias

### **Estratégia 1: Usar o arquivo minimal (Recomendado)**

```bash
# Limpar o namespace anterior
oc delete namespace aplicacao

# Aplicar a versão funcional
oc apply -f openshift-deployment-minimal.yaml

# Verificar
oc get svc -n aplicacao
oc get pods -n aplicacao
oc get route -n aplicacao
```

Este arquivo:
- ✅ Usa imagem Python pronta
- ✅ Remove PVCs complexas
- ✅ Service será criado com sucesso
- ✅ Route funcionará corretamente

### **Estratégia 2: Corrigir o arquivo original**

Se você quer manter o arquivo original com sua imagem Docker, faça:

```bash
# 1. Verificar se storageClassName existe
oc get storageclass

# 2. Se não existir "standard", use o que aparecer
oc get pv
oc describe pv <nome-do-pv>

# 3. Atualizar o arquivo com:
#    - Seu storageClassName correto
#    - Sua imagem Docker real
#    - Uma replica só para começar (replicas: 1)

# 4. Aplicar
oc apply -f openshift-deployment.yaml

# 5. Monitorar logs
oc logs -f deployment/aplicacao-deployment -n aplicacao
```

---

## 🛠️ Comandos de Diagnóstico

```bash
# Ver TODOS os recursos
oc get all -n aplicacao

# Ver apenas Services
oc get svc -n aplicacao

# Ver detalhes do Service
oc describe svc aplicacao-service -n aplicacao

# Ver erros de criação
oc get events -n aplicacao --sort-by='.lastTimestamp'

# Ver status do Deployment
oc describe deployment aplicacao-deployment -n aplicacao

# Ver logs dos pods
oc get pods -n aplicacao
oc logs <pod-name> -n aplicacao

# Testar conectividade ao Service
oc run -it --rm debug --image=alpine --restart=Never -- wget -O- http://aplicacao-service.aplicacao.svc.cluster.local
```

---

## 📋 Checklist de Verificação

- [ ] Namespace `aplicacao` foi criado? `oc get ns | grep aplicacao`
- [ ] Service `aplicacao-service` existe? `oc get svc -n aplicacao`
- [ ] Pods estão rodando? `oc get pods -n aplicacao`
- [ ] Pods têm labels `app: aplicacao`? `oc get pods -n aplicacao --show-labels`
- [ ] Service aponta para os pods certos? `oc describe svc aplicacao-service -n aplicacao`
- [ ] Route está criada? `oc get route -n aplicacao`

---

## 🎯 Próximas Ações

1. **Teste primeiro com o arquivo minimal**
   ```bash
   oc apply -f openshift-deployment-minimal.yaml
   oc get svc -n aplicacao
   ```

2. **Depois adapte para sua imagem Docker**
   - Atualize a imagem em `openshift-deployment.yaml`
   - Remova PVCs se não precisar
   - Aplique novamente

3. **Se ainda der erro**, colete os logs:
   ```bash
   oc get events -n aplicacao -o yaml > debug-events.yaml
   oc describe pod <pod-name> -n aplicacao > debug-pod.yaml
   oc logs deployment/aplicacao-deployment -n aplicacao > debug-logs.txt
   ```

---

## 🔐 Importante para Produção

O arquivo minimal usa `python:3.11-slim` como demo. Para produção:

1. Crie uma imagem Docker própria (veja `Dockerfile`)
2. Publique no seu registry
3. Atualize a imagem no YAML
4. Adicione PVCs se precisar de persistência
5. Aumente replicas (3+)
6. Configure Resource Limits corretos
