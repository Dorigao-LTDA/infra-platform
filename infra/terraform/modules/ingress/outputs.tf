output "public_ip_address" {
  value       = var.enable_argocd_public_access ? local.ingress_public_ip_address : ""
  description = "Static public IP used by Argo CD service (LoadBalancer)"
}
