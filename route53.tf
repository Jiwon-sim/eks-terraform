# Route53 Hosted Zone 생성
resource "aws_route53_zone" "main" {
  name = "bluesunnywings.com"

  tags = {
    Name = "EKS External DNS Zone"
    Environment = "production"
  }
}

# External DNS가 사용할 수 있는 Hosted Zone 정보를 로컬 변수로 정의
locals {
  hosted_zone_id = aws_route53_zone.main.zone_id
  domain_name    = "bluesunnywings.com"
}