//ElasticContainer Registory
resource "aws_ecr_repository" "example" {
  name = "example"

  force_delete = true
}