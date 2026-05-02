#!/bin/bash

echo "1. Criando o Service..."
oc create service clusterip trabalho-final-openshift --tcp=80:8080

echo ""
echo "2. Verificando Service..."
oc get svc trabalho-final-openshift

echo ""
echo "3. Expondo o Service com Route..."
oc expose svc/trabalho-final-openshift --hostname=trabalho-final-openshift.apps.example.com

echo ""
echo "4. Verificando Route..."
oc get route trabalho-final-openshift

echo ""
echo "✅ Pronto! Sua aplicação está exposta!"
