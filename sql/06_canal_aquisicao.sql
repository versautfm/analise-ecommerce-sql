-- =====================================================================
-- 06 · Desempenho por canal de aquisição
-- Pergunta: qual canal (Search, Organic, Facebook...) traz clientes que
--           mais compram e gastam?
-- Técnicas: LEFT JOIN (para manter quem se cadastrou e não comprou)
-- =====================================================================

WITH receita_por_cliente AS (
  SELECT
    user_id,
    SUM(sale_price) AS receita
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY user_id
)

SELECT
  u.traffic_source                              AS canal,
  COUNT(*)                                      AS clientes_cadastrados,
  COUNT(r.user_id)                              AS clientes_compradores,
  ROUND(100 * COUNT(r.user_id) / COUNT(*), 1)   AS conversao_pct,
  ROUND(SUM(r.receita), 2)                      AS receita,
  ROUND(AVG(r.receita), 2)                      AS receita_media_por_comprador
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN receita_por_cliente AS r
  ON r.user_id = u.id
GROUP BY canal
ORDER BY receita DESC;
