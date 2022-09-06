resource "aws_ssm_parameter" "db_username" {
  name = "/db/username"
  value = "root"
  type = "String"
  description = "データベースのユーザー名"
}

resource "aws_ssm_parameter" "db_raw_password"{
    name = "/db/password"
    value = "VerityStrongPassword!"
    type = "SecureString"
    description = "データベースのパスワード"
}