#------------------------ CERT-MANAGER ---------------------------------------------

locals {
  k8s_service_account_cert_manager_namespace = "kube-system"
  k8s_service_account_cert_manager_name      = "cert-manager-route53"
}

module "iam_assumable_role_cert_manager" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.8.0"
  create_role                   = true
  role_name                     = "${local.cluster_name}-cert-manager-role"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_cert_manager_namespace}:${local.k8s_service_account_cert_manager_name}"]
}

resource "aws_route53_zone" "k8s_zone" {
  name = "k8s.cert-manager"
}

resource "aws_iam_policy" "cert_manager" {
  name        = "${local.cluster_name}-cert-manager-policy"
  description = "EKS AWS Cert Manager policy for the cluster ${local.cluster_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
          "arn:aws:route53:::hostedzone/${aws_route53_zone.k8s_zone.zone_id}",
          "arn:aws:route53:::hostedzone/${var.aws_route53_hosted_zone_id}"
      ]
    }
  ]
}
EOF
}

#------------------------ EXTERNAL-DNS ---------------------------------------------

locals {
  k8s_service_account_external_dns_namespace = "external-dns"
  k8s_service_account_external_dns_name      = "external-dns"
}

module "iam_assumable_role_external_dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.2.0"
  create_role                   = true
  role_name                     = "${local.cluster_name}-external-dns-role"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_external_dns_namespace}:${local.k8s_service_account_external_dns_name}"]
}

resource "aws_iam_policy" "external_dns" {
  name        = "${local.cluster_name}-external-dns-policy"
  description = "EKS AWS ExternalDNS policy for cluster ${local.cluster_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

#------------------------ EBS-CSI DRIVER ---------------------------------------------

locals {
  ebs_csi_driver = {
    namespace            = "kube-system"
    service_account_name = "ebs-csi-controller-sa"
  }
}

resource "aws_kms_key" "kms" {
  description              = "AWS KMS key used to encrypt AWS resources."
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 7
}

module "irsa_ebs_csi_driver" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.3.0"
  create_role                   = true
  role_name                     = "${local.cluster_name}-ebs-csi-driver-role"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_driver.arn, aws_iam_policy.ebs_csi_driver_kms.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.ebs_csi_driver.namespace}:${local.ebs_csi_driver.service_account_name}"]
}

data "aws_iam_policy" "ebs_csi_driver" {
  name = "AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_policy" "ebs_csi_driver_kms" {
  name = "${local.cluster_name}-ebs-csi-driver-kms-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "${aws_kms_key.kms.arn}",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "${aws_kms_key.kms.arn}"
    }
  ]
}
EOF
}