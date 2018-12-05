resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "Webserver cpu utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.webserver_asg.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.webserver_asg_policy.arn}"]
}
