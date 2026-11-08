-- =====================================================================
-- 00 · Exploração inicial da base
-- Objetivo: entender o tamanho, o período e a qualidade dos dados
--           antes de responder qualquer pergunta de negócio.
-- Base: bigquery-public-data.thelook_ecommerce (dados fictícios de e-commerce)
-- =====================================================================


-- 1) Quantas linhas tem cada tabela e qual período ela cobre?
SELECT 'orders' AS tabela, COUNT(*) AS linhas, MIN(created_at) AS primeiro_registro, MAX(created_at) AS ultimo_registro
FROM `bigquery-public-data.thelook_ecommerce.orders`
UNION ALL
SELECT 'order_items', COUNT(*), MIN(created_at), MAX(created_at)
FROM `bigquery-public-data.thelook_ecommerce.order_items`
UNION ALL
SELECT 'users', COUNT(*), MIN(created_at), MAX(created_at)
FROM `bigquery-public-data.thelook_ecommerce.users`
UNION ALL
SELECT 'products', COUNT(*), NULL, NULL
FROM `bigquery-public-data.thelook_ecommerce.products`;


-- 2) Como os itens se distribuem por status?
--    Isso define o que conta como "venda" no resto do projeto:
--    itens Cancelled e Returned ficam de fora da receita.
SELECT
  status,
  COUNT(*) AS itens,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_do_total
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY status
ORDER BY itens DESC;


-- 3) Há valores nulos em colunas que vou usar para agrupar?
SELECT
  COUNT(*)                   AS produtos,
  COUNTIF(name IS NULL)      AS sem_nome,
  COUNTIF(brand IS NULL)     AS sem_marca,
  COUNTIF(category IS NULL)  AS sem_categoria,
  COUNTIF(cost IS NULL)      AS sem_custo
FROM `bigquery-public-data.thelook_ecommerce.products`;


-- 4) Existe cliente duplicado? (o resultado esperado é zero linhas)
SELECT id, COUNT(*) AS ocorrencias
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY id
HAVING COUNT(*) > 1;
