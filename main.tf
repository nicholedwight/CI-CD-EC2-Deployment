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
  ami                  = "ami-830c94e3"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.terraform_ec2_profile.name

  tags = {
    Name = "TerraformTestServerInstance"
  }
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