# Домашнее задание к занятию "7.3. Основы и принцип работы Терраформ"

## Задача 1. Создадим бэкэнд в S3 (необязательно, но крайне желательно).

Если в рамках предыдущего задания у вас уже есть аккаунт AWS, то давайте продолжим знакомство со взаимодействием
терраформа и aws. 

1. Создайте s3 бакет, iam роль и пользователя от которого будет работать терраформ. Можно создать отдельного пользователя,
а можно использовать созданного в рамках предыдущего задания, просто добавьте ему необходимы права, как описано 
[здесь](https://www.terraform.io/docs/backends/types/s3.html).
1. Зарегистрируйте бэкэнд в терраформ проекте как описано по ссылке выше. 


## Задача 2. Инициализируем проект и создаем воркспейсы. 

1. Выполните `terraform init`:
    * если был создан бэкэнд в S3, то терраформ создат файл стейтов в S3 и запись в таблице 
dynamodb.
    * иначе будет создан локальный файл со стейтами.  
1. Создайте два воркспейса `stage` и `prod`.
1. В уже созданный `aws_instance` добавьте зависимость типа инстанса от вокспейса, что бы в разных ворскспейсах 
использовались разные `instance_type`.
1. Добавим `count`. Для `stage` должен создаться один экземпляр `ec2`, а для `prod` два. 
1. Создайте рядом еще один `aws_instance`, но теперь определите их количество при помощи `for_each`, а не `count`.
1. Что бы при изменении типа инстанса не возникло ситуации, когда не будет ни одного инстанса добавьте параметр
жизненного цикла `create_before_destroy = true` в один из рессурсов `aws_instance`.
1. При желании поэкспериментируйте с другими параметрами и рессурсами.

В виде результата работы пришлите:
* Вывод команды `terraform workspace list`.
* Вывод команды `terraform plan` для воркспейса `prod`.  

---

### Ответ
Решил переехать на новую машину и начать процесс с нуля, попутно его подробно документируя.

Команда для смены раскладки
```
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Alt>Shift_L']"
```
Установим curl
```
sudo apt install curl
```
Изменим конфиг, что бы DNS корректно резовлвились
```
sudo sh -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
```
Скачаем актуальную версию терраформ
```
wget "https://hashicorp-releases.yandexcloud.net/terraform/1.3.3/terraform_1.3.3_linux_amd64.zip"
```
Разархивируем
```
unzip terraform_1.3.3_linux_amd64.zip 
```
Создадим симлинк и сделаем файлы исполняемыми
```
sudo ln -s /home/igor/terraform /usr/bin/terraform
sudo chmod ugo+x /usr/bin/terraform*
```
Установка Яндекс Клауд CLI
```
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```
Далее необходимо перезапустить терминал и проверить, что всё установилось
```
yc --version
```
Делаем симлинк
```
sudo ln -s /home/igor/yandex-cloud/bin/yc /usr/bin/yc
```

При инициализации yc CLI выйдет ссылка по которой нужно перейти, что бы узнать свой токен.

Если по каким то причинам этого не произошло можно:

Из инструкции

https://cloud.yandex.ru/docs/cli/quickstart#install

перейти по ссылке 

https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb

Получаем наш токен


Инициализируем yc CLI
```
yc init
```
Вставляем наш токен.
При дальнейших вопросах ответил, что folder по умолчанию это netology, зона ru-central1-a

Проверить наши настройки 
```
yc config list
```
Далее необходимо создать сервисный аккаунт и присвоить ему необходимые роли. Это уже сделано и легко делается через веб-интерфейс.


Далее нас просят создать авторизованные ключи для сервисного аккаунта по инструкции из веб интерфейса или CLI. Даже если это уже было сделано ранее, лучше создать заново, так как срок его действия быстро истекает

Создал ключи в веб интерфейсе и скачал файл с ними

Создадим рабочую директорию и перейдём туда
```
mkdir myterraform && cd myterraform
```
Скопировал файл с ключами в директорию.

Создадим профиль service-profile
```
yc config profile create service-profile
```
```
Profile 'service-profile' created and activated
```
Зададим конфигурацию профиля используя наш файл с ключами. Не забываем делать это из рабочей дирректории, где лежат ключи
```
yc config set service-account-key authorized_key.json
yc config set cloud-id b1g8rvrldf45r9h4mnbl
yc config set folder-id b1gcj17iv37qg7h91dfe  
```
Добавим аутентификационные данные в переменные окружения. Некоторые символы экранируем, что бы вставлялись команды, а не их значения
```
sudo sh -c "echo export YC_TOKEN=\$\(yc iam create-token\) >> /etc/environment"
sudo sh -c "echo export YC_CLOUD_ID=\$\(yc config get cloud-id\) >> /etc/environment"
sudo sh -c "echo export YC_FOLDER_ID=\$\(yc config get folder-id\) >> /etc/environment"
```
И прочтём их
```
source /etc/environment
```
Так же скопировал ssh ключи для машин в директорию .ssh

## Настройка терраформ

Добавим зеркала в терраформ
```
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

Создадим provider.tf
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}
```
Создадим сеть и подсеть в веб-интерфейсе, а так же заполним main.tf для проверки на создание ресурсов. Подставляем сеть
```
resource "yandex_compute_instance" "node01" {
  name                      = "node01"
  zone                      = "ru-central1-a"
  hostname                  = "node01.netology.cloud"
  allow_stopping_for_update = true

  resources {
    cores  = 8
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kb72eo1r5fs97a1ki" #ubuntu
      name     = "root-node01"
      type     = "network-nvme"
      size     = "50"
    }
  }
  network_interface {
    subnet_id = "e2l4hqmd505sl0fkj1lm"
    nat       = true
  }

  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_rsa.pub")}"
  }
}


```
Инициализируем терраформ
```
terraform init
```
В наш provider.tf добавим информацию о бекенде.
В итоге он будет иметь вид
```
 terraform {
  backend "s3" {
      endpoint = "storage.yandexcloud.net"
      bucket   = "s3-netology-mystate2"
      region   = "ru-central1-a"
      key      = "testfolder/terraform.tfstate"
      

      skip_region_validation      = true
      skip_credentials_validation = true
    }
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

 
```

Создадим iam ключи доступа, что бы управлять s3 бакетом в будущем.
Можно использовать уже существующие ключи, если мы знаем их access key и secret key.
Но если мы их не знаем, секретная часть выдаётся только один раз при генерации, поэтому сгенерируем ключи
```
yc iam access-key create --service-account-id aje164j36fslfgb32qce --description "bucket key"
```
Из вывода нас интересует key_id (это наш access key) и secret (это наш secret key)
Создадим файл backend.conf и запишем туда эти данные
```
access_key = "наш ключ"
secret_key = "наш ключ подлиннее"
```
В блоке terraform нельзя использовать переменные, таким образом мы вывели секреты отдельно, что бы не хранить их на гите.
Переконфигурируем наш терраформ.
```
terraform init -reconfigure -backend-config=backend.conf
```
Проверим, что все процессы будут происходить
```
terraform plan
terraform apply
terrafrom destroy
```
В наш бакет записался state файл

Создадим новый workspace, после чего система сообщит нам о том, что он создан и сделан switch на него
```
terraform workspace new stage
```
В main.tf в наш ресурс добавим строчку
```
count = terraform.workspace == "stage" ? "1" : terraform.workspace == "prod" ? "2" : "1"
```
В этой строке описано условие, если workspace равен stage, то количество ресурсов 1, если prod, то 2, во всех остальных случаях 1.


Новый воркспейс изолирован от других, поэтому снова выполняем инициализацию и не забудем про наш конфигурационный файл для бекенда.
В s3 наш state файл будет храниться отдельно.
```
terraform init -reconfigure -backend-config=backend.conf
```
Узнаем, что планирует создать терраформ
```
terraform plan
```
```
Plan: 1 to add, 0 to change, 0 to destroy
```
Всё сходится, наш workspace сейчас stage и для него мы прописали создать 1 ресурс.
Проверим тоже самое в workspace prod
```
terraform workspace new prod
terraform init -reconfigure -backend-config=backend.conf
terraform plan
```
```
Plan: 2 to add, 0 to change, 0 to destroy
```
В workspace prod создаётся 2 ресурса, как мы и хотели.

Так же можно было бы использовать конструкцию
```
locals {
  instances = {
	  stage = 1
		prod   = 2
	}
}

count = locals.instances[terraform.workspace]
```

Для for_each сработает примерно та же конструкция. 
```
locals {
  subnet_ids = toset([
    "subnet-abcdef",
    "subnet-012345",
  ])
}

resource "aws_instance" "server" {
  for_each = local.subnet_ids
```

Сдесь мы создали список с id наших подсетей, а затем создаём по инстансу для каждой подсети.

Вывод команды terraform workspace list

![Image](https://i.ibb.co/zSVr1b4/Screenshot-from-2022-10-27-21-48-49.png)

Вывод команды terraform plan
```
terraform plan

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.node01[0] will be created
  + resource "yandex_compute_instance" "node01" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "node01.netology.cloud"
      + id                        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                centos:-----BEGIN PUBLIC KEY-----
                MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAptCr44sFVJVmjDiq0Cy7
                twQps1pYHMzkr//XSDf+YA+FZ/ZokzvZNJ4RMbLcZzlcXqc2sG3d8I0EtdSPa2nx
                yZrv4SDNmK89Ugp4Ppev1MjKM5tDc6xAec3dEccURgXLO/SHTchPpftUM/gYA7t6
                s6oAoIySSOZUcYQtdkf7i90/gG5LPhfL/GmBR6Dw5zS7qhHXQ+p2p0h9/cqmomvR
                F5H8hs1THrYMqfXC+WHH6Ddl9ncsdqpIF4S5XWZ4TfeJhTwX4TzkH+pnkkTU5BxF
                h0GgWnjTNDQnYuN3HvGR5QRFpkd19uPBcl0FY0w1F4jQTgEzuuP11iWAo+R3LuRS
                gQIDAQAB
                -----END PUBLIC KEY-----
            EOT
        }
      + name                      = "node01"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kb72eo1r5fs97a1ki"
              + name        = "root-node01"
              + size        = 50
              + snapshot_id = (known after apply)
              + type        = "network-nvme"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e9brl9jl7f9vhiki8c3q"
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 8
          + memory        = 8
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.node01[1] will be created
  + resource "yandex_compute_instance" "node01" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "node01.netology.cloud"
      + id                        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                centos:-----BEGIN PUBLIC KEY-----
                MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAptCr44sFVJVmjDiq0Cy7
                twQps1pYHMzkr//XSDf+YA+FZ/ZokzvZNJ4RMbLcZzlcXqc2sG3d8I0EtdSPa2nx
                yZrv4SDNmK89Ugp4Ppev1MjKM5tDc6xAec3dEccURgXLO/SHTchPpftUM/gYA7t6
                s6oAoIySSOZUcYQtdkf7i90/gG5LPhfL/GmBR6Dw5zS7qhHXQ+p2p0h9/cqmomvR
                F5H8hs1THrYMqfXC+WHH6Ddl9ncsdqpIF4S5XWZ4TfeJhTwX4TzkH+pnkkTU5BxF
                h0GgWnjTNDQnYuN3HvGR5QRFpkd19uPBcl0FY0w1F4jQTgEzuuP11iWAo+R3LuRS
                gQIDAQAB
                -----END PUBLIC KEY-----
            EOT
        }
      + name                      = "node01"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kb72eo1r5fs97a1ki"
              + name        = "root-node01"
              + size        = 50
              + snapshot_id = (known after apply)
              + type        = "network-nvme"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e9brl9jl7f9vhiki8c3q"
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 8
          + memory        = 8
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```
