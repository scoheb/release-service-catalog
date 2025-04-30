#!/usr/bin/env bash

# Use this periodically to produce a cleanup script

tenant_namespace=dev-release-team-tenant
managed_namespace=managed-release-team-tenant

#oc project $managed_namespace
kubectl config set-context --current --namespace=$managed_namespace
echo "kubectl config set-context --current --namespace=$managed_namespace" | tee /tmp/cleanup.sh
kubectl get sa --no-headers | grep collector- | awk '{print "kubectl delete sa/"$1}' | tee -a /tmp/cleanup.sh
kubectl get secret --no-headers | grep collector- | awk '{print "kubectl delete secret/"$1}' | tee -a /tmp/cleanup.sh
kubectl get rpa --no-headers | grep collector- | awk '{print "kubectl delete rpa/"$1}' | tee -a /tmp/cleanup.sh
kubectl get enterprisecontractpolicy --no-headers | grep collector- | awk '{print "kubectl delete enterprisecontractpolicy/"$1}' | tee -a /tmp/cleanup.sh
kubectl get rolebinding --no-headers | grep collector- | awk '{print "kubectl delete rolebinding/"$1}' | tee -a /tmp/cleanup.sh

#oc project $tenant_namespace
kubectl config set-context --current --namespace=$tenant_namespace
echo "kubectl config set-context --current --namespace=$tenant_namespace" | tee -a /tmp/cleanup.sh
kubectl get application --no-headers | grep e2eapp- | awk '{print "kubectl delete application/"$1}' | tee -a /tmp/cleanup.sh
kubectl get component --no-headers | grep collector- | awk '{print "kubectl delete component/"$1}' | tee -a /tmp/cleanup.sh
kubectl get rp --no-headers | grep collector- | awk '{print "kubectl delete rp/"$1}' | tee -a /tmp/cleanup.sh
kubectl get rolebinding --no-headers | grep collector- | awk '{print "kubectl delete rolebinding/"$1}' | tee -a /tmp/cleanup.sh
kubectl get sa --no-headers | grep collector- | awk '{print "kubectl delete sa/"$1}' | tee -a /tmp/cleanup.sh
kubectl get secret --no-headers | grep collector- | awk '{print "kubectl delete secret/"$1}' | tee -a /tmp/cleanup.sh

echo "run  sh /tmp/cleanup.sh"
