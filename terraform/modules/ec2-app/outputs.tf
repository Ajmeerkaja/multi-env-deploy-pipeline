output "public_ip" {
  value = aws_instance.app_server.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.app_key.private_key_pem
  sensitive = true
}