-- =====================================================================
-- 07 · Tempo de envio e entrega por centro de distribuição
-- Pergunta: algum centro de distribuição demora mais para enviar ou entregar?
-- Técnicas: JOIN de 3 tabelas, TIMESTAMP_DIFF, percentil 90
-- =====================================================================

SELECT
  dc.name                                                                  AS centro_distribuicao,
  COUNT(*)                                                                 AS itens_entregues,
  ROUND(AVG(TIMESTAMP_DIFF(oi.shipped_at,   oi.created_at, HOUR)) / 24, 1) AS dias_ate_envio,
  ROUND(AVG(TIMESTAMP_DIFF(oi.delivered_at, oi.shipped_at, HOUR)) / 24, 1) AS dias_em_transito,
  ROUND(AVG(TIMESTAMP_DIFF(oi.delivered_at, oi.created_at, HOUR)) / 24, 1) AS dias_total_medio,
  -- 90% das entregas acontecem em até X dias
  ROUND(APPROX_QUANTILES(TIMESTAMP_DIFF(oi.delivered_at, oi.created_at, HOUR), 100)[OFFSET(90)] / 24, 1)
                                                                           AS dias_total_p90
FROM `bigquery-public-data.thelook_ecommerce.order_items`          AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products`             AS p
  ON p.id = oi.product_id
JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc
  ON dc.id = p.distribution_center_id
WHERE oi.delivered_at IS NOT NULL
GROUP BY centro_distribuicao
ORDER BY dias_total_medio DESC;
