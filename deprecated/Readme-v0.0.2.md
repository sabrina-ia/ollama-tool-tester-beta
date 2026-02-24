# Ollama Tool Tester Beta 🛠️

**Ferramenta de Teste de Capacidades Tool/Function Calling para Modelos Ollama**

O **Ollama Tool Tester Beta** é um toolkit open-source de avaliação e validação de *tool calling* (chamada de ferramentas) para modelos Ollama, projetado para testar e qualificar LLMs na execução de funções externas através do ecossistema OpenClaw.

## 🏢 Sobre Este Projeto
Este projeto é desenvolvido e mantido por **SAB Tecnologia e Serviços**, sendo parte do ecossistema de IA Autônoma **S.A.B.R.I.N.A.**.
&gt; ⚠️ **Nota**: Este é um componente standalone de IA atualmente em desenvolvimento privado.

| Aspecto | Detalhe |
|---------|---------|
| **Empresa Desenvolvedora** | SAB Tecnologia e Serviços |
| **GitHub Corporativo** | [github.com/sabtecno](https://github.com/sabtecno) |
| **Projeto de IA** | Sabrina - IA Autônoma |
| **GitHub do Projeto** | [github.com/sabrina-ia](https://github.com/sabrina-ia) |
| **Gestão do Repositório** | Autônomo via Sabrina IA |

> **Nota:** Este repositório é operado pela IA Autônoma Sabrina em nome da SAB Tecnologia e Serviços. Issues, pull requests e manutenção são gerenciados automaticamente pelo sistema de IA.

## Propósito

Originalmente desenvolvido para validar capacidades de tool calling para o projeto SABRINA, o Ollama Tool Tester Beta agora está disponível para a comunidade testar quais modelos Ollama conseguem utilizar ferramentas externas (tools) em seus próprios projetos com OpenClaw.

## O que é Testado

Este script avalia se os modelos conseguem:
- **Interpretar schemas de ferramentas** (function definitions)
- **Invocar ferramentas corretamente** via OpenClaw
- **Passar parâmetros adequados** para funções externas
- **Processar retornos de ferramentas** e integrar à resposta final
- **Multi-step reasoning** com sequências de chamadas de ferramentas

## Características

- **Validação de Tool Calling**: Testa compatibilidade nativa de modelos com function calling
- **Integração OpenClaw**: Validador oficial para o ecossistema OpenClaw
- **Testes Multi-Ferramenta**: Avalia uso de Web Search, Calculadora, APIs e funções customizadas
- **Relatórios de Compatibilidade**: Lista quais modelos suportam tools nativamente vs. via prompting
- **Métricas de Precisão**: Taxa de sucesso na chamada correta de ferramentas
- **Modo Debug**: Logs detalhados das interações modelo-ferramenta

## Instalação Rápida

```bash
# Clone o repositório
git clone https://github.com/sabtecno/ollama-tool-tester-beta.git
cd ollama-tool-tester-beta

# Execute o script
chmod +x ollama-tool-tester-beta-v0.0.3.sh
./ollama-tool-tester-beta-v0.0.3.sh
```

## 📦 Changelog

### Beta-v0.0.3 (2026-02-24)
**Principais alterações:**
- ✅ Nova variável `RELATORIO_FILE` para armazenar caminho do relatório
- ✅ Arquivos de saída atualizados:
  - **CSV**: Resultados em formato CSV
  - **LOG**: Log de execução
  - **SYSINFO**: Informações do sistema
  - **RELATÓRIO**: Relatório completo formatado
- ✅ Seção de geração do relatório no final do script:
  - Cabeçalho corporativo
  - Metadados do projeto
  - Informações completas do sistema
  - Tabela resumo dos testes
  - Detalhamento dos testes (legendas explicativas)
  - Níveis de suporte
  - Lista de arquivos gerados

### Beta-v0.0.2 (2026-02-21)
- Versão inicial pública
- Testes básicos de function calling

---

## 🔄 Versionamento

Este projeto segue versionamento semântico:
- **MAJOR**: Mudanças incompatíveis
- **MINOR**: Novas funcionalidades
- **PATCH**: Correções e melhorias

Cada release inclui relatório técnico das mudanças.
### Infraestrutura Testada ✅
| Componente | Especificação                              |
| ---------- | ------------------------------------------ |
| **CPU**    | Intel Xeon E5-2680 v4 @ 2.40GHz            |
| **RAM**    | 32GB                                       |
| **GPU**    | AMD Radeon R5 220 (2GB) - Offboard Simples |

### Stack de Software
| Camada                    | Tecnologia       |
| ------------------------- | ---------------- |
| **Host OS**               | Windows 10       |
| **Virtualizador**         | Hyper-V          |
| **Guest OS**              | Ubuntu 24.04 LTS |
| **Orquestração de Tools** | OpenClaw         |
| **LLM Backend**           | Ollama           |
| **Web Search**            | SearXNG          |
| **Interface**             | OpenWebUI        |
✅ Status: Todos os componentes instalados, atualizados e operacionais (100%)

### Dependências
Ollama com suporte a tool calling
OpenClaw instalado e configurado
Bash 4.0+
jq (processamento JSON)
curl

## Uso
./ollama-tool-tester-beta-v0.0.1.sh [opções]

### Opções disponíveis:
-m, --model : Especifica o modelo a ser testado (ex: llama3.1, mistral, qwen2.5)
-t, --tools : Define quais ferramentas testar (web_search, calculator, custom)
-s, --strict : Modo estrito - falha se modelo não suportar tool calling nativo
-j, --json : Saída em formato JSON para integração CI/CD
-v, --verbose : Modo debug com logs completos das chamadas
-h, --help : Exibe ajuda completa

# Testar modelo com todas as ferramentas disponíveis
./ollama-tool-tester-beta-v0.0.2.sh -m llama3.1 -t all

# Testar apenas web search em modo estrito
./ollama-tool-tester-beta-v0.0.2.sh -m mistral -t web_search -s

# Exportar resultados para CI/CD
./ollama-tool-tester-beta-v0.0.2.sh -m qwen2.5 -j > results.json

# Estrutura do Projeto
ollama-tool-tester/
├── ollama-tool-tester-beta-v0.0.1.sh   # Script principal de testes
├── tools/                               # Definições de ferramentas de teste
│   ├── web_search.json                  # Schema SearXNG
│   ├── calculator.json                  # Schema calculadora
│   └── weather_api.json                 # Exemplo API externa
├── test-cases/                          # Casos de teste por categoria
│   ├── single-tool/
│   ├── multi-tool/
│   └── parallel-tools/
├── validators/                          # Validadores de resposta
├── reports/                             # Templates de relatório
└── docs/                               # Documentação de integração OpenClaw

# Resultados dos Testes
## O script gera:
🔧 Relatório de Compatibilidade - Lista verde/vermelho por modelo
📊 Métricas de Tool Calling - Taxa de acerto nas invocações
🐛 Log de Erros - Casos onde o modelo falhou em chamar ferramentas
📈 Benchmark Comparativo - Ranking de modelos por capacidade de tools
🔌 Arquivo de Configuração - JSON pronto para uso no OpenClaw

### Modelos Testados (Exemplos)
| Modelo    | Tool Calling Nativo | Notas                       |
| --------- | ------------------- | --------------------------- |
| llama3.1  | ✅ Sim               | Excelente suporte a tools   |
| mistral   | ✅ Sim               | Via fine-tuning específico  |
| qwen2.5   | ✅ Sim               | Muito preciso em parâmetros |
| llama2    | ❌ Não               | Requer prompting manual     |
| codellama | ⚠️ Parcial          | Bom em tools de código      |

# Roadmap
[ ] Suporte a ferramentas com autenticação OAuth
[ ] Testes de ferramentas com streaming de respostas
[ ] Validação automática de schemas OpenAPI
[ ] Integração com MCP (Model Context Protocol)
[ ] Modo stress-test com 100+ chamadas sequenciais
[ ] Dashboard web de compatibilidade de modelos

# 👥 EQUIPE
| Entidade                      | Função                               | GitHub                                      | Observação                     |
| ----------------------------- | ------------------------------------ | ------------------------------------------- | ------------------------------ |
| **SAB Tecnologia e Serviços** | Empresa Desenvolvedora               | [sabtecno](https://github.com/sabtecno)     | Responsável técnica e legal    |
| **Sabrina**                   | IA Autônoma / Mantenedora do Projeto | [sabrina-ia](https://github.com/sabrina-ia) | Gestão autônoma do repositório |
| **Tiago Sant Anna**           | CEO / Arquiteto de IA                | [sabtecno](https://github.com/sabtecno)     | Supervisão estratégica         |


# Contribuição
Contribuições são bem-vindas! Por favor, leia nosso CONTRIBUTING.md antes de submeter PRs.

# Licença
Este projeto está licenciado sob a MIT License.

# Sobre a SAB TEC
Desenvolvido por: Tiago Sant Anna
Cargo: AI Engineer | Especialista em LLMs & Agentes Autônomos
Empresa: SAB TEC - Tecnologia e Serviços
Contato: sab.tecno@gmail.com
GitHub: https://github.com/sabtecno

# Versão: Beta-v0.0.3
Data de Lançamento: 2026-02-24
Licenciado por: SAB Tecnologia e Serviços © 2026

# Recursos Adicionais
📖 Documentação OpenClaw
🦙 Modelos Ollama com Tool Support
🔍 Configuração SearXNG

## 📸 Screenshots

Abaixo estão imagens do **Ollama Tool Tester Beta** em funcionamento:

### Tela Inicial - Logo ASCII Art
![Tela Inicial](screenshots/ollama-tool-testes-01.png)

### Menu Interativo
![Menu Interativo](screenshots/ollama-tool-testes-02.png)

### Execução dos Benchmarks
![Execução Benchmarks](screenshots/ollama-tool-testes-03.png)

### Resultados e Métricas
![Resultados](screenshots/ollama-tool-testes-04.png)

## Agradecimentos
Este projeto ganhou forma graças à invaluable ajuda e suporte da Comunidade Automatik. A troca de conhecimentos, feedback técnico e colaboração dentro desta comunidade foram fundamentais para o desenvolvimento e aprimoramento desta ferramenta.
### Agradecimentos especiais a:
Rafa Martins - Comunidade Automatik
Claudeir Ribeiro - Comunidade Automatik

## Referências
| Recurso                 | Link                               |
| ----------------------- | ---------------------------------- |
| **Automatik**           | <https://mundoautomatik.com/>      |
| **Automatik \| Grupos** | <https://links.mundoautomatik.com> |
| **Telegram\|Automatik** | <https://t.me/mundoautomatik>      |
| **Openclaw**            | <https://openclaw.ai>              |