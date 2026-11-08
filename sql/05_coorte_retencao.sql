-- =====================================================================
-- 05 · Retenção por coorte (mês da primeira compra)
-- Pergunta: dos clientes que compraram pela primeira vez em cada mês,
--           quantos % voltaram 1, 2, 3 e 6 meses depois?
-- Técnicas: várias CTEs, DATE_DIFF, pivot com agregação condicional
-- =====================================================================

WITH pedidos AS (
  SELECT
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS mes
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
    -- ignora o mês atual: ainda incompleto, ele derrubaria a retenção
    AND DATE(created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

coorte AS (
  SELECT user_id, MIN(mes) AS mes_coorte
  FROM pedidos
  GROUP BY user_id
),

atividade AS (
  SELECT
    c.mes_coorte,
    DATE_DIFF(p.mes, c.mes_coorte, MONTH) AS meses_depois,
    COUNT(DISTINCT p.user_id)             AS clientes
  FROM pedidos AS p
  JOIN coorte  AS c USING (user_id)
  GROUP BY c.mes_coorte, meses_depois
)

SELECT
  mes_coorte,
  MAX(IF(meses_depois = 0, clientes, NULL)) AS tamanho_coorte,
  ROUND(100 * SAFE_DIVIDE(MAX(IF(meses_depois = 1, clientes, NULL)), MAX(IF(meses_depois = 0, clientes, NULL))), 1) AS m1_pct,
  ROUND(100 * SAFE_DIVIDE(MAX(IF(meses_depois = 2, clientes, NULL)), MAX(IF(meses_depois = 0, clientes, NULL))), 1) AS m2_pct,
  ROUND(100 * SAFE_DIVIDE(MAX(IF(meses_depois = 3, clientes, NULL)), MAX(IF(meses_depois = 0, clientes, NULL))), 1) AS m3_pct,
  ROUND(100 * SAFE_DIVIDE(MAX(IF(meses_depois = 6, clientes, NULL)), MAX(IF(meses_depois = 0, clientes, NULL))), 1) AS m6_pct
FROM atividade
-- últimos 12 meses completos, para a tabela caber no README
WHERE mes_coorte >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 12 MONTH)
  AND mes_coorte <  DATE_TRUNC(CURRENT_DATE(), MONTH)
GROUP BY mes_coorte
ORDER BY mes_coorte;
