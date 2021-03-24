### Example #3: Deploy NGINX hello-app

### Deployment

```   
    kubectl apply -f 01-nginx-namespace.yaml
    kubectl apply -f 02-nginx-deployment.yaml
```

### K8s Commands: kubectl get commands

```
    kubectl -n ns-nginx-hello-app get pod
    kubectl -n ns-nginx-hello-app get pod --watch
    kubectl -n ns-nginx-hello-app get service
    kubectl -n ns-nginx-hello-app get ingress
    kubectl -n ns-nginx-hello-app get all
```

### K8s Commands: kubectl debugging commands

```
    kubectl -n ns-nginx-hello-app describe pod nginx-7797b98666-9sfhj
    kubectl -n ns-nginx-hello-app logs nginx-7797b98666-9sfhj
    kubectl -n ns-nginx-hello-app describe service nginx-service
```

### Remove app

```
    kubectl delete --all  deployments,services,replicasets --namespace=ns-nginx-hello-app
    kubectl delete namespace ns-nginx-hello-app
```

### Imperative

```
    kubectl create namespace ns-nginx-hello-app
    kubectl run hello-app --image=nginxdemos/hello --port=80 --replicas=2 -n ns-nginx-hello-app
    kubectl expose deployment hello-app --port=80 --type="LoadBalancer" -n ns-nginx-hello-app
    kubectl -n ns-nginx-hello-app get all
```