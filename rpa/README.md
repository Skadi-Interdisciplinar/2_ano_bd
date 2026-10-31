# RPA de carga delta

Este script sincroniza os dados operacionais do PostgreSQL legado com o PostgreSQL do Skadi.

Ele preserva os IDs do legado no destino e executa `INSERT ... ON CONFLICT (id) DO UPDATE`.
Por isso, a carga inicial deve ocorrer antes de existirem registros conflitantes nas tabelas de destino.

## Dados sincronizados

- `CD` → `tb_cd`
- `Endereco` → `tb_endereco`
- `Usuario` → `tb_usuario`
- `Categoria` → `tb_categoria`
- `Termometro` → `tb_termometro`
- `Frigorifico` → `tb_camara_frigorifica`
- `Lote` → `tb_lote`
- `lote_frigorifico` → `tb_lote_camara_frigorifica`

As colunas extras do legado sem destino equivalente não são copiadas, como `Usuario.cargo` e `Termometro.status`.

O legado precisa possuir `Frigorifico.localizacao`, `Frigorifico.temperatura_min` e `Frigorifico.temperatura_max`. Esses campos são copiados diretamente; se estiverem ausentes ou inválidos, a carga falha sem atualizar o controle de execução. Câmara frigorífica não possui campo de modelo no destino; o modelo do termômetro continua sendo copiado normalmente.

Os valores controlados precisam chegar ao legado no padrão do destino (`SUPER_ADMIN`, `ADMIN`, `GESTOR`, `OPERADOR` e `ATIVO`, `BLOQUEADO`, `EXPEDIDO`, `VENDIDO`). O RPA valida esses valores e interrompe a carga quando encontrar um valor inválido; ele não cria vínculos, troca CDs ou corrige dados automaticamente.

Para usuários, as regras do banco são respeitadas diretamente: `SUPER_ADMIN`, `ADMIN` e `GESTOR` não podem possuir `cod_gestor`, e `OPERADOR` precisa possuir um gestor válido no mesmo CD. Dados fora dessas regras devem ser corrigidos no legado antes da nova execução.

## Pré-requisitos

No legado, as tabelas sincronizadas devem ter `data_atualizacao` preenchida em inserções e atualizações. O modelo esperado inclui:

- `frigorifico.temperatura_min` e `frigorifico.temperatura_max`;
- `categoria.temperatura_min`, `categoria.temperatura_max` e `categoria.vida_util_horas`;
- `usuario.nivel_acesso` com `super_admin`, quando aplicável;
- um termômetro por frigorífico.

O RPA lê `vida_util_horas` do legado em horas numéricas e converte para `INTERVAL` ao gravar no PostgreSQL normalizado.

No destino, `tb_controle_rpa` guarda a data da última carga concluída. Exclusões físicas no legado não são sincronizadas.

## Execução local

```powershell
pip install -r rpa/requirements.txt
$env:LEGACY_DATABASE_URL = "postgresql://usuario:senha@host:5432/skadi_primeiro"
$env:SKADI_DATABASE_URL = "postgresql://usuario:senha@host:5432/skadi"
python rpa/carga_delta.py --completa
```

Após a carga inicial, execute sem `--completa` para trazer somente registros com `data_atualizacao` posterior à última carga bem-sucedida.
