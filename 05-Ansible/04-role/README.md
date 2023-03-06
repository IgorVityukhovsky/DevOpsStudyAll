# Домашнее задание к занятию "4. Работа с roles"

## Подготовка к выполнению
1. (Необязательно) Познакомтесь с [lighthouse](https://youtu.be/ymlrNlaHzIY?t=929)
2. Создайте два пустых публичных репозитория в любом своём проекте: vector-role и lighthouse-role.
3. Добавьте публичную часть своего ключа к своему профилю в github.

## Основная часть

Наша основная цель - разбить наш playbook на отдельные roles. Задача: сделать roles для clickhouse, vector и lighthouse и написать playbook для использования этих ролей. Ожидаемый результат: существуют три ваших репозитория: два с roles и один с playbook.

1. Создать в старой версии playbook файл `requirements.yml` и заполнить его следующим содержимым:

   ```yaml
   ---
     - src: git@github.com:AlexeySetevoi/ansible-clickhouse.git
       scm: git
       version: "1.11.0"
       name: clickhouse 
   ```

2. При помощи `ansible-galaxy` скачать себе эту роль.
3. Создать новый каталог с ролью при помощи `ansible-galaxy role init vector-role`.
4. На основе tasks из старого playbook заполните новую role. Разнесите переменные между `vars` и `default`. 
5. Перенести нужные шаблоны конфигов в `templates`.
6. Описать в `README.md` обе роли и их параметры.
7. Повторите шаги 3-6 для lighthouse. Помните, что одна роль должна настраивать один продукт.
8. Выложите все roles в репозитории. Проставьте тэги, используя семантическую нумерацию Добавьте roles в `requirements.yml` в playbook.
9. Переработайте playbook на использование roles. Не забудьте про зависимости lighthouse и возможности совмещения `roles` с `tasks`.
10. Выложите playbook в репозиторий.
11. В ответ приведите ссылки на оба репозитория с roles и одну ссылку на репозиторий с playbook.

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---

# Выполнение

Создал 2 репозитория:  
IgorVityukhovsky/vector-role  
IgorVityukhovsky/lighthouse-role  

Добавил публичную часть своего ключа к своему профилю в github.  

Ставить опыты я буду на инфраструктуре, которую буду разворачивать с помощью Терраформ.  
Поэтому прикладываю и его настройки тоже.

Создал файл `requirements.yml` и наполнил содержимым

  ```yaml
   ---
     - src: git@github.com:AlexeySetevoi/ansible-clickhouse.git
       scm: git
       version: "1.11.0"
       name: clickhouse 
   ```
   
Установить
```
ansible-galaxy install -r requirements.yml -p ./roles
```
```
Starting galaxy role install process
- extracting clickhouse to /Users/igorvityukhovsky/Git/08-ansible-04-role/playbook/roles/clickhouse
clickhouse (1.11.0) was installed successfully

```
Перейдём в каталог с ролями и инициируем создание новой роли
```
cd roles
ansible-galaxy role init vector-role
```
```
- Role vector-role was created successfully
```
Распределил таски и переменные по каталогам новой роли.
Таски теперь содержат переменные, которые в свою очередь ссылаются на дефолты.

Повторил тоже самое для роли lighthouse-role

Выложил все roles в репозитории. Проставил тэги, используя семантическую нумерацию 1.0.0

Добавил roles в `requirements.yml` в playbook.  
Привёл к виду:


  ```yaml
---
- src: git@github.com:AlexeySetevoi/ansible-clickhouse.git
  scm: git
  version: '1.11.0'
  name: clickhouse

- src: git@github.com:IgorVityukhovsky/lighthouse-role.git
  scm: git
  version: '1.0.0'
  name: lighthouse-role

- src: git@github.com:IgorVityukhovsky/vector-role.git
  scm: git
  version: '1.0.0'
  name: vector-role

   ```
Если бы у нас не было этих ролей, их можно было бы установить той же командой
```
ansible-galaxy install -r requirements.yml -p ./roles
```

Плейбук привёл к виду:

```yaml
---
- name: Install Clickhouse
  hosts: clickhouse_RHEL
  roles:
    - role: clickhouse

  post_tasks:
    - name: Create database
      ansible.builtin.command: "clickhouse-client -q 'create database logs;'"
      register: create_db
      failed_when: create_db.rc != 0 and create_db.rc !=82
      changed_when: create_db.rc == 0

- name: Install Vector
  hosts: vector_RHEL
  roles:
    - role: vector-role

- name: Install Lighthouse
  hosts: lighthouse_UBUNTU
  roles:
    - role: lighthouse-role
```


После создания инфраструктуры запускаем ансибл подставив сгенерированный терраформом инвентори файл

```
ansible-playbook site.yml -i /$HOME/terraform/inventary.yml
```
Всё прошло успешно
```
PLAY RECAP *******************************************************************************
clickhouse_RHEL            : ok=25   changed=0    unreachable=0    failed=0    skipped=10   rescued=0    ignored=0   
lighthouse_UBUNTU          : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
vector_RHEL                : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```
