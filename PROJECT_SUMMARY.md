# EKS Terraform 프로젝트 작업 내역

## 프로젝트 개요
AWS EKS 클러스터를 Terraform으로 구성하는 Infrastructure as Code 프로젝트

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

## 파일 구조

```
eks-terraform/
├── main.tf                                    # 메인 Terraform 구성
├── iam.tf                                     # IAM 역할 및 정책
├── outputs.tf                                 # 출력 값 정의
├── policies/
│   └── AWSLoadBalancerController.json         # Load Balancer Controller 정책
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
- **정책**: Route53 권한 (사용자 정의)
- **서비스 계정**: external-dns

## 주요 출력 값
- `cluster_endpoint`: EKS 클러스터 엔드포인트
- `cluster_name`: 클러스터 이름
- `cluster_arn`: 클러스터 ARN
- `oidc_provider_arn`: OIDC 프로바이더 ARN
- `configure_kubectl`: kubectl 구성 명령어

## 사용 방법

1. **초기화**
   ```bash
   terraform init
   ```

2. **계획 확인**
   ```bash
   terraform plan
   ```

3. **배포**
   ```bash
   terraform apply
   ```

4. **kubectl 구성**
   ```bash
   aws eks --region ap-northeast-1 update-kubeconfig --name devsecops-eks
   ```

5. **정리**
   ```bash
   terraform destroy
   ```

## GitHub 저장소
- **URL**: https://github.com/Jiwon-sim/eks-terraform.git
- **브랜치**: main

## 주의사항
- AWS 리소스 생성으로 인한 비용 발생
- 사용 후 반드시 리소스 정리 필요
- IAM 권한 확인 필요