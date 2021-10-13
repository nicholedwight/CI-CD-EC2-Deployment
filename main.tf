terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_iam_instance_profile" "terraform_ec2_profile" {
  name = "terraform_ec2_profile"
  role = aws_iam_role.terraform_ec2_role.name
}

resource "aws_instance" "terraform_app_server" {
  ami                    = "ami-013a129d325529d4d"
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.terraform_ec2_profile.name
  key_name               = "terraform_pub_key"
  vpc_security_group_ids = [aws_security_group.main.id]

  provisioner "remote-exec" {
    inline = [
      "touch hello.txt",
      "sudo yum update -y",
      "echo installing ruby",
      "sudo yum install -y ruby",
      "sudo yum update httpd",
      "sudo yum install httpd",
      "sudo systemctl start httpd",
      "echo installing wget",
      "sudo yum install wget",
      "wget https://aws-codedeploy-us-west-2.s3.us-west-2.amazonaws.com/latest/install",
      "chmod +x ./install",
      "sudo ./install auto",
      "echo starting codedeploy",
      "sudo service codedeploy-agent start"
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("/home/nichole/.ssh/id_rsa_terraformtest2")
    timeout     = "4m"
  }

  tags = {
    Name        = "TerraformTestServerInstance",
    development = ""
  }
}

resource "aws_key_pair" "terraform_pub_key" {
  key_name   = "terraform_pub_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCurZoSkZsNU0HwT31Bw+I7ltgyQgpUtJmcFwr/KK/k/HbvF1iEsDnoyptriX14Kt4iPpNc5FNFUDb2x5u76wbxIRPDi2aPibDWH8t9f1saWxlrrOfpEAsDqqYrrGO9KVCdu7t/7wZ73Cc9jS0lDDoYJGtVuy3C8C8Z5ExY6xbayj6iv4o+bh8h4MrwowQN+j+cAfb8+ys9eW1JLo6dIuWqmWI1SKTAzpaQlwx8gkZCieh5/wBsycpHjMt7aEn9b+Z3Co4rJOesAuCHPF76YiJ35qym27ogem76WUT43pe2ZmihlCUgrGPN6Il4JrBnlayQ7Qrt1BX3jj/UB5XFlIwdP2f0MbVkA9rPwlv28AeCLfoCn0PJFGms/GQ5vI9sns17KfpHGqIx5NDON0854Lg5vdprahnOPjQ4r6KDBiWr5k9H7TvzWtrnJu72Z/ipJlQfdBVCtNqO3SwrDqC5sspHv3MUnFxVSQvK/Fnyf3ktLkoJE2RZ+1UyDi9ya6pSeg/LJklgcBSpmeDRgc7bBY6Lsy2BfsTUacoO7xwIXFZJ8gkVnzilRxP9B9592nREU2NEiDHtxFqXWGV7Aj6nY4nHSmNdN4c8tl9OEC2NnrF0fizCdhglliTUkqOncqPysYMmQGxSHobnjbWWo1abZmSL0ERB6Ldk4iv9Ya60PPKD5w== nicholedwight@gmail.com"
}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
}

resource "aws_iam_policy" "terraform_ec2_policy" {
  name        = "terraform-ec2-policy"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role" "terraform_ec2_role" {
  name = "terraform_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "test"
        Principal = {
          Service = ["ec2.amazonaws.com"]
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.terraform_ec2_role.name
  policy_arn = aws_iam_policy.terraform_ec2_policy.arn
}

data "aws_iam_policy_document" "terraform_codedeploy_policy" {
  statement {
    actions = [
      "*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "elasticloadbalancing:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "cloudwatch:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "autoscaling:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "codedeploy:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"

      values = [
        "autoscaling.amazonaws.com",
        "ec2scheduled.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "spot.amazonaws.com",
        "spotfleet.amazonaws.com",
        "transitgateway.amazonaws.com"
      ]
    }
  }

  statement {
    sid = "CodeStarNotificationsReadWriteAccess"

    actions = [
      "codestar-notifications:CreateNotificationRule",
      "codestar-notifications:DescribeNotificationRule",
      "codestar-notifications:UpdateNotificationRule",
      "codestar-notifications:DeleteNotificationRule",
      "codestar-notifications:Subscribe",
      "codestar-notifications:Unsubscribe"
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringLike"
      variable = "codestar-notifications:NotificationsForResourc"

      values = [
        "arn:aws:codedeploy:*"
      ]
    }
  }

  statement {
    sid = "CodeStarNotificationsListAccess"

    actions = [
      "codestar-notifications:ListNotificationRules",
      "codestar-notifications:ListTargets",
      "codestar-notifications:ListTagsforResource",
      "codestar-notifications:ListEventTypes"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "CodeStarNotificationsSNSTopicCreateAccess"

    actions = [
      "sns:CreateTopic",
      "sns:SetTopicAttributes"
    ]

    resources = [
      "arn:aws:sns:*:*:codestar-notifications*",
    ]
  }

  statement {
    sid = "CodeStarNotificationsChatbotAccess"

    actions = [
      "chatbot:DescribeSlackChannelConfigurations"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "SNSTopicListAccess"

    actions = [
      "sns:ListTopics"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DeleteLifecycleHook",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:PutLifecycleHook",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:EnableMetricsCollection",
      "autoscaling:DescribePolicies",
      "autoscaling:DescribeScheduledActions",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:SuspendProcesses",
      "autoscaling:ResumeProcesses",
      "autoscaling:AttachLoadBalancers",
      "autoscaling:AttachLoadBalancerTargetGroups",
      "autoscaling:PutScalingPolicy",
      "autoscaling:PutScheduledUpdateGroupAction",
      "autoscaling:PutNotificationConfiguration",
      "autoscaling:PutWarmPool",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DeleteAutoScalingGroup",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:TerminateInstances",
      "tag:GetResources",
      "sns:Publish",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]

    resources = [
      "*",
    ]
  }

}

resource "aws_iam_policy" "terraform_codedeploy_policy" {
  name   = "terraform-codedeploy-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.terraform_codedeploy_policy.json
}

resource "aws_iam_role" "terraform_codedeploy_role" {
  name = "terraform_codedeploy_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "test"
        Principal = {
          Service = ["codedeploy.amazonaws.com"]
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy-attach" {
  role       = aws_iam_role.terraform_codedeploy_role.name
  policy_arn = aws_iam_policy.terraform_codedeploy_policy.arn
}

resource "aws_codedeploy_app" "terraform_git_app" {
  compute_platform = "Server"
  name             = "Terraform_Git_Application"
}

resource "aws_sns_topic" "terraform_sns" {
  name = "example-topic"
}

resource "aws_codedeploy_deployment_group" "terraform_deployment_group" {
  app_name              = aws_codedeploy_app.terraform_git_app.name
  deployment_group_name = "example-group"
  service_role_arn      = aws_iam_role.terraform_codedeploy_role.arn

  ec2_tag_filter {
    key  = "development"
    type = "KEY_ONLY"
  }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "example-trigger"
    trigger_target_arn = aws_sns_topic.terraform_sns.arn
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["my-alarm-name"]
    enabled = true
  }
}