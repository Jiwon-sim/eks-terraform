terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "devsecops-eks"
  cluster_version = "1.28"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      name = "main"
      
      instance_types = ["t3.small"]
      
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.25.0"

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  depends_on = [
    kubernetes_service_account.ebs_csi_controller
  ]
}

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

  # External DNS 소스 설정
  set {
    name  = "sources[0]"
    value = "service"
  }

  set {
    name  = "sources[1]"
    value = "ingress"
  }

  # 도메인 필터 설정
  set {
    name  = "domainFilters[0]"
    value = local.domain_name
  }

  # AWS 설정
  set {
    name  = "aws.zoneType"
    value = "public"
  }

  # 정책 설정
  set {
    name  = "policy"
    value = "upsert-only"
  }

  # 레지스트리 설정
  set {
    name  = "registry"
    value = "txt"
  }

  # TXT 소유자 ID 설정
  set {
    name  = "txtOwnerId"
    value = local.hosted_zone_id
  }

  # 로그 레벨 설정
  set {
    name  = "logLevel"
    value = "info"
  }

  # 동기화 간격 설정
  set {
    name  = "interval"
    value = "1m"
  }

  # 리소스 요청 및 제한 설정
  set {
    name  = "resources.requests.cpu"
    value = "10m"
  }

  set {
    name  = "resources.requests.memory"
    value = "50Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "50m"
  }

  set {
    name  = "resources.limits.memory"
    value = "100Mi"
  }

  # 보안 컨텍스트 설정
  set {
    name  = "securityContext.runAsNonRoot"
    value = "true"
  }

  set {
    name  = "securityContext.runAsUser"
    value = "65534"
  }

  set {
    name  = "securityContext.fsGroup"
    value = "65534"
  }

  # 노드 선택기 (시스템 노드에서 실행)
  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  # 톨러런스 설정
  set {
    name  = "tolerations[0].key"
    value = "node-role.kubernetes.io/master"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  depends_on = [
    kubernetes_service_account.external_dns,
    aws_route53_zone.main
  ]
}