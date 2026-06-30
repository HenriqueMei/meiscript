#!/bin/bash

echo "[+] Ligando o Cérebro (Ollama)..."
sudo systemctl start ollama

echo "[+] Ligando a Interface Web (Open WebUI via Podman)..."
systemctl --user start open-webui.service

echo "[+] Ligando o Estúdio de Imagens (ComfyUI)..."
nohup $HOME/ComfyUI/start_comfyui.sh > ~/comfyui.log 2>&1 &

echo "[!] Laboratório de IA 100% Online!"