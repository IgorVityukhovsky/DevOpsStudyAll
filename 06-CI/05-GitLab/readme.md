# Домашнее задание к занятию "09.05 Gitlab"

## Подготовка к выполнению

1. Необходимо [зарегистрироваться](https://about.gitlab.com/free-trial/)
2. Создайте свой новый проект
3. Создайте новый репозиторий в gitlab, наполните его [файлами](./repository)
4. Проект должен быть публичным, остальные настройки по желанию

## Основная часть

### DevOps

В репозитории содержится код проекта на python. Проект - RESTful API сервис. Ваша задача автоматизировать сборку образа с выполнением python-скрипта:
1. Образ собирается на основе [centos:7](https://hub.docker.com/_/centos?tab=tags&page=1&ordering=last_updated)
2. Python версии не ниже 3.7
3. Установлены зависимости: `flask` `flask-jsonpify` `flask-restful`
4. Создана директория `/python_api`
5. Скрипт из репозитория размещён в /python_api
6. Точка вызова: запуск скрипта
7. Если сборка происходит на ветке `master`: Образ должен пушится в docker registry вашего gitlab `python-api:latest`, иначе этот шаг нужно пропустить

### Product Owner

Вашему проекту нужна бизнесовая доработка: необходимо поменять JSON ответа на вызов метода GET `/rest/api/get_info`, необходимо создать Issue в котором указать:
1. Какой метод необходимо исправить
2. Текст с `{ "message": "Already started" }` на `{ "message": "Running"}`
3. Issue поставить label: feature

### Developer

Вам пришел новый Issue на доработку, вам необходимо:
1. Создать отдельную ветку, связанную с этим issue
2. Внести изменения по тексту из задания
3. Подготовить Merge Requst, влить необходимые изменения в `master`, проверить, что сборка прошла успешно


### Tester

Разработчики выполнили новый Issue, необходимо проверить валидность изменений:
1. Поднять докер-контейнер с образом `python-api:latest` и проверить возврат метода на корректность
2. Закрыть Issue с комментарием об успешности прохождения, указав желаемый результат и фактически достигнутый

## Итог

После успешного прохождения всех ролей - отправьте ссылку на ваш проект в гитлаб, как решение домашнего задания

## Необязательная часть

Автомазируйте работу тестировщика, пусть у вас будет отдельный конвейер, который автоматически поднимает контейнер и выполняет проверку, например, при помощи curl. На основе вывода - будет приниматься решение об успешности прохождения тестирования

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---

# Выполнение

### DevOps
Создал dockerfile на основе которого происходит сборка докер образа  
```
FROM centos:7
RUN yum install python3 python3-pip -y
RUN mkdir /python_api
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY python-api.py /python_api/python-api.py
CMD ["python3", "/python_api/python-api.py"]
```
Написал пайплайн согласно условиям задания  
```
stages:          
  - build
  - deploy
image: docker:20.10.5
services:
  - docker:20.10.5-dind

build-job:       
  stage: build
  script:
    - docker build -t igorvit/restful:latest .
    - echo "Build complete."

deploy-job:      
  stage: deploy  
  environment: production
  script:
    - docker build -t registry.gitlab.com/igorvityukhovsky/devops-netology/restful:latest .
    - docker login -u IgorVityukhovsky -p $CI_REGISTRY_PASS registry.gitlab.com
    - docker push registry.gitlab.com/igorvityukhovsky/devops-netology/restful:latest
    - echo "Deploying application..."
    - echo "Application successfully deployed."
  only:
    - main
```

### Product Owner
Создал задачу с необходимым описанием и лейблом  
![Скриншот](https://i.ibb.co/kxyyKwK/Screenshot-from-2023-01-09-16-50-01.png)
### Developer
Подкорректировал пайтоновский скрипт в отдельной ветке  
Сделал Merge в main, проверил что сборка и деплой проходят успешно  
![Скриншот](https://i.ibb.co/LrBRdsZ/Screenshot-from-2023-01-09-16-52-21.png)
### Tester
Протестировал докер контейнер, всё отрабатывает так, как задумано.  
Закрыл задачу  
![Скриншот](https://i.ibb.co/wg3qx3k/Screenshot-from-2023-01-05-15-14-02.png)
