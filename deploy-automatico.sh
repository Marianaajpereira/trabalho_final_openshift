#!/bin/bash

set -e

echo "🚀 Iniciando deploy no OpenShift..."
echo ""

# Passo 1
echo "📦 Passo 1: Criando aplicação..."
oc new-app https://github.com/Marianaajpereira/trabalho_final_openshift.git --name=trabalho-final-openshift
echo "✅ Aplicação criada!"
echo ""

# Passo 2
echo "⏳ Passo 2: Aguardando build completar (pode levar 2-3 minutos)..."
while true; do
  BUILD_STATUS=$(oc get build trabalho-final-openshift-1 -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
  if [ "$BUILD_STATUS" = "Complete" ]; then
    echo "✅ Build completo!"
    break
  elif [ "$BUILD_STATUS" = "Failed" ]; then
    echo "❌ Build falhou!"
    exit 1
  fi
  echo -n "."
  sleep 5
done
echo ""

# Passo 3
echo "🔧 Passo 3: Aguardando Deployment estar pronto..."
sleep 10
oc rollout status deployment/trabalho-final-openshift --timeout=5m
echo "✅ Deployment pronto!"
echo ""

# Passo 4
echo "🛠️  Passo 4: Aplicando correção de portas..."
oc apply -f deployment-fix.yaml
echo "✅ Correção aplicada!"
echo ""

# Passo 5
echo "⏳ Passo 5: Aguardando pod reiniciar..."
sleep 5
oc rollout status deployment/trabalho-final-openshift --timeout=5m
echo "✅ Pod reiniciado!"
echo ""

# Passo 6
echo "🔌 Passo 6: Criando Service..."
oc delete svc trabalho-final-openshift 2>/dev/null || true
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
echo "✅ Service criado!"
echo ""

# Passo 7
echo "🌐 Passo 7: Expondo aplicação (criando Route)..."
oc expose svc/trabalho-final-openshift 2>/dev/null || echo "ℹ️  Route já existe"
echo "✅ Route criada/atualizada!"
echo ""

# Passo 8
echo "🎉 Passo 8: Obtendo URL..."
ROUTE_URL=$(oc get route trabalho-final-openshift -o jsonpath='{.spec.host}')
echo ""
echo "========================================="
echo "✅ APLICAÇÃO DEPLOYADA COM SUCESSO!"
echo "========================================="
echo ""
echo "🌐 URL da aplicação:"
echo "   http://$ROUTE_URL"
echo ""
echo "📝 Teste:"
echo "   curl http://$ROUTE_URL/"
echo ""
echo "✅ Todos os passos concluídos!"
