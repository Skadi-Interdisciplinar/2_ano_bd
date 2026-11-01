// ============================================================
// PERGUNTA DE NEGÓCIO — TRAVERSAL
// ============================================================
// A pergunta busca identificar quais usuários trabalham no mesmo CD de uma
// câmara que armazena lotes da categoria informada em $categoria_nome e possui um atendimento
// em aberto.
//
// Para responder, é necessário percorrer diferentes partes do grafo:
// usuário, CD, câmara frigorífica, lote, categoria, alerta e atendimento.
// Portanto, não é uma simples busca por um nó isolado.

MATCH path_categoria = (usuario:Usuario)-[:TRABALHA_NO_CD]->(cd:CD)
    -[:POSSUI_CAMARA]->(camara:CamaraFrigorifica)
    -[:ARMAZENA_LOTE]->(lote:Lote)
    -[:PERTENCE_A_CATEGORIA]->(categoria:Categoria)
MATCH path_alerta = (camara)-[:GEROU_ALERTA]->(alerta:Alerta)
    -[:POSSUI_ATENDIMENTO]->(atendimento:Atendimento)
WHERE categoria.nome = $categoria_nome
  AND atendimento.status IN ['PENDENTE', 'EM_ANDAMENTO']
RETURN path_categoria, path_alerta;
