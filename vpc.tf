## https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/datasource_dataproc_cluster
## https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/dataproc_cluster

resource "yandex_dataproc_cluster" "foo" {
  depends_on = [yandex_resourcemanager_folder_iam_binding.dataproc]

  bucket      = yandex_storage_bucket.foo.bucket
  description = "Dataproc Cluster created by Terraform"
  name        = "dataproc-cluster"
  labels = {
    created_by = "terraform"
  }
  service_account_id = yandex_iam_service_account.dataproc.id
  zone_id            = "ru-central1-a"

  cluster_config {
    # Certain cluster version can be set, but better to use default value (last stable version)
    # version_id = "2.0"

    hadoop {
      #services = ["HDFS", "YARN", "SPARK", "TEZ", "MAPREDUCE", "HIVE"]
      services = ["HDFS", "YARN", "SPARK"]
      properties = {
        "yarn:yarn.resourcemanager.am.max-attempts" = 5
      }
      ssh_public_keys = [
      file("id_ed25519.pub")]
    }

    subcluster_spec {
      name = "main"
      role = "MASTERNODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = yandex_vpc_subnet.dataproc-control-subnet.id
      hosts_count = 1
    }

    subcluster_spec {
      name = "data"
      role = "DATANODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = yandex_vpc_subnet.dataproc-control-subnet.id
      hosts_count = 2
    }

    subcluster_spec {
      name = "compute"
      role = "COMPUTENODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = yandex_vpc_subnet.dataproc-control-subnet.id
      hosts_count = 2
    }

    subcluster_spec {
      name = "compute_autoscaling"
      role = "COMPUTENODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = yandex_vpc_subnet.dataproc-control-subnet.id
      hosts_count = 2      
      autoscaling_config {
        max_hosts_count = 10
        measurement_duration = 60
        warmup_duration = 60
        stabilization_duration = 120
        preemptible = false
        decommission_timeout = 60
      }
    }
  }
}

resource "yandex_vpc_network" "dataproc-net" {
  name = "dataproc-net"
}

resource "yandex_vpc_gateway" "dataproc-gateway" {
  name  = "dataproc-gateway"
}

resource "yandex_vpc_route_table" "dataproc-route-table" {
  name        = "dataproc-route-table"
  network_id = yandex_vpc_network.dataproc-net.id
  static_route { 
    destination_prefix= "0.0.0.0/0"
    gateway_id=yandex_vpc_gateway.dataproc-gateway.id
  }
}


resource "yandex_vpc_subnet" "dataproc-control-subnet" {

  name             = "dataproc-control-subnet"
  zone             = "ru-central1-a"
  network_id       = yandex_vpc_network.dataproc-net.id
  v4_cidr_blocks   = ["10.1.0.0/24"]
  route_table_id = yandex_vpc_route_table.dataproc-route-table.id
}

resource "yandex_iam_service_account" "dataproc" {
  name        = "dataproc-svc-acc"
  description = "service account to manage Dataproc Cluster"
}

data "yandex_resourcemanager_folder" "foo" {
  folder_id = "b1goq1sgaqo50ok2drfn"
}

resource "yandex_resourcemanager_folder_iam_binding" "dataproc" {
  folder_id = data.yandex_resourcemanager_folder.foo.id
  role      = "dataproc.agent"
  members = [
    "serviceAccount:${yandex_iam_service_account.dataproc.id}",
  ]
}

// required in order to create bucket
resource "yandex_resourcemanager_folder_iam_binding" "bucket-creator" {
  folder_id = data.yandex_resourcemanager_folder.foo.id
  role      = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.dataproc.id}",
  ]
}

resource "yandex_iam_service_account_static_access_key" "foo" {
  service_account_id = yandex_iam_service_account.dataproc.id
}

resource "yandex_storage_bucket" "foo" {
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.bucket-creator
  ]

  bucket     = "dataproc-shared-bucket"
  access_key = yandex_iam_service_account_static_access_key.foo.access_key
  secret_key = yandex_iam_service_account_static_access_key.foo.secret_key
}

