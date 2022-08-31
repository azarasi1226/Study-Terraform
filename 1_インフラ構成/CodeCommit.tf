resource "aws_codecommit_repository" "example" {
    repository_name = "example"
    description = "これがCICDtてやつｗｗｗｗ"
    default_branch = "master"
}