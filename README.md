# Análise de vendas de e-commerce com SQL (BigQuery)

Projeto de portfólio em SQL. Respondo 8 perguntas de negócio de um e-commerce usando só SQL no Google BigQuery: receita, margem, devoluções, recompra, retenção, canais de aquisição, logística e segmentação de clientes.

**Autor:** Felipe Gonzaga · [LinkedIn](https://www.linkedin.com/in/felipe-gonzaga-b3173b143/)

---

## Base de dados

[`bigquery-public-data.thelook_ecommerce`](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce): base pública do Google com dados **fictícios** de uma loja de roupas online.

| Tabela | Linhas | O que tem |
|---|---:|---|
| `orders` | 125.136 | um registro por pedido, com status e datas |
| `order_items` | 181.610 | um registro por item vendido, com preço e status |
| `products` | 29.120 | catálogo com categoria, marca, custo e centro de distribuição |
| `users` | 100.000 | clientes, com país, idade e canal de aquisição |
| `distribution_centers` | 10 | centros de distribuição |

**Período:** jan/2019 a nov/2026.

**Regras usadas em todo o projeto:**
- Itens com status `Cancelled` ou `Returned` não contam como venda.
- Nas análises mensais, o mês atual fica de fora, porque ainda não fechou.
- A base tem alguns itens com data futura (até 12/11/2026). Eles ficam de fora quando a data importa.

**Qualidade dos dados:** não há clientes duplicados. Dos 29.120 produtos, 2 não têm nome e 24 não têm marca. Nenhum produto está sem categoria ou sem custo.

---

## Perguntas e consultas

| # | Pergunta de negócio | Arquivo | Técnicas de SQL |
|---|---|---|---|
| 0 | Qual o tamanho, o período e a qualidade dos dados? | [`00_exploracao.sql`](sql/00_exploracao.sql) | `UNION ALL`, `COUNTIF`, `HAVING` |
| 1 | A receita cresce mês a mês? | [`01_receita_mensal.sql`](sql/01_receita_mensal.sql) | CTE, `DATE_TRUNC`, `LAG` |
| 2 | Quais categorias dão mais receita e mais lucro? | [`02_categorias_receita_margem.sql`](sql/02_categorias_receita_margem.sql) | `JOIN`, `RANK` |
| 3 | Onde estão as maiores taxas de devolução? | [`03_devolucao_cancelamento.sql`](sql/03_devolucao_cancelamento.sql) | `COUNTIF`, `HAVING` |
| 4 | Quantos clientes voltam a comprar? | [`04_recompra.sql`](sql/04_recompra.sql) | `ROW_NUMBER`, mediana |
| 5 | Como é a retenção por coorte? | [`05_coorte_retencao.sql`](sql/05_coorte_retencao.sql) | várias CTEs, `DATE_DIFF`, pivot |
| 6 | Qual canal traz os melhores clientes? | [`06_canal_aquisicao.sql`](sql/06_canal_aquisicao.sql) | `LEFT JOIN` |
| 7 | Algum centro de distribuição atrasa mais? | [`07_tempo_entrega.sql`](sql/07_tempo_entrega.sql) | JOIN de 3 tabelas, percentil 90 |
| 8 | Quais grupos de clientes concentram a receita? | [`08_segmentacao_rfm.sql`](sql/08_segmentacao_rfm.sql) | `NTILE`, `CASE`, % do total |

---

## Resultados

> Consultas rodadas em **08/11/2026**. O Google atualiza essa base, então os números podem mudar um pouco com o tempo.

### 1. Receita mensal

Últimos 6 meses completos:

| Mês | Pedidos | Receita ($) | Ticket médio ($) | vs. mês anterior |
|---|---:|---:|---:|---:|
| mai/2026 | 2.822 | 239.767 | 84,96 | +15,5% |
| jun/2026 | 2.882 | 248.993 | 86,40 | +3,8% |
| jul/2026 | 3.264 | 279.381 | 85,59 | +12,2% |
| ago/2026 | 3.556 | 302.540 | 85,08 | +8,3% |
| set/2026 | 3.984 | 345.028 | 86,60 | +14,0% |
| out/2026 | 5.107 | 440.486 | 86,25 | +27,7% |

**O que encontrei:** a receita de outubro/2026 foi 2,6 vezes a de outubro/2025 ($167.468). Quase todo o crescimento veio do número de pedidos, que subiu 2,6 vezes. O ticket médio ficou praticamente parado, entre $80 e $90, em todos os anos.

### 2. Categorias: receita × lucro

| Categoria | Receita ($) | Lucro bruto ($) | Margem | Posição em receita | Posição em lucro |
|---|---:|---:|---:|---:|---:|
| Outerwear & Coats | 967.238 | 537.724 | 55,6% | 1 | 1 |
| Jeans | 940.020 | 436.953 | 46,5% | 2 | 2 |
| Sweaters | 623.615 | 323.144 | 51,8% | 3 | 3 |
| Suits & Sport Coats | 495.220 | 296.236 | 59,8% | 4 | 4 |
| Tops & Tees | 364.953 | 160.635 | 44,0% | 9 | **13** |
| Accessories | 316.109 | 189.425 | 59,9% | 14 | **10** |

**O que encontrei:** as 4 maiores categorias em receita também são as 4 maiores em lucro. As diferenças aparecem no meio da lista. **Tops & Tees** é a 9ª em receita, mas cai para 13ª em lucro, porque tem uma das menores margens (44%). **Accessories** faz o caminho contrário: é a 14ª em receita e sobe para 10ª em lucro, com margem de 59,9%.

### 3. Devolução e cancelamento

**O que encontrei:** em todas as categorias com pelo menos 500 itens, a taxa de devolução fica entre 9,1% e 11,1%, e a de cancelamento entre 14,3% e 17,2%. Nenhuma categoria se destaca. No total, **1 em cada 4 itens** é cancelado ou devolvido (15% + 10%). Como a taxa é parecida em todas as categorias, o problema não parece ser do produto: vale olhar o processo de compra, pagamento e estoque.

### 4. Recompra

| Clientes compradores | Recompraram | Taxa de recompra | Mediana até a 2ª compra |
|---:|---:|---:|---:|
| 66.116 | 20.353 | 30,8% | 275 dias |

**O que encontrei:** cerca de 3 em cada 10 clientes voltam a comprar, mas o cliente típico leva **9 meses** para fazer a segunda compra.

### 5. Retenção por coorte

| Coorte (1ª compra) | Clientes | Voltou no mês 1 | Mês 2 | Mês 3 | Mês 6 |
|---|---:|---:|---:|---:|---:|
| nov/2025 | 1.310 | 2,5% | 3,5% | 3,0% | 3,0% |
| jan/2026 | 1.481 | 3,7% | 2,9% | 2,4% | 3,0% |
| abr/2026 | 1.587 | 4,8% | 4,2% | 4,9% | 4,7% |
| jul/2026 | 2.014 | 7,6% | 6,8% | 7,0% | – |
| ago/2026 | 2.113 | 8,2% | 8,1% | – | – |
| set/2026 | 2.302 | 12,1% | – | – | – |

**O que encontrei:** poucos clientes voltam logo depois da primeira compra (de 2,5% a 5% até meados de 2026). As coortes mais recentes retêm bem mais: a de setembro/2026 teve 12,1% de volta no mês seguinte. Esse aumento coincide com o crescimento acelerado de pedidos visto no item 1.

### 6. Canais de aquisição

| Canal | Cadastrados | Conversão | Receita ($) | Receita média por comprador ($) |
|---|---:|---:|---:|---:|
| Search | 70.083 | 66,1% | 5.681.307 | 122,57 |
| Organic | 14.947 | 65,7% | 1.201.311 | 122,37 |
| Facebook | 5.999 | 66,9% | 484.424 | 120,74 |
| Email | 4.893 | 66,0% | 390.970 | 121,16 |
| Display | 4.078 | 66,4% | 334.824 | 123,64 |

**O que encontrei:** Search traz 70% dos clientes e 70% da receita. Mas a **qualidade** do cliente é a mesma em todos os canais: cerca de 66% de conversão e $121 a $124 por comprador. Os canais se diferenciam pelo volume que trazem, não pelo valor de cada cliente.

### 7. Logística

**O que encontrei:** os 10 centros de distribuição têm desempenho praticamente igual: cerca de 0,5 dia até o envio, 2,5 dias em trânsito e 3 dias no total. 90% das entregas chegam em até 5,9 dias. Nenhum centro precisa de atenção especial.

### 8. Segmentação RFM

| Segmento | Clientes | % dos clientes | Pedidos médios | % da receita |
|---|---:|---:|---:|---:|
| Campeões | 11.701 | 17,7% | 2,01 | 34,9% |
| Regulares | 23.758 | 36,0% | 1,39 | 31,1% |
| Em risco (gastavam muito) | 9.241 | 14,0% | 1,54 | 25,3% |
| Perdidos | 11.818 | 17,9% | 1,05 | 4,8% |
| Novos ou promissores | 9.516 | 14,4% | 1,11 | 3,9% |

**O que encontrei:** os **Campeões** são 17,7% dos clientes e trazem 34,9% da receita. O grupo **Em risco** preocupa: são clientes que já gastaram bastante (25,3% da receita), mas não compram há mais de 3 anos, em média.

**Limitação:** a maioria dos clientes tem um pedido só, então a nota de frequência quase não separa os clientes. Por isso os segmentos usam recência e valor.

### Uma observação sobre a base

Como os dados são gerados por computador, várias métricas saem quase iguais entre grupos: devolução por categoria, conversão por canal e prazo por centro de distribuição. Numa empresa real, esses números variam mais. Mesmo assim, concluir que "não há diferença" também é resultado: evita gastar esforço investigando a categoria, o canal ou o centro errado.

---

## Recomendações para o negócio

- **Atacar cancelamentos e devoluções pelo processo, não pela categoria.** Um quarto dos itens é perdido, e a taxa é igual em todas as categorias. O próximo passo é investigar o checkout, o pagamento e a disponibilidade de estoque.
- **Reativar o grupo "Em risco".** São 9.241 clientes que já representaram 25% da receita. Uma campanha de reativação por e-mail para esse grupo é barata de testar e fácil de medir.
- **Rever preço ou custo de Tops & Tees** (margem de 44%) e dar mais destaque a Accessories (margem de 59,9%), que lucra mais do que o volume de vendas indica.

---

## Como reproduzir

1. Acesse o [BigQuery Sandbox](https://console.cloud.google.com/bigquery). É gratuito e não pede cartão.
2. Crie um projeto no Google Cloud.
3. Abra qualquer arquivo da pasta `sql/`, cole no editor e clique em **Executar**.

As consultas leem a base pública direto, sem precisar copiar nada para o seu projeto. Cada uma processa poucos MB, bem dentro da cota gratuita.

---

## O que pratiquei

- Definir uma regra de negócio ("o que conta como venda") antes de calcular
- Quebrar uma pergunta grande em CTEs pequenas e legíveis
- Funções de janela: `LAG`, `RANK`, `ROW_NUMBER`, `NTILE`, `SUM() OVER ()`
- Cuidado com divisão por zero (`SAFE_DIVIDE`), com meses incompletos e com datas futuras
- Usar `LEFT JOIN` quando quem "não fez nada" também importa (cadastrados que não compraram)
- Desconfiar do resultado: a primeira versão da análise de coorte contava novembro/2026, que ainda não acabou, e mostrava uma queda de retenção que não existia
