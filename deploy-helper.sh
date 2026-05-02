#!/bin/bash

# Script Helper para Gerenciamento de Deployment OpenShift
# Uso: ./deploy-helper.sh [comando]

set -e

# Configurações
NAMESPACE="aplicacao"
DEPLOYMENT="aplicacao-deployment"
YAML_FILE="openshift-deployment.yaml"
REGISTRY="seu-registry.azurecr.io"  # Alterar conforme necessário
IMAGE_NAME="aplicacao"
ROUTE_NAME="aplicacao-route"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}\n"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}\n"
}

print_error() {
    echo -e "${RED}✗ $1${NC}\n"
}

# Verificar pré-requisitos
check_prerequisites() {
    print_header "Verificando Pré-requisitos"
    
    if ! command -v oc &> /dev/null; then
        print_error "OpenShift CLI (oc) não está instalado"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl não está instalado (opcional)"
    fi
    
    if [ ! -f "$YAML_FILE" ]; then
        print_error "Arquivo $YAML_FILE não encontrado"
        exit 1
    fi
    
    print_success "Pré-requisitos verificados"
}

# Validar YAML
validate_yaml() {
    print_header "Validando YAML"
    
    if oc apply -f "$YAML_FILE" --dry-run=client &> /dev/null; then
        print_success "YAML válido"
    else
        print_error "YAML inválido"
        exit 1
    fi
}

# Deploy
deploy() {
    print_header "Iniciando Deploy"
    
    if oc apply -f "$YAML_FILE"; then
        print_success "Deploy aplicado com sucesso"
        
        # Aguardar rollout
        print_header "Aguardando Rollout"
        if oc rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m; then
            print_success "Rollout completado com sucesso"
        else
            print_warning "Rollout não completou no tempo esperado"
        fi
    else
        print_error "Falha ao aplicar deployment"
        exit 1
    fi
}

# Status
status() {
    print_header "Status do Deployment"
    
    echo -e "${BLUE}Pods:${NC}"
    oc get pods -n $NAMESPACE -l app=aplicacao --no-headers
    
    echo -e "\n${BLUE}Deployment:${NC}"
    oc get deployment -n $NAMESPACE $DEPLOYMENT
    
    echo -e "\n${BLUE}Service:${NC}"
    oc get svc -n $NAMESPACE
    
    echo -e "\n${BLUE}Route:${NC}"
    oc get route -n $NAMESPACE $ROUTE_NAME
    
    echo -e "\n${BLUE}HPA:${NC}"
    oc get hpa -n $NAMESPACE
}

# Logs
logs() {
    print_header "Mostrando Logs"
    
    if [ -z "$1" ]; then
        echo "Mostrando logs do deployment mais recente..."
        oc logs deployment/$DEPLOYMENT -n $NAMESPACE -f --tail=100
    else
        echo "Mostrando logs do pod: $1"
        oc logs $1 -n $NAMESPACE -f --tail=100
    fi
}

# Atualizar imagem
update_image() {
    print_header "Atualizando Imagem Docker"
    
    if [ -z "$1" ]; then
        print_error "Versão/tag não fornecida"
        print_warning "Uso: $0 update-image <versao>"
        exit 1
    fi
    
    NEW_IMAGE="$REGISTRY/$IMAGE_NAME:$1"
    
    echo "Atualizando para: $NEW_IMAGE"
    
    if oc set image deployment/$DEPLOYMENT \
        $DEPLOYMENT=$NEW_IMAGE \
        -n $NAMESPACE; then
        print_success "Imagem atualizada"
        
        echo "Aguardando novo rollout..."
        oc rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m
        print_success "Novo rollout completado"
    else
        print_error "Falha ao atualizar imagem"
        exit 1
    fi
}

# Rollback
rollback() {
    print_header "Realizando Rollback"
    
    if [ -z "$1" ]; then
        echo "Histórico de revisões:"
        oc rollout history deployment/$DEPLOYMENT -n $NAMESPACE
        echo ""
        print_warning "Uso: $0 rollback <numero-revisao>"
    else
        echo "Fazendo rollback para revisão: $1"
        if oc rollout undo deployment/$DEPLOYMENT --to-revision=$1 -n $NAMESPACE; then
            print_success "Rollback completado"
            oc rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m
        else
            print_error "Falha ao fazer rollback"
            exit 1
        fi
    fi
}

# Escalar
scale() {
    print_header "Escalando Deployment"
    
    if [ -z "$1" ]; then
        print_error "Número de replicas não fornecido"
        print_warning "Uso: $0 scale <numero-replicas>"
        exit 1
    fi
    
    echo "Escalando para $1 replicas..."
    if oc scale deployment/$DEPLOYMENT --replicas=$1 -n $NAMESPACE; then
        print_success "Scaling completado"
    else
        print_error "Falha ao escalar"
        exit 1
    fi
}

# Executar command em pod
exec_pod() {
    print_header "Executando Comando em Pod"
    
    if [ -z "$1" ]; then
        print_error "Comando não fornecido"
        print_warning "Uso: $0 exec-pod <comando>"
        exit 1
    fi
    
    POD=$(oc get pods -n $NAMESPACE -l app=aplicacao -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$POD" ]; then
        print_error "Nenhum pod encontrado"
        exit 1
    fi
    
    echo "Executando em pod: $POD"
    oc exec -it $POD -n $NAMESPACE -- bash -c "$1"
}

# Port forward
port_forward() {
    print_header "Port Forward"
    
    if [ -z "$1" ]; then
        LOCAL_PORT=8080
    else
        LOCAL_PORT=$1
    fi
    
    POD=$(oc get pods -n $NAMESPACE -l app=aplicacao -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$POD" ]; then
        print_error "Nenhum pod encontrado"
        exit 1
    fi
    
    echo "Acessar: http://localhost:$LOCAL_PORT"
    oc port-forward pod/$POD $LOCAL_PORT:8080 -n $NAMESPACE
}

# Health check
health_check() {
    print_header "Verificando Health Check"
    
    POD=$(oc get pods -n $NAMESPACE -l app=aplicacao -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$POD" ]; then
        print_error "Nenhum pod encontrado"
        exit 1
    fi
    
    echo "Verificando endpoints de health do pod: $POD"
    
    echo -e "\n${BLUE}Liveness Probe (/health/live):${NC}"
    oc exec -it $POD -n $NAMESPACE -- curl -s localhost:8080/health/live || print_warning "Falha na liveness probe"
    
    echo -e "\n${BLUE}Readiness Probe (/health/ready):${NC}"
    oc exec -it $POD -n $NAMESPACE -- curl -s localhost:8080/health/ready || print_warning "Falha na readiness probe"
}

# Remover deployment
remove() {
    print_header "Removendo Deployment"
    
    read -p "Tem certeza que deseja remover o namespace $NAMESPACE? (s/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        if oc delete namespace $NAMESPACE; then
            print_success "Namespace removido"
        else
            print_error "Falha ao remover namespace"
            exit 1
        fi
    else
        print_warning "Operação cancelada"
    fi
}

# Abrir URL da aplicação
open_app() {
    print_header "Abrindo Aplicação"
    
    ROUTE=$(oc get route $ROUTE_NAME -n $NAMESPACE -o jsonpath='{.spec.host}')
    
    if [ -z "$ROUTE" ]; then
        print_error "Route não encontrada"
        exit 1
    fi
    
    URL="https://$ROUTE"
    echo "URL: $URL"
    
    if command -v open &> /dev/null; then
        open "$URL"
        print_success "Abrindo $URL no navegador"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$URL"
        print_success "Abrindo $URL no navegador"
    else
        print_warning "Navegador não encontrado. Acesse manualmente: $URL"
    fi
}

# Menu de ajuda
show_help() {
    cat << EOF
${BLUE}=== OpenShift Deployment Helper ===${NC}

COMANDOS DISPONÍVEIS:

  check              Verifica pré-requisitos
  validate           Valida arquivo YAML
  deploy             Faz deploy da aplicação
  status             Mostra status do deployment
  logs [pod]         Mostra logs (opcional: pod específico)
  update-image TAG   Atualiza para nova versão da imagem
  rollback [REV]     Faz rollback (opcional: para revisão específica)
  scale NUM          Escala para N replicas
  exec-pod CMD       Executa comando em um pod
  port-forward [P]   Port forward para localhost:P (padrão: 8080)
  health             Verifica health checks
  remove             Remove deployment e namespace
  open               Abre aplicação no navegador
  help               Mostra esta mensagem

EXEMPLOS:

  ./deploy-helper.sh deploy
  ./deploy-helper.sh update-image v2.0.0
  ./deploy-helper.sh logs
  ./deploy-helper.sh scale 5
  ./deploy-helper.sh exec-pod "env"
  ./deploy-helper.sh port-forward 9090

EOF
}

# Main
main() {
    COMMAND="${1:-help}"
    
    case "$COMMAND" in
        check)
            check_prerequisites
            ;;
        validate)
            validate_yaml
            ;;
        deploy)
            check_prerequisites
            validate_yaml
            deploy
            ;;
        status)
            status
            ;;
        logs)
            logs "$2"
            ;;
        update-image)
            update_image "$2"
            ;;
        rollback)
            rollback "$2"
            ;;
        scale)
            scale "$2"
            ;;
        exec-pod)
            exec_pod "$2"
            ;;
        port-forward)
            port_forward "$2"
            ;;
        health)
            health_check
            ;;
        remove)
            remove
            ;;
        open)
            open_app
            ;;
        help)
            show_help
            ;;
        *)
            print_error "Comando desconhecido: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
