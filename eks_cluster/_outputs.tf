# Variables
output "project_name" {
  value = var.project_name
}

output "environment" {
  value = var.environment
}

# EKS

output "name" {
  value = aws_eks_cluster.main.name
}

output "endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "certificate_authority" {
  value = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
}
