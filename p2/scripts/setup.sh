#!/bin/bash

echo "Setting up Kubernetes applications and ingress..."

kubectl apply -f /vagrant/confs/app-one.yaml
kubectl apply -f /vagrant/confs/app-two.yaml
kubectl apply -f /vagrant/confs/app-three.yaml
kubectl apply -f /vagrant/confs/ingress.yaml

echo "Kubernetes applications and ingress setup completed."
