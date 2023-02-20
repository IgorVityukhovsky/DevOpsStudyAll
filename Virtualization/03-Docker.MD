
# Домашнее задание к занятию "5.3. Введение. Экосистема. Архитектура. Жизненный цикл Docker контейнера"

---

## Задача 1

Сценарий выполения задачи:

- создайте свой репозиторий на https://hub.docker.com;
- выберете любой образ, который содержит веб-сервер Nginx;
- создайте свой fork образа;
- реализуйте функциональность:
запуск веб-сервера в фоне с индекс-страницей, содержащей HTML-код ниже:
```
<html>
<head>
Hey, Netology
</head>
<body>
<h1>I’m DevOps Engineer!</h1>
</body>
</html>
```
Опубликуйте созданный форк в своем репозитории и предоставьте ответ в виде ссылки на https://hub.docker.com/username_repo.

### **Ответ:**
https://hub.docker.com/repository/docker/igorvit/netology
```
docker run -p 80:80 igorvit/netology:netology
```

## Задача 2

Посмотрите на сценарий ниже и ответьте на вопрос:
"Подходит ли в этом сценарии использование Docker контейнеров или лучше подойдет виртуальная машина, физическая машина? Может быть возможны разные варианты?"

Детально опишите и обоснуйте свой выбор.

--

Сценарий:

- Высоконагруженное монолитное java веб-приложение;

**Ответ:** Физическая машина. Обеспечит лучшую производительность для высоконагруженного приложения по сравнению с виртуальным сервером, контейнеризация для монолитного приложения не требуется.

- Nodejs веб-приложение;

**Ответ:** Использовал бы Docker, с настроеной средой и проброшенным куда необходимо портом. Веб приложение критично к настройкам среды, в то же время требует очень много ресурсов по моему мнению.

- Мобильное приложение c версиями для Android и iOS;

**Ответ:** Docker контейнеры. Удобно иметь образы для разных сред, сэкономит ресурсы и проще обслуживать.

- Шина данных на базе Apache Kafka;

**Ответ:** физические сервера, так как очень высоконагруженная система.

- Elasticsearch кластер для реализации логирования продуктивного веб-приложения - три ноды elasticsearch, два logstash и две ноды kibana;

**Ответ:** все описанные можно гибко масштабировать, так что реализовывать их лучше на виртуальных машинах

- Мониторинг-стек на базе Prometheus и Grafana;

**Ответ:** подойдёт виртуальный сервер, ничего особенно часто там настраивать не нужно, нагрузка там приемлимая. В принципе Docker тоже подойдёт

- MongoDB, как основное хранилище данных для java-приложения;

**Ответ:** использовал бы виртуальную машину с отдельно подключенным к ней железным диском

- Gitlab сервер для реализации CI/CD процессов и приватный (закрытый) Docker Registry.

**Ответ:** для GitLab подойдёт виртуальный сервер в кластере для отказоустойчивости, в том числе это облегчает процесс его резервного копирования. Для Docker Registry использовал бы физический сервер, скорее всего там потребуются гонять большие объёмы данных

## Задача 3

- Запустите первый контейнер из образа ***centos*** c любым тэгом в фоновом режиме, подключив папку ```/data``` из текущей рабочей директории на хостовой машине в ```/data``` контейнера;
- Запустите второй контейнер из образа ***debian*** в фоновом режиме, подключив папку ```/data``` из текущей рабочей директории на хостовой машине в ```/data``` контейнера;
- Подключитесь к первому контейнеру с помощью ```docker exec``` и создайте текстовый файл любого содержания в ```/data```;
- Добавьте еще один файл в папку ```/data``` на хостовой машине;
- Подключитесь во второй контейнер и отобразите листинг и содержание файлов в ```/data``` контейнера.


### Ответ:
```
sudo mkdir /data
sudo chmod 666 /data
docker run --name=centos -t -d -v /data:/data centos
docker run --name=debian -t -d -v /data:/data debian
docker exec -it centos /bin/bash
echo "123" > /data/123.txt
exit
sudo su
echo "456" > /data/456.txt
docker exec -it debian /bin/bash
cd /data
```
```
root@ddae0e0d72ab:/data# ls
123.txt  456.txt
```

## Задача 4 (*)

Воспроизвести практическую часть лекции самостоятельно.

Соберите Docker образ с Ansible, загрузите на Docker Hub и пришлите ссылку вместе с остальными ответами к задачам.
### Ответ:
```
sudo nano dockerfile
```
```
FROM alpine:3.14
RUN CARGO_NET_GIT_FETCH_WITH_CLI=1 && \
 apk --no-cache add \
sudo python3 py3-pip openssl ca-certificates sshpass openssh-client rsync git && \
 apk --no-cache add --virtual build-dependencies python3-dev libffi-dev musl-dev gcc cargo openssl-dev \
 libressl-dev \
 build-base && \
 pip install --upgrade pip wheel && \
 pip install --upgrade cryptography cffi && \
 pip install ansible==2.9.24 && \
 pip install mitogen ansible-lint jmespath && \
 pip install --upgrade pywinrm && \
 apk del build-dependencies && \
 rm -rf /var/cache/apk/* && \
 rm -rf /root/.cache/pip && \
 rm -rf /root/.cargo
RUN mkdir /ansible && \
 mkdir -p /etc/ansible && \
 echo 'localhost' > /etc/ansible/hosts
WORKDIR /ansible
CMD [ "ansible-playbook", "--version" ]
```

```
docker build -t igorvit/ansible:2.9.24 .
...
Successfully built 7cf8ae40764d
Successfully tagged igorvit/ansible:2.9.24
```
```
docker login
docker push igorvit/ansible:2.9.24
```

https://hub.docker.com/repository/docker/igorvit/ansible
