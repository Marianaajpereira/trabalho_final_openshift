# Integração CI/CD com OpenShift

## GitHub Actions

```yaml
name: Deploy to OpenShift

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: seu-registry.azurecr.io
  IMAGE_NAME: aplicacao

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - uses: actions/checkout@v3

    - name: Login ao Azure Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ secrets.AZURE_USERNAME }}
        password: ${{ secrets.AZURE_PASSWORD }}

    - name: Build e Push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

    - name: Deploy para OpenShift
      if: github.ref == 'refs/heads/main'
      run: |
        # Login no OpenShift
        oc login --server=${{ secrets.OPENSHIFT_SERVER }} \
          --token=${{ secrets.OPENSHIFT_TOKEN }} \
          --insecure-skip-tls-verify=true
        
        # Atualizar imagem
        oc set image deployment/aplicacao-deployment \
          aplicacao=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
          -n aplicacao
        
        # Aguardar rollout
        oc rollout status deployment/aplicacao-deployment -n aplicacao

  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Run tests
      run: |
        docker build -t test-image .
        docker run test-image npm test

    - name: Upload coverage
      uses: codecov/codecov-action@v3
```

## GitLab CI

```yaml
stages:
  - build
  - test
  - push
  - deploy

variables:
  REGISTRY: seu-registry.azurecr.io
  IMAGE_NAME: aplicacao
  IMAGE_TAG: $CI_COMMIT_SHA

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $REGISTRY/$IMAGE_NAME:$IMAGE_TAG .
  only:
    - main
    - develop

test:
  stage: test
  image: $REGISTRY/$IMAGE_NAME:$IMAGE_TAG
  script:
    - npm test
    - npm run coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

push:
  stage: push
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $REGISTRY
  script:
    - docker push $REGISTRY/$IMAGE_NAME:$IMAGE_TAG
    - docker tag $REGISTRY/$IMAGE_NAME:$IMAGE_TAG $REGISTRY/$IMAGE_NAME:latest
    - docker push $REGISTRY/$IMAGE_NAME:latest
  only:
    - main

deploy:
  stage: deploy
  image: openshift/origin-cli
  script:
    - oc login --server=$OPENSHIFT_SERVER --token=$OPENSHIFT_TOKEN --insecure-skip-tls-verify=true
    - oc set image deployment/aplicacao-deployment aplicacao=$REGISTRY/$IMAGE_NAME:$IMAGE_TAG -n aplicacao
    - oc rollout status deployment/aplicacao-deployment -n aplicacao
  environment:
    name: production
    kubernetes:
      namespace: aplicacao
  only:
    - main

rollback:
  stage: deploy
  image: openshift/origin-cli
  script:
    - oc login --server=$OPENSHIFT_SERVER --token=$OPENSHIFT_TOKEN --insecure-skip-tls-verify=true
    - oc rollout undo deployment/aplicacao-deployment -n aplicacao
    - oc rollout status deployment/aplicacao-deployment -n aplicacao
  when: manual
  environment:
    name: production
```

## Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        REGISTRY = 'seu-registry.azurecr.io'
        IMAGE_NAME = 'aplicacao'
        IMAGE_TAG = "${BUILD_NUMBER}"
        NAMESPACE = 'aplicacao'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                script {
                    sh '''
                        docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:latest
                    '''
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    sh '''
                        docker run --rm ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} npm test
                    '''
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'azure-registry', 
                        usernameVariable: 'REGISTRY_USER', 
                        passwordVariable: 'REGISTRY_PASS')]) {
                        sh '''
                            echo $REGISTRY_PASS | docker login -u $REGISTRY_USER --password-stdin ${REGISTRY}
                            docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${REGISTRY}/${IMAGE_NAME}:latest
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to OpenShift') {
            when {
                branch 'main'
            }
            steps {
                script {
                    withCredentials([string(credentialsId: 'openshift-token', 
                        variable: 'OC_TOKEN')]) {
                        sh '''
                            oc login --server=${OPENSHIFT_SERVER} --token=${OC_TOKEN} --insecure-skip-tls-verify=true
                            oc set image deployment/aplicacao-deployment \
                                aplicacao=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                                -n ${NAMESPACE}
                            oc rollout status deployment/aplicacao-deployment -n ${NAMESPACE}
                        '''
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    sh '''
                        sleep 10
                        oc rollout status deployment/aplicacao-deployment -n ${NAMESPACE}
                        
                        # Verificar logs
                        oc logs -l app=aplicacao -n ${NAMESPACE} --tail=50
                    '''
                }
            }
        }
    }
    
    post {
        failure {
            script {
                sh '''
                    echo "Deploy falhou, revertendo..."
                    oc login --server=${OPENSHIFT_SERVER} --token=${OC_TOKEN} --insecure-skip-tls-verify=true
                    oc rollout undo deployment/aplicacao-deployment -n ${NAMESPACE}
                '''
            }
        }
    }
}
```

## Argo CD (GitOps)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aplicacao-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/sua-org/seu-repo
    targetRevision: HEAD
    path: openshift/configs
  destination:
    server: https://kubernetes.default.svc
    namespace: aplicacao
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

## Flux CD (GitOps alternativo)

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: aplicacao-repo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/sua-org/seu-repo
  ref:
    branch: main

---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: aplicacao
  namespace: flux-system
spec:
  interval: 10m
  path: ./openshift/configs
  prune: true
  sourceRef:
    kind: GitRepository
    name: aplicacao-repo
  targetNamespace: aplicacao
```

## Scripts Úteis

### Deploy com validação
```bash
#!/bin/bash
set -e

NAMESPACE="aplicacao"
DEPLOYMENT="aplicacao-deployment"
IMAGE_TAG="$1"

if [ -z "$IMAGE_TAG" ]; then
    echo "Uso: ./deploy.sh <image-tag>"
    exit 1
fi

echo "Deployando versão: $IMAGE_TAG"

# Login
oc login --server=$OPENSHIFT_SERVER --token=$OPENSHIFT_TOKEN

# Atualizar imagem
oc set image deployment/$DEPLOYMENT \
    aplicacao=seu-registry.azurecr.io/aplicacao:$IMAGE_TAG \
    -n $NAMESPACE

# Aguardar deploy
oc rollout status deployment/$DEPLOYMENT -n $NAMESPACE

# Healthcheck
echo "Executando healthchecks..."
POD=$(oc get pods -l app=aplicacao -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')
oc exec -it $POD -n $NAMESPACE -- curl http://localhost:8080/health

echo "Deploy concluído com sucesso!"
```

### Rollback automático
```bash
#!/bin/bash

NAMESPACE="aplicacao"
DEPLOYMENT="aplicacao-deployment"

echo "Revertendo para versão anterior..."
oc rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
oc rollout status deployment/$DEPLOYMENT -n $NAMESPACE

echo "Rollback concluído!"
```
