# 팀원의 기존 Route53 Hosted Zone 참조 (글로벌 리소스)
data "aws_route53_zone" "main" {
  zone_id = "Z09120142CD7A3RLD19TY"  # 팀원의 첫 번째 Zone
}

# 도쿄 리전에 새 ACM 인증서 생성
resource "aws_acm_certificate" "main" {
  domain_name               = "bluesunnywings.com"
  subject_alternative_names = ["*.bluesunnywings.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "bluesunnywings-cert-tokyo"
  }
}

# DNS 검증 레코드 생성 (팀원의 Route53에 추가)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# 인증서 검증 완료 대기
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

