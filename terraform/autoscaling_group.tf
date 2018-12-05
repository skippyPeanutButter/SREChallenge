resource "aws_autoscaling_group" "webserver_asg" {
  launch_configuration = "${aws_launch_configuration.webserver_launch_config.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  load_balancers = ["${aws_elb.webserver_elb.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "webserver_asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "webserver_asg_policy" {
  name                   = "webserver-asg-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.webserver_asg.name}"
}
