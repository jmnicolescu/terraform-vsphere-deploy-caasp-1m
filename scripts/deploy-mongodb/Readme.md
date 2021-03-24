### Example #1: Deploy MongoDB and Mongo Express

### Create secrets / Update secretes configuration file

```
    The values in the key-value pair must be based64 encoded

    \> echo -n "appuser1" | base64
    YXBwdXNlcjE=
    \> echo -n "abc1234"  | base64
    YWJjMTIzNA==

    Update mongodb-secret.yaml file.
```

### Deployment

```    
    kubectl apply -f 01-mongodb-namespace.yaml
    kubectl apply -f 02-mongodb-pvc.yaml
    kubectl apply -f 03-mongodb-secret.yaml
    kubectl apply -f 04-mongodb-deployment.yaml
    kubectl apply -f 05-mongo-express-deployment.yaml
```

### K8s Commands: kubectl get commands

```
    kubectl -n ns-mongodb get all
    kubectl -n ns-mongodb get secret
    kubectl -n ns-mongodb describe secret mongodb-secret 
    kubectl -n ns-mongodb get pod
    kubectl -n ns-mongodb get pod --watch
    kubectl -n ns-mongodb describe pod mongodb-deployment-78444d94d6-jgkpc
    kubectl -n ns-mongodb get service
    kubectl -n ns-mongodb describe service mongodb-service
    kubectl -n ns-mongodb get all -o wide | grep mongodb
    kubectl -n ns-mongodb get all -o wide | grep mongo-express
    kubectl -n ns-mongodb get configmap
    kubectl -n ns-mongodb describe configmap mongodb-configmap
    kubectl -n ns-mongodb get service
    kubectl -n ns-mongodb describe service mongo-express-service
```

### K8s Commands: kubectl debugging commands

```
    kubectl describe pod mongodb-deployment-78444d94d6-jgkpc
    kubectl logs mongodb-deployment-78444d94d6-jgkpc
    kubectl describe pod mongo-express-797845bd97-65d2d
    kubectl logs mongo-express-797845bd97-65d2d
    kubectl get service | grep -i mongo-express-service 
```

### Remove app

```
    kubectl delete --all  deployments,services,replicasets --namespace=ns-mongodb
    kubectl delete namespace ns-mongodb
```