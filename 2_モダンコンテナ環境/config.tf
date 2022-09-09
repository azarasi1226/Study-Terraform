terraform {
    // バックエンドにS3を使用する
    backend "s3" {
        bucket = "ecs-study-terraform-tfstate"
        region = "ap-northeast-1"
        key = "terraform.tfstate"
    }
}

//プロバイダーはaws
provider "aws" {
    region = "ap-northeast-1"
    default_tags {
      tags = {
        env = "dev"
      }
    }
}