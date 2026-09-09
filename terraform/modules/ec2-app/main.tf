resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "app_key" {
  key_name   = "${var.environment}-app-key"
  public_key = tls_private_key.app_key.public_key_openssh
}

resource "aws_security_group" "app_sg" {
  name        = "${var.environment}-app-sg"
  description = "Allow SSH and app traffic for ${var.environment}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.app_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name        = "${var.environment}-app-server"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when ${var.environment} server CPU exceeds 80%"
  dimensions = {
    InstanceId = aws_instance.app_server.id
  }
}