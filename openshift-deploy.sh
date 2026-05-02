#!/bin/bash

# Script Completo de Deploy e Gerenciamento no OpenShift
# Uso: ./openshift-deploy.sh [comando] [argumentos]

set -e

# Configurações
REGISTRY="${REGISTRY:-seu-registry.azurecr.io}"
NAMESPACE="${NAMESPACE:-aplicacao}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-aplicacao-deployment}"
CONFIG_FILE="${CONFIG_FILE:-openshift-deployment.yaml}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de output
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Função para verificar pré-requisitos
check_prerequisites() {
    info "Verificando pré-requisitos..."
    
    if ! command -v oc &> /dev/null; then
        error "oc CLI não encontrado. Instale em: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started.html"
    fi
    
    if ! command -v docker &> /dev/null; then
        error "Docker não encontrado"
    fi
    
    success "Pré-requisitos verificados"
}

# Função para fazer login
login() {
    local server="$1"
    local token="$2"
    
    info "Fazendo login no OpenShift..."
    
    oc login --server="$server" \
        --token="$token" \
        --insecure-skip-tls-verify=true
    
    success "Login bem-sucedido"
}

# Função para criar/atualizar namespace
create_namespace() {
    info "Verificando namespace: $NAMESPACE"
    
    if ! oc get namespace "$NAMESPACE" &> /dev/null; then
        info "Criando namespace: $NAMESPACE"
        oc create namespace "$NAMESPACE"
        success "Namespace criado"
    else
        info "Namespace já existe"
    fi
}

# Função para aplicar configurações
apply_config() {
    info "Aplicando configurações do arquivo: $CONFIG_FILE"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Arquivo não encontrado: $CONFIG_FILE"
    fi
    
    oc apply -f "$CONFIG_FILE"
    success "Configurações aplicadas"
}

# Função para build e push da imagem
build_and_push() {
    local image_tag="$1"
    local dockerfile="${2:-.}"
    
    if [ -z "$image_tag" ]; then
        error "Tag da imagem não especificada. Uso: $0 build <tag> [dockerfile]"
    fi
    
    info "Building Docker image: $REGISTRY/aplicacao:$image_tag"
    docker build -t "$REGISTRY/aplicacao:$image_tag" -f "$dockerfile" .
    
    info "Pushing para registry..."
    docker push "$REGISTRY/aplicacao:$image_tag"
    
    success "Image built and pushed: $REGISTRY/aplicacao:$image_tag"
}

# Função para update de imagem
update_image() {
    local image_tag="$1"
    
    if [ -z "$image_tag" ]; then
        error "Tag da imagem não especificada. Uso: $0 update <tag>"
    fi
    
    info "Atualizando imagem para: $image_tag"
    oc set image deployment/$DEPLOYMENT_NAME \
        aplicacao="$REGISTRY/aplicacao:$image_tag" \
        -n "$NAMESPACE"
    
    success "Imagem atualizada"
}

# Função para verificar status do deploy
status() {
    info "Verificando status do deployment: $DEPLOYMENT_NAME"
    oc rollout status deployment/$DEPLOYMENT_NAME -n "$NAMESPACE"
    success "Deployment status OK"
}

# Função para ver logs
logs() {
    local lines="${1:-50}"
    
    info "Mostrando últimas $lines linhas de logs..."
    oc logs -l app=aplicacao -n "$NAMESPACE" --tail="$lines" -f
}

# Função para escalar deployment
scale() {
    local replicas="$1"
    
    if [ -z "$replicas" ]; then
        error "Número de replicas não especificado. Uso: $0 scale <replicas>"
    fi
    
    info "Escalando para $replicas replicas..."
    oc scale deployment/$DEPLOYMENT_NAME --replicas="$replicas" -n "$NAMESPACE"
    success "Deployment escalado para $replicas replicas"
}

# Função para rollback
rollback() {
    warn "Revertendo para versão anterior..."
    oc rollout undo deployment/$DEPLOYMENT_NAME -n "$NAMESPACE"
    oc rollout status deployment/$DEPLOYMENT_NAME -n "$NAMESPACE"
    success "Rollback concluído"
}

# Função para ver histórico de deployments
history() {
    info "Histórico de deployments:"
    oc rollout history deployment/$DEPLOYMENT_NAME -n "$NAMESPACE"
}

# Função para obter informações do pod
pod_info() {
    info "Informações dos pods:"
    oc get pods -n "$NAMESPACE" -o wide
}

# Função para executar comando no pod
exec_pod() {
    local pod="$1"
    shift
    local cmd="$@"
    
    if [ -z "$pod" ]; then
        # Usar primeiro pod se não especificado
        pod=$(oc get pods -l app=aplicacao -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')
    fi
    
    if [ -z "$cmd" ]; then
        info "Abrindo shell no pod: $pod"
        oc exec -it "$pod" -n "$NAMESPACE" -- /bin/bash
    else
        info "Executando: $cmd"
        oc exec -it "$pod" -n "$NAMESPACE" -- bash -c "$cmd"
    fi
}

# Função para port forward
port_forward() {
    local local_port="${1:-8080}"
    local remote_port="${2:-8080}"
    
    info "Port forwarding: localhost:$local_port -> deployment:$remote_port"
    info "Acesse: http://localhost:$local_port"
    
    oc port-forward svc/aplicacao-service "$local_port:$remote_port" -n "$NAMESPACE"
}

# Função para ver eventos
events() {
    info "Eventos recentes:"
    oc get events -n "$NAMESPACE" --sort-by='.lastTimestamp'
}

# Função para limpar recursos
cleanup() {
    warn "Limpando recursos..."
    
    read -p "Tem certeza que deseja deletar o namespace $NAMESPACE? (sim/não): " confirm
    if [ "$confirm" = "sim" ]; then
        oc delete namespace "$NAMESPACE"
        success "Namespace deletado"
    else
        info "Cleanup cancelado"
    fi
}

# Função para mostrar uso
usage() {
    cat << EOF
Uso: $0 [comando] [argumentos]

Comandos:
  check              Verificar pré-requisitos
  login <server> <token>  Fazer login no OpenShift
  namespace          Criar/verificar namespace
  apply              Aplicar configurações
  build <tag> [dockerfile]  Build e push da imagem Docker
  update <tag>       Atualizar imagem do deployment
  status             Verificar status do deployment
  logs [linhas]      Ver logs (padrão: 50 linhas)
  scale <replicas>   Escalar deployment
  rollback           Reverter para versão anterior
  history            Ver histórico de deployments
  pods               Listar pods e informações
  exec [pod] [cmd]   Executar comando no pod
  port-forward [local] [remote]  Port forwarding
  events             Ver eventos recentes
  cleanup            Deletar namespace
  help               Mostrar esta ajuda

Exemplos:
  $0 check
  $0 login https://api.seu-cluster.com:6443 token123abc
  $0 namespace
  $0 build v1.0.0
  $0 update v1.0.0
  $0 status
  $0 logs 100
  $0 scale 5
  $0 rollback
  $0 exec myapp echo "Hello"
  $0 port-forward 8080 8080
EOF
}

# Main
main() {
    local command="$1"
    shift || true
    
    case "$command" in
        check)
            check_prerequisites
            ;;
        login)
            login "$@"
            ;;
        namespace)
            create_namespace
            ;;
        apply)
            apply_config
            ;;
        build)
            build_and_push "$@"
            ;;
        update)
            update_image "$@"
            ;;
        status)
            status
            ;;
        logs)
            logs "$@"
            ;;
        scale)
            scale "$@"
            ;;
        rollback)
            rollback
            ;;
        history)
            history
            ;;
        pods)
            pod_info
            ;;
        exec)
            exec_pod "$@"
            ;;
        port-forward)
            port_forward "$@"
            ;;
        events)
            events
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Comando desconhecido: $command"
            usage
            exit 1
            ;;
    esac
}

# Executar main
main "$@"
