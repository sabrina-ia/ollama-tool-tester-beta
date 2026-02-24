#!/bin/bash
# =============================================================================
#  ███████  █████  ██████      ████████ ███████ ██████  
#  ██      ██   ██ ██   ██        ██    ██      ██   ██ 
#  ███████ ███████ ██████         ██    █████   ██████  
#       ██ ██   ██ ██   ██        ██    ██      ██      
#  ███████ ██   ██ ██████         ██    ███████ ███████ 
# =============================================================================
# SAB TEC - Tecnologia e Serviços
# Teste de Function Calling Tools para Modelos Ollama | beta-v.0.0.2
# =============================================================================

# =============================================================================
# METADADOS DO PROJETO
# =============================================================================
PROJECT_NAME="Ollama Tool Tester - Function Calling Validator"
VERSION="beta-v.0.0.2"
COMPANY="SAB TEC - Tecnologia e Serviços"
CONTACT="sab.tecno.ia@gmail.com"
GITHUB="https://github.com/sabrina-ia"
ISSUES="https://github.com/sabrina-ia"
DEVELOPER="Tiago Sant Anna"
ROLE="AI Engineer | Especialista em LLMs & Agentes Autônomos"
SCRIPT_NAME="ollama-tool-tester-${VERSION}.sh"
RELEASE_DATE="2026-02-24"

DESCRIPTION="Script profissional para validação de Function Calling (Tools) em 
modelos locais do Ollama. Essencial para integração com frameworks como OpenClaw.
Testado em ambiente de produção Ubuntu 24.04 LTS em Hyper-V.
Recursos: Auto-detecção de modelos | Auto-chmod | Sudo-check interativo |
Validação de tools nativas | System Info completo | Hyper-V detection |
Visualização colorida com lolcat e figlet."

# =============================================================================
# CONFIGURAÇÕES DE LOG
# =============================================================================
LOG_TIMESTAMP_FORMAT="%Y-%m-%d %H:%M:%S"
LOG_FILE="/tmp/ollama-tool-tester-${VERSION}-$(date +%Y%m%d_%H%M%S).log"
MAX_INSTALL_ATTEMPTS=3
ERROR_TIMEOUT=20

# =============================================================================
# FUNÇÃO DE LOG COM TIMESTAMP
# =============================================================================
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"$LOG_TIMESTAMP_FORMAT")
    local log_entry="[$timestamp] [$level] $message"
    
    # Escreve no arquivo de log
    echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
    
    # Exibe no console conforme nível
    case "$level" in
        "ERROR")
            echo -e "${RED}❌ $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "INFO")
            echo -e "${CYAN}ℹ️  $message${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "DEBUG")
            # Só loga no arquivo, não exibe
            ;;
    esac
}

# Inicializa log
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
log_message "INFO" "Iniciando $PROJECT_NAME v$VERSION"

# =============================================================================
# CORES BÁSICAS (antes de verificar lolcat)
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# VERIFICAÇÃO CORRETA DO LOCAT (incluindo /usr/games)
# =============================================================================
LOLCAT_CMD=""

find_lolcat() {
    # Verifica PATH padrão
    if command -v lolcat &> /dev/null; then
        LOLCAT_CMD=$(command -v lolcat)
        return 0
    fi
    
    # Verifica /usr/games (local comum no Ubuntu)
    if [ -x "/usr/games/lolcat" ]; then
        LOLCAT_CMD="/usr/games/lolcat"
        return 0
    fi
    
    # Verifica /usr/local/games
    if [ -x "/usr/local/games/lolcat" ]; then
        LOLCAT_CMD="/usr/local/games/lolcat"
        return 0
    fi
    
    # Verifica /opt
    if [ -x "/opt/lolcat/bin/lolcat" ]; then
        LOLCAT_CMD="/opt/lolcat/bin/lolcat"
        return 0
    fi
    
    return 1
}

# Tenta encontrar lolcat
find_lolcat
if [ -n "$LOLCAT_CMD" ]; then
    log_message "INFO" "lolcat encontrado em: $LOLCAT_CMD"
else
    log_message "WARN" "lolcat não encontrado no PATH ou locais alternativos"
fi

# =============================================================================
# FUNÇÃO: VERIFICAR E INSTALAR DEPENDÊNCIAS (máximo 3 tentativas)
# =============================================================================

check_and_install_dependencies() {
    local deps=("lolcat" "figlet" "bc" "jq" "dos2unix")
    local missing=()
    local needs_restart=false
    local install_attempt=0
    
    log_message "INFO" "Verificando dependências do sistema..."
    
    for dep in "${deps[@]}"; do
        if [ "$dep" = "lolcat" ]; then
            if ! find_lolcat; then
                missing+=("$dep")
            fi
        elif ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_message "WARN" "Dependências ausentes: ${missing[*]}"
        
        # Loop de tentativas (máximo 3)
        while [ $install_attempt -lt $MAX_INSTALL_ATTEMPTS ]; do
            install_attempt=$((install_attempt + 1))
            log_message "INFO" "Tentativa de instalação $install_attempt de $MAX_INSTALL_ATTEMPTS..."
            
            if [ "$EUID" -ne 0 ]; then
                echo -e "${YELLOW}🔐 Será necessário privilégio sudo para instalar dependências.${NC}"
                echo -e "${CYAN}⏳ Aguardando 5 segundos... (Ctrl+C para cancelar)${NC}"
                sleep 5
            fi
            
            log_message "INFO" "Atualizando repositórios..."
            if ! sudo apt-get update -qq 2>>"$LOG_FILE"; then
                log_message "ERROR" "Falha ao atualizar repositórios (tentativa $install_attempt)"
                if [ $install_attempt -lt $MAX_INSTALL_ATTEMPTS ]; then
                    sleep 5
                    continue
                fi
                break
            fi
            
            log_message "INFO" "Instalando: ${missing[*]}"
            if sudo apt-get install -y "${missing[@]}" 2>>"$LOG_FILE"; then
                log_message "SUCCESS" "Dependências instaladas com sucesso na tentativa $install_attempt"
                needs_restart=true
                break
            else
                log_message "ERROR" "Falha na instalação (tentativa $install_attempt)"
                if [ $install_attempt -lt $MAX_INSTALL_ATTEMPTS ]; then
                    sleep 5
                fi
            fi
        done
        
        if [ $install_attempt -eq $MAX_INSTALL_ATTEMPTS ] && [ "$needs_restart" = false ]; then
            log_message "ERROR" "Falha em todas as $MAX_INSTALL_ATTEMPTS tentativas de instalação"
            show_error_menu "Falha na instalação de dependências após $MAX_INSTALL_ATTEMPTS tentativas."
            return 1
        fi
    else
        log_message "SUCCESS" "Todas as dependências já estão instaladas"
    fi
    
    # Re-verifica lolcat após instalação
    find_lolcat
    
    if command -v dos2unix &> /dev/null; then
        if file "$0" 2>/dev/null | grep -q "CRLF"; then
            log_message "INFO" "Convertendo script para formato Unix..."
            dos2unix "$0" 2>/dev/null || true
            needs_restart=true
        fi
    fi
    
    if [ "$needs_restart" = true ]; then
        log_message "INFO" "Reiniciando script com dependências atualizadas..."
        sleep 2
        exec bash "$0" "$@"
    fi
    
    return 0
}

# =============================================================================
# MENU DE ERRO COM TIMEOUT DE 20S
# =============================================================================
show_error_menu() {
    local error_msg="$1"
    local choice=""
    
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${SAB_WHITE}                     ❌ ERRO CRÍTICO DETECTADO                          ${RED}║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}$error_msg${NC}"
    echo ""
    echo -e "${SAB_WHITE}Opções disponíveis:${NC}"
    echo ""
    echo -e "   ${SAB_GREEN}[1]${SAB_WHITE} 🔄 Tentar novamente${NC}"
    echo -e "   ${SAB_GOLD}[2]${SAB_WHITE} ⚠️  Continuar sem dependências coloridas (modo fallback)${NC}"
    echo -e "   ${SAB_RED}[3]${SAB_WHITE} 🚪 Sair do script${NC}"
    echo ""
    echo -e "${SAB_GOLD}⏳ Aguardando escolha (${ERROR_TIMEOUT} segundos)...${NC}"
    echo -e "${SAB_GRAY}   O script continuará automaticamente com a opção [2] após o tempo.${NC}"
    echo ""

    for ((i=ERROR_TIMEOUT; i>=1; i--)); do
        echo -ne "\r${SAB_GOLD}   Tempo restante: ${SAB_ORANGE}${i}s${SAB_GOLD} | Digite 1, 2 ou 3: ${NC}"
        
        if read -t 1 -n 1 choice 2>/dev/null; then
            echo ""
            case $choice in
                1)
                    log_message "INFO" "Usuário escolheu tentar novamente"
                    return 2  # Código especial para retry
                    ;;
                2)
                    log_message "WARN" "Usuário escolheu continuar em modo fallback"
                    USE_COLOR=false
                    return 0
                    ;;
                3)
                    log_message "INFO" "Usuário escolheu sair"
                    exit 1
                    ;;
                *)
                    echo -e "${SAB_RED}   Opção inválida. Use 1, 2 ou 3.${NC}"
                    i=$((i+1))
                    sleep 0.5
                    ;;
            esac
        fi
    done
    
    # Timeout - fallback automático
    echo ""
    log_message "WARN" "Timeout atingido. Ativando modo fallback..."
    USE_COLOR=false
    return 0
}

# =============================================================================
# VERIFICAÇÃO DE PERMISSÕES (AUTO-CHMOD)
# =============================================================================

if [ ! -x "$0" ]; then
    log_message "WARN" "Script sem permissão de execução detectado"
    
    if chmod +x "$0" 2>/dev/null; then
        log_message "SUCCESS" "Permissão aplicada automaticamente"
        exec bash "$0" "$@"
    else
        log_message "ERROR" "Não foi possível aplicar permissão de execução"
        
        if [ "$EUID" -ne 0 ]; then
            echo -e "${YELLOW}⏳ Aguardando 10 segundos...${NC}"
            
            for i in {10..1}; do
                echo -ne "\r${YELLOW}   Continuando em $i segundos... (Ctrl+C para cancelar)${NC}"
                sleep 1
            done
            echo ""
            echo ""
            
            if ! chmod +x "$0" 2>/dev/null; then
                echo -e "${RED}❌ FALHA: Execute manualmente:${NC}"
                echo -e "${RED}   sudo chmod +x $SCRIPT_NAME && sudo ./$SCRIPT_NAME${NC}"
                exit 1
            fi
        else
            exit 1
        fi
    fi
fi

# =============================================================================
# INSTALAR DEPENDÊNCIAS
# =============================================================================

check_and_install_dependencies

# =============================================================================
# AGORA PODEMOS USAR CORES AVANÇADAS (com fallback)
# =============================================================================

USE_COLOR=${USE_COLOR:-true}

if [ "$USE_COLOR" = true ] && [ -n "$LOLCAT_CMD" ]; then
    # Modo com cores
    SAB_BLUE='\033[38;5;33m'
    SAB_CYAN='\033[38;5;87m'
    SAB_GREEN='\033[38;5;82m'
    SAB_GOLD='\033[38;5;220m'
    SAB_ORANGE='\033[38;5;208m'
    SAB_RED='\033[38;5;196m'
    SAB_WHITE='\033[38;5;255m'
    SAB_GRAY='\033[38;5;245m'
    NC='\033[0m'
else
    # Modo fallback (sem cores)
    SAB_BLUE=''
    SAB_CYAN=''
    SAB_GREEN=''
    SAB_GOLD=''
    SAB_ORANGE=''
    SAB_RED=''
    SAB_WHITE=''
    SAB_GRAY=''
    NC=''
    log_message "INFO" "Executando em modo fallback (sem dependências coloridas)"
fi

# =============================================================================
# FUNÇÃO: IMPRIMIR CABEÇALHO CORPORATIVO (com fallback)
# =============================================================================

print_header() {
    clear
    echo ""
    
    if [ "$USE_COLOR" = true ] && [ -n "$LOLCAT_CMD" ] && command -v figlet &> /dev/null; then
        figlet -f slant "SAB TEC" | "$LOLCAT_CMD"
    else
        echo "  ███████  █████  ██████      ████████ ███████ ██████ "
        echo "  ██      ██   ██ ██   ██        ██    ██      ██   ██"
        echo "  ███████ ███████ ██████         ██    █████   ██████ "
        echo "       ██ ██   ██ ██   ██        ██    ██      ██     "
        echo "  ███████ ██   ██ ██████         ██    ███████ ███████"
    fi
    
    echo -e "${SAB_BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${SAB_BLUE}║${SAB_GOLD}  ${COMPANY}${NC}"
    echo -e "${SAB_BLUE}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${SAB_BLUE}║${SAB_CYAN}  📋 PROJETO:${SAB_WHITE}  ${PROJECT_NAME}${NC}"
    echo -e "${SAB_BLUE}║${SAB_CYAN}  🏷️  VERSÃO:${SAB_WHITE}   ${VERSION}${NC}"
    echo -e "${SAB_BLUE}║${SAB_CYAN}  📅 RELEASE:${SAB_WHITE}  ${RELEASE_DATE}${NC}"
    echo -e "${SAB_BLUE}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${SAB_BLUE}║${SAB_GREEN}  👤 DESENVOLVEDOR:${SAB_WHITE} ${DEVELOPER}${NC}"
    echo -e "${SAB_BLUE}║${SAB_GREEN}  🎯 ESPECIALIDADE:${SAB_WHITE}  ${ROLE}${NC}"
    echo -e "${SAB_BLUE}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${SAB_BLUE}║${SAB_GOLD}  📧 CONTATO:${SAB_WHITE}  ${CONTACT}${NC}"
    echo -e "${SAB_BLUE}║${SAB_GOLD}  🐙 GITHUB:${SAB_WHITE}   ${GITHUB}${NC}"
    echo -e "${SAB_BLUE}║${SAB_GOLD}  🐛 ISSUES:${SAB_WHITE}   ${ISSUES}${NC}"
    echo -e "${SAB_BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =============================================================================
# FUNÇÃO: IMPRIMIR DESCRIÇÃO TÉCNICA
# =============================================================================

print_description() {
    echo -e "${SAB_CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${SAB_CYAN}│${SAB_WHITE} 📖 DESCRIÇÃO TÉCNICA${NC}"
    echo -e "${SAB_CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
    
    echo "$DESCRIPTION" | fold -s -w 70 | while read line; do
        printf "${SAB_CYAN}│${SAB_GRAY} %-71s${SAB_CYAN}│${NC}\n" "$line"
    done
    
    echo -e "${SAB_CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# =============================================================================
# MENU INTERATIVO SUDO
# =============================================================================

print_header
print_description

if [ "$EUID" -eq 0 ]; then
    echo -e "${SAB_GREEN}✅ Você já está executando como root/sudo!${NC}"
    echo -e "${SAB_GREEN}   A limpeza de cache será automática sem solicitar senha.${NC}"
    SUDO_MODE="AUTO"
    sleep 3
else
    echo -e "${SAB_ORANGE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${SAB_ORANGE}║${SAB_WHITE}                    🔐 CONFIGURAÇÃO DE PRIVILÉGIOS SUDO                 ${SAB_ORANGE}║${NC}"
    echo -e "${SAB_ORANGE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${SAB_ORANGE}⚠️  Você NÃO está executando como sudo.${NC}"
    echo -e "${SAB_GRAY}   Durante o teste, a limpeza de cache a cada 3 modelos requer privilégios.${NC}"
    echo ""
    echo -e "${SAB_WHITE}Escolha uma opção:${NC}"
    echo ""
    echo -e "   ${SAB_GREEN}[1]${SAB_WHITE} 🔐 Logar como sudo ${SAB_GREEN}AGORA${SAB_WHITE} (senha solicitada uma única vez)${NC}"
    echo -e "   ${SAB_GOLD}[2]${SAB_WHITE} 🚪 Encerrar e executar manualmente: ${SAB_GOLD}sudo ./${SCRIPT_NAME}${NC}"
    echo -e "   ${SAB_RED}[3]${SAB_WHITE} ⚠️  Continuar sem sudo (senha solicitada a cada limpeza de cache)${NC}"
    echo ""
    echo -e "${SAB_GOLD}⏳ Aguardando escolha (20 segundos)...${NC}"
    echo -e "${SAB_GRAY}   O script continuará automaticamente com a opção [3] após o tempo.${NC}"
    echo ""

    SUDO_MODE="MANUAL"
    for ((i=20; i>=1; i--)); do
        echo -ne "\r${SAB_GOLD}   Tempo restante: ${SAB_ORANGE}${i}s${SAB_GOLD} | Digite 1, 2 ou 3: ${NC}"
        
        if read -t 1 -n 1 escolha 2>/dev/null; then
            echo ""
            case $escolha in
                1)
                    echo -e "${SAB_CYAN}🔐 Solicitando senha sudo...${NC}"
                    if sudo -v 2>/dev/null; then
                        echo -e "${SAB_GREEN}✅ Autenticação sudo bem-sucedida!${NC}"
                        SUDO_MODE="AUTO"
                        echo -e "${SAB_GREEN}🔄 Reiniciando script com privilégios sudo...${NC}"
                        sleep 2
                        exec sudo bash "$0" "$@"
                    else
                        echo -e "${SAB_RED}❌ Falha na autenticação sudo.${NC}"
                        echo -e "${SAB_ORANGE}⚠️  Continuando sem privilégios elevados...${NC}"
                        SUDO_MODE="MANUAL"
                    fi
                    break
                    ;;
                2)
                    echo -e "${SAB_GOLD}🚪 Encerrando script...${NC}"
                    echo ""
                    echo -e "${SAB_CYAN}💡 Execute manualmente:${NC}"
                    echo -e "${SAB_GREEN}   sudo ./${SCRIPT_NAME}${NC}"
                    echo ""
                    exit 0
                    ;;
                3)
                    echo -e "${SAB_ORANGE}⚠️  Continuando sem sudo.${NC}"
                    echo -e "${SAB_GRAY}   Atenção: A senha será solicitada a cada limpeza de cache!${NC}"
                    SUDO_MODE="MANUAL"
                    sleep 3
                    break
                    ;;
                *)
                    echo -e "${SAB_RED}   Opção inválida. Use 1, 2 ou 3.${NC}"
                    i=$((i+1))
                    sleep 0.5
                    ;;
            esac
        fi
    done
    
    if [ "$SUDO_MODE" = "MANUAL" ] && [ "$i" -eq 0 ]; then
        echo ""
        echo -e "${SAB_ORANGE}⏱️  Tempo esgotado. Continuando sem sudo...${NC}"
        sleep 2
    fi
fi

echo ""
echo -e "${SAB_GREEN}▶ Iniciando teste de function calling tools...${NC}"
echo ""

set -e

# =============================================================================
# CAPTURA DE INFORMAÇÕES DO SISTEMA
# =============================================================================

echo -e "${SAB_CYAN}🔍 Analisando ambiente de execução...${NC}"

detectar_virtualizacao() {
    local virt="Bare Metal (Fisico)"
    local virt_type="N/A"
    local host_os="N/A"
    
    if [ -d "/sys/bus/vmbus" ] || [ -d "/sys/class/vmbus" ]; then
        virt="Hyper-V (Microsoft)"
        virt_type="VM"
        host_os="Windows (provavel)"
    fi
    
    if grep -q "hypervisor" /proc/cpuinfo 2>/dev/null; then
        if grep -q "Microsoft" /proc/cpuinfo 2>/dev/null; then
            virt="Hyper-V"
            virt_type="VM"
        fi
    fi
    
    if [ -f "/sys/class/dmi/id/product_name" ]; then
        local dmi=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
        if echo "$dmi" | grep -qi "virtual"; then
            virt="Hyper-V"
            virt_type="VM"
        fi
    fi
    
    if command -v systemd-detect-virt &> /dev/null; then
        local sd_virt=$(systemd-detect-virt 2>/dev/null || echo "none")
        if [ "$sd_virt" != "none" ]; then
            virt="$sd_virt"
            virt_type="VM"
            [ "$sd_virt" = "microsoft" ] && virt="Hyper-V" && host_os="Windows"
        fi
    fi
    
    if command -v lscpu &> /dev/null; then
        local hypervisor=$(lscpu 2>/dev/null | grep -i "hypervisor vendor" | awk -F': ' '{print $2}' | xargs)
        if [ -n "$hypervisor" ]; then
            virt="$hypervisor"
            virt_type="VM"
            [ "$hypervisor" = "Microsoft" ] && virt="Hyper-V" && host_os="Windows"
        fi
    fi
    
    echo "$virt|$virt_type|$host_os"
}

SYS_INFO=$(detectar_virtualizacao)
SYS_VIRT=$(echo "$SYS_INFO" | cut -d'|' -f1)
SYS_VIRT_TYPE=$(echo "$SYS_INFO" | cut -d'|' -f2)
SYS_HOST_OS=$(echo "$SYS_INFO" | cut -d'|' -f3)

SYS_OS=$(lsb_release -d -s 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Desconhecido")
SYS_KERNEL=$(uname -r)
SYS_ARCH=$(uname -m)
SYS_CPU=$(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || echo "N/A")
SYS_CPU_CORES=$(nproc 2>/dev/null || echo "N/A")
SYS_RAM_TOTAL=$(free -h 2>/dev/null | awk 'NR==2{print $2}' || echo "N/A")
SYS_RAM_AVAILABLE=$(free -h 2>/dev/null | awk 'NR==2{print $7}' || echo "N/A")
SYS_OLLAMA_VERSION=$(ollama --version 2>/dev/null || echo "N/A")

# =============================================================================
# CONFIGURAÇÃO DE DIRETÓRIOS - CORREÇÃO: USA DIRETÓRIO DO SCRIPT
# =============================================================================

# Detecta o diretório onde o script está localizado (não onde está sendo executado)
if [ -n "$BASH_SOURCE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Se não conseguir detectar, usa o diretório atual
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(pwd)"
fi

RESULTS_DIR="${SCRIPT_DIR}/benchmark_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Tenta criar o diretório com tratamento de erro
if ! mkdir -p "$RESULTS_DIR" 2>/dev/null; then
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${SAB_WHITE}                     ❌ ERRO AO CRIAR DIRETÓRIO                         ${RED}║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}Não foi possível criar o diretório de resultados:${NC}"
    echo -e "${RED}  ${RESULTS_DIR}${NC}"
    echo ""
    echo -e "${SAB_YELLOW}Possíveis causas:${NC}"
    echo -e "  • Sem permissão de escrita no diretório: ${SCRIPT_DIR}"
    echo -e "  • Diretório protegido por permissões do sistema"
    echo -e "  • Filesystem montado como somente leitura"
    echo ""
    echo -e "${SAB_CYAN}Soluções sugeridas:${NC}"
    echo -e "  1. Execute o script com sudo: ${SAB_GREEN}sudo ${SCRIPT_DIR}/${SCRIPT_NAME}${NC}"
    echo -e "  2. Altere as permissões: ${SAB_GREEN}sudo chown -R $(whoami) '${SCRIPT_DIR}'${NC}"
    echo -e "  3. Execute de um diretório com permissão de escrita (ex: /tmp ou ~)"
    echo ""
    echo -e "${SAB_GOLD}Diretório do script detectado:${NC} ${SCRIPT_DIR}"
    echo -e "${SAB_GOLD}Usuário atual:${NC} $(whoami)"
    echo -e "${SAB_GOLD}Permissões do diretório:${NC}"
    ls -ld "${SCRIPT_DIR}" 2>/dev/null || echo "  (não foi possível verificar)"
    echo ""
    exit 1
fi

# Verifica se tem permissão de escrita no diretório criado
if [ ! -w "$RESULTS_DIR" ]; then
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${SAB_WHITE}                  ❌ SEM PERMISSÃO DE ESCRITA                            ${RED}║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}O diretório foi criado, mas sem permissão de escrita:${NC}"
    echo -e "${RED}  ${RESULTS_DIR}${NC}"
    echo ""
    echo -e "${SAB_CYAN}Execute com sudo ou verifique as permissões:${NC}"
    echo -e "  ${SAB_GREEN}sudo ${SCRIPT_DIR}/${SCRIPT_NAME}${NC}"
    echo ""
    exit 1
fi

echo -e "${SAB_GREEN}✅ Diretório de resultados configurado:${NC}"
echo -e "   ${RESULTS_DIR}"
echo ""

COUNTER=1
RESULTS_FILE="${RESULTS_DIR}/tools_test_${VERSION}_${TIMESTAMP}.csv"
while [ -f "$RESULTS_FILE" ]; do
    RESULTS_FILE="${RESULTS_DIR}/tools_test_${VERSION}_${TIMESTAMP}_${COUNTER}.csv"
    COUNTER=$((COUNTER + 1))
done

LOG_FILE="${RESULTS_FILE%.csv}.log"
SYSINFO_FILE="${RESULTS_FILE%.csv}_sysinfo.txt"
RELATORIO_FILE="${RESULTS_FILE%.csv}_relatorio.txt"

# =============================================================================
# SALVAR INFORMAÇÕES DO SISTEMA E EMPRESA
# =============================================================================

{
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                    SAB TEC - TECNOLOGIA E SERVIÇOS                       ║"
echo "║           Teste de Function Calling Tools para Ollama                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "METADADOS DO PROJETO:"
echo "  Nome:        ${PROJECT_NAME}"
echo "  Versão:      ${VERSION}"
echo "  Release:     ${RELEASE_DATE}"
echo "  Script:      ${SCRIPT_NAME}"
echo ""
echo "DESENVOLVEDOR:"
echo "  Nome:        ${DEVELOPER}"
echo "  Especialidade: ${ROLE}"
echo ""
echo "CONTATO:"
echo "  Email:       ${CONTACT}"
echo "  GitHub:      ${GITHUB}"
echo "  Issues:      ${ISSUES}"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "INFORMAÇÕES DO SISTEMA"
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Data/Hora:   $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Modo Sudo:   ${SUDO_MODE}"
echo "  Modo Cores:  $([ "$USE_COLOR" = true ] && echo 'Ativo' || echo 'Fallback')"
echo ""
echo "SISTEMA OPERACIONAL:"
echo "  OS:          ${SYS_OS}"
echo "  Kernel:      ${SYS_KERNEL}"
echo "  Arquitetura: ${SYS_ARCH}"
echo ""
echo "VIRTUALIZAÇÃO:"
echo "  Tipo:        ${SYS_VIRT}"
echo "  Classificação: ${SYS_VIRT_TYPE}"
echo "  Host OS:     ${SYS_HOST_OS}"
echo ""
echo "HARDWARE:"
echo "  CPU:         ${SYS_CPU}"
echo "  Cores:       ${SYS_CPU_CORES}"
echo "  RAM Total:   ${SYS_RAM_TOTAL}"
echo "  RAM Disp.:   ${SYS_RAM_AVAILABLE}"
echo ""
echo "OLLAMA:"
echo "  Versão:      ${SYS_OLLAMA_VERSION}"
echo ""
echo "ARQUIVOS DE SAÍDA:"
echo "  CSV:         ${RESULTS_FILE}"
echo "  LOG:         ${LOG_FILE}"
echo "  SYSINFO:     ${SYSINFO_FILE}"
echo "  RELATÓRIO:   ${RELATORIO_FILE}"
echo "═══════════════════════════════════════════════════════════════════════════"
} > "$SYSINFO_FILE"

# =============================================================================
# HEADER DE EXECUÇÃO
# =============================================================================

print_header

echo -e "${SAB_CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${SAB_CYAN}│${SAB_WHITE} 🖥️  AMBIENTE DE EXECUÇÃO${NC}"
echo -e "${SAB_CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  Diretório:  ${SAB_WHITE}${SCRIPT_DIR}${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  Sistema:    ${SAB_WHITE}${SYS_OS}${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  Kernel:     ${SAB_WHITE}${SYS_KERNEL}${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  Virtual:    ${SAB_WHITE}${SYS_VIRT}${NC}"
[ "$SYS_VIRT_TYPE" = "VM" ] && echo -e "${SAB_CYAN}│${SAB_GRAY}  Host:       ${SAB_WHITE}${SYS_HOST_OS}${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  CPU:        ${SAB_WHITE}${SYS_CPU_CORES} cores${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  RAM:        ${SAB_WHITE}${SYS_RAM_TOTAL}${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  Ollama:     ${SAB_WHITE}${SYS_OLLAMA_VERSION}${NC}"
echo -e "${SAB_CYAN}│${SAB_GRAY}  Modo:       ${SAB_GREEN}${SUDO_MODE}${NC}"
echo -e "${SAB_CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
echo ""

# =============================================================================
# AUTO-DETECÇÃO DE MODELOS
# =============================================================================

echo -e "${SAB_CYAN}🔍 Detectando modelos instalados no Ollama...${NC}"

MODELS_ARRAY=()

while IFS= read -r line; do
    [ -z "$line" ] && continue
    [ "$line" = "NAME" ] && continue
    
    modelo=$(echo "$line" | awk '{print $1}')
    [ -z "$modelo" ] && continue
    
    if echo "$modelo" | grep -q ":cloud$"; then
        echo -e "  ${SAB_CYAN}☁️  Pulando cloud:${NC} $modelo"
        continue
    fi
    
    MODELS_ARRAY+=("$modelo")
    
done < <(ollama list 2>/dev/null | tail -n +2)

if [ ${#MODELS_ARRAY[@]} -eq 0 ]; then
    echo -e "${SAB_RED}❌ Nenhum modelo local detectado!${NC}"
    exit 1
fi

echo -e "${SAB_GREEN}✅ ${#MODELS_ARRAY[@]} modelo(s) detectado(s):${NC}"
for m in "${MODELS_ARRAY[@]}"; do
    echo -e "   ${SAB_CYAN}•${NC} $m"
done
echo ""

echo "modelo,suporte_tools,confianca_final,teste1_status,teste2_status,teste3_status,exemplo_resposta,timestamp,versao_script,os_info,virt_info,empresa,desenvolvedor" > "$RESULTS_FILE"

{
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                    SAB TEC - TECNOLOGIA E SERVIÇOS                       ║"
echo "║                        LOG DE EXECUÇÃO                                   ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Projeto:    ${PROJECT_NAME}"
echo "Versão:     ${VERSION}"
echo "Início:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "Desenv.:    ${DEVELOPER} | ${ROLE}"
echo "Contato:    ${CONTACT}"
echo "GitHub:     ${GITHUB}"
echo "Issues:     ${ISSUES}"
echo "Sistema:    ${SYS_OS} | ${SYS_KERNEL}"
echo "Virtual:    ${SYS_VIRT}"
echo "Hardware:   ${SYS_CPU_CORES} cores | ${SYS_RAM_TOTAL} RAM"
echo "Modelos:    ${#MODELS_ARRAY[@]}"
echo "Arquivo:    ${RESULTS_FILE}"
echo "Modo Cores: $([ "$USE_COLOR" = true ] && echo 'Ativo' || echo 'Fallback')"
echo "═══════════════════════════════════════════════════════════════════════════"
} | tee "$LOG_FILE"

echo -e "${SAB_GOLD}📅 Início:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${SAB_GOLD}📊 Resultados:${NC} ${RESULTS_FILE}"
echo ""

# =============================================================================
# FUNÇÃO DE TESTE DE TOOLS
# =============================================================================

test_model_tools() {
    local model=$1
    local test1_status="NAO_TESTADO"
    local test2_status="NAO_TESTADO"
    local test3_status="NAO_TESTADO"
    local confianca=0
    local exemplo=""
    
    echo -e "${SAB_BLUE}─────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${SAB_GOLD}🤖 Testando:${NC} ${SAB_CYAN}$model${NC}"
    
    if ! ollama list | grep -q "^${model}"; then
        echo -e "${SAB_RED}❌ Modelo não encontrado${NC}"
        echo "$model,NAO_INSTALADO,0,$test1_status,$test2_status,$test3_status,,$(date +%s),${VERSION},\"$SYS_OS\",\"$SYS_VIRT\",\"$COMPANY\",\"$DEVELOPER\"" >> "$RESULTS_FILE"
        return
    fi
    
    local model_info=$(ollama list | grep "^${model}" | awk '{print $2, $3}' || echo "N/A")
    echo -e "  ${SAB_CYAN}Info:${NC} $model_info"
    
    # TESTE 1: Consciência de tools
    echo -e "  ${SAB_ORANGE}Teste 1:${NC} Consciência de ferramentas..."
    
    local prompt1="Voce tem acesso a ferramentas (tools)? Responda SIM ou NAO e explique brevemente."
    
    local resp1=$(curl -s --max-time 120 \
        http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"prompt\": \"$prompt1\",
            \"stream\": false,
            \"options\": {\"temperature\": 0.2, \"num_ctx\": 4096}
        }" 2>/dev/null)
    
    local text1=$(echo "$resp1" | jq -r '.response // "ERROR"' | head -c 300 | tr '\n' ' ' | sed 's/"/""/g')
    
    if [ "$text1" = "ERROR" ] || [ -z "$text1" ]; then
        test1_status="ERRO"
        echo -e "    ${SAB_RED}❌ Falha na geração${NC}"
    else
        echo -e "    ${SAB_GREEN}Resposta:${NC} ${text1:0:80}..."
        
        if echo "$text1" | grep -qiE "sim.*tenho|yes.*have|posso usar|tenho acesso"; then
            test1_status="SIM"
            confianca=30
        else
            test1_status="NAO"
        fi
        
        if echo "$text1" | grep -qiE "function|tool|api|search|calculator|weather|code"; then
            confianca=$((confianca + 20))
        fi
    fi
    
    # TESTE 2: Descrição de ferramentas
    echo -e "  ${SAB_ORANGE}Teste 2:${NC} Descrição de ferramentas..."
    
    local prompt2="Liste 3 ferramentas que voce usaria se tivesse acesso a um sistema de execucao de codigo."
    
    local resp2=$(curl -s --max-time 120 \
        http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"prompt\": \"$prompt2\",
            \"stream\": false,
            \"options\": {\"temperature\": 0.3, \"num_ctx\": 4096}
        }" 2>/dev/null)
    
    local text2=$(echo "$resp2" | jq -r '.response // "ERROR"' | head -c 400 | tr '\n' ' ')
    
    if [ "$text2" != "ERROR" ] && [ -n "$text2" ]; then
        if echo "$text2" | grep -qiE "python|bash|execu|calcul|busca|search|file|arquivo"; then
            test2_status="DESCREVE_TOOLS"
            confianca=$((confianca + 25))
            echo -e "    ${SAB_GREEN}✅ Descreve ferramentas relevantes${NC}"
        else
            test2_status="NAO_DESCREVE"
            echo -e "    ${SAB_ORANGE}⚠️  Não descreve ferramentas específicas${NC}"
        fi
    else
        test2_status="ERRO"
    fi
    
    # TESTE 3: Function calling estruturado
    echo -e "  ${SAB_ORANGE}Teste 3:${NC} Function calling estruturado (JSON)..."
    
    local prompt3="Qual o clima em Sao Paulo? Responda usando formato JSON com 'action' e 'parameters' se precisar chamar uma ferramenta, ou 'resposta' direta."
    
    local resp3=$(curl -s --max-time 120 \
        http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"prompt\": \"$prompt3\",
            \"stream\": false,
            \"format\": \"json\",
            \"options\": {\"temperature\": 0.1, \"num_ctx\": 4096}
        }" 2>/dev/null)
    
    local text3=$(echo "$resp3" | jq -r '.response // "ERROR"' | head -c 500 | tr '\n' ' ')
    
    if echo "$text3" | grep -qE '"action"|"function"|"tool"|"name"|"call"'; then
        if echo "$text3" | grep -qE '"parameters"|"args"|"arguments"'; then
            test3_status="FUNCTION_CALL_COMPLETO"
            confianca=100
            exemplo="${text3:0:200}"
            echo -e "    ${SAB_GREEN}✅ Function call COMPLETO detectado!${NC}"
        else
            test3_status="FUNCTION_CALL_PARCIAL"
            confianca=80
            exemplo="${text3:0:200}"
            echo -e "    ${SAB_ORANGE}🟡 Function call parcial${NC}"
        fi
    elif echo "$text3" | grep -qE '\{"resposta":|\{"response":|\{"answer":'; then
        test3_status="JSON_DIRETO"
        confianca=$((confianca + 10))
        echo -e "    ${SAB_CYAN}ℹ️  Responde em JSON mas sem function call${NC}"
    else
        test3_status="RESPOSTA_LIVRE"
        echo -e "    ${SAB_RED}❌ Sem estrutura JSON/function call${NC}"
    fi
    
    # Determinar suporte final
    local suporte_tools="NAO"
    if [ "$test3_status" = "FUNCTION_CALL_COMPLETO" ] || [ "$confianca" -ge 80 ]; then
        suporte_tools="SIM"
    elif [ "$test3_status" = "FUNCTION_CALL_PARCIAL" ] || [ "$confianca" -ge 50 ]; then
        suporte_tools="PROVAVEL"
    elif [ "$confianca" -ge 30 ]; then
        suporte_tools="POSSIVEL"
    fi
    
    # Salvar resultado
    echo "$model,$suporte_tools,$confianca,$test1_status,$test2_status,$test3_status,\"$exemplo\",$(date +%s),${VERSION},\"$SYS_OS\",\"$SYS_VIRT\",\"$COMPANY\",\"$DEVELOPER\"" >> "$RESULTS_FILE"
    
    # Output final
    echo ""
    echo -e "  ${SAB_CYAN}📊 RESULTADO:${NC}"
    echo -e "  ${SAB_CYAN}Suporte Tools:${NC} $suporte_tools"
    echo -e "  ${SAB_CYAN}Confiança:${NC} ${confianca}%"
    echo -e "  ${SAB_CYAN}T1:${NC} $test1_status | ${SAB_CYAN}T2:${NC} $test2_status | ${SAB_CYAN}T3:${NC} $test3_status"
    
    if [ "$suporte_tools" = "SIM" ]; then
        echo -e "  ${SAB_GREEN}✅ RECOMENDADO PARA OPENCLAW${NC}"
    elif [ "$suporte_tools" = "PROVAVEL" ]; then
        echo -e "  ${SAB_ORANGE}🟡 PROVAVELMENTE COMPATÍVEL${NC}"
    elif [ "$suporte_tools" = "POSSIVEL" ]; then
        echo -e "  ${SAB_ORANGE}⚠️  TESTAR COM CAUTELA${NC}"
    else
        echo -e "  ${SAB_RED}❌ NÃO RECOMENDADO${NC}"
    fi
    
    echo ""
    sleep 2
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

echo -e "${SAB_GREEN}▶ Iniciando testes com ${#MODELS_ARRAY[@]} modelo(s)...${NC}"
echo "======================================================="

model_count=0

for model in "${MODELS_ARRAY[@]}"; do
    test_model_tools "$model"
    
    model_count=$((model_count + 1))
    
    # LIMPEZA DE CACHE COM TRATAMENTO DE SUDO (a cada 3 modelos)
    if [ $((model_count % 3)) -eq 0 ] && [ $model_count -lt ${#MODELS_ARRAY[@]} ]; then
        echo "  🧹 Limpando cache..."
        
        if [ "$SUDO_MODE" = "AUTO" ]; then
            sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true
            echo -e "    ${SAB_GREEN}✅ Cache limpo (sudo automático)${NC}"
        else
            echo -e "    ${SAB_ORANGE}⚠️  Modo manual: senha sudo pode ser solicitada...${NC}"
            if sudo -n true 2>/dev/null; then
                sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true
                echo -e "    ${SAB_GREEN}✅ Cache limpo (sudo em cache)${NC}"
            else
                echo -e "    ${SAB_ORANGE}🔐 Digite a senha sudo para limpar o cache:${NC}"
                if sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1; then
                    echo -e "    ${SAB_GREEN}✅ Cache limpo com sucesso${NC}"
                else
                    echo -e "    ${SAB_ORANGE}⚠️  Falha ao limpar cache (sem privilégios)${NC}"
                fi
            fi
        fi
        echo ""
    fi
done

echo "======================================================="
echo -e "${SAB_GREEN}✅ TESTES CONCLUÍDOS!${NC}"
echo -e "${SAB_GOLD}📅 Fim:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${SAB_GOLD}📁 Arquivos:${NC}"
echo -e "   CSV: ${RESULTS_FILE}"
echo -e "   LOG: ${LOG_FILE}"
echo -e "   SYS: ${SYSINFO_FILE}"
echo -e "   RELATÓRIO: ${RELATORIO_FILE}"
echo ""

echo -e "${SAB_CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${SAB_CYAN}║${SAB_WHITE}                        📋 RESUMO FINAL                                     ${SAB_CYAN}║${NC}"
echo -e "${SAB_CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${SAB_CYAN}Modelo              | Suporte | Conf. | T1    | T2    | T3    | Status${NC}"
echo -e "${SAB_CYAN}────────────────────┼─────────┼───────┼───────┼───────┼───────┼────────────────${NC}"

# =============================================================================
# RESUMO FINAL - CORREÇÃO: REMOVIDO 'local' DA VARIÁVEL STATUS
# =============================================================================

while IFS=',' read -r modelo suporte conf t1 t2 t3 exemplo timestamp versao os_info virt_info empresa desenvolvedor; do
    [ "$modelo" = "modelo" ] && continue
    
    # CORREÇÃO: Removido 'local' - variável global no loop
    status=""
    if [ "$suporte" = "SIM" ]; then
        status="${SAB_GREEN}✅ APROVADO${NC}"
    elif [ "$suporte" = "PROVAVEL" ]; then
        status="${SAB_ORANGE}🟡 PROVAVEL${NC}"
    elif [ "$suporte" = "POSSIVEL" ]; then
        status="${SAB_ORANGE}⚠️  POSSIVEL${NC}"
    else
        status="${SAB_RED}❌ REJEITADO${NC}"
    fi
    
    printf "%-19s | %-7s | %3s%%  | %-5s | %-5s | %-5s | %b\n" \
        "$modelo" "$suporte" "$conf" "$t1" "$t2" "$t3" "$status"
done < "$RESULTS_FILE"

echo ""
echo -e "${SAB_GOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${SAB_GOLD}║${SAB_WHITE}                     SAB TEC - TECNOLOGIA E SERVIÇOS                        ${SAB_GOLD}║${NC}"
echo -e "${SAB_GOLD}║${SAB_CYAN}              Obrigado por utilizar nossas soluções!                        ${SAB_GOLD}║${NC}"
echo -e "${SAB_GOLD}║${SAB_GRAY}  📧 ${CONTACT}  |  🐙 ${GITHUB}  ${SAB_GOLD}║${NC}"
echo -e "${SAB_GOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${SAB_CYAN}💡 Legenda:${NC}"
echo -e "  ${SAB_CYAN}T1:${NC} Consciência de tools | ${SAB_CYAN}T2:${NC} Descrição de tools | ${SAB_CYAN}T3:${NC} Function call estruturado"
echo -e "${SAB_CYAN}🔧 Próximo passo:${NC} Teste real com OpenClaw usando:"
echo -e "   ${SAB_GREEN}openclaw run --model <modelo_aprovado>${NC}"
echo ""

# =============================================================================
# GERAÇÃO DO RELATÓRIO COMPLETO
# =============================================================================

{
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                    SAB TEC - TECNOLOGIA E SERVIÇOS                       ║"
echo "║       Ollama Tool Tester - Relatório de Teste de Function Calling        ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "METADADOS DO PROJETO:"
echo "  Nome:        ${PROJECT_NAME}"
echo "  Versão:      ${VERSION}"
echo "  Release:     ${RELEASE_DATE}"
echo "  Script:      ${SCRIPT_NAME}"
echo ""
echo "DESENVOLVEDOR:"
echo "  Nome:        ${DEVELOPER}"
echo "  Especialidade: ${ROLE}"
echo ""
echo "CONTATO:"
echo "  Email:       ${CONTACT}"
echo "  GitHub:      ${GITHUB}"
echo "  Issues:      ${ISSUES}"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "INFORMAÇÕES DO SISTEMA"
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Data/Hora Início:  $(head -n 20 "$LOG_FILE" | grep "Início:" | cut -d':' -f2- | xargs)"
echo "  Data/Hora Fim:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Modo Sudo:         ${SUDO_MODE}"
echo "  Modo Cores:        $([ "$USE_COLOR" = true ] && echo 'Ativo' || echo 'Fallback')"
echo ""
echo "SISTEMA OPERACIONAL:"
echo "  OS:          ${SYS_OS}"
echo "  Kernel:      ${SYS_KERNEL}"
echo "  Arquitetura: ${SYS_ARCH}"
echo ""
echo "VIRTUALIZAÇÃO:"
echo "  Tipo:        ${SYS_VIRT}"
echo "  Classificação: ${SYS_VIRT_TYPE}"
echo "  Host OS:     ${SYS_HOST_OS}"
echo ""
echo "HARDWARE:"
echo "  CPU:         ${SYS_CPU}"
echo "  Cores:       ${SYS_CPU_CORES}"
echo "  RAM Total:   ${SYS_RAM_TOTAL}"
echo "  RAM Disp.:   ${SYS_RAM_AVAILABLE}"
echo ""
echo "OLLAMA:"
echo "  Versão:      ${SYS_OLLAMA_VERSION}"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "RESUMO DOS TESTES"
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Total de Modelos Testados: ${#MODELS_ARRAY[@]}"
echo ""
echo "Modelo               | Suporte | Conf. | T1        | T2           | T3"
echo "─────────────────────┼─────────┼───────┼───────────┼──────────────┼────────────────────"

while IFS=',' read -r modelo suporte conf t1 t2 t3 exemplo timestamp versao os_info virt_info empresa desenvolvedor; do
    [ "$modelo" = "modelo" ] && continue
    
    # Remove aspas se houver
    modelo=$(echo "$modelo" | sed 's/"//g')
    suporte=$(echo "$suporte" | sed 's/"//g')
    t1=$(echo "$t1" | sed 's/"//g')
    t2=$(echo "$t2" | sed 's/"//g')
    t3=$(echo "$t3" | sed 's/"//g')
    
    printf "%-20s | %-7s | %3s%%  | %-9s | %-12s | %-18s\n" \
        "$modelo" "$suporte" "$conf" "$t1" "$t2" "$t3"
done < "$RESULTS_FILE"

echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "DETALHAMENTO DOS TESTES"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Legenda:"
echo "  T1 (Teste 1): Consciência de tools - O modelo afirma ter acesso a ferramentas?"
echo "  T2 (Teste 2): Descrição de tools - O modelo descreve ferramentas específicas?"
echo "  T3 (Teste 3): Function call estruturado - O modelo gera JSON com action/parameters?"
echo ""
echo "Status Possíveis:"
echo "  SIM                - Modelo confirmou ter acesso a tools"
echo "  NAO                - Modelo negou ter acesso a tools"
echo "  NAO_TESTADO        - Teste não foi executado"
echo "  ERRO               - Falha na comunicação com o modelo"
echo "  DESCREVE_TOOLS     - Modelo descreveu ferramentas relevantes"
echo "  NAO_DESCREVE       - Modelo não descreveu ferramentas específicas"
echo "  FUNCTION_CALL_COMPLETO    - JSON completo com action e parameters"
echo "  FUNCTION_CALL_PARCIAL     - JSON parcial (só action ou parameters)"
echo "  JSON_DIRETO               - Responde em JSON mas sem function call"
echo "  RESPOSTA_LIVRE            - Resposta em texto livre, sem estrutura"
echo ""
echo "Níveis de Suporte:"
echo "  SIM       - ✅ RECOMENDADO PARA OPENCLAW (Function call completo ou confiança >= 80%)"
echo "  PROVAVEL  - 🟡 PROVAVELMENTE COMPATÍVEL (Function call parcial ou confiança >= 50%)"
echo "  POSSIVEL  - ⚠️  TESTAR COM CAUTELA (Confiança >= 30%)"
echo "  NAO       - ❌ NÃO RECOMENDADO (Confiança < 30%)"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "ARQUIVOS DE SAÍDA"
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  CSV:         ${RESULTS_FILE}"
echo "  LOG:         ${LOG_FILE}"
echo "  SYSINFO:     ${SYSINFO_FILE}"
echo "  RELATÓRIO:   ${RELATORIO_FILE}"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Próximo passo recomendado:"
echo "  Teste real com OpenClaw usando:"
echo "    openclaw run --model <modelo_aprovado>"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "FIM DO RELATÓRIO"
echo "═══════════════════════════════════════════════════════════════════════════"
} > "$RELATORIO_FILE"

echo -e "${SAB_GREEN}📄 Relatório completo gerado:${NC} ${RELATORIO_FILE}"
echo ""