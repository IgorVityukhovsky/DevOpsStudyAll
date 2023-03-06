data "template_file" "inventary" {
  template = "${file("./template-inventary.yml.tpl")}"
  
  vars = {
    clickhouse-centos-ip = "${yandex_compute_instance.centos[0].network_interface[0].nat_ip_address}"
    vector-centos-ip = "${yandex_compute_instance.centos[1].network_interface[0].nat_ip_address}"
    lighthouse-ubuntu-ip = "${yandex_compute_instance.ubuntu.network_interface[0].nat_ip_address}"
  }
}

resource "null_resource" "dev-hosts" {
  triggers = {
    template_rendered = "${data.template_file.inventary.rendered}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.inventary.rendered}' > inventary.yml"
}
  }