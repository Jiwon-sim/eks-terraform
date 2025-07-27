# AWS EKS Terraform 자동 배포


AWS 도쿄 리전에 Production-ready EKS 클러스터를 Terraform으로 자동 배포


## 파일 구조

```
eks-terraform/
├── main.tf                    # 메인 인프라 설정
├── iam.tf                     # 권한 관리
├── route53-acm.tf             # 도메인 & SSL 인증서
├── outputs.tf                 # 결과 출력
├── test-app.yaml              # 테스트 애플리케이션
├── policies/                  # IAM 정책 파일들
└── README.md                
```
**목표**
✅ **완전한 Kubernetes 클러스터** (EKS)  
✅ **자동 로드밸런싱** (AWS Load Balancer Controller)  
✅ **자동 스토리지 관리** (EBS CSI Driver)  
✅ **자동 DNS 관리** (External DNS + Route53)  
✅ **SSL 인증서** (ACM)  
✅ **테스트 웹 애플리케이션**  

## 구성 요소

### 🌐 네트워킹
- **VPC**: 10.0.0.0/16 (3개 가용영역)
- **프라이빗 서브넷**: 컴퓨터들이 안전하게 작업하는 공간
- **퍼블릭 서브넷**: 인터넷과 연결되는 공간
- **NAT Gateway**: 보안 인터넷 연결

### 💻 컴퓨팅
- **EKS 클러스터**: `devsecops-eks` (Kubernetes 1.28)
- **노드 그룹**: t3.small 인스턴스 1-3대 (자동 확장)

### 🛠️ 자동화 도구
- **Load Balancer Controller**: 트래픽 자동 분산
- **EBS CSI Driver**: 디스크 자동 연결
- **External DNS**: 도메인 자동 관리

### 1️⃣ 사전 준비

```bash
# 필수 도구 설치 확인
aws --version     # AWS CLI
terraform --version  # Terraform
kubectl version --client  # kubectl
```

**설치가 필요하다면:**
- [AWS CLI 설치](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform 설치](https://developer.hashicorp.com/terraform/downloads)
- [kubectl 설치](https://kubernetes.io/docs/tasks/tools/)

### 2️⃣ AWS 계정 설정

```bash
# AWS 자격증명 설정
aws configure
```

입력 정보:
- **Access Key ID**: AWS 콘솔에서 발급
- **Secret Access Key**: AWS 콘솔에서 발급
- **Region**: `ap-northeast-1` (도쿄)
- **Output format**: `json`

### 3️⃣ 프로젝트 다운로드

```bash
# 이 저장소 복제
git clone <이-저장소-URL>
cd eks-terraform
```

### 4️⃣ 배포 실행

```bash
# 1. Terraform 초기화 (도구 다운로드)
terraform init

# 2. 배포 계획 확인 (뭐가 만들어질지 미리보기)
terraform plan

# 3. 실제 배포 (약 15-20분 소요)
terraform apply
```

**`yes` 입력하면 배포 시작!**

### 5️⃣ 클러스터 연결

```bash
# kubectl을 EKS 클러스터에 연결
aws eks --region ap-northeast-1 update-kubeconfig --name devsecops-eks

# 연결 확인
kubectl get nodes
```

성공하면 이런 화면이 나옵니다:
```
NAME                                               STATUS   ROLES    AGE   VERSION
ip-10-0-1-xxx.ap-northeast-1.compute.internal     Ready    <none>   5m    v1.28.x
ip-10-0-2-xxx.ap-northeast-1.compute.internal     Ready    <none>   5m    v1.28.x
```

## 🧪 테스트 애플리케이션 배포

```bash
# 샘플 웹 애플리케이션 배포
kubectl apply -f test-app.yaml

# 배포 상태 확인
kubectl get pods
kubectl get ingress
```

## 배포 결과 확인

### 생성된 리소스 확인
```bash
# Terraform으로 생성된 리소스 목록
terraform state list

# 주요 정보 출력
terraform output
```

### Kubernetes 클러스터 상태
```bash
# 노드 상태
kubectl get nodes -o wide

# 모든 파드 상태
kubectl get pods -A

# 서비스 상태
kubectl get svc -A
```

## 🔧 커스터마이징

### 도메인 변경
`main.tf`와 `route53-acm.tf`에서 `bluesuunywings.com`을 본인 도메인으로 변경:

```hcl
# main.tf
set {
  name  = "domainFilters[0]"
  value = "your-domain.com"  # 여기 변경
}

# route53-acm.tf
resource "aws_route53_zone" "main" {
  name = "your-domain.com"  # 여기 변경
}
```

### 인스턴스 크기 변경
`main.tf`에서 인스턴스 타입 수정:

```hcl
instance_types = ["t3.medium"]  # t3.small → t3.medium
```

### 노드 개수 조정
```hcl
min_size     = 2  # 최소 개수
max_size     = 5  # 최대 개수
desired_size = 3  # 희망 개수
```

## 비용 정보

**예상 월 비용 (도쿄 리전):**
- EKS 클러스터: ~$73
- EC2 인스턴스 (t3.small × 2): ~$30
- NAT Gateway: ~$45
- 기타 (로드밸런서, 스토리지): ~$20

**총 예상 비용: ~$170/월**

> ⚠️ **중요**: 테스트 후 반드시 리소스를 정리하세요!

## 🗑️ 리소스 정리

```bash
# 테스트 앱 삭제
kubectl delete -f test-app.yaml

# 모든 AWS 리소스 삭제
terraform destroy
```

`yes` 입력하면 모든 리소스가 삭제됩니다. (약 10-15분 소요)


### 자주 발생하는 문제

**1. AWS 권한 오류**
```bash
# IAM 사용자에게 다음 권한 필요:
# - AmazonEKSClusterPolicy
# - AmazonEKSWorkerNodePolicy
# - AmazonEC2FullAccess
# - AmazonRoute53FullAccess
```

**2. 도메인 검증 실패**
```bash
# Route53에서 네임서버 확인
terraform output route53_name_servers
# 도메인 등록업체에서 네임서버 변경 필요
```

**3. kubectl 연결 실패**
```bash
# AWS CLI 프로필 확인
aws sts get-caller-identity

# kubeconfig 재설정
aws eks --region ap-northeast-1 update-kubeconfig --name devsecops-eks
```

### 로그 확인
```bash
# Terraform 상세 로그
TF_LOG=DEBUG terraform apply

# Kubernetes 파드 로그
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns
```

---
