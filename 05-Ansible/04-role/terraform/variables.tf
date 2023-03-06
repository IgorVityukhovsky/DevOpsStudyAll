variable "CentOS_names" {
  type    = list(any)
  default = ["clickhouse-centos", "vector-centos"]
}

variable "ssh_user" {
  default = "igor"
}
