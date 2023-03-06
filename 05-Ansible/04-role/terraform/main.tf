resource "yandex_compute_instance" "centos" {
  count = 2
  name  = element(var.CentOS_names, count.index)

  resources {
    cores  = 2
    memory = 2
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  boot_disk {
    initialize_params {
      image_id = "fd816jiq3n13qtli6fh3" #centos 
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.lab-subnet-a.id
    nat       = true
  }
}

resource "yandex_compute_instance" "ubuntu" {
  name = "lighthouse-ubuntu"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8smb7fj0o91i68s15v" #ubuntu
    }
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.lab-subnet-a.id
    nat       = true
  }
}