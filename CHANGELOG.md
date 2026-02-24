# 📋 CHANGELOG - Ollama Tool Tester

**Projeto:** Ollama Tool Tester - Function Calling Validator  
**Empresa:** SAB Tecnologia e Serviços  
**Repositório:** https://github.com/sabtecno/ollama-tool-tester-beta

---

## 🔄 SISTEMA DE VERSIONAMENTO

### Padrão de Versão:
```
Beta-vX.Y.Z
│    │ │ │
│    │ │ └── Patch (correções menores)
│    │ └── Minor (novas funcionalidades)
│    └── Major (mudanças significativas)
└── Fase (Alpha/Beta/Release)
```

---

## 📦 RELEASES

---

### Beta-v0.0.3 (2026-02-24)

**Autor:** Sabrina (SAB-01)

#### ✅ Novas Funcionalidades:

1. **Variável RELATORIO_FILE**
   - Novo caminho para armazenar relatório completo
   - Formato: `{results_dir}/tools_test_{version}_{timestamp}_relatorio.txt`

2. **Arquivos de Saída Expandidos**
   - **CSV**: Resultados em formato CSV para análise
   - **LOG**: Log completo de execução
   - **SYSINFO**: Informações detalhadas do sistema
   - **RELATÓRIO**: Relatório completo formatado

3. **Seção de Geração de Relatório**
   - Cabeçalho corporativo SAB TEC
   - Metadados do projeto (nome, versão, release, script)
   - Informações do desenvolvedor
   - Dados de contato e GitHub
   - Informações completas do sistema operacional
   - Detalhes de virtualização detectada
   - Especificações de hardware (CPU, RAM)
   - Versão do Ollama
   - Tabela resumo dos testes
   - Detalhamento completo dos testes (T1, T2, T3)
   - Legendas explicativas
   - Níveis de suporte documentados
   - Lista de arquivos gerados
   - Próximos passos recomendados

#### 📊 Status:
- ✅ Script funcional
- ✅ README atualizado
- ✅ CHANGELOG criado
- ⏳ Testes com modelos locais

---

### Beta-v0.0.2 (2026-02-21)

**Autor:** Tiago Sant Anna

#### ✅ Funcionalidades:

1. **Testes de Function Calling**
   - Teste 1: Consciência de tools
   - Teste 2: Descrição de ferramentas
   - Teste 3: Function calling estruturado (JSON)

2. **Interface Visual**
   - Logo ASCII art com lolcat
   - Cores corporativas SAB TEC
   - Menu interativo de sudo

3. **Detecção de Sistema**
   - Auto-detecção de virtualização (Hyper-V)
   - Informações de hardware
   - Versão do Ollama

---

### Beta-v0.0.1 (2026-02-20)

**Autor:** Tiago Sant Anna

#### ✅ Versão Inicial:
- Script básico de teste de tools
- Estrutura de projeto criada
- README inicial

---

**Documento criado:** 2026-02-24  
**Mantido por:** Sabrina (SAB-01)
