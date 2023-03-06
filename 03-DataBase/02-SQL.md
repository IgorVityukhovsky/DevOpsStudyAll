# Домашнее задание к занятию "6.2. SQL"


## Задача 1

Используя docker поднимите инстанс PostgreSQL (версию 12) c 2 volume, 
в который будут складываться данные БД и бэкапы.

Приведите получившуюся команду или docker-compose манифест.

## Ответ

Установка Docker copmose
```
sudo apt-get update
sudo apt-get install docker-compose-plugin
```
Проверка Docker copmose
```
docker compose version
```
Создадим каталоги и дадим права, если мы хотим, что бы Volume хранились в определённых местах
```
sudo mkdir -p /var/lib/postgresql/data
sudo mkdir -p /var/lib/postgresql/backup
sudo chmod 777 /var/lib/postgresql/data
sudo chmod 777 /var/lib/postgresql/backup
```
Для нашей тестовой задачи мы будем использовать дефолтные пути (/var/lib/docker/volumes/), поэтому предыдущий пункт не обязателен.

Создадим docker compose file
```
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
Соберём проект
```
docker compose build 
```
Запустим проект
```
docker compose up -d
```
Проверим, что контейнер создался, запущен и работает
```
docker compose ps
```


## Задача 2 - 5

В docker compose файле я так же подключил - /home/igor/HomeWorkSQL/Script:/docker-entrypoint-initdb.d
В папке Script лежит скрипт StartScript, который создаёт необходимые для задач базы данных, выборки и выводит их результат в файлы.
Сделано с целью автоматизировать процесс.
Описание скрипта:
```
CREATE DATABASE test_db
	TEMPLATE template0
	ENCODING 'UTF-8';
CREATE USER "test-admin-user";
CREATE USER "test-simple-user";
CREATE TABLE orders (
	id	serial PRIMARY KEY,
	order_name	varchar(25) NOT NULL CHECK (order_name <> ''),
	price	integer NOT NULL CHECK (price > 0)
);
CREATE TABLE clients (
        id      serial PRIMARY KEY,
        last_name	varchar(45) NOT NULL CHECK (last_name <> ''),
	country	varchar(35) NOT NULL CHECK (country <> ''),
	order_number	integer REFERENCES orders
);
CREATE INDEX country_index ON clients(country);
GRANT ALL ON ALL TABLES IN SCHEMA "public" TO "test-admin-user";
GRANT SELECT, INSERT, UPDATE, DELETE
	ON ALL TABLES IN SCHEMA "public"
	TO "test-simple-user";

\o /tmp/output-task2
\l
\d+ orders
\d+ clients
SELECT table_name, grantee, privilege_type
	FROM information_schema.role_table_grants
	WHERE table_name='orders';
SELECT table_name, grantee, privilege_type
	FROM information_schema.role_table_grants
	WHERE table_name='clients';

\o
INSERT INTO orders
	VALUES (1, 'Шоколад', 10),
		(2, 'Принтер', 3000),
		(3, 'Книга', 500),
		(4, 'Монитор', 7000),
		(5, 'Гитара', 4000);
INSERT INTO clients
	VALUES (1, 'Иванов Иван Иванович', 'USA'),
		(2, 'Петров Петр Петрович', 'Canada'),
		(3, 'Иоганн Себастьян Бах', 'Japan'),
		(4, 'Ронни Джеймс Дио', 'Russia'),
		(5, 'Ritchie Blackmore', 'Russia');

\o /tmp/output-task3
SELECT * FROM orders;
SELECT * FROM clients;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM clients;

\o
UPDATE clients SET order_number=3 WHERE id=1;
UPDATE clients SET order_number=4 WHERE id=2;
UPDATE clients SET order_number=5 WHERE id=3;

\o /tmp/output-task4
SELECT * FROM clients;
SELECT * FROM clients WHERE order_number IS NOT NULL;

\o /tmp/output-task5
EXPLAIN (FORMAT YAML) SELECT * FROM clients WHERE order_number IS NOT NULL;

```
Подключимся в контейнер и передаём скрипт
```
docker exec -it homeworksql-mydb-1 bash
psql -f /docker-entrypoint-initdb.d/StartScript -U postgres
```
Результат вывода по задачам:
```
cat /tmp/output-task2
```
```

 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 test_db   | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
(4 rows)

                                                         Table "public.orders"
   Column   |         Type          | Collation | Nullable |              Default               | Storage  | Stats target | Description 
------------+-----------------------+-----------+----------+------------------------------------+----------+--------------+-------------
 id         | integer               |           | not null | nextval('orders_id_seq'::regclass) | plain    |              | 
 order_name | character varying(25) |           | not null |                                    | extended |              | 
 price      | integer               |           | not null |                                    | plain    |              | 
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "orders_order_name_check" CHECK (order_name::text <> ''::text)
    "orders_price_check" CHECK (price > 0)
Referenced by:
    TABLE "clients" CONSTRAINT "clients_order_number_fkey" FOREIGN KEY (order_number) REFERENCES orders(id)
Access method: heap

                                                          Table "public.clients"
    Column    |         Type          | Collation | Nullable |               Default               | Storage  | Stats target | Description 
--------------+-----------------------+-----------+----------+-------------------------------------+----------+--------------+-------------
 id           | integer               |           | not null | nextval('clients_id_seq'::regclass) | plain    |              | 
 last_name    | character varying(45) |           | not null |                                     | extended |              | 
 country      | character varying(35) |           | not null |                                     | extended |              | 
 order_number | integer               |           |          |                                     | plain    |              | 
Indexes:
    "clients_pkey" PRIMARY KEY, btree (id)
    "country_index" btree (country)
Check constraints:
    "clients_country_check" CHECK (country::text <> ''::text)
    "clients_last_name_check" CHECK (last_name::text <> ''::text)
Foreign-key constraints:
    "clients_order_number_fkey" FOREIGN KEY (order_number) REFERENCES orders(id)
Access method: heap

 table_name |     grantee      | privilege_type 
------------+------------------+----------------
 orders     | postgres         | INSERT
 orders     | postgres         | SELECT
 orders     | postgres         | UPDATE
 orders     | postgres         | DELETE
 orders     | postgres         | TRUNCATE
 orders     | postgres         | REFERENCES
 orders     | postgres         | TRIGGER
 orders     | test-admin-user  | INSERT
 orders     | test-admin-user  | SELECT
 orders     | test-admin-user  | UPDATE
 orders     | test-admin-user  | DELETE
 orders     | test-admin-user  | TRUNCATE
 orders     | test-admin-user  | REFERENCES
 orders     | test-admin-user  | TRIGGER
 orders     | test-simple-user | INSERT
 orders     | test-simple-user | SELECT
 orders     | test-simple-user | UPDATE
 orders     | test-simple-user | DELETE
(18 rows)

 table_name |     grantee      | privilege_type 
------------+------------------+----------------
 clients    | postgres         | INSERT
 clients    | postgres         | SELECT
 clients    | postgres         | UPDATE
 clients    | postgres         | DELETE
 clients    | postgres         | TRUNCATE
 clients    | postgres         | REFERENCES
 clients    | postgres         | TRIGGER
 clients    | test-admin-user  | INSERT
 clients    | test-admin-user  | SELECT
 clients    | test-admin-user  | UPDATE
 clients    | test-admin-user  | DELETE
 clients    | test-admin-user  | TRUNCATE
 clients    | test-admin-user  | REFERENCES
 clients    | test-admin-user  | TRIGGER
 clients    | test-simple-user | INSERT
 clients    | test-simple-user | SELECT
 clients    | test-simple-user | UPDATE
 clients    | test-simple-user | DELETE
(18 rows)
```
```
cat /tmp/output-task3
```
```
 id | order_name | price 
----+------------+-------
  1 | Шоколад    |    10
  2 | Принтер    |  3000
  3 | Книга      |   500
  4 | Монитор    |  7000
  5 | Гитара     |  4000
(5 rows)

 id |      last_name       | country | order_number 
----+----------------------+---------+--------------
  1 | Иванов Иван Иванович | USA     |             
  2 | Петров Петр Петрович | Canada  |             
  3 | Иоганн Себастьян Бах | Japan   |             
  4 | Ронни Джеймс Дио     | Russia  |             
  5 | Ritchie Blackmore    | Russia  |             
(5 rows)

 count 
-------
     5
(1 row)

 count 
-------
     5
(1 row)
```
```
cat /tmp/output-task4
```
```
id |      last_name       | country | order_number 
----+----------------------+---------+--------------
  4 | Ронни Джеймс Дио     | Russia  |             
  5 | Ritchie Blackmore    | Russia  |             
  1 | Иванов Иван Иванович | USA     |            3
  2 | Петров Петр Петрович | Canada  |            4
  3 | Иоганн Себастьян Бах | Japan   |            5
(5 rows)

 id |      last_name       | country | order_number 
----+----------------------+---------+--------------
  1 | Иванов Иван Иванович | USA     |            3
  2 | Петров Петр Петрович | Canada  |            4
  3 | Иоганн Себастьян Бах | Japan   |            5
(3 rows)
```
Дирректива EXPLAIN позволяет узнать сколько времени будет выполняться запрос по мнению СУБД. Помогает при диагностики проблем и оптимизации
```
cat /tmp/output-task5
```
```
 QUERY PLAN                
------------------------------------------
 - Plan:                                 +
     Node Type: "Seq Scan"               +
     Parallel Aware: false               +
     Relation Name: "clients"            +
     Alias: "clients"                    +
     Startup Cost: 0.00                  +
     Total Cost: 13.50                   +
     Plan Rows: 348                      +
     Plan Width: 204                     +
     Filter: "(order_number IS NOT NULL)"
(1 row)
```

## Задача 6

Создайте бэкап БД test_db и поместите его в volume, предназначенный для бэкапов (см. Задачу 1).

Остановите контейнер с PostgreSQL (но не удаляйте volumes).

Поднимите новый пустой контейнер с PostgreSQL.

Восстановите БД test_db в новом контейнере.

Приведите список операций, который вы применяли для бэкапа данных и восстановления. 

## Ответ

Подключаемся к контейнеру, даём права на бекап-директорию, логинимся под пользователем postgres и выполняем бекап
```
docker exec -it homeworksql-mydb-1 bash
chmod 777 /var/lib/postgresql/backup
su postgress
pg_dumpall > /var/lib/postgresql/backup/backup_netology
```
Удаляем контейнер, смотрим, какие у нас есть volume. 
```
docker compose down
docker volume ls

```
```
DRIVER    VOLUME NAME
local     homeworksql_db-backup
local     homeworksql_db-data
```
Имитируем потерю нашей базы удалив volume с ней.
```
docker volume rm homeworksql_db-data
```
Запускаем контейнер снова. В результате запустится контайнер с пустым volume под базу и с volume в котором хранится бекап
```
docker compose build
docker compose up -d
```
Подключаемся к контейнеру и проверяем, что бекап на месте
```
docker exec -it homeworksql-mydb-1 bash
cd /var/lib/postgresql/backup
ls -lh
```
```
total 8.0K
-rw-r--r-- 1 postgres postgres 7.1K Sep 19 15:56 backup_netology
```
Логинимся под postgres и восстанавливаем бекап
```
su postgres
psql -f /var/lib/postgresql/backup/backup_netology
```
Заходим в СУБД и выводим список баз, что бы убедиться, что всё прошло успешно
```
psql -h localhost -p 5432 -U postgres -W
*вводим пароль*
postgres=# \l
```
```
List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 test_db   | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
(4 rows)
```
