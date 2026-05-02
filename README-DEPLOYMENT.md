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