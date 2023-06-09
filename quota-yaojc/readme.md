# 说明

## 部署

在4.10上登录你的账户，执行

```c
kubectl get all
```

你的命名空间下此时没有任何资源。把这个库下载到4.10上（使用ssh链接，https没速度）。然后按照下面手动部署服务。

```c
// gateway
cd manifests/gateway-yaojc
// 部署gateway服务
kubectl apply -f gateway-deployment.yaml
// ssh服务，方便你可以登录该容器进行开发
kubectl apply -f ssh-service.yaml
// quota
cd manifests/quota-yaojc
// 赋予quota模块管理员权限
kubectl apply -f role-bind.yaml
// 部署quota服务
kubectl apply -f quota-deloyment.yaml
// ssh服务，方便你可以登录该容器进行开发
kubectl apply -f ssh-service.yaml
```

执行 `kubectl get all`，可以看到你的命名空间下的所有服务，类似像下面这样

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
kubectl exec -it k8s-gateway-server-v0-68db9dd68d-kzcjj -n yaojc -- /bin/zsh
kubectl exec -it k8s-quota-server-v0-7b5fd846f6-8xjfm -n yaojc -- /bin/zsh
```

如果要查看pod/service/deployment/replicaset详情，使用describe

```c
kubectl describe pod/k8s-quota-server-v0-7b5fd846f6-8xjfm -n yaojc
kubectl describe service/svc-gateway-v0 -n yaojc
kubectl describe deployment.apps/k8s-gateway-server-v0 -n yaojc
```

如果想删除pod/service/deployment/replicaset，使用delete

```c
kubectl delete pod/k8s-quota-server-v0-7b5fd846f6-8xjfm -n yaojc
kubectl delete service/svc-gateway-v0 -n yaojc
kubectl delete deployment.apps/k8s-gateway-server-v0 -n yaojc
```

## 开发

这两个容器（gateway，quota）里都已经安装了go环境，以及zsh和tmux（可以熟悉一下这两个工具，非常有用，尤其是tmux）

这两个容器挂载了公共存储盘，路径是/data/yaojc。建议你在此路径下进行代码开发，这样可以保证两个容器里代码一致性。容器的.ssh/文件夹里面配置了你的公钥和私钥。git clone时使用ssh链接，不要用https。

### ssh配置及环境配置

在vscode上把remote-ssh拓展安装好，配置如下。

```c
Host gateway_by10
  HostName 192.168.4.10
  User root
  Port 9900

Host quota_by10
  HostName 192.168.4.10
  User root
  Port 9901
```

ssh登录进容器和`kube exec`进容器的区别是，前者缺少很多环境变量。你首先要`kube exec`进入容器把环境变量保存到`~/.env`文件，并且打开一个tmux窗口（因为tmux可以保留环境变量）。

```c
// gateway模块
kubectl exec -it k8s-gateway-server-v0-7b5fd846f6-8xjfm -n yaojc -- /bin/zsh
// 进入容器后
printenv > ~/.env
// 新建一个tmux窗口，tmux可以保留环境变量，ctrl+b+d可以脱离该窗口
tmux new -s gateway_by10

// quota 重复以上步骤
kubectl exec -it k8s-quota-server-v0-7b5fd846f6-8xjfm -n yaojc -- /bin/zsh
// 进入容器后
printenv > ~/.env
// 新建一个tmux窗口，tmux可以保留环境变量，ctrl+b+d可以脱离该窗口
tmux new -s quota_by10
```

<!-- 然后，通过ssh登录gateway和quota后端。在你自己的主机上（开启pptp）

```c
// 登录quota后端
ssh root@192.168.4.10 -p 9901
// 进入之前创建的tmux窗口，里面有k8s环境变量
tmux attach -t dev_by10
printenv
``` -->

### 代码配置

打开gateway/quota任一模块里面下载代码，因为两个容器挂载的是同一块存储。代码路径一定要放在/data/yaojc下。打开vscode窗口，连接gateway。

```c
cd /data/yaojc
git clone git@github.com:USTC-MCCLab/aiarena-backend.git
```

修改`aiarena-backend/.vscode/launch.json`，主要是加上envFile和env，方便使用vscode debug。

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
                "SECRET_KEY": "mykey",
                "QUOTA_SERVICE":"svc-quota-v0.yaojc:8003"
            }
        }
    ]
}
```

修改一下`aiarena-backend/services/gateway/script/start.sh`脚本，

```c
export GATEWAY_PORT=8000
export USER_SERVICE=svc-user-v0.shuwd:8001
export TASK_SERVICE=svc-task-v0.hanjl:8002
export QUOTA_SERVICE=svc-quota-v0.yaojc:8003
cd ..
go run .
```

### 运行服务

打开两个vscode窗口，分别连接到gateway和quota。把vscode窗口上的go拓展安装好，然后`ctrl+shift+p`，输入go，选择go install，把显示的几个的包全选并安装，这些都是debug所需的工具。

在连接quota的vscode窗口里，执行如下命令，开启服务

```c
// 进入tmux窗口
tmux a -t quota_by10
cd aiarena-backend
// 安装第三方包
go mod tidy
// 开启quota
cd aiarena-backend/services/quota/script
sh start.sh
```

在连接gateway的vscode窗口里，执行如下命令，开启服务

```c
// 进入tmux窗口
tmux a -t gateway_by10
cd aiarena-backend
// 安装第三方包
go mod tidy
// 开启quota
cd aiarena-backend/services/gateway/script
sh start.sh
```

你的gateway入口是192.168.4.10:9500，quota模块的相关API在 [https://docs.qq.com/doc/DYXZ1T0hxSGRkSFBt](https://docs.qq.com/doc/DYXZ1T0hxSGRkSFBt)。然后就可以使用postman访问了。比如获取quota就是 GET 192.168.4.10:9500/api/v1/quota/get
