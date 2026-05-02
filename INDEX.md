# 📚 Índice Completo - Deployment de Aplicação Containerizada no OpenShift

## 🎯 Início Rápido (5 minutos)

1. **Personalize o arquivo base**: [openshift-deployment.yaml](openshift-deployment.yaml)
   - Altere `REGISTRY` para seu registry
   - Altere `image` para sua imagem Docker
   - Configure secrets e configmaps

2. **Use o script de deploy**: [openshift-deploy.sh](openshift-deploy.sh)
   ```bash
   ./openshift-deploy.sh check           # Verificar pré-requisitos
   ./openshift-deploy.sh login <server> <token>  # Login
   ./openshift-deploy.sh apply           # Deploy
   ./openshift-deploy.sh status          # Verificar
   ```

3. **Acesse sua aplicação** via Route configurada em `openshift-deployment.yaml`

---

## 📂 Arquivos de Configuração YAML

| Arquivo | Propósito | Quando Usar |
|---------|----------|------------|
| [openshift-deployment.yaml](openshift-deployment.yaml) | Configuração completa e pronta para produção | Sempre (base para todo deploy) |
| [openshift-network-policies.yaml](openshift-network-policies.yaml) | Segurança de rede (Deny by default, Allow específico) | Produção com requisitos de segurança |
| [openshift-quotas-limits.yaml](openshift-quotas-limits.yaml) | Quotas e limites de recursos para namespace | Multi-tenant ou ambiente compartilhado |
| [openshift-monitoring.yaml](openshift-monitoring.yaml) | Prometheus, métricas e alertas | Produção com requisitos de observabilidade |
| [openshift-advanced-deployment.yaml](openshift-advanced-deployment.yaml) | Canary, Blue-Green, StatefulSet, DaemonSet, Jobs | Estratégias avançadas de deploy |

### 📝 Como Aplicar Arquivos YAML

```bash
# Aplicar um arquivo
oc apply -f openshift-deployment.yaml

# Aplicar múltiplos arquivos
oc apply -f openshift-deployment.yaml \
         -f openshift-network-policies.yaml \
         -f openshift-monitoring.yaml

# Aplicar todos os arquivos de um diretório
oc apply -f .

# Deletar tudo
oc delete -f openshift-deployment.yaml
```

---

## 📖 Documentação de Referência

| Documento | Conteúdo | Para Quem |
|-----------|----------|----------|
| [README-DEPLOYMENT.md](README-DEPLOYMENT.md) | Guia completo com customizações básicas | Iniciantes |
| [EXEMPLOS-DEPLOYMENT.md](EXEMPLOS-DEPLOYMENT.md) | Exemplos por ambiente (Dev, Staging, Prod) | Todos que precisam de referência rápida |
| [openshift-troubleshooting.md](openshift-troubleshooting.md) | Diagnóstico de problemas com soluções | Troubleshooting |
| [openshift-tipos-aplicacoes.md](openshift-tipos-aplicacoes.md) | Exemplos específicos por tipo de app | Procurando template para sua app |
| [openshift-cicd.md](openshift-cicd.md) | Integração com GitHub Actions, GitLab, Jenkins, ArgoCD | Setup de CI/CD |
| [openshift-best-practices.md](openshift-best-practices.md) | Boas práticas de segurança, performance, HA | Arquitetura e design |
| [CHECKLIST-PRE-DEPLOY.md](CHECKLIST-PRE-DEPLOY.md) | Checklist de validação antes do deploy | Verificação final antes de produção |

---

## 🛠️ Scripts de Automação

| Script | Funcionalidade |
|--------|---|
| [openshift-deploy.sh](openshift-deploy.sh) | ⭐ **Principal**: 15+ comandos para deploy, logs, scaling, rollback |
| [deploy-helper.sh](deploy-helper.sh) | Comandos básicos de setup inicial |

### Usando o openshift-deploy.sh

```bash
# Ajuda
./openshift-deploy.sh help

# Verificar requisitos
./openshift-deploy.sh check

# Login
./openshift-deploy.sh login https://api.seu-cluster.com:6443 token123

# Setup inicial
./openshift-deploy.sh namespace
./openshift-deploy.sh apply

# Build e deploy da imagem
./openshift-deploy.sh build v1.0.0
./openshift-deploy.sh update v1.0.0

# Operações
./openshift-deploy.sh status           # Ver status
./openshift-deploy.sh logs             # Ver logs (últimas 50 linhas)
./openshift-deploy.sh logs 100         # Ver últimas 100 linhas
./openshift-deploy.sh pods             # Listar pods
./openshift-deploy.sh scale 5          # Escalar para 5 replicas

# Troubleshooting
./openshift-deploy.sh exec             # Shell no primeiro pod
./openshift-deploy.sh exec mypod 'ps aux'  # Comando no pod
./openshift-deploy.sh port-forward 8080    # Port forward

# Rollback
./openshift-deploy.sh history          # Ver histórico
./openshift-deploy.sh rollback         # Reverter versão anterior
```

---

## 🔄 Fluxo de Deployment Típico

```
1. Preparar Imagem Docker
   ├── Crie/compile sua aplicação
   ├── Crie Dockerfile
   └── Test localmente: docker build && docker run

2. Configurar OpenShift
   ├── Customize [openshift-deployment.yaml](openshift-deployment.yaml)
   ├── Configure secrets: database, API keys
   ├── Configure ConfigMaps: variáveis de ambiente
   └── Revise [CHECKLIST-PRE-DEPLOY.md](CHECKLIST-PRE-DEPLOY.md)

3. Build e Push
   ├── ./openshift-deploy.sh build v1.0.0
   └── Ou: docker build -t seu-registry/app:v1.0.0 .

4. Deploy
   ├── ./openshift-deploy.sh namespace
   ├── ./openshift-deploy.sh apply
   └── ./openshift-deploy.sh update v1.0.0

5. Validar
   ├── ./openshift-deploy.sh status
   ├── ./openshift-deploy.sh logs
   ├── ./openshift-deploy.sh pods
   └── Teste a URL da aplicação

6. Monitorar
   ├── Configure monitoramento: [openshift-monitoring.yaml](openshift-monitoring.yaml)
   ├── Setup alertas
   └── Configure backups se necessário

7. Produção
   ├── Aplique [openshift-network-policies.yaml](openshift-network-policies.yaml)
   ├── Configure [openshift-quotas-limits.yaml](openshift-quotas-limits.yaml)
   └── Setup CI/CD: [openshift-cicd.md](openshift-cicd.md)
```

---

## 🎓 Cenários de Uso

### Cenário 1: Deploy Simples (Desenvolvimento)

```bash
# 1. Setup
./openshift-deploy.sh login ...
./openshift-deploy.sh namespace
./openshift-deploy.sh apply

# 2. Usar a aplicação
./openshift-deploy.sh port-forward 8080 8080
# Acesse http://localhost:8080

# 3. Ver logs se houver problemas
./openshift-deploy.sh logs
```

### Cenário 2: Deploy em Produção com Monitoramento

```bash
# 1. Preparar
./openshift-deploy.sh check

# 2. Aplicar base + segurança + quotas + monitoring
oc apply -f openshift-deployment.yaml
oc apply -f openshift-network-policies.yaml
oc apply -f openshift-quotas-limits.yaml
oc apply -f openshift-monitoring.yaml

# 3. Escalar para alta disponibilidade
./openshift-deploy.sh scale 3

# 4. Verificar tudo
./openshift-deploy.sh status
./openshift-deploy.sh pods
```

### Cenário 3: Deploy com CI/CD (GitOps)

```bash
# Ver [openshift-cicd.md](openshift-cicd.md) para:
# - GitHub Actions workflow
# - GitLab CI pipeline
# - Jenkins declarative pipeline
# - ArgoCD applicationnya
```

### Cenário 4: Troubleshooting de Problema

```bash
# Ver por que pod não inicia
./openshift-deploy.sh describe pods
./openshift-deploy.sh logs

# Entrar no pod para debugar
./openshift-deploy.sh exec myapp bash

# Fazer port forward para testar localmente
./openshift-deploy.sh port-forward 8080 8080

# Ver eventos recentes
./openshift-deploy.sh events
```

### Cenário 5: Blue-Green Deployment

```bash
# Ver [openshift-advanced-deployment.yaml](openshift-advanced-deployment.yaml)
# Tem exemplo completo de blue-green

# Basicamente:
# 1. Deploy nova versão como "green"
# 2. Testar completamente
# 3. Switch service de "blue" para "green"
# 4. Manter "blue" como fallback
```

---

## 📊 Componentes do Deployment

```
Aplicação Containerizada no OpenShift
├── 🔐 Segurança
│   ├── ServiceAccount (identidade da app)
│   ├── Role/RoleBinding (permissões RBAC)
│   ├── SecurityContext (container security)
│   ├── NetworkPolicies (firewall de pods)
│   └── Secrets (dados sensíveis)
│
├── 🚀 Deployment
│   ├── Deployment (gerencia pods)
│   ├── ReplicaSet (mantém replicas)
│   ├── Pods (containers executando)
│   └── ConfigMap (variáveis de ambiente)
│
├── 🌐 Networking
│   ├── Service (descoberta interna)
│   ├── Route (acesso externo com TLS)
│   └── Ingress (roteamento avançado)
│
├── 💾 Storage (opcional)
│   ├── PersistentVolumeClaim (dados persistentes)
│   └── StorageClass (tipo de storage)
│
├── 📊 Observabilidade
│   ├── Prometheus (métricas)
│   ├── PrometheusRules (alertas)
│   ├── Logs (stdout/stderr)
│   └── Eventos (mudanças no cluster)
│
├── 📈 Escalamento
│   ├── HorizontalPodAutoscaler (auto-scaling)
│   ├── VerticalPodAutoscaler (ajuste de resources)
│   └── ResourceQuota (limite de namespace)
│
└── 🔄 Operações
    ├── RollingUpdate (deploy gradual)
    ├── Canary Deployment (5-10% tráfego primeiro)
    ├── Blue-Green (2 versões paralelas)
    └── Rollback (reverter versão anterior)
```

---

## ✅ Checklist Pré-Deployment

- [ ] Imagem Docker testada e funcionando
- [ ] Sem vulnerabilidades de segurança (trivy scan)
- [ ] Health checks configurados (`/health/live` e `/health/ready`)
- [ ] Resource requests/limits realistas
- [ ] Secrets criados e configurados
- [ ] ConfigMaps com variáveis de ambiente
- [ ] Logs estruturados e funcionando
- [ ] Estratégia de backup definida
- [ ] Monitoramento e alertas configurados
- [ ] NetworkPolicies configuradas (se produção)
- [ ] Plano de rollback documentado
- [ ] Documentação atualizada
- [ ] Teste de failover realizado

---

## 🆘 Ajuda Rápida

| Problema | Solução |
|----------|--------|
| "command not found: oc" | Instale oc CLI |
| "ImagePullBackOff" | Verificar credenciais do registry |
| "CrashLoopBackOff" | Ver logs: `./openshift-deploy.sh logs` |
| "Pending" | Pod não consegue ser agendado - recursos insuficientes |
| "Connection refused" | Verificar NetworkPolicies ou status da app |
| "Pod restartando" | Aumentar `initialDelaySeconds` nas probes |
| "Out of Memory" | Aumentar `limits.memory` em resources |

Veja [openshift-troubleshooting.md](openshift-troubleshooting.md) para mais detalhes.

---

## 📚 Recursos Adicionais

- [Documentação OpenShift Oficial](https://docs.openshift.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [OpenShift CLI Reference](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started.html)

---

## 🎉 Conclusão

Agora você tem:

✅ Configuração YAML completa e pronta para usar  
✅ Scripts de automação para deploy e gerenciamento  
✅ Documentação detalhada de como usar tudo  
✅ Exemplos para diferentes tipos de aplicações  
✅ Guias de troubleshooting e best practices  
✅ Integração com CI/CD (GitHub, GitLab, Jenkins)  

**Próximo passo**: Customize [openshift-deployment.yaml](openshift-deployment.yaml) para sua aplicação e execute `./openshift-deploy.sh apply`!
