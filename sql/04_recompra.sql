-- =====================================================================
-- 04 · Taxa de recompra e tempo até a segunda compra
-- Pergunta: quantos clientes voltam a comprar, e quanto tempo levam?
-- Técnicas: ROW_NUMBER, agregação condicional, APPROX_QUANTILES (mediana)
-- =====================================================================

WITH pedidos_numerados AS (
  SELECT
    user_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) AS n_pedido
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
),

por_cliente AS (
  SELECT
    user_id,
    COUNT(*)                                AS total_pedidos,
    MIN(IF(n_pedido = 1, created_at, NULL)) AS primeira_compra,
    MIN(IF(n_pedido = 2, created_at, NULL)) AS segunda_compra
  FROM pedidos_numerados
  GROUP BY user_id
)

SELECT
  COUNT(*)                                          AS clientes_compradores,
  COUNTIF(total_pedidos > 1)                        AS clientes_que_recompraram,
  ROUND(100 * COUNTIF(total_pedidos > 1) / COUNT(*), 1) AS taxa_recompra_pct,
  -- APPROX_QUANTILES ignora os NULLs (clientes sem segunda compra)
  APPROX_QUANTILES(TIMESTAMP_DIFF(segunda_compra, primeira_compra, DAY), 2)[OFFSET(1)]
                                                    AS mediana_dias_ate_2a_compra
FROM por_cliente;
