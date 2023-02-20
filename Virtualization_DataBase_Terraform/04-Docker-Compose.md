Устанавливаем утилиту яндекс-клауда **yc**

```
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```
Переоткрываем bash терминал, выполняем установку
```
install yc
```
Инициализируем
```
yc init
```
Во время инициализации нужно будет перейти по ссылке в инструкции из терминала, что бы получить токен, либо найти самостоятельно

Убеждаемся, что у нас пока нет образов в облаке яндекса
```
yc compute image list
```
Создаём директорию для Packer
```
mkdir packer
cd packer
```
Создаём сеть в яндекс облаке
```
yc vpc network create --name net && yc vpc subnet create --name my-subnet-a --zone ru-central1-a --range 10.1.2.0/24 --network-name net --description "my first subnet via yc"
```
Создаём файл на основе которого будет происходить сборка образа
```
sudo nano centos-7-base.json
```
```
{
  "builders": [
    {
      "disk_type": "network-nvme",
      "folder_id": "b1gaec42k169jqpo02f7",         Изменить значение на своё
      "image_description": "by packer",
      "image_family": "centos",
      "image_name": "centos-7-base",
      "source_image_family": "centos-7",
      "ssh_username": "centos",
      "subnet_id": "e9b28580oai8e7qo4p13",         Изменить значение на своё 
      "token": "",                                 Изменить значение на своё
      "type": "yandex",
      "use_ipv4_nat": true,
      "zone": "ru-central1-a"
    }
  ],
  "provisioners": [
    {
      "inline": [
        "sudo yum -y update",
        "sudo yum -y install bridge-utils bind-utils iptables curl net-tools tcpdump rsync telnet openssh-server"
      ],
      "type": "shell"
    }
  ]
}
```
Установим Packer.

В нынешней ситуации установил VPN плагин для браузера, скачал файл с официального сайта. Скопировал в $PATH
```
sudo mv ~/Downloads/packer /usr/local/bin/
```
Перезапускаем bash терминал 

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
Инициализируем, собираем образз, проверяем, что он создался и лежит в нашем яндекс облаке
```
cd packer
packer init config.pkr.hcl
packer build centos-7-base.json
yc compute image list
```

![Image](https://i.ibb.co/8MwWQfp/Packer-images.png)

В terraform/variables.tf меняем ID на свой

Установка Terraform.

Установил пакетный менеджер snapd и установил с помощью него, так как он подкачивает и настраивает все необходимые зависимости
```
sudo apt install snapd
sudo apt update
sudo snapd install terraform --classic
```
Создаём сервисный аккаунт (например в веб-интерфейсе яндекса)

Проверяем
```
yc iam service-account --folder-id <ID каталога> list
```
Создаём авторизованный ключ для сервисного аккаунта и сохраняем его в файл key.json
```
cd terraform
yc iam key create --service-account-name default-sa --output key.json --folder-id <ID каталога>
yc config profile create sa-profile
yc config set service-account-key key.json
```
Проверим:
```
yc config list
yc config set cloud-id <ID облака>
yc config set folder-id <ID каталога>
```
Перед созданием виртуальных машин с помощью Terraform, удаляем временную сеть, которую мы создавали для Packer
```
yc vpc subnet delete --name my-subnet-a && yc vpc network delete --name net
```
Настраиваем terraform:
```
cd terraform
nano ~/.terraformrc
```
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
```
terraform init
```
Генерируем ssh ключи для наших нод:
```
ssh-keygen
```
Проверяем, что собирается создать Terraform и запускаем
```
terraform plan
terraform apply -auto-approve
```
![Image](https://i.ibb.co/47dKPYt/node01.png)

Подставляем внешние IP в /ansible/inventory и запускаем
```
cd
cd ansible
ansible-playbook provision.yml
```
Получаем настроенную графану

![Image](https://i.ibb.co/hHnjwr0/Grafana.png)

## **Задача 4**

Создаём файл node02.tf

Изменяем output.tf добавляем туда вывод информации о второй ноде

Запускаем терраформ, он пересоздаёт первую ноду и добавляет вторую
```
terraform apply -auto-approve
```
Добавляем вторую ноду в файл inventory у Ansible

Добавляем новый хост в provision.yml с другим docker-compouse file и запускаем Ansible. Он настроить первую ноду как графану с прометеусом, а вторую, как просто нод экспортер
```
ansible-playbook provision.yml
```
Заходим на первую ноду:
```
ssh centos@IP
```
Установим текстовый редактор
```
sudo yum install nano
```
Скопируем конфиг с настройками прометеуса из докер контейнера
```
sudo docker cp 2f1fa28d950b:/etc/prometheus/prometheus.yml /home/centos
```
Откроем его на редактирование
```
sudo nano prometheus.yml
```
В настройках добавим джоб nodeexporter2 с нашими IP:port второй ноды, а затем скопируем этот конфиг обратно в контейнер
```
sudo docker cp /home/centos/prometheus.yml 2f1fa28d950b:/etc/prometheus/
```
Можем зайти в контейнер и убедиться, что файл перезаписался
```
sudo docker exec -it ID-контейнера /bin/sh
cat /etc/prometheus/prometheus.yml
```
С любой машины отправим запрос Прометеусу, что бы перечитал конфиг
```
curl -X POST http://admin:admin@51.250.87.218:9090/-/reload
```
Скачаем с официального сайта графаны дашборд с ID 11074, в веб интерфейсе графаны импортируем JSON файл.

В интерфейсе видим нашу вторую ноду nodeexporter2

![Image](https://i.ibb.co/23fcwCM/node2.png)



