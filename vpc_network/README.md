# vpc_network

Provisiona uma VPC com subnets públicas, privadas e de dados distribuídas entre AZs, NAT Gateway por AZ, tabelas de rota, VPC endpoints (gateway) e zona DNS privada. Opcionalmente associa um CIDR secundário para os pods do EKS. Publica os IDs de rede no SSM Parameter Store.

## Uso

```hcl
module "vpc" {
  source = "git::https://github.com/therenanlira/container-arch--aws-eks-modules.git//vpc_network?ref=main"

  project_name = "ct-arch"
  environment  = "prd"

  cidr_block = "10.0.0.0/16"
  eks_cidr   = "100.64.0.0/16"
}
```

## Subnets

Uma subnet de cada tipo por AZ. Exemplo com `cidr_block = "10.0.0.0/16"`, `eks_cidr = "100.64.0.0/16"` e 3 AZs:

| Tipo | Origem | Tamanho | AZs a, b, c | Saída para internet |
| --- | --- | --- | --- | --- |
| Privada | 1º quarto do `cidr_block` | `/20` | `10.0.0.0/20`, `10.0.16.0/20`, `10.0.32.0/20` | NAT da AZ |
| Pública | 2º quarto do `cidr_block` | `/24` | `10.0.64.0/24`, `10.0.65.0/24`, `10.0.66.0/24` | Internet Gateway |
| Dados | 3º quarto do `cidr_block` | `/22` | `10.0.128.0/22`, `10.0.132.0/22`, `10.0.136.0/22` | NAT da AZ |
| EKS | `eks_cidr` | `/18` | `100.64.0.0/18`, `100.64.64.0/18`, `100.64.128.0/18` | NAT da AZ |

- O 4º quarto do `cidr_block` fica livre.
- `subnet_count` aceita no máximo `4`.
- Com `eks_cidr` definido, as subnets privadas recebem `kubernetes.io/role/internal-elb = 1` e as públicas `kubernetes.io/role/elb = 1`, usadas pelo AWS Load Balancer Controller.

## SSM Parameter

Publicado em `/{environment}/{região}/{project_name}/vpc-network`, tipo `String`, com um JSON:

```json
{
  "vpc_id": "vpc-...",
  "public_subnet_ids": { "us-east-2a": "subnet-...", "...": "..." },
  "private_subnet_ids": { "...": "..." },
  "data_subnet_ids": { "...": "..." },
  "eks_subnet_ids": { "...": "..." },
  "public_route_table_ids": { "...": "..." },
  "private_route_table_ids": { "...": "..." }
}
```

`eks_subnet_ids` vem como `{}` quando `eks_cidr` está vazio.

Leitura em outro root:

```hcl
data "aws_ssm_parameter" "vpc_network" {
  name = "/prd/us-east-2/ct-arch/vpc-network"
}

locals {
  vpc = jsondecode(data.aws_ssm_parameter.vpc_network.insecure_value)
}
```

Use `insecure_value`: o `value` é marcado como sensível e impede `for_each` sobre os IDs.

## Inputs

| Nome | Descrição | Tipo | Default |
| --- | --- | --- | --- |
| `project_name` | Nome do projeto, usado em tags e nomes de recursos | `string` | — |
| `environment` | Ambiente de deploy (`dev`, `prd`, etc) | `string` | — |
| `cidr_block` | CIDR primário da VPC | `string` | — |
| `subnet_count` | Quantidade de AZs (uma subnet de cada tipo por AZ), máximo `4` | `number` | `3` |
| `eks_cidr` | CIDR secundário para os pods do EKS. Vazio desliga | `string` | `""` |
| `vpce_gateways` | Serviços AWS para criar VPC endpoints (gateway) | `list(string)` | `["s3", "dynamodb"]` |
| `create_dns_zone` | Cria a zona privada `{project_name}.internal.com`. Só a região central cria; as demais associam a VPC delas | `bool` | `true` |
| `dns_zone_id` | Zone ID da zona privada a associar quando `create_dns_zone = false` | `string` | `null` |
| `dns_name` | Nome da zona privada quando ela não é criada aqui | `string` | `null` |

## Outputs

| Nome | Descrição |
| --- | --- |
| `vpc_id` | ID da VPC |
| `private_subnet_ids` | Map `{az => subnet_id}` das subnets privadas |
| `public_subnet_ids` | Map `{az => subnet_id}` das subnets públicas |
| `data_subnet_ids` | Map `{az => subnet_id}` das subnets de dados |
| `eks_subnet_ids` | Map `{az => subnet_id}` das subnets de EKS. `{}` sem `eks_cidr` |
| `private_route_table_ids` / `public_route_table_ids` | Map `{az => route_table_id}` |
| `dns_zone_id` / `dns_name` | Zona privada criada ou associada |
| `project_name`, `environment`, `cidr_block`, `subnet_count`, `vpce_gateways` | Repassam os inputs |
