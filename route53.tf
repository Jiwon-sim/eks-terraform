# 서울 리전 Route53 Hosted Zone 
data "aws_route53_zone" "main" {
  zone_id = "Z09120142CD7A3RLD19TY"  # 서울 리전 Zone ID
}

# 서울 리전의 기존 ACM 인증서 참조
data "aws_acm_certificate" "main" {
  provider    = aws.seoul
  domain      = "bluesunnywings.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

# External DNS가 사용할 수 있는 로컬 변수 정의
locals {
  hosted_zone_id = data.aws_route53_zone.main.zone_id
  domain_name    = "bluesunnywings.com"
}