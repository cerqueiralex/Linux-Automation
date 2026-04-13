#!/bin/bash
# =============================================================================
#  setup.sh — Automação de configuração para Ubuntu
#  Uso: bash setup.sh
#
#  Dar permissão:
#  sudo chmod +x setup.sh
#
#  Verificar Permissão:
#  sudo ls -l setup.sh
#
#  Executar
#  sudo ./setup.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# VERIFICAÇÃO DE PRIVILÉGIOS
# =============================================================================

if [[ "$EUID" -ne 0 ]]; then
    echo "❌ Este script precisa ser executado como root. Use: sudo ./setup.sh"
    exit 1
fi

# =============================================================================
# VARIÁVEIS DE CONFIGURAÇÃO GERAL
# =============================================================================

INSTALL_DOCKER=true           # Docker Engine + Docker Compose
INSTALL_VSCODE=true           # Visual Studio Code

# =============================================================================
# Instalar Docker
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# =============================================================================

if [ "$INSTALL_DOCKER" = true ]; then

    echo "🐳 Instalando Docker..."

    # -------------------------------------------------------------------------
    # Limpeza prévia — remove pacotes corrompidos ou instalações anteriores
    # incompletas que causariam erro "needs to be reinstalled" no apt.
    # O "|| true" garante que o script não aborte se os pacotes não existirem.
    # -------------------------------------------------------------------------
    echo "🧹 Removendo instalações anteriores do Docker (se houver)..."
    dpkg --remove --force-remove-reinstreq \
        containerd.io docker-ce docker-ce-cli \
        docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt-get remove --purge -y \
        containerd.io docker-ce docker-ce-cli \
        docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt-get autoremove -y
    apt-get clean

    # Add Docker's official GPG key:
    apt-get update
    apt-get install -y ca-certificates curl          # CORRIGIDO: flag -y adicionada
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    # CORRIGIDO: substituído <<-EOF (remove tabs) por <<'EOF' sem indentação,
    # evitando que espaços impeçam o reconhecimento do delimitador de fechamento.
    tee /etc/apt/sources.list.d/docker.sources > /dev/null <<'EOF'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: UBUNTU_CODENAME_PLACEHOLDER
Components: stable
Architectures: ARCH_PLACEHOLDER
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    # Substitui os placeholders com os valores reais após o heredoc
    UBUNTU_CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
    ARCH=$(dpkg --print-architecture)
    sed -i \
        -e "s/UBUNTU_CODENAME_PLACEHOLDER/${UBUNTU_CODENAME}/" \
        -e "s/ARCH_PLACEHOLDER/${ARCH}/" \
        /etc/apt/sources.list.d/docker.sources

    apt-get update

    # Instala a versão mais recente do Docker:
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  # CORRIGIDO: flag -y adicionada

    echo "✅ Docker instalado com sucesso."

    # O serviço Docker inicia automaticamente após a instalação. Para verificar:
    # [sudo systemctl status docker]
    # Caso não inicie automaticamente:
    # [sudo systemctl start docker]
    # Para testar a instalação:
    # [sudo docker run hello-world]

else
    echo "❎ INSTALL_DOCKER = false (Docker ignorado nas configurações)"
fi

# =============================================================================
# Instalar VSCode
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# =============================================================================

if [ "$INSTALL_VSCODE" = true ]; then
 
    echo "💻 Instalando Visual Studio Code..."
 
    # -------------------------------------------------------------------------
    # Limpeza prévia — remove instalações anteriores via snap ou apt
    # -------------------------------------------------------------------------
    echo "🧹 Removendo instalações anteriores do VSCode (se houver)..."
    snap remove code 2>/dev/null || true
    apt-get remove --purge -y code 2>/dev/null || true
    apt-get autoremove -y
 
    # -------------------------------------------------------------------------
    # Instala via snap (sem plugins, configuração limpa)
    # --classic é obrigatório: o VSCode precisa de acesso fora do sandbox snap
    # -------------------------------------------------------------------------
    snap install code --classic
 
    echo "✅ Visual Studio Code instalado com sucesso."
 
    # Para abrir o VSCode:
    # [code .]          — abre no diretório atual
    # [code /caminho]   — abre em um caminho específico
 
else
    echo "❎ INSTALL_VSCODE = false (VSCode ignorado nas configurações)"
fi
