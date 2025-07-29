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

# kubectl 설정 명령어 (리전 수정!)
output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ap-northeast-1 update-kubeconfig --name ${module.eks.cluster_name}"
}

# ACM 인증서 정보 (서울 리전 인증서 참조)
output "acm_certificate_arn" {
  description = "ACM certificate ARN (Seoul region)"
  value       = data.aws_acm_certificate.main.arn
}

output "domain_name" {
  description = "Domain name"
  value       = "bluesunnywings.com"
}

# ALB 정보 추가
output "ingress_info" {
  description = "Instructions for accessing the application"
  value = {
    http_url  = "http://nginx.bluesunnywings.com"
    https_url = "https://nginx.bluesunnywings.com"
    note      = "DNS propagation may take a few minutes after deployment"
  }
}