# Guia de Deployment no OpenShift

## 📋 Conteúdo do Arquivo de Deployment

O arquivo `openshift-deployment.yaml` contém a configuração completa para deploy de uma aplicação containerizada no OpenShift, incluindo:

### Componentes Inclusos

1. **Namespace** - Isolamento da aplicação
2. **Secret** - Credenciais e dados sensíveis
3. **ConfigMap** - Configurações não sensíveis
4. **Deployment** - Configuração da aplicação com:
   - 3 replicas (escalável)
   - Health checks (liveness e readiness probes)
   - Resource limits
   - Security context
   - Pod anti-affinity (distribuição entre nós)
   - Graceful shutdown

5. **Service** - Exposição interna da aplicação
6. **Route** - Exposição externa com TLS (específico do OpenShift)
7. **ServiceAccount** - Identidade da aplicação
8. **Role/RoleBinding** - Permissões RBAC
9. **HorizontalPodAutoscaler** - Auto-scaling baseado em CPU/Memória

## 🔧 Como Customizar

### 1. Imagem Docker
```yaml
image: seu-registry.azurecr.io/aplicacao:latest
```
Substitua `seu-registry.azurecr.io/aplicacao` pela sua imagem Docker real.

### 2. Variáveis de Ambiente
Edite o `Secret` com suas credenciais:
```yaml
stringData:
  DATABASE_PASSWORD: "sua-senha-aqui"
  API_KEY: "sua-api-key-aqui"
```

Edite o `ConfigMap` com configurações gerais:
```yaml
data:
  LOG_LEVEL: "INFO"
  ENVIRONMENT: "production"
```

### 3. URL da Aplicação (Route)
```yaml
host: aplicacao.apps.sua-cluster.com
```
Substitua pela URL correta do seu cluster OpenShift.

### 4. Recursos
Ajuste conforme necessário:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 5. Replicas
```yaml
replicas: 3
```
Ou remova e deixe apenas o HPA gerenciar.

## �배 Como Fazer Deploy

### Pré-requisitos
- oc CLI instalado e configurado
- Acesso ao cluster OpenShift
- Imagem Docker publicada no registry

### Comandos de Deploy

#### 1. Login no OpenShift
```bash
oc login --token=<seu-token> --server=<sua-api-server>
```

#### 2. Aplicar configuração
```bash
oc apply -f openshift-deployment.yaml
```

#### 3. Verificar status
```bash
oc get pods -n aplicacao
oc get deployment -n aplicacao
oc get route -n aplicacao
```

#### 4. Ver logs
```bash
oc logs -f deployment/aplicacao-deployment -n aplicacao
```

#### 5. Acessar a aplicação
```bash
oc get route aplicacao-route -n aplicacao
```

## 🔐 Segurança

- ✅ Aplicação roda como usuário não-root
- ✅ TLS habilitado na Route
- ✅ Secrets separados de ConfigMaps
- ✅ RBAC configurado (menor privilégio)
- ✅ Resource limits definidos
- ✅ Pod security standards

## 📊 Monitoramento

O deployment inclui:
- **Health checks**: Liveness e Readiness probes
- **Métricas**: Prometheus scrape configurado na porta 9090
- **Auto-scaling**: HPA reagindo a CPU e Memória

## 🔄 Atualizar Aplicação

```bash
# Atualizar imagem
oc set image deployment/aplicacao-deployment \
  aplicacao=seu-registry.azurecr.io/aplicacao:v2.0 \
  -n aplicacao

# Rollout status
oc rollout status deployment/aplicacao-deployment -n aplicacao
```

## ⏮️ Rollback

```bash
oc rollout history deployment/aplicacao-deployment -n aplicacao
oc rollout undo deployment/aplicacao-deployment -n aplicacao
```

## 🗑️ Remover Deployment

```bash
oc delete namespace aplicacao
```

## 📝 Notas Importantes

1. **Registry Privado**: Se usar registry privado, você precisará criar um ImagePullSecret
2. **Health Check Endpoints**: Certifique-se de que sua aplicação tem os endpoints:
   - `/health/live` (liveness)
   - `/health/ready` (readiness)
3. **Variáveis de Ambiente**: Ajuste conforme a necessidade da sua aplicação
4. **Limites de Recursos**: Teste e ajuste conforme o comportamento observado

---

Customizações baseadas em sua aplicação específica podem ser necessárias!
