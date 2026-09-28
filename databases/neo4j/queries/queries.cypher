// ============================================================
// QUERY 1 — Visualizar uma câmara e seus lotes
// ============================================================
// Exibe apenas uma câmara frigorífica, os lotes armazenados nela e suas
// categorias. Essa consulta é menor e adequada para uma evidência visual.
MATCH p = (cd:CD {id: 1})
    -[:POSSUI_CAMARA]->(camara:CamaraFrigorifica {id: 1})
    -[:ARMAZENA_LOTE]->(lote:Lote)
    -[:PERTENCE_A_CATEGORIA]->(categoria:Categoria)
RETURN p
LIMIT 5;

// ============================================================
// QUERY 2 — CD, câmaras, lotes e categorias
// ============================================================
// Mostra a estrutura de armazenamento de um CD específico:
// CD → Câmara frigorífica → Lote → Categoria.
MATCH p = (cd:CD)-[:POSSUI_CAMARA]->(camara:CamaraFrigorifica)
    -[:ARMAZENA_LOTE]->(lote:Lote)
    -[:PERTENCE_A_CATEGORIA]->(categoria:Categoria)
WHERE cd.id = 1
RETURN p;