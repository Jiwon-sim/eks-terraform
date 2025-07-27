# EKS Terraform Infrastructure with External DNS

이 프로젝트는 AWS EKS 클러스터와 External DNS를 Terraform으로 구성하는 Infrastructure as Code입니다.

## 주요 특징

- **완전 자동화된 External DNS 설정**: Route53 Hosted Zone 자동 생성 및 구성
- **도메인 기반 DNS 관리**: `bluesunnywings.com` 도메인에 대한 자동 DNS 레코드 생성
- **Well-Architected Framework 준수**: 보안, 안정성, 성능 최적화

## 구성된 리소스

### 1. VPC 및 네트워킹
- **VPC**: 10.0.0.0/16 CIDR 블록
- **가용 영역**: 3개 AZ 사용
- **서브넷**: 
  - 프라이빗 서브넷: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
  - 퍼블릭 서브넷: 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24
- **NAT Gateway**: 활성화

### 2. EKS 클러스터
- **클러스터명**: devsecops-eks
- **Kubernetes 버전**: 1.28
- **노드 그룹**: 
  - 인스턴스 타입: t3.small
  - 최소: 1개, 최대: 3개, 희망: 2개

### 3. Kubernetes Add-ons

#### AWS Load Balancer Controller
- **버전**: 1.6.2
- **네임스페이스**: kube-system
- **IAM 역할**: IRSA를 통한 권한 관리

#### AWS EBS CSI Driver
- **버전**: 2.25.0
- **네임스페이스**: kube-system
- **IAM 역할**: AmazonEBSCSIDriverPolicy 연결

#### External DNS
- **버전**: 1.13.1
- **네임스페이스**: kube-system
- **프로바이더**: AWS Route53
- **도메인**: bluesunnywings.com
- **정책**: upsert-only (안전한 레코드 관리)
- **소스**: Service, Ingress 리소스 자동 감지

### 4. Route53 DNS
- **Hosted Zone**: bluesunnywings.com 자동 생성
- **DNS 레코드**: Kubernetes 리소스 기반 자동 생성
- **TXT 레코드**: 소유권 관리를 위한 TXT 레코드 자동 생성

## 파일 구조

```
eks-terraform/
├── main.tf                                    # 메인 Terraform 구성
├── iam.tf                                     # IAM 역할 및 정책
├── route53.tf                                 # Route53 Hosted Zone 구성
├── outputs.tf                                 # 출력 값 정의
├── external-dns-troubleshooting.tf           # External DNS 디버깅 리소스
├── policies/
│   └── AWSLoadBalancerController.json         # Load Balancer Controller 정책
├── test-external-dns.yaml                    # External DNS 테스트 애플리케이션
├── check-external-dns.sh                     # External DNS 상태 확인 스크립트
├── deploy-and-test.sh                         # 자동 배포 및 테스트 스크립트
├── EXTERNAL_DNS_SETUP.md                     # External DNS 상세 가이드
├── README.md                                  # 프로젝트 문서
└── .gitignore                                 # Git 제외 파일
```

## IAM 구성

### 1. AWS Load Balancer Controller
- **역할명**: aws-load-balancer-controller
- **정책**: 사용자 정의 정책 (AWSLoadBalancerController.json)
- **서비스 계정**: aws-load-balancer-controller

### 2. EBS CSI Driver
- **역할명**: AmazonEKS_EBS_CSI_DriverRole
- **정책**: AmazonEBSCSIDriverPolicy (AWS 관리형)
- **서비스 계정**: ebs-csi-controller-sa

### 3. External DNS
- **역할명**: external-dns
- **정책**: Route53 권한 (특정 Hosted Zone에 제한)
- **서비스 계정**: external-dns
- **권한**: 
  - route53:ChangeResourceRecordSets (특정 Zone만)
  - route53:ListHostedZones
  - route53:ListResourceRecordSets
  - route53:GetChange

## 빠른 시작

### 자동 배포 (권장)

```bash
# 실행 권한 부여
chmod +x deploy-and-test.sh

# 자동 배포 실행
./deploy-and-test.sh
```

### 수동 배포

1. **AWS CLI 설정**
   ```bash
   aws configure
   ```

2. **Terraform 초기화**
   ```bash
   terraform init
   ```

3. **계획 확인**
   ```bash
   terraform plan
   ```

4. **배포**
   ```bash
   terraform apply
   ```

5. **네임서버 설정**
   ```bash
   # 네임서버 확인
   terraform output route53_name_servers
   
   # 이 네임서버를 도메인 등록업체에서 설정
   ```

6. **kubectl 구성**
   ```bash
   aws eks --region ap-northeast-1 update-kubeconfig --name devsecops-eks
   ```

7. **External DNS 테스트**
   ```bash
   kubectl apply -f test-external-dns.yaml
   ./check-external-dns.sh
   ```

## 정리

```bash
terraform destroy
```

## 주요 출력 값

### EKS 클러스터
- `cluster_endpoint`: EKS 클러스터 엔드포인트
- `cluster_name`: 클러스터 이름
- `cluster_security_group_id`: 클러스터 보안 그룹 ID

### Route53 및 DNS
- `route53_zone_id`: Route53 Hosted Zone ID
- `route53_zone_name`: 도메인 이름 (bluesunnywings.com)
- `route53_name_servers`: 네임서버 목록 (도메인 등록업체에서 설정 필요)

### External DNS
- `external_dns_service_account_arn`: External DNS 서비스 계정 ARN
- `external_dns_iam_role_arn`: External DNS IAM 역할 ARN
- `domain_configuration`: 도메인 설정 정보

## External DNS 사용 예시

### Service에 DNS 레코드 생성

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.bluesunnywings.com
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

### Ingress에 DNS 레코드 생성

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    external-dns.alpha.kubernetes.io/hostname: webapp.bluesunnywings.com
spec:
  rules:
  - host: webapp.bluesunnywings.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
```

## 문제 해결

### External DNS 상태 확인

```bash
./check-external-dns.sh
```

### 일반적인 문제

1. **DNS 레코드가 생성되지 않는 경우**:
   - 네임서버가 도메인 등록업체에서 올바르게 설정되었는지 확인
   - External DNS Pod 로그 확인: `kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns`

2. **IAM 권한 문제**:
   - Service Account 어노테이션 확인
   - IAM 역할 권한 확인

3. **DNS 전파 지연**:
   - DNS 변경사항은 최대 48시간까지 소요될 수 있습니다

## 상세 문서

- [External DNS 설정 가이드](EXTERNAL_DNS_SETUP.md)
- [AWS Load Balancer Controller 문서](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 주의사항

- 이 구성은 AWS 리소스를 생성하므로 비용이 발생할 수 있습니다
- 사용 후 반드시 `terraform destroy`로 리소스를 정리하세요
- 도메인 네임서버 설정이 필요합니다
- DNS 전파에는 시간이 소요될 수 있습니다