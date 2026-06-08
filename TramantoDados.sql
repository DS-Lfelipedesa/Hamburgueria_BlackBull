SELECT Descricao,
       Tipo,
       PedidoID,
       substr(Descricao, length(Descricao) - 7, 8) AS ultimos_8_digitos
FROM financeiro
WHERE Tipo = 'Receita'
  AND (PedidoID IS NULL OR PedidoID = '');