---
clickhouse:
  hosts:
    clickhouse_RHEL:
      ansible_host: ${clickhouse-centos-ip}
      ansible_ssh_user: igor
    vector_RHEL:
      ansible_host: ${vector-centos-ip}
      ansible_ssh_user: igor
    lighthouse_UBUNTU:
      ansible_host: ${lighthouse-ubuntu-ip}
      ansible_ssh_user: igor