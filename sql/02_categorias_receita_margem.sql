-- =====================================================================
-- 02 · Receita e margem por categoria
-- Pergunta: quais categorias trazem mais receita, e elas são as mesmas
--           que trazem mais lucro?
-- Técnicas: JOIN, agregação, RANK, SAFE_DIVIDE
-- =====================================================================

WITH itens_vendidos AS (
  SELECT
    p.category   AS categoria,
    oi.sale_price,
    p.cost
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products`    AS p
    ON p.id = oi.product_id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
)

SELECT
  categoria,
  COUNT(*)                                     AS itens_vendidos,
  ROUND(SUM(sale_price), 2)                    AS receita,
  ROUND(SUM(sale_price - cost), 2)             AS lucro_bruto,
  ROUND(100 * SAFE_DIVIDE(SUM(sale_price - cost), SUM(sale_price)), 1) AS margem_pct,
  RANK() OVER (ORDER BY SUM(sale_price) DESC)        AS posicao_em_receita,
  RANK() OVER (ORDER BY SUM(sale_price - cost) DESC) AS posicao_em_lucro
FROM itens_vendidos
GROUP BY categoria
ORDER BY receita DESC;
