# 说明

## 部署

在4.10上登录你的账户，执行

```c
kubectl get all
```

你的命名空间下此时没有任何资源。把这个库下载到4.10上（使用ssh链接，https没速度），需要你手动部署服务。

```c
// gateway
cd manifests/gateway-lzm
// 部署gateway服务
kubectl apply -f gateway-deployment.yaml
// ssh服务，方便你可以登录该容器进行开发
kubectl apply -f ssh-service.yaml
// quota
cd manifests/quota
// 赋予quota模块管理员权限
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

如果想进入pod，使用exec

```c
kubectl exec -it k8s-gateway-server-v0-68db9dd68d-kzcjj -- /bin/zsh
kubectl exec -it k8s-quota-server-v0-7b5fd846f6-8xjfm -- /bin/zsh
```

如果将查看pod/service/deployment/replicaset详情，使用describe

```c
kubectl describe pod/k8s-quota-server-v0-7b5fd846f6-8xjfm
kubectl describe service/svc-gateway-v0 
kubectl describe deployment.apps/k8s-gateway-server-v0
```

如果想删除pod/service/deployment/replicaset，使用delete

```c
kubectl delete pod/k8s-quota-server-v0-7b5fd846f6-8xjfm
kubectl delete service/svc-gateway-v0 
kubectl delete deployment.apps/k8s-gateway-server-v0
```

## 开发

这两个容器里都已经安装了go环境，以及zsh和tmux（可以熟悉一下这两个工具，非常有用，尤其是tmux）

ssh登录进容器和`kube exec`进容器的区别是，前者缺少很多环境变量。你首先要`kube exec`进入容器把环境变量保存到`~/.env`文件，并且打开一个tmux窗口（tmux可以保留环境变量）

```c
// gateway不要环境变量，只需进入quota模块
kubectl exec -it k8s-quota-server-v0-7b5fd846f6-8xjfm -- /bin/zsh
printenv > ~/.env
// tmux可以保留环境变量，ctrl+b+d可以脱离该窗口
tmux new -s dev_by10
```

ssh登录gateway和quota后端

```c
// 登录gateway
ssh root@192.168.4.10 -p 20000
// 登录quota后端
ssh root@192.168.4.10 -p 20001
// 进入tmux窗口，里面应该是有k8s环境变量的
tmux attach -t dev_by10
printenv
```

这两个容器挂在了公共存储盘，路径是/data/lzm。建议你在此路径下进行代码开发，这样可以保证两个容器里代码一致性。容器的.ssh里面配置了你的公钥和私钥。git clone时使用ssh链接，不要用https。

```c
cd /data/lzm
git clone git@github.com:USTC-MCCLab/aiarena-backend.git
```

代码下载后，在vscode上把remote-ssh拓展安装好，配置一下。然后把go拓展安装好，然后`ctrl+shift+p`，输入go，选择go install，把显示的几个的包全选并安装。

修改`aiarena-backend/.vscode/launch.json`，方便使用vscode debug。之后你应该加上quota相关内容。

```c
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch Package",
            "type": "go",
            "request": "launch",
            "mode": "auto",
            "program": "${fileDirname}",
            "envFile": "/root/.env",
            "env": {
                "GATEWAY_PORT":"8000", 
                "USER_SERVICE":"svc-user-v0.shuwd:8001", 
                "USER_PORT":"8001", 
                "TASK_SERVICE":"svc-task-v0.hanjl:8002", 
                "TASK_PORT": "8002",
            }
        }
    ]
}
```

修改一下`aiarena-backend/services/gateway/script`脚本，之后要加上你自己的quota

```c
export GATEWAY_PORT=8000
export USER_SERVICE=svc-user-v0.shuwd:8001
export TASK_SERVICE=svc-task-v0.hanjl:8002
cd ..
go run .
```

执行如下命令，开启服务

```c
cd aiarena-backend
// 安装第三方包
go mod tidy
// 开启gateway
cd aiarena-backend/services/gateway/script
sh start.sh
// 如果想开启user服务
cd aiarena-backend/services/user/script
sh start.sh
// 如果想开启task服务
cd aiarena-backend/services/task/script
sh start.sh
```

你的gateway入口是192.168.4.10:10003，该地址加上/api/v1...等后缀即可使用postman访问。

## 提交pr

理想情况下，你应该只改动`aiarena-backend/services/quota/`路径下的代码。其他文件夹下的代码可能也需要改动，为了让程序跑起来。go.mod和go.sum的改动不要commit，所有脚本文件的改动不要commit，暂时先只对`aiarena-backend/services/quota/`路径下的代码commit。
