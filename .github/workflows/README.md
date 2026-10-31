# Workflows do repositório de banco

Os arquivos de workflow devem ficar diretamente em `.github/workflows/`, na raiz do repositório. Não mover os YAMLs para `rpa/` ou `databases/redis/`: o GitHub Actions não os descobre nessas pastas.

| Workflow | Código executado | Disparo |
| --- | --- | --- |
| `rpa-carga-delta.yml` | `rpa/carga_delta.py` | Manual e a cada cinco minutos |
| `simulacao-temperaturas.yml` | `databases/redis/simulacao_ciclo.py` | Manual e a cada cinco minutos |

Cada domínio mantém scripts, dependências e documentação na sua própria pasta. O workflow apenas prepara o ambiente e chama esses scripts a partir da raiz. Não inclui senhas: as credenciais são fornecidas pelos Secrets do repositório.

O RPA usa `LEGACY_DATABASE_URL` e `SKADI_DATABASE_URL` nos Secrets e executa a carga delta, sem `--completa`. O agendamento começa após publicação na branch padrão, sujeito a atrasos do GitHub. A concorrência impede cargas simultâneas deste workflow; se uma execução demorar mais que cinco minutos, a próxima aguarda, sem interromper a anterior. O timeout continua em quinze minutos.

O workflow de simulação precisa ser publicado na branch padrão para o agendamento funcionar. Ele gera um lote e coleta no Redis, mas não mantém o worker de alertas em execução. Consulte `databases/redis/workflow-simulacao.md` para configuração dos Secrets e limitações.
