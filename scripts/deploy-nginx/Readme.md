### Example #2: Deploy NGINX

### Deployment

```    
    kubectl apply -f 01-nginx-namespace.yaml
    kubectl apply -f 02-nginx-deployment.yaml
```

### K8s Commands: kubectl get commands

```
    kubectl -n ns-nginx get pod
    kubectl -n ns-nginx get pod --watch
    kubectl -n ns-nginx describe pod nginx-xxxxxx
    kubectl -n ns-nginx get service
    kubectl -n ns-nginx get ingress
    kubectl -n ns-nginx get all
```

### K8s Commands: kubectl debugging commands

```
    kubectl -n ns-nginx describe pod nginx-xxxxxx
    kubectl -n ns-nginx logs nginx-xxxxxx
    kubectl -n ns-nginx describe service nginx-service
```

### Remove app

```
    kubectl delete --all  deployments,services,replicasets --namespace=ns-nginx
    kubectl delete namespace ns-nginx
```

### Imperative

```
    kubectl create namespace ns-nginx
    kubectl run nginx --image=nginx:1.16 --port=80 --replicas=2 -n ns-nginx
    kubectl expose deployment nginx --port=80 --type="LoadBalancer" -n ns-nginx
    kubectl -n ns-nginx get all
```