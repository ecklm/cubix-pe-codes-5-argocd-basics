resource "helm_release" "demo-app" {
  provider = helm.sbx

  name             = "colors"
  repository       = "oci://docker.io/ecklm"
  chart            = "colors-demo-app"
  namespace        = "colors"
  create_namespace = true

  set = [
    {
      name  = "ingress.host"
      value = "colors.${local.project_domain}"
    },
    {
      name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "letsencrypt"
      type  = "string"
    }
  ]

  atomic          = true
  cleanup_on_fail = true
}
