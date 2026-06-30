#!/bin/bash

echo "[-] Desligando o Ollama..."
sudo systemctl stop ollama

echo "[-] Desligando o Open WebUI (Podman)..."
systemctl --user stop open-webui.service

echo "[-] Desligando o ComfyUI..."
pkill -f "main.py --lowvram"

echo "[!] Todos os recursos liberados. Bom jogo!"