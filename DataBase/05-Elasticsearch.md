# Домашнее задание к занятию "6.5. Elasticsearch"

## Задача 1

Используя докер образ [elasticsearch:7](https://hub.docker.com/_/elasticsearch) как базовый:

- составьте Dockerfile-манифест для elasticsearch
- соберите docker-образ и сделайте `push` в ваш docker.io репозиторий
- запустите контейнер из получившегося образа и выполните запрос пути `/` c хост-машины

Требования к `elasticsearch.yml`:
- данные `path` должны сохраняться в `/var/lib` 
- имя ноды должно быть `netology_test`

В ответе приведите:
- текст Dockerfile манифеста
- ссылку на образ в репозитории dockerhub
- ответ `elasticsearch` на запрос пути `/` в json виде

Подсказки:
- при сетевых проблемах внимательно изучите кластерные и сетевые настройки в elasticsearch.yml
- при некоторых проблемах вам поможет docker директива ulimit
- elasticsearch в логах обычно описывает проблему и пути ее решения
- обратите внимание на настройки безопасности такие как `xpack.security.enabled` 
- если докер образ не запускается и падает с ошибкой 137 в этом случае может помочь настройка `-e ES_HEAP_SIZE`
- при настройке `path` возможно потребуется настройка прав доступа на директорию

Далее мы будем работать с данным экземпляром elasticsearch.

## Ответ

Подготовим машину для работы, увеличив количество выделяемой виртуальной памяти
```
sudo sysctl -w vm.max_map_count = 262144
```
Для решения задачи использовал docker compose
```
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
Собираем проект, запускаем контейнер, проверяем, что он запустился, подключаемся к нему и выполняем нужный нам запрос /
```
docker compose build
docker compose up -d
docker compose ps
docker exec -it es bash
curl -XGET 'http://localhost:9200/'
```
```
{
  "name" : "netology_test",                  #Имя которое мы задали
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "00kuogNgSki7om2uwB8Q3w",
  "version" : {
    "number" : "7.17.6",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "f65e9d338dc1d07b642e14a27f338990148ee5b6",
    "build_date" : "2022-08-23T11:08:48.893373482Z",
    "build_snapshot" : false,
    "lucene_version" : "8.11.1",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```
Можем проверить, что остальные наши настройки так же применились
```
curl -XGET 'http://localhost:9200/_nodes'
```
![скриншот](https://i.ibb.co/zNXz9Vf/Screenshot-from-2022-10-04-14-21-08.png) 
![скриншот](https://i.ibb.co/xfs8tRZ/Screenshot-from-2022-10-04-19-56-29.png)

В текущей реализации обошлось без правки elasticsearch.yml.

Но если бы она была нам нужна, в elasticsearch.yml помимо дефолтных значений, которые находятся в образе мы бы добавили ещё свои и получилось бы:
```
cluster.name: "docker-cluster"
network.host: 0.0.0.0
discovery.type: single-node
node.name: netology_test
path.data: /var/lib
path.repo: /usr/share/elasticsearch/snapshots
```

Можно было бы создать этот конфиг локально и подмапить волюм, описав это в docker compose
```
volumes:
      - /elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
```
Либо добавив команды в docker compose \ dockerfile на добавление нужных строк в файл при создании контейнера

Собираем образ из контейнера и пушим на докерхаб
```
docker ps
docker commit 61e6113b275b igor_es
docker login
docker tag igor_es igorvit/igor_es
docker push igorvit/igor_es
```
Остановить все контейнеры
```
docker stop $(docker ps -a -q)
```
Удалить все контейнеры
```
docker rm $(docker ps -a -q)
```
Удалить все образы
```
docker rmi $(docker images -q)
```
В случае ошибок, содержащих "must be forced" добавляем ключ -f
```
docker rmi -f $(docker images -q)
```
Запускаем докер с нашим имеджем, он скачается с докерхаб, так как локально его не будет
```
docker run --name es -d igorvit/igor_es
```
Всё работает
```
docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS                NAMES
38684a0ed7bc   igorvit/igor_es   "/bin/bash -c 'chmod…"   9 seconds ago   Up 9 seconds   9200/tcp, 9300/tcp   es
```
```
curl -XGET 'http://localhost:9200/'

{
  "name" : "netology_test",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "nyOXFCAeSIiX1POtIZSgqg",
  "version" : {
    "number" : "7.17.6",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "f65e9d338dc1d07b642e14a27f338990148ee5b6",
    "build_date" : "2022-08-23T11:08:48.893373482Z",
    "build_snapshot" : false,
    "lucene_version" : "8.11.1",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```
Ссылка на докерхаб
```
https://hub.docker.com/repository/docker/igorvit/igor_es
```

## Задача 2

В этом задании вы научитесь:
- создавать и удалять индексы
- изучать состояние кластера
- обосновывать причину деградации доступности данных

Ознакомтесь с [документацией](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html) 
и добавьте в `elasticsearch` 3 индекса, в соответствии со таблицей:

| Имя | Количество реплик | Количество шард |
|-----|-------------------|-----------------|
| ind-1| 0 | 1 |
| ind-2 | 1 | 2 |
| ind-3 | 2 | 4 |

Получите список индексов и их статусов, используя API и **приведите в ответе** на задание.

Получите состояние кластера `elasticsearch`, используя API.

Как вы думаете, почему часть индексов и кластер находится в состоянии yellow?

Удалите все индексы.

**Важно**

При проектировании кластера elasticsearch нужно корректно рассчитывать количество реплик и шард,
иначе возможна потеря данных индексов, вплоть до полной, при деградации системы.

## Ответ


Список индексов и их статусы:
```
[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X PUT https://localhost:9200/ind-1?pretty -H 'Content-Type: application/json' -d'{ "settings": { "index": { "number_of_shards": 1, "number_of_replicas": 0 }}}'
[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X PUT https://localhost:9200/ind-2?pretty -H 'Content-Type: application/json' -d'{ "settings": { "index": { "number_of_shards": 2, "number_of_replicas": 1 }}}'
[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X PUT https://localhost:9200/ind-3?pretty -H 'Content-Type: application/json' -d'{ "settings": { "index": { "number_of_shards": 4, "number_of_replicas": 2 }}}'

[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic https://localhost:9200/_cat/indices?v
Enter host password for user 'elastic':
health status index uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   ind-1 wKioCclpQgKO3UL_yzwZgg   1   0          0            0       225b           225b
yellow open   ind-3 0kOnROPHQd-hOX9IduPksw   4   2          0            0       900b           900b
yellow open   ind-2 oVkx8NaLTIGxrmRY_xO7fQ   2   1          0            0       450b           450b
```
Состояние кластера:
```
[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic https://localhost:9200/_cluster/health?pretty
Enter host password for user 'elastic':
{
  "cluster_name" : "netology",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 9,
  "active_shards" : 9,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 10,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 47.368421052631575
}
```
Состояние yellow по кластеру связано с тем, что есть unassigned шарды. 

Удаление индексов:
```
[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X DELETE https://localhost:9200/ind-1?pretty
Enter host password for user 'elastic':
{
  "acknowledged" : true
}
[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X DELETE https://localhost:9200/ind-2?pretty
Enter host password for user 'elastic':
{
  "acknowledged" : true
}
[elasticsearch@71ef1a8e572b ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X DELETE https://localhost:9200/ind-3?pretty
Enter host password for user 'elastic':
{
  "acknowledged" : true
}
```


## Задача 3

В данном задании вы научитесь:
- создавать бэкапы данных
- восстанавливать индексы из бэкапов

Создайте директорию `{путь до корневой директории с elasticsearch в образе}/snapshots`.

Используя API [зарегистрируйте](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-register-repository.html#snapshots-register-repository) 
данную директорию как `snapshot repository` c именем `netology_backup`.

**Приведите в ответе** запрос API и результат вызова API для создания репозитория.

Создайте индекс `test` с 0 реплик и 1 шардом и **приведите в ответе** список индексов.

[Создайте `snapshot`](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-take-snapshot.html) 
состояния кластера `elasticsearch`.

**Приведите в ответе** список файлов в директории со `snapshot`ами.

Удалите индекс `test` и создайте индекс `test-2`. **Приведите в ответе** список индексов.

[Восстановите](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-restore-snapshot.html) состояние
кластера `elasticsearch` из `snapshot`, созданного ранее. 

**Приведите в ответе** запрос к API восстановления и итоговый список индексов.

Подсказки:
- возможно вам понадобится доработать `elasticsearch.yml` в части директивы `path.repo` и перезапустить `elasticsearch`

---

## Ответ

Директива `path.repo: /usr/share/elasticsearch/snapshots`, была добавлена заранее на этапе создания образа, сам запрос на регистрацию snapshot repo:
```
[elasticsearch@2403641c68f1 ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X PUT https://localhost:9200/_snapshot/netology_backup?pretty -H 'Content-Type: application/json' -d' { "type": "fs", "settings": { "location": "/usr/share/elasticsearch/snapshots"}}'
Enter host password for user 'elastic':
{
  "acknowledged" : true
}
```
Список индексов:
```
[elasticsearch@2403641c68f1 ~]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic https://localhost:9200/_cat/indices?v
Enter host password for user 'elastic':
health status index uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test  7rRcEyc6S6GXZJ5B3_ii0w   1   0          0            0       225b           225b
```
Директория snapshots до snapshot:
```
[elasticsearch@2403641c68f1 snapshots]$ ls -lah /usr/share/elasticsearch/snapshots
total 16K
drwxrwxr-x. 2 elasticsearch elasticsearch 4.0K Mar  9 11:31 .
drwx------. 1 elasticsearch elasticsearch 4.0K Mar  9 11:24 ..
```
Директория snapshots после snapshot
```
[elasticsearch@2403641c68f1 snapshots]$ ls -lah /usr/share/elasticsearch/snapshots
total 52K
drwxrwxr-x. 3 elasticsearch elasticsearch 4.0K Mar  9 11:48 .
drwx------. 1 elasticsearch elasticsearch 4.0K Mar  9 11:24 ..
-rw-r--r--. 1 elasticsearch elasticsearch 1.1K Mar  9 11:48 index-0
-rw-r--r--. 1 elasticsearch elasticsearch    8 Mar  9 11:48 index.latest
drwxr-xr-x. 5 elasticsearch elasticsearch 4.0K Mar  9 11:48 indices
-rw-r--r--. 1 elasticsearch elasticsearch  18K Mar  9 11:48 meta-YCONu7qjRemBquBUkalV2g.dat
-rw-r--r--. 1 elasticsearch elasticsearch  396 Mar  9 11:48 snap-YCONu7qjRemBquBUkalV2g.dat
```
Список индексов после удаления test и создания test-2
```
[elasticsearch@2403641c68f1 snapshots]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic https://localhost:9200/_cat/indices?v
Enter host password for user 'elastic':
health status index  uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test-2 sPegl4shSY-fY0soZ2eEkw   1   0          0            0       225b           225b
```
Запрос на восстановление, список индексов:
```
[elasticsearch@2403641c68f1 snapshots]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic -X POST https://localhost:9200/_snapshot/netology_backup/snapshot_09_03_2022/_restore?pretty
Enter host password for user 'elastic':
{
  "accepted" : true
}

[elasticsearch@2403641c68f1 snapshots]$ curl --cacert /usr/share/elasticsearch/config/certs/http_ca.crt -u elastic https://localhost:9200/_cat/indices?v
Enter host password for user 'elastic':
health status index  uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test-2 sPegl4shSY-fY0soZ2eEkw   1   0          0            0       225b           225b
green  open   test   cIFjzz5mQ2O8Ng5mLlKuCQ   1   0          0            0       225b           225b

```
