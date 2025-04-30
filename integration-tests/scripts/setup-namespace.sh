#!/usr/bin/env bash

CURRENT_NAMESPACE=$(kubectl config view --minify -o 'jsonpath={..namespace}')
kubectl apply -f https://raw.githubusercontent.com/codeready-toolchain/member-operator/master/config/appstudio-pipelines-runner/base/appstudio_pipelines_runner_role.yaml
kubectl create --dry-run=client -o yaml serviceaccount appstudio-pipeline | kubectl apply -f-
kubectl create --dry-run=client -o yaml rolebinding appstudio-pipelines-runner-rolebinding --clusterrole=appstudio-pipelines-runner --serviceaccount=$CURRENT_NAMESPACE:appstudio-pipeline | kubectl apply -f-
