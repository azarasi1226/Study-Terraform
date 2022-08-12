// クラスタ
resource "aws_ecs_cluster" "example" {
    name = "example"
}

// タスク定義
resource "aws_ecs_task_definition" "example"{
    // タスクのプレフィックス名でこれにバージョン番号がつくとタスク名となる
    family = "example"
    cpu  = "256"
    memory = "512"
    //Fargateの場合固定される
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    container_definitions = file("./container_definitions.json")
}

//サービス
resource "aws_ecs_service" "example" {
    name = "example"
    cluster = aws_ecs_cluster.example.arn
    task_definition = aws_ecs_task_definition.example.arn
    //Taskの同時期同数、本番環境では２以上が推奨
    desired_count = 2
    launch_type = "FARGATE"
    platform_version = "1.4.0"

    //タスク起動時のヘルスチェック猶予期間。
    //デフォルトが0のためTaskの起動に時間がかかると、そのTaskが再起動される。つまり無限ループ！！！！
    health_check_grace_period_seconds = 60

    network_configuration {
        // ロードバランサー経由でアクセスするからいらんよね
        assign_public_ip = false
        security_groups = [module.nginx_sg.security_group_id]
        subnets = [
            aws_subnet.private_1.id,
            aws_subnet.private_2.id,
        ]
    }

    load_balancer {
      target_group_arn = aws_lb_target_group.example.arn
      container_name = "example"
      container_port = 80
    }

    lifecycle {
      ignore_changes = [task_definition]
    }
}

module "nginx_sg" {
    source = "./modules/security_group"
    name = "nginx-sg"
    vpc_id = aws_vpc.example.id
    port = 80
    cidr_blocks = [aws_vpc.example.cidr_block]
}