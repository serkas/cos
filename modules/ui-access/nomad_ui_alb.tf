## ALB -> ALB-Listener (port 80) -forwards to -> target-group (on port 4646) which is attached to the 
## AutoScalingGroup that maintains the nomad-servers.
resource "aws_alb" "alb_nomad_ui" {
  name            = "${var.stack_name}-nomad-ui${var.unique_postfix}"
  internal        = false
  subnets         = ["${var.subnet_ids}"]
  security_groups = ["${aws_security_group.sg_ui_alb.id}"]

  tags {
    Name = "${var.stack_name}-nomad-ui${var.unique_postfix}"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_nomad_ui" {
  autoscaling_group_name = "${var.nomad_server_asg_name}"
  alb_target_group_arn   = "${aws_alb_target_group.tgr_nomad_ui.arn}"
}

resource "aws_alb_target_group" "tgr_nomad_ui" {
  name_prefix = "nomad"
  port        = "${var.nomad_ui_port}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"

  health_check {
    interval            = 15
    path                = "/ui/jobs"
    port                = "${var.nomad_ui_port}"
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags {
    Name = "${var.stack_name}-nomad-ui${var.unique_postfix}"
  }
}

resource "aws_alb_listener" "albl_http_nomad_ui" {
  load_balancer_arn = "${aws_alb.alb_nomad_ui.arn}"

  #TODO: add support for https
  #protocol        = "HTTPS"
  #port            = "443"
  #certificate_arn = "${var.dummy_listener_certificate_arn}"

  protocol = "HTTP"
  port     = "80"
  default_action {
    target_group_arn = "${aws_alb_target_group.tgr_nomad_ui.arn}"
    type             = "forward"
  }
}
