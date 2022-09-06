// ECSクラスタ
resource "aws_ecs_cluster" "example" {
    name = "example"
}

// IAMポリシーデーターソース(AWS管理ポリシー))
data "aws_iam_policy" "ecs_task_execution_role_policy" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
} 

//↑のポリシーを継承して新たなポリシーを作成
data "aws_iam_policy_document" "ecs_task_execution" {
    source_policy_documents = [data.aws_iam_policy.ecs_task_execution_role_policy.policy]

    statement {
      effect = "Allow"
      actions = ["ssm:GetParameters", "kms:Decrypt"]
      resources = ["*"]
    }
}

//↑で作ったポリシードキュメントを元にロール作成
module "ecs_task_execution_role" {
    source = "./modules/iam_role"
    name = "ecs-task-execution"
    identifier = "ecs-tasks.amazonaws.com"
    policy = data.aws_iam_policy_document.ecs_task_execution.json
}

// タスク定義
resource "aws_ecs_task_definition" "example"{
    // タスクのプレフィックス名でこれにバージョン番号がつくとタスク名となる
    family = "example"
    cpu  = "256"
    memory = "512"
    //Fargateの場合ネットワークモードは固定される
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    container_definitions = file("./container_definitions.json")

    execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

//サービスに割り当てるセキュリティーグループ
module "nginx_sg" {
    source = "./modules/security_group"
    name = "nginx-sg"
    vpc_id = aws_vpc.example.id
    port = 80
    cidr_blocks = [aws_vpc.example.cidr_block]
}

//サービス
resource "aws_ecs_service" "example" {
    name = "example"
    cluster = aws_ecs_cluster.example.arn
    task_definition = aws_ecs_task_definition.example.arn
    //Taskの同時期同数、本番環境では２以上が推奨
    desired_count = 3
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