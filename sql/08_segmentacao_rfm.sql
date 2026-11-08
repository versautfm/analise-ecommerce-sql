-- =====================================================================
-- 08 · Segmentação de clientes (RFM: Recência, Frequência, Valor)
-- Pergunta: quais grupos de clientes concentram a receita, e quais
--           estão em risco de não voltar?
-- Técnicas: NTILE, CROSS JOIN com data de referência, CASE, % do total
--
-- Limitação: a maioria dos clientes tem 1 pedido só. Por isso a nota de
-- frequência separa pouco os clientes; isso entra na conclusão do README.
-- =====================================================================

WITH base AS (
  SELECT
    user_id,
    MAX(DATE(created_at))    AS ultima_compra,
    COUNT(DISTINCT order_id) AS frequencia,
    SUM(sale_price)          AS valor
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    -- a base pública tem alguns registros com data futura; ficam de fora
    AND DATE(created_at) <= CURRENT_DATE()
  GROUP BY user_id
),

referencia AS (
  -- usa a última data da base, e não a data de hoje,
  -- para a análise não depender do dia em que é executada
  SELECT MAX(ultima_compra) AS data_ref FROM base
),

notas AS (
  SELECT
    b.user_id,
    b.frequencia,
    b.valor,
    DATE_DIFF(ref.data_ref, b.ultima_compra, DAY) AS recencia_dias,
    -- nota 5 = melhor (comprou há menos tempo, compra mais, gasta mais)
    NTILE(5) OVER (ORDER BY DATE_DIFF(ref.data_ref, b.ultima_compra, DAY) DESC) AS nota_r,
    NTILE(5) OVER (ORDER BY b.frequencia) AS nota_f,
    NTILE(5) OVER (ORDER BY b.valor)      AS nota_m
  FROM base AS b
  CROSS JOIN referencia AS ref
),

segmentos AS (
  SELECT
    *,
    CASE
      WHEN nota_r >= 4 AND nota_m >= 4 THEN 'Campeões'
      WHEN nota_r >= 4 AND nota_m <= 2 THEN 'Novos ou promissores'
      WHEN nota_r <= 2 AND nota_m >= 4 THEN 'Em risco (gastavam muito)'
      WHEN nota_r <= 2 AND nota_m <= 2 THEN 'Perdidos'
      ELSE 'Regulares'
    END AS segmento
  FROM notas
)

SELECT
  segmento,
  COUNT(*)                                         AS clientes,
  ROUND(AVG(recencia_dias))                        AS recencia_media_dias,
  ROUND(AVG(frequencia), 2)                        AS pedidos_medios,
  ROUND(SUM(valor), 2)                             AS receita,
  ROUND(100 * SUM(valor) / SUM(SUM(valor)) OVER (), 1) AS pct_da_receita
FROM segmentos
GROUP BY segmento
ORDER BY receita DESC;
