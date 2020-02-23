#### Generate self-signed TLS certificates for Consul

resource "tls_private_key" "consul-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "consul-ca" {
  key_algorithm   = tls_private_key.consul-ca.algorithm
  private_key_pem = tls_private_key.consul-ca.private_key_pem

  subject {
    common_name  = "consul-ca.local"
    organization = "Arctiq"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

# Create the Consul certificates
resource "tls_private_key" "consul" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

# Create the request to sign the cert with our CA
resource "tls_cert_request" "consul-req" {
  key_algorithm   = tls_private_key.consul.algorithm
  private_key_pem = tls_private_key.consul.private_key_pem

  dns_names = [
    "consul",
    "consul.local",
    "consul.default.svc.cluster.local",
    "server.dc1.consul",
  ]

  ip_addresses = [
    google_compute_address.vault.address,
  ]

  subject {
    common_name  = "consul.local"
    organization = "Arctiq"
  }
}

# Now sign the cert
resource "tls_locally_signed_cert" "consul" {
  cert_request_pem = tls_cert_request.consul-req.cert_request_pem

  ca_key_algorithm   = tls_private_key.consul-ca.algorithm
  ca_private_key_pem = tls_private_key.consul-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul-ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "random_id" "consul_encrypt" {
  byte_length = 16
}


