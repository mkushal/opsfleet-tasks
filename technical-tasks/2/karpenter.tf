
resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  namespace  = "karpenter"
  version    = "0.18.1" # Latest stable version

  set {
    name  = "serviceAccount.annotations.eks.amazonaws.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "controller.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "controller.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "controller.clusterCa"
    value = base64encode(data.aws_eks_cluster_auth.main.certificate_authority.data)
  }
}

# Karpenter provisioner with x86 and ARM support
resource "kubernetes_manifest" "karpenter_provisioner" {
  manifest = {
    apiVersion = "karpenter.sh/v1alpha5"
    kind       = "Provisioner"
    metadata   = { name = "default" }
    spec       = {
      provider = {
        instanceTypes = ["m6g.large", "m5.large"]
        amiFamily     = "AL2"
      }
      requirements = [
        { key = "kubernetes.io/arch", operator = "In", values = ["arm64", "amd64"] }
      ]
    }
  }
}
