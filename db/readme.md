# Deploy MySQL

Read [https://www.cnblogs.com/worldinmyeyes/p/14514971.html](https://www.cnblogs.com/worldinmyeyes/p/14514971.html)

## Preparation

Build mysql image.

```c
docker build -t hanjl/mysql:v0 -f mysql.dockerfile .
```

Run the image as a container.

```c
docker run -it --rm hanjl/mysql:v0 /bin/bash
```

Change the password for root.

```c
// start mysql
service mysql start
mysql -u root
use mysql;
update user set authentication_string='' where user='root';
alter user 'root'@'localhost' identified with mysql_native_password by '123456';
exit
// restart mysql
service mysql restart
mysql -u root -p
```

MySQL only listen on localhost, so we would like to listen on `0.0.0.0`(We acually have already did it in the dockerfile).

```c
sed -i 's@127.0.0.1@0.0.0.0@g' /etc/mysql/mysql.conf.d/mysqld.cnf
```

In MySQL default setting, all users are not allowed login remotely. Read [https://stackoverflow.com/questions/1559955/host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server](https://stackoverflow.com/questions/1559955/host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server). The most important thing is to set the `user`'s `host` to `%`.

```c
mysql -u root -p
use mysql;
select host, user from user;
update user set host='%' where user='root';
select host, user from user;
exit
// restart mysql
service mysql restart
```

Copy the `/var/lib/mysql` to local storage.

```c
sudo docker cp bd921fd5e824:/var/lib/mysql /data_local/
```

## Deployment

Read [https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/assign-pods-nodes/](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/assign-pods-nodes/) about `nodeSelector`. We need to assign mysql to a specific node where we copied `/var/lib/mysql`. We can use nodeName directly or specify a label such as `nodeid:by10` for the node.

```c
kubectl apply -f mysql-deployment.yaml
```

Check whether the mysql service is available.

```c
kubectl get all
```

and we get

```c
NAME                           READY   STATUS    RESTARTS   AGE
pod/mysql-v0-f4b6cd8ff-dm5b4   1/1     Running   0          4h43m

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
service/svc-mysql-v0   ClusterIP   10.107.91.34   <none>        40003/TCP   4h43m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mysql-v0   1/1     1            1           4h43m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/mysql-v0-f4b6cd8ff   1         1         1       4h43m
```

We now can access the mysql by 10.107.91.34:40003.

```c
mysql -h 10.107.91.34 -P 40003 -u root -p
```
