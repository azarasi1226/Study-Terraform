// ALBのログ保管用S3バケット
resource "aws_s3_bucket" "alb_log" {
  bucket        = "alb-log-andoukazuki-terraform"

  //中にアイテムが残ってても消す設定。これがないとterraform destoryできなくなるよ
  force_destroy = true
}

// S3バケットに保存するアイテムのライフサイクル
resource "aws_s3_bucket_lifecycle_configuration" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id

  //180日デリソソースが消えるように
  rule {
    id     = "alb-log-lifecycle"
    status = "Enabled"
    expiration {
      days = "180"
    }
  }
}

// S3に付与するリソースポリシー(ELBからのAccessを許可する)
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
    principals {
      type = "AWS"
      // 東京リージョンの番号
      identifiers = ["582318560864"]
    }
  }
}

//リソースポリシーの紐づけ
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}


//CI/CDに使用するアーティファクトストア
resource "aws_s3_bucket" "artifact" {
  bucket = "artifact-andoukazuki-terraform"
}

// S3バケットに保存するアイテムのライフサイクル
resource "aws_s3_bucket_lifecycle_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  //180日デリソソースが消えるように
  rule {
    id     = "alb-log-lifecycle"
    status = "Enabled"
    expiration {
      days = "180"
    }
  }
}