// アプリケーションロードバランサー
resource "aws_lb" "example" {
  name               = "example"
  load_balancer_type = "application"
  // インターネット向けなおかVPC内部(internal)向けなのか
  internal = false
  //タイムアウト時間(なんの？)
  idle_timeout = 60

  //削除保護。本番環境でミスって消さないように
  enable_deletion_protection = true

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id
  ]
}

module "http_sg" {
  source      = "./modules/security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source = "./modules/security_group"
  name   = "https_sg"
  vpc_id = aws_vpc.example.id
  port   = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
    source = "./modules/security_group"
    name = "http-redirect-sg"
    vpc_id = aws_vpc.example.id
    port = 8080
    cidr_blocks = ["0.0.0.0/0"]
}

// Httpリスナー
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = "80"
    protocol = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "これは「HTTP」です"
        status_code = "200"
      }
    }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}