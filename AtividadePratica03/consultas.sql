-- 1. NUMERAÇÃO CRONOLÓGICA DE COMPRAS
-- Enumera as compras de cada cliente em ordem cronológica.
SELECT
    c.nome AS cliente,
    v.dt_venda,
    v.valor_liquido,
    ROW_NUMBER() OVER (
        PARTITION BY c.id_cliente
        ORDER BY v.dt_venda, v.id_venda
    ) AS numero_compra
FROM tb_cliente c
JOIN tb_venda v
    ON c.id_cliente = v.id_cliente
ORDER BY
    c.nome,
    v.dt_venda,
    v.id_venda;


-- 2. PARTICIPAÇÃO PERCENTUAL NO FATURAMENTO
-- Calcula o faturamento fechado de cada vendedor e seu percentual
-- em relação ao faturamento fechado total da empresa.
WITH faturamento_vendedor AS (
    SELECT
        ven.id_vendedor,
        ven.nome AS vendedor,
        NVL(SUM(v.valor_liquido), 0) AS faturamento_total
    FROM tb_vendedor ven
    LEFT JOIN tb_venda v
        ON ven.id_vendedor = v.id_vendedor
        AND v.status = 'FECHADA'
    GROUP BY
        ven.id_vendedor,
        ven.nome
)
SELECT
    vendedor,
    faturamento_total,
    ROUND(
        faturamento_total / NULLIF(SUM(faturamento_total) OVER (), 0) * 100,
        2
    ) AS percentual_faturamento
FROM faturamento_vendedor
ORDER BY
    faturamento_total DESC,
    vendedor;


-- 3. RANKING MENSAL DE VENDEDORES
-- A CTE calcula a receita mensal por vendedor.
-- O DENSE_RANK reinicia o ranking a cada mês.
WITH receita_mensal_vendedor AS (
    SELECT
        TRUNC(v.dt_venda, 'MM') AS mes_ref,
        ven.id_vendedor,
        ven.nome AS vendedor,
        SUM(v.valor_liquido) AS receita_mensal
    FROM tb_vendedor ven
    JOIN tb_venda v
        ON ven.id_vendedor = v.id_vendedor
    WHERE v.status = 'FECHADA'
    GROUP BY
        TRUNC(v.dt_venda, 'MM'),
        ven.id_vendedor,
        ven.nome
)
SELECT
    mes_ref,
    vendedor,
    receita_mensal,
    DENSE_RANK() OVER (
        PARTITION BY mes_ref
        ORDER BY receita_mensal DESC
    ) AS ranking_mensal
FROM receita_mensal_vendedor
ORDER BY
    mes_ref,
    ranking_mensal,
    vendedor;


-- 4. TERMÔMETRO DE VENDAS
-- Calcula a diferença entre cada venda e a média geral
-- de todas as vendas da empresa.
SELECT
    id_venda,
    valor_liquido,
    ROUND(
        valor_liquido - AVG(valor_liquido) OVER (),
        2
    ) AS diferenca_para_media
FROM tb_venda
ORDER BY id_venda;


-- 5. OS 3 PRODUTOS MAIS VENDIDOS
-- Primeiro somamos a quantidade vendida por produto.
-- Depois usamos ROW_NUMBER para garantir exatamente os 3 primeiros.
WITH quantidade_produto AS (
    SELECT
        p.id_produto,
        p.nome AS produto,
        SUM(i.quantidade) AS total_vendido
    FROM tb_produto p
    JOIN tb_venda_item i
        ON p.id_produto = i.id_produto
    GROUP BY
        p.id_produto,
        p.nome
),
ranking_produtos AS (
    SELECT
        id_produto,
        produto,
        total_vendido,
        ROW_NUMBER() OVER (
            ORDER BY total_vendido DESC, id_produto
        ) AS ranking
    FROM quantidade_produto
)
SELECT
    produto,
    total_vendido,
    ranking
FROM ranking_produtos
WHERE ranking <= 3
ORDER BY
    ranking;