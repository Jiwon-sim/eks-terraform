# External DNS 문제 해결을 위한 추가 리소스

# External DNS 배포 상태 확인을 위한 출력
output "external_dns_service_account_arn" {
  description = "External DNS Service Account ARN"
  value       = kubernetes_service_account.external_dns.metadata[0].annotations["eks.amazonaws.com/role-arn"]
}

output "external_dns_iam_role_arn" {
  description = "External DNS IAM Role ARN"
  value       = aws_iam_role.external_dns.arn
}

output "hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = local.hosted_zone_id
}

output "domain_name" {
  description = "Domain name for External DNS"
  value       = local.domain_name
}

# External DNS 로그 확인을 위한 CloudWatch Log Group (선택사항)
resource "aws_cloudwatch_log_group" "external_dns" {
  name              = "/aws/eks/${module.eks.cluster_name}/external-dns"
  retention_in_days = 7

  tags = {
    Name = "External DNS Logs"
  }
}

# External DNS 배포 확인을 위한 Kubernetes 매니페스트 (디버깅용)
resource "kubernetes_config_map" "external_dns_debug" {
  metadata {
    name      = "external-dns-debug"
    namespace = "kube-system"
  }

  data = {
    "check-external-dns.sh" = <<-EOF
      #!/bin/bash
      echo "=== External DNS 상태 확인 ==="
      kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns
      echo ""
      echo "=== External DNS 로그 확인 ==="
      kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns --tail=50
      echo ""
      echo "=== Service Account 확인 ==="
      kubectl get sa external-dns -n kube-system -o yaml
      echo ""
      echo "=== IAM Role 확인 ==="
      kubectl describe sa external-dns -n kube-system
    EOF
  }
}