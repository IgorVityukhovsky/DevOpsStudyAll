# Домашнее задание к занятию "2. Работа с Playbook"

## Подготовка к выполнению

1. (Необязательно) Изучите, что такое [clickhouse](https://www.youtube.com/watch?v=fjTNS2zkeBs) и [vector](https://www.youtube.com/watch?v=CgEhyffisLY)
2. Создайте свой собственный (или используйте старый) публичный репозиторий на github с произвольным именем.
3. Скачайте [playbook](./playbook/) из репозитория с домашним заданием и перенесите его в свой репозиторий.
4. Подготовьте хосты в соответствии с группами из предподготовленного playbook.

## Основная часть

1. Приготовьте свой собственный inventory файл `prod.yml`.
2. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает [vector](https://vector.dev).
3. При создании tasks рекомендую использовать модули: `get_url`, `template`, `unarchive`, `file`.
4. Tasks должны: скачать нужной версии дистрибутив, выполнить распаковку в выбранную директорию, установить vector.
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
9. Подготовьте README.md файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-02-playbook` на фиксирующий коммит, в ответ предоставьте ссылку на него.

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---

## Подготовка
Создал отдельный репозиторий для Ansible IgorVityukhovsky/Ansible и поместил туда все учебные материалы.  
Так же сгенерировал токен для дальнейшей авторизации.  
Создал инстанс.  
Подготавливаю его для выполнения ДЗ.  

Обновление и установка ansible
```
sudo apt update && sudo apt install ansible -y 
mkdir git
cd git
```

Подготовка Git
```
git config --global init.defaultBranch main && git config --global user.name "IgorVityukhovsky" && git config --global user.email relixinus@mail.ru
git init
git remote add origin https://github.com/IgorVityukhovsky/Ansible.git
git pull origin main
git clone https://github.com/IgorVityukhovsky/Ansible.git
```

Делаю тестовые изменения в любом файле.  
Проверяю  
```
git status
git add *
git commit -m "тестовое изменение"
git push --set-upstream origin main
Username for 'https://github.com': *ввожу свои данные*
Password for 'https://IgorVityukhovsky@github.com': *вставляю токен*
```
Всё работает.  
В дальнейшем я буду делать это одной командой:
```
sudo apt update && sudo apt install ansible -y &&  /
mkdir git && cd git &&  /
git config --global init.defaultBranch main &&  /
git config --global user.name "IgorVityukhovsky" &&  /
git config --global user.email relixinus@mail.ru &&  /
git init && /
git remote add origin https://github.com/IgorVityukhovsky/Ansible.git && /
git pull origin main && /
git clone https://github.com/IgorVityukhovsky/Ansible.git && /
echo "test string" >> /home/ubuntu/git/08-ansible-02-playbook/README.md && /
git status && git add * &&  /
git commit -m "тестовое изменение" &&  /
git push --set-upstream origin main
```

## Выполнение ДЗ

Скопировал закрытый ключ Admin.pem на машину, дал права 600.  
Создал второй инстанс на red hat.  
Отредактировал prod.yml добавив IP нового инстанса, так же добавил
```
ansible_ssh_user: ec2-user
```
Изменил плейбук site.yml так как исходник не рабочий:

* Отключил проверку GPG.  
* Добавил принудительный вызов хендлера там, где он нам нужен, а не после выполнения всех тасков.  
* Добавил двухсекундную паузу после перезапуска службы, иначе базы данных не создаются при первом запуске плейбука.  

В результате привёл к виду:  

```
---
- name: Install Clickhouse
  hosts: clickhouse
  handlers:
    - name: Start clickhouse service
      become: true
      ansible.builtin.service:
        name: clickhouse-server
        state: restarted
  tasks:
    - block:
        - name: Get clickhouse distrib
          ansible.builtin.get_url:
            url: "https://packages.clickhouse.com/rpm/stable/{{ item }}-{{ clickhouse_version }}.noarch.rpm"
            dest: "./{{ item }}-{{ clickhouse_version }}.rpm"
          with_items: "{{ clickhouse_packages }}"
      rescue:
        - name: Get clickhouse distrib
          ansible.builtin.get_url:
            url: "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-{{ clickhouse_version }}.x86_64.rpm"
            dest: "./clickhouse-common-static-{{ clickhouse_version }}.rpm"
    - name: Install clickhouse packages
      become: true
      ansible.builtin.yum:
        disable_gpg_check: true
        name:
          - clickhouse-common-static-{{ clickhouse_version }}.rpm
          - clickhouse-client-{{ clickhouse_version }}.rpm
          - clickhouse-server-{{ clickhouse_version }}.rpm          
      notify: Start clickhouse service
    - name: Flush handlers
      meta: flush_handlers
    - name: Pause for 2 seconds to restart service
      ansible.builtin.pause:
        seconds: 2
    - name: Create database
      ansible.builtin.command: "clickhouse-client -q 'create database logs;'"
      register: create_db
      failed_when: create_db.rc != 0 and create_db.rc !=82
      changed_when: create_db.rc == 0
```
Запускаю плейбук с ключем private-key, что бы сработало ssh соединение
```
cd /home/ubuntu/git/08-ansible-02-playbook/playbook/
ansible-playbook site.yml -i inventory/prod.yml --private-key ~/.ssh/Admin.pem
```
Всё отработало успешно.  
Зайдём на машину и проверим
```
clickhouse-client
```
```
ClickHouse client version 22.3.3.44 (official build).
Connecting to localhost:9000 as user default.
Connected to ClickHouse server version 22.3.3 revision 54455.

ip-172-31-94-75.ec2.internal :)
```
Установим ansible-lint и проверим наш плейбук
```
sudo apt install ansible-lint
ansible-lint site.yml
```
```
WARNING  Overriding detected file kind 'yaml' with 'playbook' for given positional argument: site.yml
```
На сколько я понял ansible-lint определил, что наш site.yml является плейбуком.
```
ansible-playbook site.yml -i inventory/prod.yml --private-key ~/.ssh/Admin.pem --check
```
Запуск выдал ошибку на этапе установке пакета. Вероятно потому, что ничего не скачал, а значит и устанавливать нечего.
```
ansible-playbook site.yml -i inventory/prod.yml --private-key ~/.ssh/Admin.pem --diff
```
```
PLAY RECAP ***********************************************************************************************************************************
clickhouse-01              : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0
```
Запуск с ключем --check после этого прошел успешно.  
Повторный запуск с ключом --diff успешен, плейбук индепотентен
```
PLAY RECAP ***********************************************************************************************************************************
clickhouse-01              : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0
```
