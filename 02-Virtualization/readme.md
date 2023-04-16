# Виртуализация  

+ Полная виртуализация: на железо ставится гипервизор, в котором крутятся виртуальные машины.  
+ Паравиртуализация: на железо ставится ОС и уже на неё ставится гипервизор, в котором крутятся виртуалки.  
+ Виртуализация на уровне ОС: гипервизор встроен в ОС и управляет виртаульными машинами, использующие теже ресурсы, что и хостовая ОС.

# Инфраструктура как код IaaC  

Метод **push** централизованный. Однако, если машины регулярно меняют свои имена, IP, подсети, то сервер до них не достучится и сдесь выручит модель **pull**.


# Docker-file

## Dockerfile для работы ансибла
- Берёт образ alpine
- Настраивает окружение
- Устанавливает пайтон
- Устанавливает ансибл  
- Устанавливает ансибл линт
- Обновляет все пакеты
- Удаляет лишние временные директории кешей
- Создаёт хост файл для ансибла прописывая туда локалхост
```Dockerfile
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
https://github.com/IgorVityukhovsky/DevOpsStudyAll/blob/main/02-Virtualization/03-Docker.MD  

## Докер для эластиксёрч. Сделано в docker-compose и в docekrfile
- основа эластиксёрч
- устанавливает лимиты на количество открытых файловых дескрипторов
- преднастраивает переменные среды
- данные хранит по определённому пути
- задаёт имя ноды  
- функционально добавляется конфиг эластиксёрч и подмапливается волюмом
```yml
version: '3.8'
services:
  elasticsearch:
    image: elasticsearch:7.17.6   #Не было тага 7, использовал 7.17.6
    container_name: es
    tty: true
    stdin_open: true
    ulimits:
     nofile:
      soft: 262144
      hard: 262144

    entrypoint: /bin/bash -c "chmod 777 /var/lib && /bin/tini "/usr/local/bin/docker-entrypoint.sh eswrapper""

    #Команда, которая выполнится при запуске контейнера, задаёт необходимые права на нужную нам директорию
    #Если оставить только команду на назначение прав, контейнер будет считать её основной и после её завершения завершится и контейнер
    #Что бы этого избежать, добавил в команду запуск процесса elasticsearch так как именно он нам и нужен как основной
    #Команда взята из столбца COMMAND при запуске дефолтного контейнера
    #Так же накидывает нужные права на папку из задачи 3
    

    environment:
      - discovery.type=single-node                     #Необходимо для работы одной ноды
      - node.name=netology_test                        #Задаём имя ноды
      - path.data=/var/lib                             #Задаём путь для хранения данных
      - path.repo=/usr/share/elasticsearch/snapshots   #Задаём путь для репозитория снапшотов для задачи 3
      #- xpack.security.enabled=true
      - "ES_JAVA_OPTS=-Xms3g -Xmx3g"
      - "ES_HEAP_SIZE=4g"

networks:
  elasticsearch:
    driver: 'local'
```
```dockerfile
FROM elasticsearch:7.17.6

RUN ulimit -n 262144

ENV discovery.type=single-node
ENV node.name=netology_test
ENV path.data=/var/lib
ENV path.repo=/usr/share/elasticsearch/snapshots
ENV ES_JAVA_OPTS=-Xms3g -Xmx3g
ENV ES_HEAP_SIZE=4g

ENTRYPOINT ["/bin/bash", "-c", "chmod 777 /var/lib && /bin/tini \"/usr/local/bin/docker-entrypoint.sh eswrapper\""]

EXPOSE 9200 9300

CMD ["elasticsearch"]
```
https://github.com/IgorVityukhovsky/DevOpsStudyAll/blob/main/03-DataBase/05-Elasticsearch.md  


## Dockerfile для контейнера с пайтон скриптом  

- Берётся образ centos:7  
- Устанавливается Python 3.7  
- Устанавливаются зависимости: flask flask-jsonpify flask-restful  
- Создаётся директория /python_api  
- Скрипт из репозитория размещён в /python_api  
- Точка вызова: запуск скрипта  
Дополнительно для CI/CD: Если сборка происходит на ветке master: Образ должен пушится в docker registry вашего gitlab python-api:latest, иначе этот шаг нужно пропустить  

```Dockerfile
FROM centos:7
RUN yum install python3 python3-pip -y
RUN mkdir /python_api
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY python-api.py /python_api/python-api.py
CMD ["python3", "/python_api/python-api.py"]
```
https://github.com/IgorVityukhovsky/DevOpsStudyAll/tree/main/06-CI/05-GitLab#readme  

## Docker-compose и Dockerfile поднимите инстанс PostgreSQL (версию 12) c 2 volume, в который будут складываться данные БД и бэкапы.  
- Берётся образ postgres:12
- Создаются волюмы
- Копируется скрипт создания базы данных
- Открываются порты


```yml
version: '3.8'
services:
  mydb:
    image: postgres:12
    volumes:
      - db-data:/var/lib/postgresql/data
      - db-backup:/var/lib/postgresql/backup
      - /home/igor/HomeWorkSQL/Script:/docker-entrypoint-initdb.d #Из директории с таким названием скрипты будут выполняться автоматически 1 раз при старте контейнера. Но в нашем случае этого не произойдёт, так как скрипт написан для постгресса и запускать надо через него. Скрипт создаёт базы.
    ports:
      - "5432:5432"
    environment:
      PGDATA: /var/lib/postgresql/data/
      POSTGRES_PASSWORD: example


volumes:
  db-data:
  db-backup:
networks:
  postgresnetwork000:
    driver: 'local'
```
```dockerfile
FROM postgres:12

# Установка переменных среды
ENV PGDATA /var/lib/postgresql/data/
ENV POSTGRES_PASSWORD example

# Копирование скриптов в контейнер
COPY /home/igor/HomeWorkSQL/Script /docker-entrypoint-initdb.d

# Создание точки монтирования
VOLUME ["/var/lib/postgresql/data", "/var/lib/postgresql/backup"]

# Открытие порта 5432
EXPOSE 5432

# Запуск PostgreSQL при старте контейнера
CMD ["postgres"]
```
https://github.com/IgorVityukhovsky/DevOpsStudyAll/blob/main/03-DataBase/02-SQL.md


## Dockerfile для приложения на Node.js:  

- Используется базовый образ Node.js  
- Копируется файл package.json
- Запускается команда npm install для установки зависимостей  
- Копируются файлы приложения  
- Запускается команда npm start для запуска приложения  

```Dockerfile
FROM node:latest
WORKDIR /app
COPY package.json package-lock.json /app/
RUN npm install
COPY . /app/
CMD ["npm", "start"]

```
## Dockerfile для веб-приложения на Python с использованием фреймворка Flask:  

- Используется базовый образ Python  
- Копируются файлы приложения  
- Устанавливается фреймворк Flask  
- Открывается порт 5000, на котором будет работать приложение  
- Запускается команда python app.py для запуска приложения  

```Dockerfile
FROM python:latest
WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]
```
## Dockerfile для базы данных MySQL:  

- Используется базовый образ MySQL  
- Копируется файл конфигурации базы данных  
- Создается новый пользователь и база данных  
- Открываются порты 3306 и 33060 для доступа к базе данных  
```Dockerfile
FROM mysql:latest

COPY my.cnf /etc/mysql/conf.d/my.cnf

ENV MYSQL_DATABASE=my_db \
    MYSQL_USER=my_user \
    MYSQL_PASSWORD=my_password \
    MYSQL_ROOT_PASSWORD=root_password

EXPOSE 3306 33060

CMD ["mysqld"]
```

## Dockerfile для сервера Nginx:  

- Используется базовый образ Nginx  
- Копируется файл конфигурации Nginx  
- Копируются файлы сайта  
- Открывается порт 80, на котором будет работать сервер  
```Dockerfile
FROM nginx:latest

COPY nginx.conf /etc/nginx/nginx.conf
COPY /path/to/your/site /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```
Используем директиву CMD, чтобы запустить Nginx-сервер командой nginx с флагом -g "daemon off;", чтобы сервер не запускался в фоновом режиме и не завершал работу контейнера.


## Dockerfile для развертывания полноценного web-приложения на базе Node.js, MongoDB, Nginx и React, который имеет следующий функционал:  

- Используется базовый образ Node.js  
- Устанавливается MongoDB  
- Создаются пользователи и базы данных MongoDB  
- Устанавливается и настраивается Nginx для использования в качестве прокси-сервера  
- Устанавливается и настраивается React для фронтенда  
- Запускается сервер Node.js, взаимодействующий с MongoDB  
```Dockerfile
# Установка Node.js
FROM node:latest

# Установка MongoDB
RUN apt-get update && apt-get install -y mongodb

# Создание пользователей MongoDB и баз данных
RUN mkdir -p /data/db \
    && chown -R mongodb:mongodb /data/db \
    && echo "db.createUser({ user: 'admin', pwd: 'admin', roles: [ { role: 'userAdminAnyDatabase', db: 'admin' } ] });" | mongo admin \
    && echo "db.createUser({ user: 'app', pwd: 'app', roles: [ { role: 'readWrite', db: 'app' } ] });" | mongo admin

# Установка и настройка Nginx
RUN apt-get install -y nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY sites-enabled/app /etc/nginx/sites-enabled/app

# Установка и настройка React
COPY app /app
WORKDIR /app
RUN npm install
RUN npm run build

# Запуск Node.js сервера
COPY server.js /server.js
EXPOSE 3000
CMD ["node", "/server.js"]
```
## Dockerfile в котором:  
- будет запущено полноценное веб-приложение на Python с использованием фреймворка Django
- базы данных PostgreSQL
- прокси-сервера Nginx для обслуживания HTTP-запросов.  
```Dockerfile
# базовый образ Python
FROM python:3.8-slim-buster

# установка необходимых пакетов для PostgreSQL и Nginx
RUN apt-get update && apt-get install -y postgresql postgresql-contrib nginx

# установка зависимостей Python
COPY requirements.txt /
RUN pip install --no-cache-dir -r /requirements.txt

# настройка PostgreSQL
RUN service postgresql start && \
    su postgres -c "psql -c \"CREATE USER myuser WITH PASSWORD 'mypassword';\"" && \
    su postgres -c "createdb mydb"

# копирование конфигурации Nginx и запуск
COPY nginx.conf /etc/nginx/nginx.conf
COPY site.conf /etc/nginx/conf.d/default.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# копирование файлов приложения Django
COPY app /app

# запуск миграций базы данных
RUN python /app/manage.py migrate

# открытие портов для доступа к веб-приложению и прокси-серверу
EXPOSE 80
EXPOSE 8000

# запуск сервисов PostgreSQL, Nginx и веб-приложения
CMD service postgresql start && \
    nginx && \
    python /app/manage.py runserver 0.0.0.0:8000
```
# Docker-swarm

**replication** означает, что у сервиса будет работать определённое количество копий (реплик), тогда как в режиме **global** сервисы будут работать на всех нодах  

Какой алгоритм выбора лидера используется в Docker Swarm кластере

# Terraform

Развернули на яндексе машины с прометеусом и графаной используя терраформ


