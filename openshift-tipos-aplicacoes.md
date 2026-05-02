# Exemplos de Deployment para Diferentes Tipos de Aplicações

## 1. Aplicação Web (Django, Flask, Node.js, etc)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: aplicacao
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: seu-registry.azurecr.io/web-app:latest
        ports:
        - containerPort: 8000
        env:
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: web-secrets
              key: SECRET_KEY
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8000
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8000
          initialDelaySeconds: 10
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"

---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  namespace: aplicacao
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8000
  type: ClusterIP

---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: web-app-route
  namespace: aplicacao
spec:
  host: web-app.apps.seu-cluster.com
  to:
    kind: Service
    name: web-app-service
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

## 2. API REST (Java Spring Boot)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-rest
  namespace: aplicacao
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-rest
  template:
    metadata:
      labels:
        app: api-rest
    spec:
      containers:
      - name: api
        image: seu-registry.azurecr.io/api-rest:latest
        ports:
        - containerPort: 8080
        - containerPort: 9090  # Metrics
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_URL
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 45
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 5
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        volumeMounts:
        - name: config
          mountPath: /config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: app-config

---
apiVersion: v1
kind: Service
metadata:
  name: api-rest-service
  namespace: aplicacao
spec:
  selector:
    app: api-rest
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: metrics
    port: 9090
    targetPort: 9090
  type: ClusterIP

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-rest-hpa
  namespace: aplicacao
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-rest
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 3. Banco de Dados (PostgreSQL Stateful)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: aplicacao
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 50Gi

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: aplicacao
spec:
  serviceName: postgres-service
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: aplicacao
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

## 4. Worker/Background Job (Celery, Bull, etc)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: background-worker
  namespace: aplicacao
spec:
  replicas: 2
  selector:
    matchLabels:
      app: background-worker
  template:
    metadata:
      labels:
        app: background-worker
    spec:
      containers:
      - name: worker
        image: seu-registry.azurecr.io/background-worker:latest
        command: ["celery", "-A", "tasks", "worker", "--loglevel=info"]
        env:
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: REDIS_URL
        - name: BROKER_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: BROKER_URL
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        volumeMounts:
        - name: logs
          mountPath: /var/log/worker
      volumes:
      - name: logs
        emptyDir: {}
```

## 5. Cache/Session Store (Redis)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  namespace: aplicacao
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command:
        - redis-server
        - "--requirepass"
        - "$(REDIS_PASSWORD)"
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: password
        livenessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 10
        readinessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: aplicacao
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
```

## 6. Microserviço Com Message Queue

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: message-service
  namespace: aplicacao
spec:
  replicas: 3
  selector:
    matchLabels:
      app: message-service
  template:
    metadata:
      labels:
        app: message-service
    spec:
      containers:
      - name: service
        image: seu-registry.azurecr.io/message-service:latest
        ports:
        - containerPort: 8080
        env:
        - name: QUEUE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: RABBITMQ_HOST
        - name: QUEUE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: RABBITMQ_PASSWORD
        - name: SERVICE_NAME
          value: "message-service"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```
