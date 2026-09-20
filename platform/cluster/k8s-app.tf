resource "kubernetes_namespace" "app-marathon-namespace" {
  count = var.enable-marathon-app ? 1 : 0
  metadata {
    name = var.namespace-marathon-app
  }
}

resource "kubernetes_manifest" "app-marathon-target-group-binding" {
  count = var.enable-marathon-app ? 1 : 0

  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "marathon-cloudupc-tgb"
      namespace = var.namespace-marathon-app
    }
    spec = {
      serviceRef = {
        name = "marathon-cloudupc"
        port = 5000
      }
      targetGroupARN = var.alb-cluster-arn
      targetType     = "ip"
    }
  }

  depends_on = [
    helm_release.aws-lb-controller,
    helm_release.app-marathon,
    kubernetes_namespace.app-marathon-namespace
  ]
}

resource "helm_release" "app-marathon" {
  count = var.enable-marathon-app ? 1 : 0
  name      = "marathon-cloudupc"
  chart     = "../../kubernetes/charts/marathon-app"
  namespace = var.namespace-marathon-app

  set {
    name  = "replicaCount"
    value = 2
  }
  set {
    name  = "image.repository"
    value = var.ecr-repository
  }
  set {
    name  = "image.tag"
    value = "v1.0"
  }
  set {
    name  = "container.name"
    value = "marathon-cloudupc"
  }
  set {
    name  = "container.port"
    value = 5000
  }
  set {
    name  = "service.name"
    value = "marathon-cloudupc"
  }
  set {
    name  = "service.port"
    value = 5000
  }

  depends_on = [kubernetes_namespace.app-marathon-namespace]
}
