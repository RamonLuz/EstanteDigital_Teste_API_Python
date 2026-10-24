# EstanteDigital - QA de API com Behave

Este repositório é uma suíte independente de QA para testar a API EstanteDigital como caixa-preta. A aplicação Java é o sistema sob teste; este projeto contém somente automação, dados de teste e critérios de aceitação.

Os critérios funcionais e os casos de teste existentes no projeto RestAssured são preservados em features Gherkin por recurso. A implementação Python usa as convenções da linguagem, sem reproduzir a arquitetura Java: módulos em `snake_case`, classes em `PascalCase`, type hints, `dataclass` para configurações e Ruff para lint e formatação.

## Objetivo de QA

- Verificar comportamento observável da API, status HTTP, respostas e regras de validação.
- Detectar e evidenciar diferenças entre o resultado real da API e os critérios esperados nos testes.
- Manter os critérios de teste estáveis: uma falha que revela divergência da API deve ser investigada como defeito, não escondida alterando a expectativa para fazer a suíte passar.
- Manter os cenários independentes da implementação da aplicação; nenhuma regra de negócio é corrigida neste repositório de testes.

Os casos de regressão foram alinhados à suíte RestAssured existente. Quando o resultado atual da API contradiz esses critérios, o teste permanece falhando e a divergência é documentada para triagem de QA.

## Arquitetura

```text
features/
  books/ customers/ employees/ health/ sales/
  steps/common_steps.py
  environment.py
payloads/
  books/ customers/ employees/ sales/
schemas/
  books/ customers/ employees/ health/ sales/
  common/
src/estantedigital_api_tests/
  api_client.py
  response_contract.py
  test_data.py
```

O fluxo é `feature -> step compartilhado -> ApiClient -> API`. O cliente mantém base URL, headers JSON, autenticação e timeout fora das features. Os hooks criam dados e contexto independentes por cenário e imprimem a última resposta HTTP quando um cenário falha.

As respostas são verificadas automaticamente contra os schemas em `schemas/`, escolhidos por método, rota e status HTTP. As respostas 204 e 404 são verificadas como vazias; erros 400 usam o contrato compartilhado `common/api-error.schema.json`. Ao alterar o contrato da API, atualize o schema correspondente e os cenários.

## Trilha para estudar o projeto

1. Comece por `features/books/books.feature`: cada cenário descreve uma verificacao de QA em linguagem simples.
2. Abra o payload mencionado, por exemplo `payloads/books/create-book.json`: ele representa os dados enviados a API.
3. Encontre a frase do cenário em `features/steps/common_steps.py`: o step prepara o payload, envia a chamada e verifica o resultado.
4. Consulte `src/estantedigital_api_tests/api_client.py`: esse módulo reúne a configuração e o pedido HTTP.
5. Consulte `schemas/books/book.schema.json`: o contrato descreve o formato esperado da resposta.
6. Rode `behave features\books` para executar os cenários de QA da API de livros.

O módulo `test_data.py` gera dados únicos e carrega os payloads JSON usados pelos cenários. O módulo `response_contract.py` valida o formato das respostas. O cenário não precisa conhecer esses detalhes: essa separação mantém os critérios de QA fáceis de ler e os componentes técnicos reutilizáveis.

O escopo deste projeto é testar a API como caixa-preta com Behave, não executar testes unitários da aplicação Spring Boot nem dos componentes internos da automação.

## Requisitos

- Python 3.11 ou superior
- API EstanteDigital em execução (Java 21/Maven para iniciar a aplicação)
- Ruff para verificar e formatar o código Python

## Instalação no Windows

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
Copy-Item .env.example .env
```

Inicie a API em outro terminal:

```powershell
Set-Location C:\Projeto\EstanteDigital\APIs
.\mvnw.cmd spring-boot:run
```

## Configuração

Crie um `.env` local a partir de `.env.example`, ou configure variáveis de ambiente:

| Configuração | Variável de ambiente | Padrão |
| --- | --- | --- |
| URL base | `API_BASE_URL` | `http://localhost:8080` |
| Timeout em segundos | `API_TIMEOUT_SECONDS` | `10` |
| Token Bearer (opcional) | `API_TOKEN` | sem autenticação |

A precedência é: variável de ambiente > opção `-D` do Behave > `.env` > valor padrão. Exemplo:

```powershell
$env:API_BASE_URL = "http://localhost:8081"
$env:API_TOKEN = "seu-token"
behave
```

Ou:

```powershell
behave -D base_url=http://localhost:8081 -D timeout=20 -D token=seu-token
```

Não versione credenciais nem tokens. O `.env` está ignorado pelo Git.

## Executar cenários

Na raiz do projeto, com o ambiente virtual ativado e a API disponível:

```powershell
behave
```

Selecionar smoke, regressão ou um recurso:

```powershell
behave -t "@smoke"
behave -t "@regression"
behave features\books
behave features\sales
```

Gerar relatório JUnit:

```powershell
behave -f junit -o reports\junit
```

Verificar o estilo e a ordenação dos imports:

```powershell
ruff check .
```

Formatar os arquivos Python no padrão configurado:

```powershell
ruff format .
```

## Convenções

- Siga PEP 8: quatro espaços, imports organizados, `snake_case` para módulos/variáveis/funções e `PascalCase` para classes.
- Mantenha o formato e as regras de lint centralizados em `pyproject.toml`; rode `ruff check .` antes de enviar alterações.
- Mantenha steps reutilizáveis em `features/steps/common_steps.py`; crie steps específicos por recurso somente quando houver comportamento exclusivo.
- Deixe corpos JSON em `payloads/<recurso>/` e referencie o arquivo na feature.
- Mantenha os cenários por recurso em `features/<recurso>/`, usando descrições de comportamento em Gherkin.
- Preserve as tags `@smoke` e `@regression` para permitir execuções seletivas.
- Identifique os principais casos funcionais com códigos sequenciais `CT001` a `CT011`.
- Não compartilhe estado entre cenários; IDs e dados de teste são gerados no contexto individual.
- Atualize os JSON Schemas junto aos DTOs quando o contrato mudar.

## Referências de estilo Python

- [PEP 8 - Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [Documentação Ruff - Configuração](https://docs.astral.sh/ruff/configuration/)
- [Documentação Behave - Getting Started](https://behave.readthedocs.io/en/stable/)
- [Documentação Python - Packaging projects](https://packaging.python.org/en/latest/tutorials/packaging-projects/)

## Cobertura

A suíte replica os cenários funcionais e de regressão do projeto RestAssured para health, livros, clientes, funcionários e vendas. Inclui operações CRUD aplicáveis, contratos das respostas, campos obrigatórios e opcionais, corpos ausentes, valores nulos/inválidos, IDs malformados ou inexistentes, duplicidade e associações necessárias para vendas.

### Divergência observada na API

Na execução contra a API atual, os cenários de CPF com mais de 11 dígitos falham para clientes e funcionários: a API responde HTTP 201, enquanto os testes RestAssured de referência esperam HTTP 400. Os cenários Python mantêm a expectativa de referência; ela não foi enfraquecida para esconder a diferença nem a API Java foi alterada nesta tarefa.
