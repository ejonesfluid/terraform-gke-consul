data "google_client_config" "current" {
}

variable "helm_version" {
  default = "v2.15.2"
}

provider "kubernetes" {
  load_config_file = false
  host             = google_container_cluster.vault.endpoint

  cluster_ca_certificate = base64decode(
    google_container_cluster.vault.master_auth[0].cluster_ca_certificate,
  )
  token = data.google_client_config.current.access_token
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}
resource "kubernetes_service_account" "helm_account" {
  depends_on = [
    "google_container_cluster.vault",
  ]
  metadata {
    name      = var.helm_account_name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "helm_role_binding" {
  metadata {
    name = kubernetes_service_account.helm_account.metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.helm_account.metadata.0.name
    namespace = "kube-system"
  }

  provisioner "local-exec" {
    command = "sleep 15"
  }
}


provider "helm" {
  install_tiller = true
  tiller_image = "gcr.io/kubernetes-helm/tiller:${var.helm_version}"
  service_account = kubernetes_service_account.helm_account.metadata.0.name

  kubernetes {
    host                   = google_container_cluster.vault.endpoint
    token                  = data.google_client_config.current.access_token
    client_certificate     = "${base64decode(google_container_cluster.vault.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.vault.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.vault.master_auth.0.cluster_ca_certificate)}"
  }
}

resource "helm_release" "consul" {
  name      = "backend"
  chart     = "../helm/consul-helm"
  namespace = kubernetes_namespace.consul.metadata.0.name

  set {
    name  = "global.bootstrapACLs"
    value = "true"
  }

  set {
    name  = "server.connect"
    value = "true"
  }

  set {
    name  = "server.replicas"
    value = var.num_consul_pods
  }

  set {
    name  = "server.bootstrapExpect"
    value = var.num_consul_pods
  }

  set {
    name  = "connectInject.enabled"
    value = "true"
  }

  set {
    name  = "client.grpc"
    value = "true"
  }

  values = ["${file("consul_values.yaml")}"]

  depends_on = [kubernetes_cluster_role_binding.helm_role_binding]
}

resource "kubernetes_secret" "consul_certs" {
  metadata {
    name      = "consul-certs"
    namespace = kubernetes_namespace.consul.metadata.0.name
  }

  data = {
    "ca.pem"         = tls_self_signed_cert.consul-ca.cert_pem
    "consul.pem"     = tls_locally_signed_cert.consul.cert_pem
    "consul-key.pem" = tls_private_key.consul.private_key_pem
  }

  type = "Opaque"
}

resource "kubernetes_secret" "consul_gossip_key" {
  metadata {
    name      = "consul-gossip-key"
    namespace = kubernetes_namespace.consul.metadata.0.name
  }

  data = {
    gossipkey = random_id.consul_encrypt.b64_std
  }

  type = "Opaque"
}



