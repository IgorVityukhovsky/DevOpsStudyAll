# Домашнее задание к занятию "5.5. Оркестрация кластером Docker контейнеров на примере Docker Swarm"

## Задача 1

Дайте письменые ответы на следующие вопросы:

- В чём отличие режимов работы сервисов в Docker Swarm кластере: replication и global?

**Ответ:** replication означает, что у сервиса будет работать определённое количество копий (реплик), тогда как в режиме global сервисы будут работать на всех нодах

- Какой алгоритм выбора лидера используется в Docker Swarm кластере?

**Ответ:** для выбора лидера используется протокол Raft, который осужествляющий распределённый консенсус (согласие). Каждая из нод находится в статусе слушателя и как только она не получает ответ от лидера, она может стать кандидатом в лидеры. У Raft есть таймаут выборов. Это время, по истечении которого подписчик заметивший отсутствие ответа от лидера может стать кандидатом . Тайм-аут выборов случайный от 150 мс до 300 мс. По его истечении подписчик становится кандидатом и начинает новый избирательный срок, голосует за себя и отправляет сообщения с запросом на голосование другим узлам. Если принимающий узел еще не проголосовал в течение этого срока, то он голосует за кандидата (иными словами, если данную процедуру становления кандидатом они не успели завершить прежде, чем это успела сделать другая нода-менеджер) и узел сбрасывает свой тайм-аут выбора. Как только кандидат набирает большинство голосов он становится лидером.

Если два узла становятся кандидатами одновременно, то может произойти раздельное голосование и если голосов наберётся поровну, то голосование будет повторяться пока один из них не получит большинство голосов. Однажды это в любом случае произойдёт из-за разного тайм аута выборов у каждой ноды, либо, например, разной скорости сети.

- Что такое Overlay Network?

**Ответ:** это такой тип сети, когда поверх физической сети создаётся логическая. Самый популярный пример: VPN.

## Задача 2

Создать ваш первый Docker Swarm кластер в Яндекс.Облаке

Для получения зачета, вам необходимо предоставить скриншот из терминала (консоли), с выводом команды:
```
docker node ls
```

Создаём временную сеть для Packer:
```
yc vpc network create --name net && yc vpc subnet create --name my-subnet-a --zone ru-central1-a --range 10.1.2.0/24 --network-name net --description "my first subnet via yc"
```
Правим centos-7-base.json на свои значения.
В дирректории Packer создаём файл config.pkr.hcl с содержимым
```
packer {
  required_plugins {
    yandex = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/yandex"
    }
  }
}
```

Инициализируем, собираем образ, проверяем, что он создался и лежит в нашем яндекс облаке
```
cd packer
packer init config.pkr.hcl
packer build centos-7-base.json
yc compute image list
```
Удаляем временную сеть, которую мы создавали для Packer
```
yc vpc subnet delete --name my-subnet-a && yc vpc network delete --name net
```
Копируем key.json, variables.tf (меняем ID image) в директорию терраформа из прошлого ДЗ
```
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```
```
docker node ls
```
![Image](https://i.ibb.co/kX4sMxg/docker-node-ls.png)


## Задача 3

Создать ваш первый, готовый к боевой эксплуатации кластер мониторинга, состоящий из стека микросервисов.

Для получения зачета, вам необходимо предоставить скриншот из терминала (консоли), с выводом команды:
```
docker service ls
```
![Image](https://i.ibb.co/J2tKb9c/docker-service-ls.png)

## Задача 4 (*)

Выполнить на лидере Docker Swarm кластера команду (указанную ниже) и дать письменное описание её функционала, что она делает и зачем она нужна:
```
# см.документацию: https://docs.docker.com/engine/swarm/swarm_manager_locking/
docker swarm update --autolock=true
```
Команда включает функцию автоблокировки и генерирует ключ, который администратор системы должен сохранить. Это значит, что при перезапуске Docker Swarm будет запрашиваться этот ключ в целях безопасности иначе Swarm не разблокируется.

---