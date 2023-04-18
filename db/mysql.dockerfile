FROM ubuntu:18.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN cp /etc/apt/sources.list /etc/apt/sources.list.hide && \
    sed -i "s@http://.*archive.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://mirrors.ustc.edu.cn@g" /etc/apt/sources.list

RUN apt update && \
    apt install -y mysql-server && \
    sed -i 's@127.0.0.1@0.0.0.0@g' /etc/mysql/mysql.conf.d/mysqld.cnf && \
    rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*
