resource "helm_release" "ingress-nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.6.0"
  namespace        = "ingress-nginx"
  create_namespace = true
}

resource "helm_release" "external-dns" {
  name             = "external-dns"
  repository       = "https://charts.bitnami.com/bitnami"
    chart          = "external-dns"
  version          = "6.15.0"
  namespace        = "external-dns"
  create_namespace = true

  values = [
    "${file("external_dns_variables.yaml")}",
  ]

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_external_dns.iam_role_arn
  }
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.11.0"
  namespace        = "kube-system"

  values = [
    "${file("cert_manager_variables.yaml")}",
  ]

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_cert_manager.iam_role_arn
  }
}
