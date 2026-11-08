-- =====================================================================
-- 01 · Receita mensal, ticket médio e crescimento
-- Pergunta: a receita está crescendo mês a mês? O ticket médio muda?
-- Técnicas: CTE, DATE_TRUNC, COUNT(DISTINCT), LAG, SAFE_DIVIDE
-- =====================================================================

WITH vendas AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS mes,
    order_id,
    sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    -- só meses completos: o mês atual ainda não fechou
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

mensal AS (
  SELECT
    mes,
    COUNT(DISTINCT order_id) AS pedidos,
    SUM(sale_price)          AS receita
  FROM vendas
  GROUP BY mes
)

SELECT
  mes,
  pedidos,
  ROUND(receita, 2)                    AS receita,
  ROUND(SAFE_DIVIDE(receita, pedidos), 2) AS ticket_medio,
  ROUND(100 * SAFE_DIVIDE(
    receita - LAG(receita) OVER (ORDER BY mes),
    LAG(receita) OVER (ORDER BY mes)
  ), 1)                                AS crescimento_vs_mes_anterior_pct
FROM mensal
ORDER BY mes;
