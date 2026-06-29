Backup IA

#!/bin/bash

# Configurações - Altere se o nome do seu volume ou pasta for diferente
VOLUME_DOCKER="open-webui"
PASTA_BACKUP="$HOME/backups_ia"
CONTAINER_NAME="open-webui"

clear
echo "========================================="
echo "   Gerenciador de Backup - Open WebUI   "
echo "========================================="
echo "1 - Criar Backup Completo (.tar.gz)"
echo "2 - Restaurar Backup Existente"
echo "3 - Sair"
read -p "Escolha uma opção: " opcao

mkdir -p "$PASTA_BACKUP"

case $opcao in
    1)
        DATA=$(date +%Y-%m-%d_%H-%M-%S)
        ARQUIVO_FINAL="$PASTA_BACKUP/backup_openwebui_$DATA.tar.gz"
        
        echo -e "\n[+] Parando o container para evitar corrupção de dados..."
        sudo docker stop $CONTAINER_NAME
        
        echo "[+] Criando cópia compactada do volume..."
        # Cria um container temporário para zipar o volume original de forma segura
        sudo docker run --rm -v $VOLUME_DOCKER:/data -v "$PASTA_BACKUP":/backup ubuntu tar -czf /backup/backup_openwebui_$DATA.tar.gz -C /data .
        
        echo "[+] Inicializando o container novamente..."
        sudo docker start $CONTAINER_NAME
        
        echo -e "\n[!] Perfeito! Backup salvo com sucesso em:"
        echo "--> $ARQUIVO_FINAL"
        ;;
    2)
        echo -e "\n[!] Backups disponíveis na pasta:"
        ls -1 "$PASTA_BACKUP"
        echo "-----------------------------------------"
        read -p "Digite o nome exato do arquivo .tar.gz que deseja restaurar: " arquivo_restaurar
        
        IF_FILE="$PASTA_BACKUP/$arquivo_restaurar"
        if [ ! -f "$IF_FILE" ] || [ -z "$arquivo_restaurar" ]; then
            echo "[X] Erro: Arquivo não encontrado."
            exit 1
        fi
        
        read -p "[!] ATENÇÃO: Isso vai apagar os dados atuais da IA. Deseja continuar? (s/n): " confirma
        if [[ "$confirma" =~ ^[Ss]$ ]]; then
            echo "[+] Parando container..."
            sudo docker stop $CONTAINER_NAME
            
            echo "[+] Limpando volume atual..."
            sudo docker run --rm -v $VOLUME_DOCKER:/data ubuntu find /data -mindepth 1 -delete
            
            echo "[+] Descompactando e restaurando dados..."
            sudo docker run --rm -v $VOLUME_DOCKER:/data -v "$PASTA_BACKUP":/backup ubuntu tar -xzf /backup/$arquivo_restaurar -C /data
            
            echo "[+] Inicializando container restaurado..."
            sudo docker start $CONTAINER_NAME
            echo -e "\n[!] Restauração concluída com sucesso!"
        else
            echo "[*] Operação cancelada."
        fi
        ;;
    3)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida."
        ;;
esac

