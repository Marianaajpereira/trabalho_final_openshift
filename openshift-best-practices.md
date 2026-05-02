# Boas Práticas de Deployment no OpenShift

## 1. Segurança

### Container Security
```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true      # Não rodar como root
        runAsUser: 1000         # Rodar com usuário específico
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      
      containers:
      - name: aplicacao
        securityContext:
          allowPrivilegeEscalation: false  # Proibir escalação de privilégio
          readOnlyRootFilesystem: true     # Filesystem somente leitura
          capabilities:
            drop:
            - ALL                          # Remover todas as capabilities
            add:
            - NET_BIND_SERVICE            # Adicionar apenas se necessário
```

### Image Security
- ✅ Use imagens distroless (menor, mais seguro)
- ✅ Escaneie imagens por vulnerabilidades (Trivy, Snyk)
- ✅ Use digest ao invés de tags (`image@sha256:...`)
- ✅ Nunca use `latest` em produção

### Secrets Management
```yaml
# ❌ ERRADO - Secrets em plain text
- name: DB_PASSWORD
  value: "minha-senha"

# ✅ CORRETO
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secrets
      key: password

# ✅ MELHOR - Use Sealed Secrets ou HashiCorp Vault
```

## 2. Performance

### Resource Requests e Limits
```yaml
resources:
  requests:
    memory: "256Mi"    # Mínimo garantido
    cpu: "250m"
  limits:
    memory: "512Mi"    # Máximo permitido
    cpu: "500m"
```

### Dicas:
- ✅ Sempre defina requests e limits
- ✅ Requests = recursos garantidos para o pod
- ✅ Limits = máximo que o pod pode usar
- ✅ Deixe margem entre requests e limits (ex: 2x)

### Cache e CDN
```yaml
# Use init containers para pré-carregar cache
initContainers:
- name: cache-init
  image: seu-registry.azurecr.io/cache-loader:latest
  volumeMounts:
  - name: cache
    mountPath: /cache
```

## 3. Disponibilidade

### Health Checks Corretos
```yaml
livenessProbe:
  httpGet:
    path: /health/live  # Verificar se app está vivo
    port: http
  initialDelaySeconds: 30  # Esperar inicialização
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready  # Verificar se pronto para receber tráfego
    port: http
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3
```

### Pod Disruption Budgets
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: aplicacao-pdb
  namespace: aplicacao
spec:
  minAvailable: 2          # Mínimo de 2 pods sempre disponíveis
  selector:
    matchLabels:
      app: aplicacao
```

### Anti-Affinity para HA
```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:  # Obrigatório
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - aplicacao
      topologyKey: kubernetes.io/hostname  # Diferentes nós
```

## 4. Observabilidade

### Logs Estruturados
```python
# ✅ Bom
import json
logger.info(json.dumps({
    "event": "user_login",
    "user_id": 123,
    "timestamp": datetime.now().isoformat()
}))

# ❌ Ruim
logger.info("User logged in")
```

### Métricas Importantes
```yaml
- http_request_duration_seconds  # Latência
- http_requests_total             # Taxa de requisições
- http_requests_errors_total      # Erros
- app_memory_bytes                # Uso de memória
- app_cpu_usage_seconds_total    # Uso de CPU
```

### Tracing Distribuído
```yaml
# Adicione headers de tracing
- name: JAEGER_SAMPLER_TYPE
  value: "const"
- name: JAEGER_SAMPLER_PARAM
  value: "1"
- name: JAEGER_AGENT_HOST
  value: "jaeger-agent.observability.svc"
```

## 5. Armazenamento

### StatefulSets para Estado
```yaml
# Use StatefulSet, não Deployment, para dados persistentes
kind: StatefulSet
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: 10Gi
```

### Backup Estratégia
```yaml
# CronJob para backups periódicos
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # 2h toda noite
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            command: ["./backup.sh"]
```

## 6. Networking

### Service Mesh (Istio)
```yaml
# Traffic management
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: aplicacao-vs
spec:
  hosts:
  - aplicacao
  http:
  - match:
    - uri:
        prefix: "/v2"
    route:
    - destination:
        host: aplicacao
        subset: v2
      weight: 20
    - destination:
        host: aplicacao
        subset: v1
      weight: 80
```

### Ingress Controller
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aplicacao-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - aplicacao.example.com
    secretName: aplicacao-tls
  rules:
  - host: aplicacao.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: aplicacao-service
            port:
              number: 80
```

## 7. Governance

### Resource Quotas
```yaml
# Limite total de recursos por namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    requests.cpu: "100"
    requests.memory: "200Gi"
    limits.cpu: "200"
    limits.memory: "400Gi"
```

### Network Policies
```yaml
# Deny by default, allow específico
- Deny all traffic
- Allow apenas de Ingress Controller
- Allow para banco de dados
- Allow para service mesh (Istio)
```

## 8. Deployment Strategies

### RollingUpdate (Padrão)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1      # 1 pod extra durante update
    maxUnavailable: 0  # 0 pods unavailable
```

### Blue-Green
```bash
# Deploy nova versão como "green"
# Teste completamente
# Switch router para "green"
# Manter "blue" como fallback
```

### Canary
```yaml
# 1. Deploy 1-2 replicas da nova versão
# 2. Enviar 5-10% do tráfego
# 3. Monitorar métricas
# 4. Se OK, aumentar para 100%
# 5. Se erro, rollback automático
```

## 9. Cost Optimization

- ✅ Use resource requests adequados (evita over-provisioning)
- ✅ Configure HPA para scale down em baixa demanda
- ✅ Use spot instances para workloads não-críticos
- ✅ Delete recursos não utilizados regularmente
- ✅ Monitor custos com ferramentas como Kubecost

## 10. Checklist pré-deploy

- [ ] Imagem testada e validada
- [ ] Sem vulnerabilidades (scan de segurança)
- [ ] Health checks configurados
- [ ] Resource requests/limits definidos
- [ ] Secrets configurados corretamente
- [ ] Logs estruturados
- [ ] Backup strategy em lugar
- [ ] Monitoring/alerting em lugar
- [ ] RBAC configurado
- [ ] Network policies em lugar
- [ ] Rollback strategy documentada
- [ ] Documentação atualizada
