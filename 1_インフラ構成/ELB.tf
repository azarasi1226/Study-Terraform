// アプリケーションロードバランサー
resource "aws_lb" "example" {
  name               = "example"
  load_balancer_type = "application"
  // インターネット向けなおかVPC内部(internal)向けなのか
  internal = false
  //タイムアウト時間(なんの？)
  idle_timeout = 60

  //削除保護。本番環境でミスって消さないように
  //ただこれつけるとinternet-gateway消せなくてdestoryできなくなったんだがｗｗｗ
  //enable_deletion_protection = true

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
  source      = "./modules/security_group"
  name        = "https_sg"
  vpc_id      = aws_vpc.example.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./modules/security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.example.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}


// ターゲットグループ(ECSのサービスと紐づけるよ)
resource "aws_lb_target_group" "example" {
  name = "example"
  target_type = "ip"
  vpc_id = aws_vpc.example.id
  port = 80
  protocol = "HTTP"
  deregistration_delay = 300

  health_check {
    path = "/"
    // 正常判定までの回数
    healthy_threshold = 5
    //異状判定までの回数
    unhealthy_threshold = 2
    // ヘルスチェックのタイムアウト
    timeout = 5
    //送信回数
    interval = 30
    //正常判定に使うステータスコード
    matcher = 200
    port = "traffic-port"
    protocol = "HTTP"
  }

  depends_on = [
    aws_lb.example
  ]
}

// Httpリスナー
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}