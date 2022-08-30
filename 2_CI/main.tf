// CodeCommitリポジトリ
resource "aws_codecommit_repository" "sample" {
  repository_name = "mickros-message"
  description     = "ミクロス・メッセージ用リポジトリ"

  tags {
    Name = "sampl-repository"
  }
}

output "foooaaa" {
  value = aws_codecommit_repository.sample.clone_url_http
}

//アーティファクト用S3バケット
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "sample-buketfooooo"
}
resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

//CodePipline
resource "aws_codepipeline" "sample" {
  name = "mickros-message"

  //アーティファクト保存場所
  artifact_store {
    type      = "S3"
    localtion = aws_s3_bucket.codepipeline_bucket.bucket
  }

  //ソースステージ
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example.arn
        FullRepositoryId = "my-organization/example"
        BranchName       = "main"
      }
    }
  }

  //ビルドステージ
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "test"
      }
    }
  }
}
