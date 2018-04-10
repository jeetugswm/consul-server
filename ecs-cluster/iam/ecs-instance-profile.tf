resource "aws_iam_instance_profile" "ecs-instance-profile" {
    name = "ecs-instance-profilea"
    path = "/"
    role = "${aws_iam_role.ecs-instance-role.name}"
}

output "ecs-instance-profile-name" {
  value = "${aws_iam_instance_profile.ecs-instance-profile.name}"
}
