-- =====================================================================
-- 03 · Devolução e cancelamento por categoria
-- Pergunta: em quais categorias os clientes mais devolvem ou cancelam?
-- Técnicas: COUNTIF, HAVING para descartar categorias com pouco volume
-- =====================================================================

SELECT
  p.category                          AS categoria,
  COUNT(*)                            AS itens,
  COUNTIF(oi.status = 'Returned')     AS devolvidos,
  COUNTIF(oi.status = 'Cancelled')    AS cancelados,
  ROUND(100 * COUNTIF(oi.status = 'Returned')  / COUNT(*), 2) AS taxa_devolucao_pct,
  ROUND(100 * COUNTIF(oi.status = 'Cancelled') / COUNT(*), 2) AS taxa_cancelamento_pct
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products`    AS p
  ON p.id = oi.product_id
GROUP BY categoria
-- categorias com pouco volume geram taxas instáveis
HAVING COUNT(*) >= 500
ORDER BY taxa_devolucao_pct DESC;
