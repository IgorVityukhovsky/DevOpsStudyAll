# Домашнее задание к занятию "Компьютерные сети, лекция 3"

### Цель задания

В результате выполнения этого задания вы:

1. На практике познакомитесь с маршрутизацией в сетях, что позволит понять устройство больших корпоративных сетей и интернета.
2. Проверите TCP/UDP соединения на хосте (это обычный этап отладки сетевых проблем).
3. Построите сетевую диаграмму.

### Чеклист готовности к домашнему заданию

1. Убедитесь, что у вас установлен `telnet`.
2. Воспользуйтесь пакетным менеджером apt для установки.


### Инструкция к заданию

1. Создайте .md-файл для ответов на задания в своём репозитории, после выполнения прикрепите ссылку на него в личном кабинете.
2. Любые вопросы по выполнению заданий спрашивайте в чате учебной группы и/или в разделе “Вопросы по заданию” в личном кабинете.


### Инструменты/ дополнительные материалы, которые пригодятся для выполнения задания

1. [Зачем нужны dummy интерфейсы](https://tldp.org/LDP/nag/node72.html)

------

## Задание

1. Подключитесь к публичному маршрутизатору в интернет. Найдите маршрут к вашему публичному IP
```
telnet route-views.routeviews.org
Username: rviews
show ip route x.x.x.x/32
show bgp x.x.x.x/32
```
2. Создайте dummy0 интерфейс в Ubuntu. Добавьте несколько статических маршрутов. Проверьте таблицу маршрутизации.

3. Проверьте открытые TCP порты в Ubuntu, какие протоколы и приложения используют эти порты? Приведите несколько примеров.

4. Проверьте используемые UDP сокеты в Ubuntu, какие протоколы и приложения используют эти порты?

5. Используя diagrams.net, создайте L3 диаграмму вашей домашней сети или любой другой сети, с которой вы работали. 


*В качестве решения ответьте на вопросы, опишите, каким образом эти ответы были получены и приложите по неоходимости скриншоты*

 ---
 
## Задание для самостоятельной отработки* (необязательно к выполнению)

6. Установите Nginx, настройте в режиме балансировщика TCP или UDP.

7. Установите bird2, настройте динамический протокол маршрутизации RIP.

8. Установите Netbox, создайте несколько IP префиксов, используя curl проверьте работу API.

----

Вопрос:

Подключитесь к публичному маршрутизатору в интернет. Найдите маршрут к вашему публичному IP

Ответ:

telnet route-views.routeviews.org
Username: rviews
show ip route x.x.x.x/32
show bgp x.x.x.x/32

route-views>show ip route 94.50.190.2

Routing entry for 94.50.176.0/20
  Known via "bgp 6447", distance 20, metric 0
  Tag 2497, type external
  Last update from 202.232.0.2 7w0d ago
  Routing Descriptor Blocks:
  * 202.232.0.2, from 202.232.0.2, 7w0d ago
      Route metric is 0, traffic share count is 1
      AS Hops 2
      Route tag 2497
      MPLS label: none


route-views>show bgp 94.50.190.2

BGP routing table entry for 94.50.176.0/20, version 1943057829
Paths: (24 available, best #22, table default)
  Not advertised to any peer
  Refresh Epoch 1
  4901 6079 1299 12389
    162.250.137.254 from 162.250.137.254 (162.250.137.254)
      Origin IGP, localpref 100, valid, external
      Community: 65000:10100 65000:10300 65000:10400
      path 7FE006B06B20 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  7018 3356 12389
    12.0.1.63 from 12.0.1.63 (12.0.1.63)
      Origin IGP, localpref 100, valid, external
      Community: 7018:5000 7018:37232
      path 7FE0AB1E1138 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  3267 1299 12389
    194.85.40.15 from 194.85.40.15 (185.141.126.1)
      Origin IGP, metric 0, localpref 100, valid, external
      path 7FE1286B9068 RPKI State not found
      rx pathid: 0, tx pathid: 0

 ... и так далее, вывод слишком длинный



Вопрос:

Создайте dummy0 интерфейс в Ubuntu. Добавьте несколько статических маршрутов. Проверьте таблицу маршрутизации.

Ответ:

Запуск модуля

echo "dummy" > /etc/modules-load.d/dummy.conf
cho "options dummy numdummies=2" > /etc/modprobe.d/dummy.conf

Настройка интерфейса

cat << "EOF" >> /etc/systemd/network/10-dummy0.netdev

[NetDev]
Name=dummy0
Kind=dummy
EOF

cat << "EOF" >> /etc/systemd/network/20-dummy0.network

[Match]
Name=dummy0

[Network]
Address=10.0.8.1/24
EOF


systemctl restart systemd-networkd

Добавление статического маршрута

nano /etc/netplan/02-networkd.yaml

network:
  version: 2
  ethernets:
    eth0:
      optional: true
      addresses:
        - 10.0.2.3/24
      routes:
        - to: 10.0.4.0/24
          via: 10.0.2.2

Таблица маршрутизации

ip r

default via 10.0.2.2 dev eth0 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.3
10.0.2.2 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
10.0.4.0/24 via 10.0.2.2 dev eth0 proto static
10.0.8.0/24 dev dummy0 proto kernel scope link src 10.0.8.1

Статический маршрут

ip r | grep static
10.0.4.0/24 via 10.0.2.2 dev eth0 proto static



Вопрос:

Проверьте открытые TCP порты в Ubuntu, какие протоколы и приложения используют эти порты? Приведите несколько примеров.

Ответ:

ss -tnlp

State         Recv-Q        Send-Q               Local Address:Port                 Peer Address:Port        Process
LISTEN        0             4096                 127.0.0.53%lo:53                        0.0.0.0:*
LISTEN        0             128                        0.0.0.0:22                        0.0.0.0:*
LISTEN        0             128                           [::]:22                           [::]:*

22 порт используется для SSH



Вопрос:

Проверьте используемые UDP сокеты в Ubuntu, какие протоколы и приложения используют эти порты?

Ответ:

ss -unap

State         Recv-Q        Send-Q                Local Address:Port                Peer Address:Port        Process
UNCONN        0             0                     127.0.0.53%lo:53                       0.0.0.0:*
UNCONN        0             0                    10.0.2.15%eth0:68                       0.0.0.0:*

:53 - DNS
:68 - Используется клиентскими машинами для получения информации о динамической IP-адресации от DHCP-сервера



Вопрос:

Используя diagrams.net, создайте L3 диаграмму вашей домашней сети или любой другой сети, с которой вы работали.

Ответ:

https://ibb.co/R6GL6kG

