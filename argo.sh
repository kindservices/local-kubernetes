#!/usr/bin/env bash

export ARGO_NAMESPACE=${ARGO_NAMESPACE:-argocd}
export ARGO_PORT=${ARGO_PORT:-8080}
export ARGO_USER=${ARGO_USER:-admin}

function ensureDocker() {
    docker ps || (echo "docker isn't running" && exit 1)
}

function installKind() {
    # get kind
    (which kind && echo "kind already installed") || (echo "installing kind" && brew install kind)

    # get or create a cluster
    if kind get clusters 2> /dev/null | grep -q 'local-cluster'; then
      echo "local-cluster already exists"
    else 
      echo "creating cluster"
      kind create cluster --name local-cluster
      kubectl cluster-info --context kind-local-cluster
    fi

    # and ... not really just for local clusters, but...
    (which k9s && echo "k9s is installed") || (echo "installing k9s" && brew install k9s)
}

function installArgo() {
    which argocd || brew install argocd
}

function kubeApplyArgo() {
    # ensure namespace exists
    kubectl get namespace "$ARGO_NAMESPACE" || kubectl create namespace "$ARGO_NAMESPACE"
    
    # this is idempotent - it won't have any affect if we're already installed argo
    kubectl apply -n "$ARGO_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # some script-kiddy magic which I forgot to document when I followed a blog or tutorial
    kubectl patch svc argocd-server -n "$ARGO_NAMESPACE" -p '{"spec": {"type": "LoadBalancer"}}'
}

function setPwd() {
    argocd account update-password
}

function deleteArgo() {
    kubectl delete -n "$ARGO_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
}
function getArgoPwd() {
    i=1
    doGetArgoPwd
    while [ -z "$MY_ARGO_PWD" ]
    do
        echo "(retry $i) waiting for argo to start..."
        sleep 3
        i=$(( $i + 1 ))
        doGetArgoPwd
    done
}
function doGetArgoPwd() {
  echo "****************** getting ArgoCD credentials ******************"
  export MY_ARGO_PWD=$(kubectl -n "$ARGO_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)
  echo "Argo pwd is $MY_ARGO_PWD"
}

function portForward() {
    kubectl port-forward svc/argocd-server -n argocd $ARGO_PORT:443 &
}

function login() {
    getArgoPwd
    echo "logging in w/ user admin and pwd $MY_ARGO_PWD"
    echo "running: argocd login localhost:$ARGO_PORT --username $ARGO_USER --password $MY_ARGO_PWD  --insecure --skip-test-tls "
    argocd login localhost:$ARGO_PORT --username admin --password $MY_ARGO_PWD  --insecure --skip-test-tls 

    echo "============================================="
    echo "You can open argo at https://localhost:$ARGO_PORT"    
    echo "============================================="
}

function openArgoDeprecated() {
  echo "****************** getting ArgoCD IP ******************"
  which jq || brew install jq
  export MY_ARGO_IP=$(kubectl -n "$ARGO_NAMESPACE" get svc argocd-server -o json | jq '.status.loadBalancer.ingress | .[].ip' | tr -d '"')
  echo "MY_ARGO_IP is $MY_ARGO_IP"

  echo "****************** log in to ArgoCD $MY_ARGO_IP w/ user admin, pwd $MY_ARGO_PWD ******************"
  argocd login "$MY_ARGO_IP" --password "$MY_ARGO_PWD" --username admin --insecure
  open "https://$MY_ARGO_IP"
}


# https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/
function setAutoSync() {
    APP=${APP:-guestbook}
    echo "enabling auto-sync sync on $APP"
    argocd app set $APP --sync-policy automated
}

function setAutoPrune() {
    APP=${APP:-guestbook}
    echo "enabling auto-prune sync on $APP"
    argocd app set $APP --auto-prune
}

function setSelfHeal() {
    APP=${APP:-guestbook}
    echo "enabling self-heal sync on $APP"
    argocd app set $APP --self-heal
}

function beastMode() {
    setAutoSync
    setAutoPrune
    setSelfHeal
}

# ========================================================================================================================
# guestbook
# see https://argo-cd.readthedocs.io/en/stable/getting_started/


function installGuestbook() {
    argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
}

function getGuestbook() {
    argocd app get guestbook
}

function syncGuestbook() {
    argocd app sync guestbook
}