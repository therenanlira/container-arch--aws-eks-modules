# vpc_network

Provisiona uma VPC com subnets públicas, privadas e de dados distribuídas entre AZs, tabelas de rota e VPC endpoints (gateway).

## Uso

```hcl
module "vpc" {
  source = "git::https://github.com/therenanlira/container-arch--aws-modules.git//vpc_network?ref=v1"

  project_name = "container-arch"
  environment  = "dev"

  cidr_block   = "10.0.0.0/16"
  subnet_count = 3
}
```

## Inputs

| Nome | Descrição | Tipo | Default |
| --- | --- | --- | --- |
| `project_name` | Nome do projeto, usado em tags e nomes de recursos | `string` | — |
| `environment` | Ambiente de deploy (`dev`, `prd`, etc) | `string` | — |
| `cidr_block` | CIDR block da VPC | `string` | — |
| `subnet_count` | Quantidade de subnets por tipo (uma por AZ) | `number` | `3` |
| `vpce_gateways` | Serviços AWS para criar VPC endpoints (gateway) | `list(string)` | `["s3", "dynamodb"]` |
| `create_dns_zone` | Cria a zona privada. Só a região central cria; as demais associam a VPC delas | `bool` | `true` |
| `dns_zone_id` | Zone ID da zona privada a associar quando `create_dns_zone = false` | `string` | `null` |
| `dns_name` | Nome da zona privada quando ela não é criada aqui | `string` | `null` |

## Outputs

| Nome | Descrição |
| --- | --- |
| `vpc_id` | ID da VPC |
| `private_subnet_ids` | Map `{az => subnet_id}` das subnets privadas |
| `public_subnet_ids` | Map `{az => subnet_id}` das subnets públicas |
| `data_subnet_ids` | Map `{az => subnet_id}` das subnets de dados |
| `private_route_table_ids` / `public_route_table_ids` | Route tables por AZ, consumidas pelo módulo [`vpc_peering`](../vpc_peering) |
