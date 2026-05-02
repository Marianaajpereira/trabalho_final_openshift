# Exemplos de Configurações por Ambiente

## Desenvolvimento (3 replicas, limites menores)

```yaml
spec:
  replicas: 1
  strategy:
    type: Recreate  # Mais rápido em dev
  template:
    spec:
      containers:
      - name: aplicacao
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "250m"
        livenessProbe:
          initialDelaySeconds: 10
        readinessProbe:
          initialDelaySeconds: 5
```

## Staging (2-5 replicas, recursos médios)

```yaml
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: aplicacao
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: aplicacao-hpa-staging
spec:
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 75
```

## Produção (3-20 replicas, limites altos, alta disponibilidade)

```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:  # Obrigatório em produção
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - aplicacao
            topologyKey: kubernetes.io/hostname
      containers:
      - name: aplicacao
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
      terminationGracePeriodSeconds: 60
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: aplicacao-hpa-prod
spec:
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 65
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 75
```

## Network Policy (Isolamento de Rede - Opcional)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: aplicacao-netpol
  namespace: aplicacao
spec:
  podSelector:
    matchLabels:
      app: aplicacao
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

## PodDisruptionBudget (Proteger contra interrupções)

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: aplicacao-pdb
  namespace: aplicacao
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: aplicacao
```

## ImageStream (Usar do OpenShift Registry)

```yaml
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: aplicacao
  namespace: aplicacao
spec:
  lookupPolicy:
    local: false
  tags:
  - name: latest
    from:
      kind: ImageStreamTag
      name: aplicacao:v1.0.0
    importPolicy:
      scheduled: false
```

## BuildConfig (Build da Imagem no OpenShift)

```yaml
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: aplicacao-build
  namespace: aplicacao
spec:
  source:
    type: Git
    git:
      uri: https://seu-git-repo.com/aplicacao.git
      ref: main
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
      from:
        kind: ImageStreamTag
        name: rhel9:latest
        namespace: openshift
  output:
    to:
      kind: ImageStreamTag
      name: aplicacao:latest
  triggers:
  - type: GitHub
    github:
      secret: seu-webhook-secret
```

## Exemplo com Banco de Dados PostgreSQL

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: aplicacao
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: aplicacao
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgresql
        image: postgres:15
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: aplicacao_db
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: db-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
  namespace: aplicacao
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast
```

---

**Dica**: Combine os exemplos acima com o arquivo principal `openshift-deployment.yaml` conforme necessário!
