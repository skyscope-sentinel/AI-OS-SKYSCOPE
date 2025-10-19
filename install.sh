#!/usr/bin/env bash
# ====================================================================
# SkyScope Sentinel OS - Ultimate AGI Installer (v1.1 Refined)
# ====================================================================
# Author: Miss Casey Jay Topojani | 2025 Ultimate Local AGI
# Purpose: This script performs a full, automated installation of the
#          SkyScope Sentinel AGI Operating System environment. It
#          handles system dependencies, Python environment setup,
#          local LLM and workflow engine deployment, and configures
#          the AGI to run as a persistent system service.
# ====================================================================

set -e
export DEBIAN_FRONTEND=noninteractive

# --- Helper Functions for logging ---
info() { echo -e "\e[34m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
fail() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }
warn() { echo -e "\e[33m[WARNING]\e[0m $1"; }

# --- Pre-flight Checks ---
info "Performing pre-flight checks..."
[[ $(id -u) -eq 0 ]] && fail "This script must not be run as root. It will use 'sudo' when necessary."
command -v git >/dev/null 2>&1 || fail "Git is required but not installed. Please install it first."
command -v curl >/dev/null 2>&1 || fail "Curl is required but not installed. Please install it first."
info "Pre-flight checks passed."

# --- System Rebranding ---
info "Rebranding system to SkyScope Sentinel OS..."
sudo hostnamectl set-hostname skyscope-sentinel
NEW_MOTD="Welcome to SkyScope Sentinel Intelligence Enterprise ASI AGI AI OS"
echo "$NEW_MOTD" | sudo tee /etc/motd > /dev/null
info "Hostname and MOTD updated."

# --- Main Installation ---
info "Updating system and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y \
    python3 python3-pip python3-venv git curl jq ffmpeg sox vlc imagemagick \
    chromium-driver nodejs npm build-essential unzip wget libnss3 libatk1.0-0 \
    libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libgbm1 libasound2
success "System dependencies installed."

# --- Environment Setup ---
SKYSCOPE_HOME="$HOME/.skyscope_os"
info "Setting up SkyScope OS environment at $SKYSCOPE_HOME..."
mkdir -p "$SKYSCOPE_HOME"/{env,logs,memory,knowledge_stack,agents,mcp,workflows,llm}
python3 -m venv "$SKYSCOPE_HOME/env"
source "$SKYSCOPE_HOME/env/bin/activate"
pip install --upgrade pip wheel
success "Python virtual environment created."

# --- Create requirements.txt ---
info "Creating requirements file..."
cat > "$SKYSCOPE_HOME/requirements.txt" <<'EOF'
torch
torchvision
torchaudio
numpy
pandas
requests
psutil
fastapi
uvicorn
python-multipart
selenium
helium
sentence-transformers
langchain
langchain-core
langgraph
swarms
evoagentx
smolagents[toolkit]
faiss-cpu
alive-progress
prompt_toolkit
google-auth
google-auth-oauthlib
google-api-python-client
pyyaml
arxiv
docker
lief
capstone
uncompyle6
jinja2
playwright
beautifulsoup4
moviepy
gtts
transformers
tqdm
gitpython
pillow
EOF

# --- Python Dependencies ---
info "Installing core Python agentic and system dependencies from requirements.txt..."
pip install -r "$SKYSCOPE_HOME/requirements.txt"
success "Python dependencies installed."

info "Installing Playwright browsers..."
playwright install
success "Playwright browsers installed."

# --- n8n Setup for Local Workflow Orchestration ---
info "Installing n8n and pm2..."
sudo npm install -g n8n pm2
info "Configuring n8n to run with pm2..."
# The --unsafe-perm flag is sometimes needed for global npm installs
if ! pm2 show skyscope-n8n > /dev/null 2>&1; then
    pm2 start "n8n" --name skyscope-n8n
    pm2 startup
    pm2 save --force
    success "n8n is running via pm2 at http://localhost:5678"
else
    info "n8n is already managed by pm2."
fi


# --- Ollama Setup for Local LLM Inference ---
info "Installing Ollama for local LLM intelligence..."
curl -fsSL https://ollama.com/install.sh | sh
info "Pulling required models (phi3:mini and smollm:135m)..."
ollama pull phi3:mini
ollama pull smollm:135m
success "Ollama installed and models are available."

# --- Deploying SkyScope OS Modules ---
info "Deploying SkyScope OS Python modules with correct structure..."
ENV_DIR="$SKYSCOPE_HOME/env"

# Copy top-level files
cp orchestrator.py cli.py memory.py "$ENV_DIR/"

# Copy package directories
cp -r daemons governance tools "$ENV_DIR/"

success "All SkyScope OS Python modules deployed."

# --- CLI Launcher ---
info "Installing the 'skyscope' command-line launcher..."
mkdir -p "$HOME/bin"
cat > "$HOME/bin/skyscope" <<'EOF'
#!/usr/bin/env bash
# Launcher for the SkyScope Sentinel CLI
if [ -f "$HOME/.skyscope_os/env/bin/activate" ]; then
    source "$HOME/.skyscope_os/env/bin/activate"
    python3 "$HOME/.skyscope_os/env/cli.py"
else
    echo "Error: SkyScope environment not found. Please run the installer."
fi
EOF
chmod +x "$HOME/bin/skyscope"

# --- Robust PATH modification ---
info "Configuring PATH for skyscope command..."
BIN_DIR="$HOME/bin"
CONFIG_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")

for config_file in "${CONFIG_FILES[@]}"; do
    if [ -f "$config_file" ]; then
        if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$config_file"; then
            info "Adding $BIN_DIR to PATH in $config_file"
            echo '' >> "$config_file"
            echo '# Add SkyScope command to PATH' >> "$config_file"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$config_file"
        else
            info "$BIN_DIR is already in PATH in $config_file"
        fi
    fi
done
export PATH="$BIN_DIR:$PATH"
success "CLI launcher 'skyscope' is now available."
warn "Please open a new terminal or run 'source ~/.bashrc' (or appropriate file) to use the 'skyscope' command."


# --- Systemd Service for Persistence ---
info "Setting up systemd service for persistent autonomous operation..."
SERVICE_FILE="/etc/systemd/system/skyscope.service"
sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=SkyScope Sentinel OS - Autonomous AGI Core
After=network.target

[Service]
User=$USER
Group=$(id -gn $USER)
ExecStart=$SKYSCOPE_HOME/env/bin/python3 $SKYSCOPE_HOME/env/orchestrator.py
Restart=always
RestartSec=10
Environment=\"HOME=$HOME\"
Environment=\"PYTHONPATH=$SKYSCOPE_HOME/env\"
WorkingDirectory=$SKYSCOPE_HOME/env

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable skyscope.service
sudo systemctl restart skyscope.service # Use restart to ensure it picks up changes
success "SkyScope OS systemd service has been enabled and started."

echo
success "================================================================"
success "SkyScope Sentinel OS installation complete."
info "To interact with the AGI, open a NEW terminal and type: skyscope"
info "The API endpoint is available at http://localhost:8000"
info "The n8n workflow editor is at http://localhost:5678"
success "================================================================"
echo
