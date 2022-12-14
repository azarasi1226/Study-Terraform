variable "name" {
  description = "セキュリティーグループ名"
  type = string
}
variable "vpc_id" {
  description = "VPC_ID"
  type = string
}
variable "port" {
  description = "接続を許可するポート番号"
  type = number
}
variable "cidr_blocks" {
  description = "接続を許可するIPアドレスリスト"
  type = list(string)
}

// セキュリティグループ
resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = var.vpc_id

  tags = {
    Name = var.name
  }
}

// インバウンドルール
resource "aws_security_group_rule" "ingress_example" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks
  security_group_id = aws_security_group.default.id
}

// アウトバウンドルール(すべての通信OK)
resource "aws_security_group_rule" "egress_example" {
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

output "security_group_id" {
  value = aws_security_group.default.id
}
