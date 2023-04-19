# 说明

## 部署

在4.10上登录你的账户，执行

```c
kubectl get all
```

你的命名空间下此时没有任何资源。需要你手动部署服务

```c
// gateway
cd /manifests/gateway-lzm
// 部署gateway服务
kubectl apply -f gateway-deployment.yaml
// ssh服务，方便你可以登录该容器进行开发
kubectl apply -f ssh-service.yaml
// quota
cd /manifests/quota
// 声明权限
kubectl apply -f role-bind.yaml
// 部署quota服务
kubectl apply -f quota-deloyment.yaml
// ssh服务，方便你可以登录该容器进行开发
kubectl apply -f ssh-service.yaml
```

执行 `kubectl get all`，可以看到你的命名空间下的所有服务

```c
NAME                                         READY   STATUS    RESTARTS   AGE
pod/k8s-gateway-server-v0-68db9dd68d-kzcjj   1/1     Running   0          110s
pod/k8s-quota-server-v0-7b5fd846f6-8xjfm     1/1     Running   0          14s

NAME                         TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)     AGE
service/svc-gateway-v0       LoadBalancer   10.96.210.225    192.168.4.10   10003/TCP   110s
service/svc-quota-v0         ClusterIP      10.97.197.177    <none>         8003/TCP    14s
service/svc-ssh-gateway-v0   LoadBalancer   10.105.255.161   192.168.4.10   20000/TCP   116s
service/svc-ssh-quota-v0     LoadBalancer   10.111.163.149   192.168.4.10   20001/TCP   20s

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/k8s-gateway-server-v0   1/1     1            1           110s
deployment.apps/k8s-quota-server-v0     1/1     1            1           14s

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/k8s-gateway-server-v0-68db9dd68d   1         1         1       110s
replicaset.apps/k8s-quota-server-v0-7b5fd846f6     1         1         1       14s
```

## 开发

登录gateway和quota后端

```c
// 登录gateway
ssh root@192.168.4.10 -p 20000
// 登录quota后端
ssh root@192.168.4.10 -p 20001
```

这两个容器里都已经安装了go环境，以及zsh和tmux（可以熟悉一下这两个工具，非常有用，尤其是tmux）。此外，这两个容器挂在了公共存储盘，路径是/data/lzm。建议你在此路径下进行代码开发，这样可以保证两个容器里代码一致性。

git clone时使用ssh链接，不要用https。代码下载后，在vscode上把go拓展安装好，然后`ctrl+shift+p`，输入go，选择go install，把所有的包全选并安装。

执行如下命令，开启服务

```c
cd aiarena-backend
// 安装第三方包
go mod tidy
// 开启gateway
cd aiarena-backend/services/gateway/script
sh start.sh
// 开启user服务
cd aiarena-backend/services/user/script
sh start.sh
// 开启task服务
cd aiarena-backend/services/task/script
sh start.sh
// 开启quota服务
cd aiarena-backend/services/quota/script
sh start.sh
```

你的gateway入口是192.168.4.10:10003，该地址加上/api/v1...等后缀即可使用postman访问。