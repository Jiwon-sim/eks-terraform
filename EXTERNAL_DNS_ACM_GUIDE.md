# External DNS와 ACM 설정 가이드

## 🎯 목적과 개념

### External DNS란?
- **목적**: Kubernetes Ingress/Service에서 자동으로 DNS 레코드를 생성/관리
- **동작 방식**: Ingress의 `host` 필드를 보고 Route53에 A/CNAME 레코드 자동 생성
- **실제 사용**: `app.bluesunnywings.com` → ALB 주소로 자동 매핑

### ACM(AWS Certificate Manager)이란?
- **목적**: SSL/TLS 인증서 자동 발급 및 갱신
- **동작 방식**: DNS 검증을 통해 도메인 소유권 확인 후 인증서 발급
- **실제 사용**: HTTPS 통신을 위한 인증서를 ALB에 자동 연결

## 🔧 Terraform 구성

### 1. Route53 Hosted Zone 생성

```hcl
# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "bluesuunywings.com"
  
  tags = {
    Name = "bluesuunywings-zone"
  }
}
```

### 2. ACM 인증서 생성 및 검증

```hcl
# ACM 인증서 생성
resource "aws_acm_certificate" "main" {
  domain_name               = "bluesuunywings.com"
  subject_alternative_names = ["*.bluesuunywings.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "bluesuunywings-cert"
  }
}

# DNS 검증 레코드 생성
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
  zone_id         = aws_route53_zone.main.zone_id
}

# 인증서 검증 완료 대기
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}
```

### 3. External DNS 설정 보완

```hcl
# External DNS IAM 정책 업데이트
resource "aws_iam_policy" "external_dns" {
  name = "AllowExternalDNSUpdates"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${aws_route53_zone.main.zone_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# External DNS Helm 설정 개선
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.13.1"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = "ap-northeast-1"
  }

  # 도메인 필터링 (보안상 중요!)
  set {
    name  = "domainFilters[0]"
    value = "bluesuunywings.com"
  }

  # 정책 설정 (upsert-only 권장)
  set {
    name  = "policy"
    value = "upsert-only"
  }

  # 레지스트리 설정 (중복 방지)
  set {
    name  = "registry"
    value = "txt"
  }

  # 로그 레벨 설정
  set {
    name  = "logLevel"
    value = "info"
  }

  # 동기화 간격
  set {
    name  = "interval"
    value = "1m"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  depends_on = [
    kubernetes_service_account.external_dns,
    aws_route53_zone.main
  ]
}
```

## 🚀 실습 예시

### 1. 테스트 애플리케이션 배포

```yaml
# test-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: test-app-service
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:ap-northeast-1:ACCOUNT:certificate/CERT-ID"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
  - host: app.bluesuunywings.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-app-service
            port:
              number: 80
```

### 2. 배포 및 확인

```bash
# 애플리케이션 배포
kubectl apply -f test-app.yaml

# Ingress 상태 확인
kubectl get ingress test-app-ingress -o wide

# External DNS 로그 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns -f
```

## 🔍 상태 확인 명령어

### Terraform 상태 확인
```bash
# ACM 인증서 상태 확인
terraform state show aws_acm_certificate.main

# Route53 레코드 확인
terraform state show aws_route53_zone.main

# 인증서 검증 상태 확인
terraform state show aws_acm_certificate_validation.main
```

### Kubernetes 상태 확인
```bash
# External DNS 파드 상태
kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns

# External DNS 로그 (디버깅용)
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns --tail=100

# Ingress 상태 및 ALB 주소 확인
kubectl get ingress -A

# Service Account 확인
kubectl get sa external-dns -n kube-system -o yaml
```

### AWS CLI 확인
```bash
# Route53 레코드 확인
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890

# ACM 인증서 상태 확인
aws acm list-certificates --region ap-northeast-1

# ALB 상태 확인
aws elbv2 describe-load-balancers --region ap-northeast-1
```

## 💡 실용적 팁과 설정

### 1. External DNS 고급 설정

```hcl
# 더 안전한 External DNS 설정
resource "helm_release" "external_dns" {
  # ... 기본 설정 ...

  # 드라이런 모드 (테스트용)
  set {
    name  = "dryRun"
    value = "false"  # true로 설정하면 실제 변경 없이 로그만 출력
  }

  # 소유권 ID 설정 (여러 클러스터 사용 시)
  set {
    name  = "txtOwnerId"
    value = "eks-cluster-1"
  }

  # 메트릭 활성화
  set {
    name  = "metrics.enabled"
    value = "true"
  }

  # 리소스 제한
  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }
}
```

### 2. ACM 인증서 고급 설정

```hcl
# 인증서 갱신 대기 시간 설정
resource "time_sleep" "wait_for_certificate" {
  depends_on = [aws_acm_certificate_validation.main]
  create_duration = "30s"
}

# 여러 도메인 인증서
resource "aws_acm_certificate" "wildcard" {
  domain_name = "*.bluesuunywings.com"
  subject_alternative_names = [
    "bluesuunywings.com",
    "api.bluesuunywings.com",
    "admin.bluesuunywings.com"
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
    # 인증서 삭제 방지
    prevent_destroy = true
  }
}
```

### 3. 트러블슈팅 설정

```hcl
# External DNS 디버그 모드
resource "helm_release" "external_dns_debug" {
  # ... 기본 설정 ...

  # 디버그 로그 레벨
  set {
    name  = "logLevel"
    value = "debug"
  }

  # 더 자주 동기화 (개발 환경용)
  set {
    name  = "interval"
    value = "30s"
  }

  # 이벤트 기반 동기화 활성화
  set {
    name  = "triggerLoopOnEvent"
    value = "true"
  }
}
```

## ⚠️ 자주 발생하는 이슈와 해결책

### 1. DNS 전파 지연
```bash
# DNS 전파 확인
dig app.bluesuunywings.com
nslookup app.bluesuunywings.com

# External DNS가 레코드를 생성했는지 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns | grep "CREATE"
```

### 2. 인증서 검증 실패
```bash
# 인증서 상태 확인
aws acm describe-certificate --certificate-arn arn:aws:acm:region:account:certificate/cert-id

# DNS 검증 레코드 확인
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890 | grep _acme-challenge
```

### 3. 권한 문제
```bash
# External DNS 서비스 계정 권한 확인
kubectl describe sa external-dns -n kube-system

# IAM 역할 확인
aws sts get-caller-identity
aws iam get-role --role-name external-dns
```

## 📋 체크리스트

### 배포 전 확인사항
- [ ] Route53 Hosted Zone 생성 완료
- [ ] 도메인 네임서버 설정 완료
- [ ] ACM 인증서 DNS 검증 완료
- [ ] External DNS IAM 권한 설정 완료
- [ ] Load Balancer Controller 정상 동작 확인

### 배포 후 확인사항
- [ ] External DNS 파드 정상 실행
- [ ] Ingress 생성 시 DNS 레코드 자동 생성 확인
- [ ] HTTPS 접속 정상 동작 확인
- [ ] 인증서 자동 갱신 설정 확인

이 가이드를 통해 External DNS와 ACM을 효과적으로 설정하고 관리할 수 있습니다.