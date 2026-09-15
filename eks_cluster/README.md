# eks_cluster

Provisiona um cluster EKS com node group gerenciado, secrets criptografados com KMS, provider OIDC (IRSA), add-ons gerenciados (`vpc-cni`, `coredns`, `kube-proxy`) e os charts `metrics-server` e `kube-state-metrics`.

Consome a rede publicada pelo módulo [`vpc_network`](../vpc_network).

## Uso

O módulo não configura providers: o root configura `aws`, `kubernetes` e `helm`.

```hcl
data "aws_ssm_parameter" "vpc_network" {
  name = "/prd/us-east-2/ct-arch/vpc-network"
}

module "eks_cluster" {
  source = "git::https://github.com/therenanlira/container-arch--aws-eks-modules.git//eks_cluster?ref=main"

  project_name = "ct-arch"
  environment  = "prd"

  vpc_network = jsondecode(data.aws_ssm_parameter.vpc_network.insecure_value)

  auto_scale_options   = { min = 1, max = 2, des = 1 }
  nodes_instance_types = ["t3.large", "t3a.large"]
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks_cluster.name
}

provider "kubernetes" {
  host                   = module.eks_cluster.endpoint
  cluster_ca_certificate = module.eks_cluster.certificate_authority
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks_cluster.endpoint
    cluster_ca_certificate = module.eks_cluster.certificate_authority
    token                  = data.aws_eks_cluster_auth.default.token
  }
}
```

## Recursos

| Recurso | Nome | Detalhes |
| --- | --- | --- |
| Cluster | `{environment}-{project_name}-eks` | Control plane nas subnets privadas. Endpoint privado ligado e público restrito a `public_access_cidrs`. Logs `api`, `audit`, `authenticator`, `controllerManager` e `scheduler`. Zonal shift ligado |
| Node group | Mesmo nome do cluster | Nas subnets de EKS (`eks_subnet_ids`). `desired_size` só vale na criação. Label `ingress/ready=true` |
| KMS | `alias/{environment}-{região}-{project_name}-kms` | Criptografia dos `secrets` do cluster |
| IAM | `{environment}-{região}-{project_name}-ekscluster-role` e `-eksnodes-role` | Nodes com `AmazonEKS_CNI_Policy`, `AmazonEKSWorkerNodePolicy` e `CloudWatchAgentServerPolicy` |
| OIDC provider | — | Habilita IRSA |
| Access entry | — | A dos nodes (`EC2_LINUX`) é criada pelo próprio EKS junto com o node group. Autenticação `API_AND_CONFIG_MAP`; quem cria o cluster vira admin |
| Security group | SG do cluster | Libera NodePorts (`30000-32768/tcp`) e DNS (`53/tcp`, `53/udp`) a partir de `0.0.0.0/0` |
| Helm | `metrics-server` (Bitnami `7.2.16`) e `kube-state-metrics` | Em `kube-system` |

## Inputs

| Nome | Descrição | Tipo | Default |
| --- | --- | --- | --- |
| `project_name` | Nome do projeto, usado em tags e nomes de recursos | `string` | — |
| `environment` | Ambiente de deploy (`dev`, `prd`, etc) | `string` | — |
| `vpc_network` | IDs de rede do `vpc_network` (JSON do SSM decodificado). Atributos extras são ignorados | `object({ vpc_id = string, private_subnet_ids = map(string), eks_subnet_ids = map(string) })` | — |
| `k8s_version` | Versão do Kubernetes | `string` | `"1.36"` |
| `public_access_cidrs` | CIDRs com acesso ao endpoint público da API | `list(string)` | `["0.0.0.0/0"]` |
| `auto_scale_options` | Tamanho do node group | `object({ min = number, max = number, des = number })` | — |
| `nodes_instance_types` | Tipos de instância dos nodes | `list(string)` | — |
| `addon_cni_version` | Versão do add-on `vpc-cni` | `string` | `"v1.22.4-eksbuild.3"` |
| `addon_coredns_version` | Versão do add-on `coredns` | `string` | `"v1.14.3-eksbuild.14"` |
| `addon_kubeproxy_version` | Versão do add-on `kube-proxy` | `string` | `"v1.36.0-eksbuild.17"` |

## Outputs

| Nome | Descrição |
| --- | --- |
| `name` | Nome do cluster |
| `endpoint` | Endpoint da API |
| `certificate_authority` | CA do cluster já decodificada (PEM). Vai direto no `cluster_ca_certificate` dos providers |
| `project_name`, `environment` | Repassam os inputs |
