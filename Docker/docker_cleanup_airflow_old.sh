#!/bin/bash

# Dar permissão:
# sudo chmod +x docker_cleanup.sh

# Verificar Permissão:
# sudo ls -l docker_cleanup.sh

# Executar
# sudo ./docker_cleanup.sh

# 🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰
# VARIÁVEIS DE CONFIGURAÇÃO GERAL

# set -e # interrompe o script ao encontrar qualquer erro (opcional: comentar em caso de conteineres zumbis)
# set -x  # Descomentar para ver log completo
modo_debug=false # Variável para reiniciar o docker após finalização do script
reiniciar_docker=false
docker_container_prefix="nome_do_container"
conteiner_zumbi=false # Variável para eliminar containers com PID = 0 (zumbis reais)

# Módulo Airflow
airflow=false
reiniciar_containers=false

# 🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰
# CONTEINERES ZUMBI

# Verificar e remover containers zumbis com PID = 0
if [ "$conteiner_zumbi" = true ]; then  
  echo "🧟 Verificando containers com PID = 0 (zumbis reais)..."

  zombie_pid_zero=$(docker ps -aq | while read cid; do
    pid=$(docker inspect --format '{{.State.Pid}}' "$cid" 2>/dev/null || echo "error")
    if [[ "$pid" == "0" ]]; then
      echo "$cid"
    fi
  done)

  if [ -n "$zombie_pid_zero" ]; then
    echo "⚠️ Containers zumbis com PID = 0 encontrados:"
    docker ps -a --filter "id=$(echo $zombie_pid_zero | tr '\n' ',')" 2>/dev/null

    echo "🗑️ Removendo containers zumbis (PID = 0)..."
    docker rm -f $zombie_pid_zero && echo "✅ Containers zumbis removidos."
  else
    echo "🎉 Nenhum container com PID = 0 encontrado."
  fi
else
  echo "conteiner_zumbi false"
fi
# exit 1

# 🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰
# AIRFLOW MÓDULO

if [ "$modo_debug" = false ]; then
  echo "Iniciando Limpeza Airflow"
  if [ "$airflow" = true ]; then
    echo "🌀 Limpando logs do Airflow dentro dos containers..."
    docker exec ${docker_container_prefix}-airflow-scheduler-1 bash -c "rm -rf /opt/airflow/logs/*"
    docker exec ${docker_container_prefix}-airflow-webserver-1 bash -c "rm -rf /opt/airflow/logs/*"
    docker exec ${docker_container_prefix}-airflow-worker-1 bash -c "rm -rf /opt/airflow/logs/*"
    docker exec ${docker_container_prefix}-airflow-triggerer-1 bash -c "rm -rf /opt/airflow/logs/*"
    echo "✅ Logs internos do Airflow limpos."
  else 
    echo "airflow = false"
  fi
else 
  echo "debug true"
fi

if [ "$modo_debug" = false ]; then
  if [ "$reiniciar_containers" = true ]; then
    echo "🌀 Todos os logs limps. Reiniciando os containers..."
    docker restart ${docker_container_prefix}-airflow-scheduler-1 ${docker_container_prefix}-airflow-webserver-1 ${docker_container_prefix}-airflow-worker-1 ${docker_container_prefix}-airflow-triggerer-1
    echo "Containers restarted. Checking container status..."
    docker ps -a | grep ${docker_container_prefix} # Show container status
  else 
    echo "reiniciar_containers = false"
  fi
else 
  echo "debug true"
fi
# exit 1
# 🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰

echo "🧹 Iniciando limpeza total do Docker com permissões sudo..."

# Variáveis para serem utilizadas nos módulos de remoção
containers=$(sudo docker ps -aq) 
images=$(sudo docker images -aq)
volumes=$(sudo docker volume ls -q)

# Derrubando serviços Docker Compose, se houver
if [ "$modo_debug" = false ]; then
  if [ -f docker-compose.yml ] || [ -f docker-compose.yaml ]; then
    echo "📉 Executando 'docker compose down'..."
    if sudo docker compose down --volumes --remove-orphans; then
      echo "✅ docker compose down executado com sucesso."
    else
      echo "❌ Falha ao executar docker compose down." >&2
      exit 1
    fi
  fi
else 
  echo "debug true"
fi

# Parar todos os containers em execução
if [ "$modo_debug" = false ]; then
  echo "⛔ Parando todos os containers..."
  if [ -n "$containers" ]; then
    if sudo docker stop $containers; then
      echo "✅ Containers parados."
    else
      echo "❌ Falha ao parar containers." >&2
      exit 1
    fi
  else
    echo "⚠️ Nenhum container para parar."
  fi
else 
  echo "debug true"
fi

# Remover todos os containers
if [ "$modo_debug" = false ]; then
  echo "🗑️ Removendo todos os containers..."
  if [ -n "$containers" ]; then
    if sudo docker rm -f $containers; then
      echo "✅ Containers removidos."
    else
      echo "❌ Falha ao remover containers." >&2
      exit 1
    fi
  else
    echo "⚠️ Nenhum container para remover."
  fi
else 
  echo "debug true"
fi

# Remover todas as imagens
if [ "$modo_debug" = false ]; then
  echo "🖼️ Removendo todas as imagens..."
  if [ -n "$images" ]; then
    if sudo docker rmi -f $images; then
      echo "✅ Imagens removidas."
    else
      echo "❌ Falha ao remover imagens." >&2
      exit 1
    fi
  else
    echo "⚠️ Nenhuma imagem para remover."
  fi
else 
  echo "debug true"
fi

# Remover todos os volumes
if [ "$modo_debug" = false ]; then
  echo "📦 Removendo todos os volumes..."
  if [ -n "$volumes" ]; then
    if sudo docker volume rm -f $volumes; then
      echo "✅ Volumes removidos."
    else
      echo "❌ Falha ao remover volumes." >&2
      exit 1
    fi
  else
    echo "⚠️ Nenhum volume para remover."
  fi
else 
  echo "debug true"
fi

# Remover redes não utilizadas (exceto as padrão)
if [ "$modo_debug" = false ]; then
  echo "🔌 Removendo redes não utilizadas..."
  if sudo docker network prune -f; then
    echo "✅ Redes não utilizadas removidas."
  else
    echo "❌ Falha ao remover redes." >&2
    exit 1
  fi
else 
  echo "debug true"
fi

# Remover cache de build
if [ "$modo_debug" = false ]; then
  echo "🛠️ Removendo cache de build..."
  if sudo docker builder prune -af; then
    echo "✅ Cache de build removido."
  else
    echo "❌ Falha ao remover cache de build." >&2
    exit 1
  fi
else 
  echo "debug true"
fi

# Prune geral para garantir limpeza total
if [ "$modo_debug" = false ]; then
  echo "🧽 Limpando tudo com docker system prune..."
  if sudo docker system prune -af --volumes; then
    echo "✅ Prune geral concluído."
  else
    echo "❌ Falha no docker system prune." >&2
    exit 1
  fi
else 
  echo "debug true"
fi

# 🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰
# VERIFICAÇÃO (DEBUG)

echo -e "\n🔍 Imprimindo status de Debug e verificação:\n"

echo "🧱 Containers existentes:"
sudo docker ps -a || echo "Nenhum container encontrado."

echo -e "\n🖼️ Imagens existentes:"
sudo docker images || echo "Nenhuma imagem encontrada."

echo -e "\n📦 Volumes existentes:"
sudo docker volume ls || echo "Nenhum volume encontrado."

echo -e "\n🛠️ Builds existentes:"
sudo docker builder ls || echo "Nenhum builder encontrado."

echo -e "\n🛠️ Redes existentes:"
sudo docker network ls || echo "Nenhuma rede encontrada."

# 🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰🀰
# Reiniciar Docker

if [ "$reiniciar_docker" = true ]; then
  echo "Reiniciando Docker"
  sudo systemctl restart docker
else 
  echo "reiniciar_docker = false"
fi

echo -e "\n✨ Script Finalizado."
