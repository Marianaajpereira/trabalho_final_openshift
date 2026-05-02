# Checklist Pré-Deployment

## ✅ Validação do Arquivo YAML

- [ ] Executar validação sintática:
  ```bash
  oc apply -f openshift-deployment.yaml --dry-run=client
  ```

- [ ] Verificar se há erros:
  ```bash
  kubeval openshift-deployment.yaml
  ```

- [ ] Lint com kube-score:
  ```bash
  kube-score score openshift-deployment.yaml
  ```

## 🐳 Imagem Docker

- [ ] Imagem Docker está construída
- [ ] Imagem está publicada no registry
- [ ] Tag da imagem está correta no arquivo YAML
- [ ] Credenciais de acesso ao registry (se privado):
  ```bash
  oc create secret docker-registry regcred \
    --docker-server=seu-registry.azurecr.io \
    --docker-username=seu-usuario \
    --docker-password=sua-senha \
    -n aplicacao
  ```
  
  Adicione ao Deployment:
  ```yaml
  spec:
    template:
      spec:
        imagePullSecrets:
        - name: regcred
  ```

## 🔐 Secrets e ConfigMaps

- [ ] Valores de senha/credenciais foram alterados de "seu-xxxxx-aqui"
- [ ] Não há credenciais commitadas no Git
- [ ] Secrets necessários foram identificados
- [ ] ConfigMaps estão completos
- [ ] Variáveis de ambiente obrigatórias estão presentes

## 📱 Health Checks

- [ ] Endpoints de health check existem na aplicação:
  - [ ] `/health/live`
  - [ ] `/health/ready`
- [ ] Os endpoints retornam HTTP 200 em estado saudável
- [ ] Os valores de `initialDelaySeconds` estão apropriados

## 🎯 Portas

- [ ] Porto HTTP (padrão 8080) está correto
- [ ] Porto de métricas (padrão 9090) está correto
- [ ] Firewall/NSGs permitem acesso

## 🌐 Route/URL

- [ ] Host da Route é válido
- [ ] Certificado TLS está disponível (edge termination)
- [ ] DNS aponta para o ingress do cluster

## 💾 Recursos

- [ ] Requests e limits foram testados
- [ ] Aplicação não usa mais do que os limits definidos
- [ ] Há capacidade no cluster para os requests
- [ ] Em produção: limites são > que para staging

## 🔄 Replicas e Escalabilidade

- [ ] Número de replicas inicial está apropriado
- [ ] HPA min/max replicas estão corretos
- [ ] Métricas para HPA (CPU/Memória) estão disponíveis
- [ ] Cluster tem capacidade para máximo de replicas

## 👥 RBAC

- [ ] ServiceAccount foi criado
- [ ] Role tem permissões necessárias (não muito permissivo)
- [ ] RoleBinding conecta corretamente
- [ ] Aplicação pode acessar ConfigMaps/Secrets necessários

## 🏢 Namespace

- [ ] Namespace existe ou será criado
- [ ] Namespace está isolado de outros workloads
- [ ] Network Policies estão configuradas se necessário

## 📋 Backup e Recuperação

- [ ] Persistent volumes (se houver) têm backup configurado
- [ ] Strategy de rollback foi planejada
- [ ] Histórico de rollouts será mantido

## 🔍 Monitoramento e Logging

- [ ] Logs podem ser acessados:
  ```bash
  oc logs deployment/aplicacao-deployment -n aplicacao
  ```
- [ ] Prometheus scrape está habilitado (annotations)
- [ ] Dashboards Grafana foram preparados
- [ ] Alertas foram configurados

## 🚀 Deploy

- [ ] Ambiente correto foi selecionado (dev/staging/prod)
- [ ] Backup do cluster foi feito
- [ ] Time foi notificado
- [ ] Janela de manutenção respeitada

```bash
# Fazer deploy
oc apply -f openshift-deployment.yaml

# Verificar roll out
oc rollout status deployment/aplicacao-deployment -n aplicacao
```

## ✔️ Pós-Deploy

- [ ] Todos os pods estão rodando:
  ```bash
  oc get pods -n aplicacao
  ```

- [ ] Nenhum pod está em CrashLoopBackOff:
  ```bash
  oc describe pod <pod-name> -n aplicacao
  ```

- [ ] Aplicação está respondendo em sua URL
- [ ] Health checks passando:
  ```bash
  oc exec <pod-name> -n aplicacao -- curl localhost:8080/health/live
  ```

- [ ] Logs não mostram erros críticos:
  ```bash
  oc logs deployment/aplicacao-deployment -n aplicacao --all-containers=true
  ```

- [ ] Métricas estão sendo coletadas
- [ ] Comunicação com dependências (DB, cache, etc) funciona

## 🔧 Troubleshooting

### Pod não sai de Pending
```bash
oc describe node <node-name>
oc top node
```

### Pod em CrashLoopBackOff
```bash
oc logs <pod-name> -n aplicacao -p  # logs anteriores
oc describe pod <pod-name> -n aplicacao
```

### Aplicação não acessível
```bash
oc get svc -n aplicacao
oc get route -n aplicacao
curl -v <route-url>
```

### Verificar resource usage
```bash
oc top pods -n aplicacao
oc top nodes
```

## 📚 Referências Úteis

- [OpenShift Documentation](https://docs.openshift.com)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Red Hat Container Best Practices](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html-single/best_practices_guide/index)

---

**Lembrete**: Executar este checklist antes de cada deploy reduz significativamente o risco de problemas em produção!
