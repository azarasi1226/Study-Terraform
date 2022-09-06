//コードビルド用IAMポリシー
data "aws_iam_policy_document" "codebuild" {
    statement {
        effect = "Allow"
        resources = ["*"]

        actions = [
            "s3:PutObjcet",
            "s3:GetObject",
            "s3:GetObjectVersion",

            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",

            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage",
        ]
    }
}

//コードビルドIAMロール
module "codebuild_role" {
    source = "./modules/iam_role"
    name = "codeBuild"
    identifier = "codebuild.amazonaws.com"
    policy = data.aws_iam_policy_document.codebuild.json
}

//コードビルドプロジェクト
resource "aws_codebuild_project" "example" {
    name = "example"
    service_role =  module.codebuild_role.iam_role_arn

    source {
        type = "CODEPIPELINE"
    }

    artifacts {
        type = "CODEPIPELINE"
    }

    environment {
        type = "LINUX_CONTAINER"
        compute_type = "BUILD_GENERAL1_SMALL"
        image = "aws/codebuild/standard:2.0"
        privileged_mode = true
    }
}