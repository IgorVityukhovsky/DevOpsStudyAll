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


# Docker-swarm

**replication** означает, что у сервиса будет работать определённое количество копий (реплик), тогда как в режиме **global** сервисы будут работать на всех нодах  

Какой алгоритм выбора лидера используется в Docker Swarm кластере

# Terraform

Развернули на яндексе машины с прометеусом и графаной используя терраформ


