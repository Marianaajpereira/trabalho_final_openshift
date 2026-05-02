# 🚀 Passo a Passo - Deploy OpenShift

## ✅ Passo 1: Criar a aplicação
```bash
oc new-app https://github.com/Marianaajpereira/trabalho_final_openshift.git --name=trabalho-final-openshift
```

Espere os logs aparecerem. Você verá:
```
--> Success
Build scheduled...
```

---

## ✅ Passo 2: Esperar a build terminar
```bash
# Monitorar o progresso da build
oc get build

# Espere até aparecer "Complete"
# Pode levar 1-2 minutos
```

---

## ✅ Passo 3: Verificar se o Deployment está pronto
```bash
oc get deployment trabalho-final-openshift
```

Você deve ver:
```
NAME                       READY   UP-TO-DATE   AVAILABLE
trabalho-final-openshift   1/1     1            1
```

---

## ✅ Passo 4: Aplicar a correção do Deployment (adiciona portas)
```bash
oc apply -f deployment-fix.yaml
```

Espere um pouco para o pod reiniciar.

---

## ✅ Passo 5: Criar o Service
```bash
oc delete svc trabalho-final-openshift 2>/dev/null

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: trabalho-final-openshift
  namespace: lab-open-shift-mariana364217
spec:
  type: ClusterIP
  selector:
    deployment: trabalho-final-openshift
  ports:
  - port: 80
    targetPort: 8080
EOF
```

Verifique:
```bash
oc describe svc trabalho-final-openshift
```

Deve aparecer:
```
Endpoints:         10.8.0.XX:8080
```

---

## ✅ Passo 6: Expor a Route
```bash
oc expose svc/trabalho-final-openshift
```

---

## ✅ Passo 7: Obter a URL pública
```bash
oc get route trabalho-final-openshift
```

Você verá algo como:
```
NAME                          HOST/PORT                              PORT   PROTOCOL
trabalho-final-openshift      trabalho-final-openshift-lab-...       80     http
```

---

## ✅ Passo 8: Acessar a aplicação

Copie a URL do HOST/PORT e acesse no navegador:

```
http://trabalho-final-openshift-lab-open-shift-mariana364217.apps.seu-cluster.com
```

Você deve ver:
```
Hello World
```

---

## 🔍 Se der erro "Application is not available"

Execute:
```bash
# Ver logs
oc logs deployment/trabalho-final-openshift

# Ver status do pod
oc get pods

# Descrição detalhada
oc describe pod -l deployment=trabalho-final-openshift
```

---

## 📝 Resumo dos comandos em sequência

```bash
# 1. Criar app
oc new-app https://github.com/Marianaajpereira/trabalho_final_openshift.git --name=trabalho-final-openshift

# 2. Esperar build
sleep 30

# 3. Aplicar correção de portas
oc apply -f deployment-fix.yaml

# 4. Esperar pod reiniciar
sleep 10

# 5. Criar Service
oc delete svc trabalho-final-openshift 2>/dev/null
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: trabalho-final-openshift
  namespace: lab-open-shift-mariana364217
spec:
  type: ClusterIP
  selector:
    deployment: trabalho-final-openshift
  ports:
  - port: 80
    targetPort: 8080
EOF

# 6. Expor
oc expose svc/trabalho-final-openshift

# 7. Ver URL
oc get route trabalho-final-openshift
```

Pronto! 🎉
