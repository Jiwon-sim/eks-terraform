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
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_zone_name" {
  description = "Route53 Hosted Zone Name"
  value       = data.aws_route53_zone.main.name
}

output "route53_name_servers" {
  description = "Route53 Name Servers (도메인 등록업체에서 설정 필요)"
  value       = data.aws_route53_zone.main.name_servers
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ap-northeast-2 update-kubeconfig --name ${module.eks.cluster_name}"
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}

output "domain_name" {
  description = "Domain name"
  value       = data.aws_route53_zone.main.name
}