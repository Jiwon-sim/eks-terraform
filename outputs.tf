# EKS 클러스터 정보
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

# Route53 정보
output "route53_zone_id" {
  description = "Route53 Hosted Zone ID for External DNS"
  value       = aws_route53_zone.main.zone_id
}

output "route53_zone_name" {
  description = "Route53 Hosted Zone Name"
  value       = aws_route53_zone.main.name
}

output "route53_name_servers" {
  description = "Route53 Name Servers (도메인 등록업체에서 설정 필요)"
  value       = aws_route53_zone.main.name_servers
}

# External DNS 정보
output "external_dns_service_account_arn" {
  description = "External DNS Service Account ARN"
  value       = kubernetes_service_account.external_dns.metadata[0].annotations["eks.amazonaws.com/role-arn"]
}

output "external_dns_iam_role_arn" {
  description = "External DNS IAM Role ARN"
  value       = aws_iam_role.external_dns.arn
}

# 설정 확인용 정보
output "domain_configuration" {
  description = "External DNS 도메인 설정 정보"
  value = {
    domain_name    = local.domain_name
    hosted_zone_id = local.hosted_zone_id
    txt_owner_id   = local.hosted_zone_id
  }
}