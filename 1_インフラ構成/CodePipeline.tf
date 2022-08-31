data "aws_iam_policy_document" "codepipeline" {
    statement {
        effect = "Allow"
        resources = ["*"]

        actions = [
            "s3:*",
            "codebuild:*",
            "ecs:*",
            "iam:PassRole",
        ]
    }
}

//コードパイプラインRole
module "codepipeline_role" {
    source = "./modules/iam_role"
    name  = "codepipeline"
    identifier = "codepipeline.amazonaws.com"
    policy = data.aws_iam_policy_document.codepipeline.json
}

//コードパイプライン
resource "aws_codepipeline" "example" {
    name = "example"
    role_arn = module.codepipeline_role.iam_role_arn

    artifact_store {
        //ここ大文字にしないとだめとか罠すぎるだろ
        type = "S3"
        location = aws_s3_bucket.artifact.bucket
    }

    stage {
        name = "Source"

        action {
            name = "Source"
            category = "Source"
            owner = "AWS"
            provider = "CodeCommit"
            version = 1
            output_artifacts = ["Source"]

            configuration = {
                RepositoryName = aws_codecommit_repository.example.repository_name
                BranchName  = "master"
            }
        }
    }

    stage {
        name = "Build"

        action {
            name = "Build"
            category = "Build"
            owner = "AWS"
            provider = "CodeBuild"
            version = 1
            input_artifacts = ["Source"]
            output_artifacts = ["Build"]

            configuration = {
                RepositoryName = aws_codebuild_project.example.id
            }
        }
    }

    stage {
        name = "Deploy"

        action {
            name = "Deploy"
            category = "Deploy"
            owner = "AWS"
            provider = "ECS"
            version = 1
            input_artifacts = ["Build"]

            configuration = {
                ClusterName = aws_ecs_cluster.example.name
                ServiceName = aws_ecs_service.example.name
                FileName = "imagedefinitions.json"
            }
        }
    }
}