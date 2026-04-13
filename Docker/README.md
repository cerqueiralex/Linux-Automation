# Docker Cleaner Shell - Script para automação de limpeza de ambiente Docker

O script docker_cleanup.sh é um utilitário Bash avançado que realiza uma limpeza completa de recursos Docker, especialmente voltado para projetos que utilizam o Airflow. 

O script inicia a limpeza total do ambiente Docker. Ele verifica se há um docker-compose.yml e, se existir, executa docker compose down com as flags --volumes e --remove-orphans para encerrar e remover os serviços compostos. Em seguida, para e remove todos os containers (docker stop e docker rm), remove todas as imagens (docker rmi), todos os volumes (docker volume rm), redes não utilizadas (docker network prune), cache de build (docker builder prune) e realiza uma limpeza geral com docker system prune. 

Cada etapa possui validação de sucesso ou falha com mensagens claras.

Após a limpeza, o script exibe o estado atual do Docker, listando containers, imagens, volumes e builders restantes. 

Por fim, se a variável reiniciar_docker estiver ativada, o serviço Docker é reiniciado com sudo systemctl restart docker. 

O script é cuidadosamente estruturado para uso seguro com sudo e fornece feedback visual detalhado durante toda a execução.

## Modularidade

Primeiramente, ele define algumas variáveis de controle que podem ser customizadas de acordo com a característica do projeto e usa set -e para interromper a execução caso algum erro ocorra. 

Exemplo de módulo para quem trabalha com Airflow:

Caso a variável airflow esteja ativada, ele limpa os logs dentro dos containers do Airflow (scheduler, webserver, worker e triggerer), executando comandos docker exec com rm -rf. Se reiniciar_containers estiver como true, reinicia esses mesmos containers usando docker restart e exibe seu status com docker ps.

<img src="https://i.imgur.com/hQiipRq.png" style="width:100%;height:auto"/>
<img src="https://i.imgur.com/C5Q8R8Z.png" style="width:100%;height:auto"/>

## Updates

🧟 Remoção de Containers Zumbis com PID = 0

Este script realiza uma etapa adicional de verificação e remoção de containers zumbis, que são instâncias Docker que aparecem como "em execução", mas na verdade estão com o processo interno travado ou ausente — ou seja, com PID = 0 no sistema.  

🔍 O que são containers zumbis?  

Containers com PID = 0 são geralmente um sinal de erro no Docker ou no sistema operacional. Eles não executam nenhum processo real e não respondem a comandos tradicionais como docker stop.
✅ Como o script lida com eles?  

Durante a execução do script, é feita uma varredura em todos os containers ativos e parados. Aqueles com PID = 0 são identificados usando docker inspect e removidos à força com docker rm -f.  
```
docker inspect --format '{{.State.Pid}}' <container_id>
```

Se o retorno for 0, o container é marcado como zumbi e excluído do sistema automaticamente. 
