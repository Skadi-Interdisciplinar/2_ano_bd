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

Os campos do legado sem destino equivalente não são copiados: `Frigorifico.nome`, `Usuario.cargo` e `Termometro.status`.

## Pré-requisitos

No legado, as tabelas sincronizadas devem ter `data_atualizacao` preenchida em inserções e atualizações. O modelo esperado inclui:

- `frigorifico.modelo`, `frigorifico.temperatura_min` e `frigorifico.temperatura_max`;
- `categoria.temperatura_min`, `categoria.temperatura_max` e `categoria.vida_util_horas`;
- `usuario.nivel_acesso` com `super_admin`, quando aplicável;
- um termômetro por frigorífico.

No destino, `tb_controle_rpa` guarda a data da última carga concluída. Exclusões físicas no legado não são sincronizadas.

## Execução local

```powershell
pip install -r rpa/requirements.txt
$env:LEGACY_DATABASE_URL = "postgresql://usuario:senha@host:5432/skadi_primeiro"
$env:SKADI_DATABASE_URL = "postgresql://usuario:senha@host:5432/skadi"
python rpa/carga_delta.py --completa
```

Após a carga inicial, execute sem `--completa` para trazer somente registros com `data_atualizacao` posterior à última carga bem-sucedida.
