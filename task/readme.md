# Task Service Deployment

## clusterrolebinding

在自己的命名空间下创建pytorchjob是需要权限的。我们先看一下安装了kubeflow/training-operator后发什么绑定

```c
kubectl get serviceaccount -n kubeflow
kubectl get clusterrolebinding.rbac.authorization.k8s.io | grep train
```

```c
kubectl describe clusterrolebinding.rbac.authorization.k8s.io training-operator
```

得到如下。解释一下：这个绑定的名称是training-operator，把kubeflow/training-operator的ServiceAccount绑定到ClusterRole/training-operator。ClusterRole/training-operator这个角色具有创建pytorchjob权限

```c
Name:         training-operator
Labels:       app=training-operator
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  training-operator
Subjects:
  Kind            Name               Namespace
  ----            ----               ---------
  ServiceAccount  training-operator  kubeflow
```

类似的，我们可以在自己的命名空间hanjl下新建名为training-operator的serviceaccount，然后把hanjl/training-operator的ServiceAccount绑定到ClusterRole/training-operator即可。这便是下面这条指令做的事情。要注意自己的clusterrolebinding的名字不要和training-operator重复，因为clusterrolebinding.rbac.authorization.k8s.io不区分命名空间。

```c
kubectl apply -f role-bind.yaml
```

we get

```c
serviceaccount/training-operator created
clusterrolebinding.rbac.authorization.k8s.io/k8s-crb-hanjl created
```

check

```c
kubectl describe clusterrolebinding.rbac.authorization.k8s.io k8s-crb-hanjl
```

we get below. 解释一下：这个绑定的名称是k8s-crb-hanjl，把hanjl/training-operator的ServiceAccount绑定到ClusterRole/training-operator。因此，在hanjl命名空间下的pod，如果其serviceAccountName是training-operator，那么该pod具有创建pytorchjob的权限。

```c
Name:         k8s-crb-hanjl
Labels:       app=k8s-crb-hanjl
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  training-operator
Subjects:
  Kind            Name               Namespace
  ----            ----               ---------
  ServiceAccount  training-operator  hanjl
```

some cmds to check.

```c
kubectl get serviceaccount
kubectl get clusterrolebinding.rbac.authorization.k8s.io
kubectl get secret
```