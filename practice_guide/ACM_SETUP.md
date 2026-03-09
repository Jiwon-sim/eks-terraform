# ACM 인증서 설정 가이드

## 📋 현재 ACM 구성

### 1. 인증서 위치
- **리전**: 서울 (ap-northeast-2)
- **도메인**: bluesunnywings.com
- **상태**: ISSUED (발급 완료)

### 2. Terraform 설정 (route53.tf)
```hcl
# 서울 리전의 기존 ACM 인증서 참조
data "aws_acm_certificate" "main" {
  provider    = aws.seoul
  domain      = "bluesunnywings.com"
  statuses    = ["ISSUED"]
  most_recent = true
}
```

## 🌐 ALB에서 ACM 사용 흐름

1. **Ingress 생성** → ALB Controller가 감지
2. **ALB 생성** → certificate-arn 어노테이션 확인
3. **HTTPS 리스너 생성** → ACM 인증서 연결
4. **SSL 종료** → ALB에서 HTTPS → HTTP 변환
5. **트래픽 전달** → EKS Pod로 HTTP 전달

## 🔒 HTTPS 설정 상세

### Ingress 어노테이션
```yaml
# 인증서 ARN 지정
alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:..."

# HTTP/HTTPS 포트 설정
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'

# HTTP → HTTPS 리다이렉트
alb.ingress.kubernetes.io/ssl-redirect: '443'

# SSL 정책 설정
alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
```

## 🚨 주의사항

1. **리전 차이**: ACM(서울) ↔ ALB(도쿄)
   - ALB는 다른 리전의 ACM 인증서 사용 가능
   
2. **도메인 검증**: 
   - Route53에서 DNS 검증 완료 필요
   - 네임서버 설정 확인 필수

3. **인증서 갱신**:
   - ACM 자동 갱신 (DNS 검증 시)
   - 수동 갱신 불필요

## 🔍 문제 해결

### ACM 인증서가 없는 경우
```bash
# 새 인증서 요청 (DNS 검증)
aws acm request-certificate \
  --domain-name bluesunnywings.com \
  --validation-method DNS \
  --region ap-northeast-2
```

### ALB에서 인증서 인식 안 되는 경우
```bash
# ALB 상태 확인
kubectl describe ingress nginx-ingress-test

# ALB Controller 로그 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```
