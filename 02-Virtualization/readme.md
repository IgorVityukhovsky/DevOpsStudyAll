# Виртуализация  

+ Полная виртуализация: на железо ставится гипервизор, в котором крутятся виртуальные машины.  
+ Паравиртуализация: на железо ставится ОС и уже на неё ставится гипервизор, в котором крутятся виртуалки.  
+ Виртуализация на уровне ОС: гипервизор встроен в ОС и управляет виртаульными машинами, использующие теже ресурсы, что и хостовая ОС.

# Инфраструктура как код IaaC  

Метод **push** централизованный. Однако, если машины регулярно меняют свои имена, IP, подсети, то сервер до них не достучится и сдесь выручит модель **pull**.


# Docker-file

Докер-файл, качает образ, настраивает окружение, пайтон, ансибл  
https://github.com/IgorVityukhovsky/DevOpsStudyAll/blob/main/02-Virtualization/03-Docker.MD  

Докер-компос, основа эластиксёрч, преднастраивает, данные хранит по определённому пути, задаёт имя ноды  
https://github.com/IgorVityukhovsky/DevOpsStudyAll/blob/main/03-DataBase/05-Elasticsearch.md  


Образ собирается на основе centos:7  
Python версии не ниже 3.7  
Установлены зависимости: flask flask-jsonpify flask-restful  
Создана директория /python_api  
Скрипт из репозитория размещён в /python_api  
Точка вызова: запуск скрипта  
Если сборка происходит на ветке master: Образ должен пушится в docker registry вашего gitlab python-api:latest, иначе этот шаг нужно пропустить  

https://github.com/IgorVityukhovsky/DevOpsStudyAll/tree/main/06-CI/05-GitLab#readme  

# Dockerfile для приложения на Node.js:  

Используется базовый образ Node.js  
Копируется файл package.json и запускается команда npm install для установки зависимостей  
Копируются файлы приложения  
Запускается команда npm start для запуска приложения  
```
FROM node:latest

WORKDIR /app

COPY package.json package-lock.json /app/

RUN npm install

COPY . /app/

CMD ["npm", "start"]

```
# Dockerfile для веб-приложения на Python с использованием фреймворка Flask:  

Используется базовый образ Python  
Копируются файлы приложения  
Устанавливается фреймворк Flask  
Открывается порт 5000, на котором будет работать приложение  
Запускается команда python app.py для запуска приложения  
```
FROM python:latest

WORKDIR /app

COPY . /app

RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["python", "app.py"]
```
# Dockerfile для базы данных MySQL:  

Используется базовый образ MySQL  
Копируется файл конфигурации базы данных  
Создается новый пользователь и база данных  
Открываются порты 3306 и 33060 для доступа к базе данных  
```
FROM mysql:latest

COPY my.cnf /etc/mysql/conf.d/my.cnf

ENV MYSQL_DATABASE=my_db \
    MYSQL_USER=my_user \
    MYSQL_PASSWORD=my_password \
    MYSQL_ROOT_PASSWORD=root_password

EXPOSE 3306 33060

CMD ["mysqld"]
```

# Dockerfile для сервера Nginx:  

Используется базовый образ Nginx  
Копируется файл конфигурации Nginx  
Копируются файлы сайта  
Открывается порт 80, на котором будет работать сервер  
```
FROM nginx:latest

COPY nginx.conf /etc/nginx/nginx.conf
COPY /path/to/your/site /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```
Используем директиву CMD, чтобы запустить Nginx-сервер командой nginx с флагом -g "daemon off;", чтобы сервер не запускался в фоновом режиме и не завершал работу контейнера.

# Dockerfile для микросервиса на Java с использованием Spring Boot:  

Используется базовый образ Java  
Копируются файлы приложения  
Устанавливается фреймворк Spring Boot  
Запускается приложение командой java -jar app.jar  

```
FROM openjdk:latest

COPY app.jar /app.jar

EXPOSE 8080

CMD ["java", "-jar", "/app.jar"]
```

# Dockerfile для развертывания полноценного web-приложения на базе Node.js, MongoDB, Nginx и React, который имеет следующий функционал:  

Используется базовый образ Node.js  
Устанавливается MongoDB  
Создаются пользователи и базы данных MongoDB  
Устанавливается и настраивается Nginx для использования в качестве прокси-сервера  
Устанавливается и настраивается React для фронтенда  
Запускается сервер Node.js, взаимодействующий с MongoDB  
```
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
# Cоздать Docker-контейнер, в котором будет запущено полноценное веб-приложение на Python с использованием фреймворка Django, базы данных PostgreSQL и прокси-сервера Nginx для обслуживания HTTP-запросов.  
```
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


