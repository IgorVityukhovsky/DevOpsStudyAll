Вопрос: 

Узнайте о sparse (разряженных) файлах.

Ответ:

Ознакомился. В принципе подобным образом представлял себе сжатые файлы



Вопрос: 

Могут ли файлы, являющиеся жесткой ссылкой на один объект, иметь разные права доступа и владельца? Почему?

Ответ:

hardlink будет ссылаться на один и тот же объект с одним и тем же inode, потому права будут одни и теже



Вопрос: 

Сделайте vagrant destroy на имеющийся инстанс Ubuntu. Замените содержимое Vagrantfile:

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.provider :virtualbox do |vb|
    lvm_experiments_disk0_path = "/tmp/lvm_experiments_disk0.vmdk"
    lvm_experiments_disk1_path = "/tmp/lvm_experiments_disk1.vmdk"
    vb.customize ['createmedium', '--filename', lvm_experiments_disk0_path, '--size', 2560]
    vb.customize ['createmedium', '--filename', lvm_experiments_disk1_path, '--size', 2560]
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', lvm_experiments_disk0_path]
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', lvm_experiments_disk1_path]
  end
end

Ответ:

Сделано:

lsblk

...
sdb                         8:16   0  2.5G  0 disk
sdc                         8:32   0  2.5G  0 disk



Вопрос: 

Используя fdisk, разбейте первый диск на 2 раздела: 2 Гб, оставшееся пространство.

Ответ:

fdisk /dev/sdb     #работаем с диском b, команда начнёт работать в интерактивном режиме
g                  #будем использовать стандарт GPT
n                  #новый раздел
enter              #оставляем значение по умолчанию
enter              #оставляем значение по умолчанию
+2G                #добавляем в новый раздел 2 гигабайта

Created a new partition 1 of type 'Linux filesystem' and of size 2 GiB.

n
enter
enter
enter              #оставляем третье значение по умолчанию, что бы разметилось всё остальное пространство

Created a new partition 2 of type 'Linux filesystem' and of size 511 MiB.

p                  #что бы увидеть результат

Device       Start     End Sectors  Size Type
/dev/sdb1     2048 4196351 4194304    2G Linux filesystem
/dev/sdb2  4196352 5242846 1046495  511M Linux filesystem


w                  #записать изменения и выйти



Вопрос: 

Используя sfdisk, перенесите данную таблицу разделов на второй диск.

Ответ:

sudo sfdisk -d /dev/sdb|sudo sfdisk --force /dev/sdc

...
Device       Start     End Sectors  Size Type
/dev/sdc1     2048 4196351 4194304    2G Linux filesystem
/dev/sdc2  4196352 5242846 1046495  511M Linux filesystem



Вопрос: 

Соберите mdadm RAID1 на паре разделов 2 Гб.

Ответ:

sudo mdadm --create --verbose /dev/md1 -l 1 -n 2 /dev/sd{b1,c1}

...
mdadm: array /dev/md1 started.



Вопрос: 

Соберите mdadm RAID0 на второй паре маленьких разделов.

Ответ:

sudo mdadm --create --verbose /dev/md0 -l 1 -n 2 /dev/sd{b2,c2}

...
mdadm: array /dev/md0 started.



Вопрос: 

Создайте 2 независимых PV на получившихся md-устройствах.

Ответ:

sudo pvcreate /dev/md1 /dev/md0
  Physical volume "/dev/md1" successfully created.
  Physical volume "/dev/md0" successfully created.



Вопрос: 

Создайте общую volume-group на этих двух PV.

Ответ:

sudo vgcreate my_vol_gr /dev/md1 /dev/md0

Volume group "my_vol_gr" successfully created

sudo vgdisplay

--- Volume group ---
  VG Name               my_vol_gr
  System ID
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               2.49 GiB
  PE Size               4.00 MiB
  Total PE              638
  Alloc PE / Size       0 / 0
  Free  PE / Size       638 / 2.49 GiB
  VG UUID               G5ACu4-TeJk-yoRc-pSGU-tYs3-JAGa-D4yY0n



Вопрос: 

Создайте LV размером 100 Мб, указав его расположение на PV с RAID0.

Ответ:

sudo lvcreate -L 100M my_vol_gr /dev/md0
Logical volume "lvol0" created

sudo vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  my_vol_gr   2   1   0 wz--n-   2.49g  2.39g
  ubuntu-vg   1   1   0 wz--n- <62.50g 31.25g


sudo lvs
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lvol0     my_vol_gr -wi-a----- 100.00m
  ubuntu-lv ubuntu-vg -wi-ao---- <31.25g



Вопрос: 

Создайте mkfs.ext4 ФС на получившемся LV

Ответ:

sudo mkfs.ext4 /dev/my_vol_gr/lvol0

mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 25600 4k blocks and 25600 inodes

Allocating group tables: done
Writing inode tables: done
Creating journal (1024 blocks): done
Writing superblocks and filesystem accounting information: done



Вопрос: 

Смонтируйте этот раздел в любую директорию, например, /tmp/new

Ответ:

mkdir /tmp/new
sudo mount /dev/my_vol_gr/lvol0 /tmp/new



Вопрос: 

Поместите туда тестовый файл, например wget https://mirror.yandex.ru/ubuntu/ls-lR.gz -O /tmp/new/test.gz

Ответ:

sudo wget https://mirror.yandex.ru/ubuntu/ls-lR.gz -O /tmp/new/test.gz.

--2022-07-01 17:39:57--  https://mirror.yandex.ru/ubuntu/ls-lR.gz
Resolving mirror.yandex.ru (mirror.yandex.ru)... 213.180.204.183, 2a02:6b8::183
Connecting to mirror.yandex.ru (mirror.yandex.ru)|213.180.204.183|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 23758732 (23M) [application/octet-stream]
Saving to: ‘/tmp/new/test.gz.’

/tmp/new/test.gz.              100%[====================================================>]  22.66M  19.8MB/s    in 1.1s

2022-07-01 17:39:59 (19.8 MB/s) - ‘/tmp/new/test.gz.’ saved [23758732/23758732]



Вопрос: 

Прикрепите вывод lsblk

Ответ:

vagrant@vagrant:~$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
loop0                       7:0    0 61.9M  1 loop  /snap/core20/1328
loop1                       7:1    0 67.2M  1 loop  /snap/lxd/21835
loop2                       7:2    0 43.6M  1 loop  /snap/snapd/14978
loop3                       7:3    0   47M  1 loop  /snap/snapd/16010
loop4                       7:4    0 61.9M  1 loop  /snap/core20/1518
loop5                       7:5    0 67.8M  1 loop  /snap/lxd/22753
sda                         8:0    0   64G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.5G  0 part  /boot
└─sda3                      8:3    0 62.5G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0 31.3G  0 lvm   /
sdb                         8:16   0  2.5G  0 disk
├─sdb1                      8:17   0    2G  0 part
│ └─md1                     9:1    0    2G  0 raid1
└─sdb2                      8:18   0  511M  0 part
  └─md0                     9:0    0  510M  0 raid1
    └─my_vol_gr-lvol0     253:1    0  100M  0 lvm   /tmp/new
sdc                         8:32   0  2.5G  0 disk
├─sdc1                      8:33   0    2G  0 part
│ └─md1                     9:1    0    2G  0 raid1
└─sdc2                      8:34   0  511M  0 part
  └─md0                     9:0    0  510M  0 raid1
    └─my_vol_gr-lvol0     253:1    0  100M  0 lvm   /tmp/new



Вопрос: 

Протестируйте целостность файла

Ответ:

vagrant@vagrant:~$ gzip -t /tmp/new/test.gz. && echo $?   #случайно назвал конечный файл с точкой =)
0



Вопрос: 

Используя pvmove, переместите содержимое PV с RAID0 на RAID1

Ответ:

sudo pvmove /dev/md0

  /dev/md0: Moved: 100.00%



Вопрос: 

Сделайте --fail на устройство в вашем RAID1 md

Ответ:

sudo mdadm /dev/md1 --fail /dev/sdb1
mdadm: set /dev/sdb1 faulty in /dev/md1



Вопрос: 

Подтвердите выводом dmesg, что RAID1 работает в деградированном состоянии.

Ответ:

dmesg |grep md1
[ 2749.117350] md/raid1:md1: not clean -- starting background reconstruction
[ 2749.117351] md/raid1:md1: active with 2 out of 2 mirrors
[ 2749.117377] md1: detected capacity change from 0 to 2144337920
[ 2749.122477] md: resync of RAID array md1
[ 2759.956916] md: md1: resync done.
[16832.422307] md/raid1:md1: Disk failure on sdb1, disabling device.
               md/raid1:md1: Operation continuing on 1 devices.



Вопрос: 

Протестируйте целостность файла, несмотря на "сбойный" диск он должен продолжать быть доступен

Ответ:

gzip -t /tmp/new/test.gz. && echo $?
0



Вопрос: 

Погасите тестовый хост, vagrant destroy.

Ответ:

выполнено



