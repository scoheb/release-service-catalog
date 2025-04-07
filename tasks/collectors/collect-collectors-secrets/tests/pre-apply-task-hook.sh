#!/usr/bin/env bash

# Install the CRDs so we can create/get them
.github/scripts/install_crds.sh

# Add RBAC so that the SA executing the tests can retrieve CRs
kubectl apply -f .github/resources/crd_rbac.yaml

# Create a dummy secret for jira collector (and delete it first if it exists)
kubectl delete secret my-jira-token --ignore-not-found
kubectl create secret generic my-jira-token --from-literal=apitoken=ABCDEF
kubectl label secret my-jira-token konflux-ci.dev/collector=test-collector

# Create a dummy secret for jira collector (and delete it first if it exists)
kubectl delete secret my-jira-token-not-labelled --ignore-not-found
kubectl create secret generic my-jira-token-not-labelled --from-literal=apitoken=ABCDEF

# Create a dummy secret for bugzilla collector (and delete it first if it exists)
kubectl delete secret my-bugzilla-token --ignore-not-found
kubectl create secret generic my-bugzilla-token --from-literal=apitoken=STUVWXYZ
kubectl label secret my-bugzilla-token konflux-ci.dev/collector=test-collector

# Create a dummy sa for collectors (and delete it first if it exists)
kubectl delete sa tenant-collector-sa --ignore-not-found
cat > serviceAccount << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-collector-sa
secrets:
  - name: my-jira-token
  - name: my-bugzilla-token
EOF
kubectl apply -f serviceAccount

# Create a dummy sa for collectors (and delete it first if it exists)
kubectl delete sa tenant-collector-sa-2 --ignore-not-found
cat > serviceAccount << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-collector-sa-2
EOF
kubectl apply -f serviceAccount

# Create the default Tekton SA for collectors (and delete it first if it exists)
kubectl delete sa appstudio-pipeline --ignore-not-found
cat > serviceAccount << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: appstudio-pipeline
secrets:
  - name: my-jira-token
  - name: my-bugzilla-token
EOF
kubectl apply -f serviceAccount

kubectl delete sa tenant-collector-sa-3 --ignore-not-found
cat > serviceAccount << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-collector-sa-3
secrets:
  - name: my-jira-token-not-labelled
EOF
kubectl apply -f serviceAccount
