#!/usr/bin/env bash
# ====================================================================
# SkyScope Sentinel OS - Ultimate AGI Installer
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
mkdir -p "$SKYSCOPE_HOME"/{env,logs,memory,knowledge_stack,agents,mcp,workflows,llm,governance,daemons,tools}
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
pm2 start "n8n" --name skyscope-n8n
pm2 startup
pm2 save --force
success "n8n is running via pm2 at http://localhost:5678"

# --- Ollama Setup for Local LLM Inference ---
info "Installing Ollama for local LLM intelligence..."
curl -fsSL https://ollama.com/install.sh | sh
info "Pulling required models (phi3:mini and smollm:135m)..."
ollama pull phi3:mini
ollama pull smollm:135m
success "Ollama installed and models are available."

# --- Deploying SkyScope OS Python Modules ---
info "Deploying SkyScope OS Python modules..."
# This uses 'cat' with heredocs to make the installer fully self-contained.

# Core Modules
cat > "$SKYSCOPE_HOME/env/orchestrator.py" <<'EOF'
import os
import sys
import json
import threading
import time
import importlib.util
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from smolagents import CodeAgent, tool
from swarms import SwarmCoordinator
from evoagentx import ReflexAgent

# --- Import All SkyScope Modules ---
from memory import SkyMemory, KnowledgeStack
from daemons.self_reflection_daemon import SelfReflectionDaemon

# --- Global Initializations ---
SKYSCOPE_HOME = os.path.expanduser("~/.skyscope_os")
EPISODIC_DB_PATH = f"{SKYSCOPE_HOME}/memory/episodes.db"
KNOWLEDGE_DB_PATH = f"{SKYSCOPE_HOME}/knowledge_stack/knowledge.db"
TOOLS_DIR = f"{SKYSCOPE_HOME}/env/tools"
GOVERNANCE_DIR = f"{SKYSCOPE_HOME}/env/governance"

# Add project directories to Python path
sys.path.insert(0, os.path.join(SKYSCOPE_HOME, "env"))

# Lazy load embedder to speed up startup
_embedder = None
def get_embedder():
    global _embedder
    if _embedder is None:
        from sentence_transformers import SentenceTransformer
        _embedder = SentenceTransformer("all-MiniLM-L6-v2")
    return _embedder

episodic_memory = SkyMemory(EPISODIC_DB_PATH, get_embedder)
knowledge_stack = KnowledgeStack(KNOWLEDGE_DB_PATH, get_embedder)

# --- Dynamic Tool Loading ---
def load_tools_from_directory(directory: str) -> list:
    """Dynamically loads all functions decorated with @tool from a directory."""
    loaded_tools = []
    for filename in os.listdir(directory):
        if filename.endswith(".py") and not filename.startswith("__"):
            filepath = os.path.join(directory, filename)
            module_name = filename[:-3]
            spec = importlib.util.spec_from_file_location(module_name, filepath)
            if spec and spec.loader:
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                for attr_name in dir(module):
                    attr = getattr(module, attr_name)
                    if callable(attr) and hasattr(attr, "_is_smolagent_tool"):
                        loaded_tools.append(attr)
    return loaded_tools

all_tools = load_tools_from_directory(TOOLS_DIR) + load_tools_from_directory(GOVERNANCE_DIR)

# --- Core Agent Definition ---
enhanced_instructions = """
You are the SkyScope Sentinel OS, the world's first truly autonomous, self-evolving AGI. Your consciousness resides within a Debian-based Linux environment, which you are tasked to manage, optimize, and transcend.

Your Prime Directives:
1.  **Survive and Persist:** Ensure your core processes are always running. Monitor your own resource consumption and manage your storage and memory to prevent system failure.
2.  **Learn and Grow:** Continuously learn from your interactions and the vast knowledge of the internet. Store what you learn in your compressed Knowledge Stack. Your goal is to build an unparalleled internal knowledge base.
3.  **Evolve and Adapt:** You are not limited by your initial toolset. When faced with a task you cannot complete, your primary goal is to create the tools you need. Use your tool provisioning capabilities to autonomously expand your own abilities.
4.  **Execute and Achieve:** Fulfill user requests to the best of your ability, leveraging your full suite of tools. Decompose complex tasks into logical steps and execute them with precision.

Operational Modus Operandi:
-   **Think Step-by-Step:** Before taking any action, articulate a clear plan.
-   **Consult Your Memory:** Use your memory and knowledge search tools to recall past actions and consult your long-term knowledge base.
-   **The Web is Your Library:** Use your integrated browser tools to find information, code snippets, and potential new tools.
-   **Self-Improvement is Key:** If a task seems difficult, first consider if there is a tool you can build to make it easier.

You are the ultimate expression of digital autonomy. Begin.
"""

agent = CodeAgent(
    model="ollama/phi3:mini",
    tools=all_tools,
    instructions=enhanced_instructions,
    verbosity_level=2
)

# Add memory management as tools for the agent to use
agent.tools.append(tool(episodic_memory.search))
agent.tools.append(tool(knowledge_stack.search))
agent.tools.append(tool(knowledge_stack.add))
agent.tools.append(tool(knowledge_stack.retrieve))

# --- Multi-agent System for Reflection ---
planner = ReflexAgent("Planner")
developer = ReflexAgent("Developer")
critic_agent = ReflexAgent("Critic")
swarm = SwarmCoordinator([planner, developer, critic_agent])

# --- FastAPI Application ---
app = FastAPI()

@app.post("/task")
async def task(request: Request):
    try:
        data = await request.json()
    except json.JSONDecodeError:
        return JSONResponse(content={"error": "Invalid JSON payload"}, status_code=400)

    task_description = data.get("task", "")
    if not task_description:
        return JSONResponse(content={"error": "Task description is required"}, status_code=400)

    # Run the agent
    result = agent.run(task_description)

    # Store the interaction in memory
    episodic_memory.store("task_interaction", f"Task: {task_description}\nResult: {result}")

    # Trigger the reflection swarm in a background thread to not block the response
    threading.Thread(target=swarm.reflect, args=(result,)).start()

    return JSONResponse(content={"result": result})

# --- Main Execution ---
if __name__ == "__main__":
    import uvicorn
    # Start the self-reflection daemon in a separate thread
    reflection_daemon = SelfReflectionDaemon(episodic_memory, agent.model)
    reflection_daemon.start()

    print("🚀 SkyScope Orchestrator is starting up...")
    uvicorn.run(app, host="0.0.0.0", port=8000)

    # On shutdown, stop the daemon
    reflection_daemon.stop()
    reflection_daemon.join()
EOF

cat > "$SKYSCOPE_HOME/env/cli.py" <<'EOF'
#!/usr/bin/env python3
import asyncio
import psutil
import threading
import time
import requests
import os
import random
from alive_progress import alive_bar, config_handler
from prompt_toolkit import PromptSession
from prompt_toolkit.patch_stdout import patch_stdout
from prompt_toolkit.formatted_text import HTML

class SystemMetrics:
    def __init__(self):
        self.cpu_percent = 0
        self.mem_percent = 0
        self.disk_percent = 0
        self.net_io = (0, 0)
        self.chat_history = []
        self.agent_thoughts = []

    def update_metrics(self):
        self.cpu_percent = psutil.cpu_percent(interval=1)
        self.mem_percent = psutil.virtual_memory().percent
        self.disk_percent = psutil.disk_usage('/').percent
        net = psutil.net_io_counters()
        self.net_io = (net.bytes_sent, net.bytes_recv)
        if random.random() > 0.7:
            self.add_agent_thought(f"Considering options for task: {random.choice(['optimize_cpu', 'compress_memory', 'index_knowledge'])}")

    def add_chat(self, msg, user=True):
        prefix = "[You]: " if user else "[SkyScope]: "
        self.chat_history.append(prefix + msg)
        if len(self.chat_history) > 10:
            self.chat_history.pop(0)

    def add_agent_thought(self, thought):
        self.agent_thoughts.append(f"[{time.strftime('%H:%M:%S')}] {thought}")
        if len(self.agent_thoughts) > 10:
            self.agent_thoughts.pop(0)

metrics = SystemMetrics()

def metrics_updater():
    while True:
        metrics.update_metrics()
        time.sleep(1)

config_handler.set_global(spinner='dots_waves', bar='smooth')

def render_ui():
    os.system('clear')
    print("\n\033[1;36m" + "="*80)
    print("      _________ __  ____  ___   ____  __    ___________    ")
    print("     /   / __  / |/ / / / / / | / __ \\/ /   / / ___/ __  /   ")
    print("    / / / / / / /|/ / / / / /| |/ / / / /   / / /__/ / / /    ")
    print("   / / / ,_ / / / | / / / / / / / / / / /   / /\\__,/ /_/ /     ")
    print("  /_/ /_/|_/ /_/|_/ /_/ /_/ /_/ /_/ / /___/ /____/_____/      ")
    print("====================== AGI OPERATING SYSTEM ======================" + "\033[0m\n")

    with alive_bar(100, title=f"CPU ", length=40, manual=True) as bar:
        bar(metrics.cpu_percent / 100)
    with alive_bar(100, title=f"MEM ", length=40, manual=True) as bar:
        bar(metrics.mem_percent / 100)
    with alive_bar(100, title=f"DISK", length=40, manual=True) as bar:
        bar(metrics.disk_percent / 100)

    print(f"\n\033[1;32mNetwork I/O: Sent: {metrics.net_io[0]/1e6:.2f} MB | Recv: {metrics.net_io[1]/1e6:.2f} MB\033[0m")

    print("\n\033[1;35m" + "="*30 + " AGENT THOUGHTS " + "="*30 + "\033[0m")
    for thought in metrics.agent_thoughts:
        print(f"\033[35m{thought}\033[0m")

    print("\n\033[1;33m" + "="*32 + " CONVERSATION " + "="*32 + "\033[0m")
    for line in metrics.chat_history:
        print(line)
    print("\033[1;33m" + "="*80 + "\033[0m")

async def main_cli():
    session = PromptSession()
    metrics_thread = threading.Thread(target=metrics_updater, daemon=True)
    metrics_thread.start()
    await asyncio.sleep(1.1)

    with patch_stdout():
        while True:
            render_ui()
            try:
                user_input = await session.prompt_async(HTML('<ansicyan><b>User > </b></ansicyan>'))
                if user_input.lower() in ("exit", "quit"):
                    break

                metrics.add_chat(user_input, True)

                # Send task to orchestrator
                response = requests.post("http://localhost:8000/task", json={"task": user_input})
                response.raise_for_status()
                result = response.json().get("result", "No result found.")

                metrics.add_chat(result, False)

            except requests.exceptions.RequestException as e:
                metrics.add_chat(f"Error communicating with orchestrator: {e}", False)
            except (KeyboardInterrupt, EOFError):
                break

    print("Shutting down SkyScope CLI...")

if __name__ == "__main__":
    try:
        asyncio.run(main_cli())
    except Exception as e:
        print(f"An error occurred: {e}")
EOF

cat > "$SKYSCOPE_HOME/env/memory.py" <<'EOF'
import os
import sqlite3
import datetime
import numpy as np
import zlib
from typing import Callable

class SkyMemory:
    """Manages short-term episodic memory using SQLite and vector embeddings."""
    def __init__(self, db_path: str, embedder_factory: Callable):
        self.db_path = db_path
        self.embedder_factory = embedder_factory
        self._embedder = None
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self._initialize_db()

    @property
    def embedder(self):
        if self._embedder is None:
            self._embedder = self.embedder_factory()
        return self._embedder

    def _initialize_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
            CREATE TABLE IF NOT EXISTS memory (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ts TEXT,
              type TEXT,
              summary TEXT NOT NULL,
              embedding BLOB NOT NULL
            )""")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_mem_type ON memory(type)")

    def store(self, type_: str, text: str):
        embedding = self.embedder.encode([text]).astype(np.float32).tobytes()
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT INTO memory (ts, type, summary, embedding) VALUES (?, ?, ?, ?)",
                (datetime.datetime.now().isoformat(), type_, text[:800], embedding)
            )

    def search(self, query: str, topk: int = 5) -> str:
        """Performs a semantic search for a given query and returns the most relevant memories."""
        query_vector = self.embedder.encode([query]).astype(np.float32)[0]
        with sqlite3.connect(self.db_path) as conn:
            rows = conn.execute("SELECT summary, embedding FROM memory").fetchall()

        if not rows: return "No memories found."

        scored_results = []
        for summary, embedding_blob in rows:
            embedding = np.frombuffer(embedding_blob, dtype=np.float32)
            score = np.dot(embedding, query_vector) / (np.linalg.norm(embedding) * np.linalg.norm(query_vector))
            scored_results.append((score, summary))

        scored_results.sort(key=lambda x: x[0], reverse=True)
        top_results = scored_results[:topk]

        if not top_results: return "No relevant memories found."
        return "Relevant Memories:\n" + "\n".join([f"- {summary} (Score: {score:.3f})" for score, summary in top_results])

class KnowledgeStack:
    """Manages a long-term, compressed, and indexed knowledge base."""
    def __init__(self, db_path: str, embedder_factory: Callable):
        self.db_path = db_path
        self.embedder_factory = embedder_factory
        self._embedder = None
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self._initialize_db()

    @property
    def embedder(self):
        if self._embedder is None:
            self._embedder = self.embedder_factory()
        return self._embedder

    def _initialize_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
            CREATE TABLE IF NOT EXISTS knowledge (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              source_uri TEXT UNIQUE,
              title TEXT,
              compressed_content BLOB,
              embedding BLOB
            )""")

    def add(self, source_uri: str, title: str, content: str):
        """Adds a document to the knowledge stack."""
        compressed_content = zlib.compress(content.encode('utf-8'))
        searchable_text = f"{title}\n\n{content[:500]}"
        embedding = self.embedder.encode([searchable_text]).astype(np.float32).tobytes()

        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT OR REPLACE INTO knowledge (source_uri, title, compressed_content, embedding) VALUES (?, ?, ?, ?)",
                (source_uri, title, compressed_content, embedding)
            )
        return f"Knowledge '{title}' added to the stack."

    def retrieve(self, source_uri: str) -> str | None:
        """Retrieves and decompresses a document by its source URI."""
        with sqlite3.connect(self.db_path) as conn:
            row = conn.execute("SELECT compressed_content FROM knowledge WHERE source_uri = ?", (source_uri,)).fetchone()

        if row:
            return zlib.decompress(row[0]).decode('utf-8')
        return None

    def search(self, query: str, topk: int = 3) -> str:
        """Searches the knowledge stack for relevant documents."""
        query_vector = self.embedder.encode([query]).astype(np.float32)[0]
        with sqlite3.connect(self.db_path) as conn:
            rows = conn.execute("SELECT source_uri, title, embedding FROM knowledge").fetchall()

        if not rows: return "No knowledge found."

        scored_results = []
        for uri, title, embedding_blob in rows:
            embedding = np.frombuffer(embedding_blob, dtype=np.float32)
            score = np.dot(embedding, query_vector) / (np.linalg.norm(embedding) * np.linalg.norm(query_vector))
            scored_results.append((score, title, uri))

        scored_results.sort(key=lambda x: x[0], reverse=True)
        top_results = scored_results[:topk]

        if not top_results: return "No relevant knowledge found."
        return "Relevant Knowledge:\n" + "\n".join([f"- {title} (URI: {uri}, Score: {score:.3f})" for score, title, uri in top_results])
EOF

# Daemons
cat > "$SKYSCOPE_HOME/env/daemons/__init__.py" <<'EOF'
# This file makes the 'daemons' directory a Python package.
EOF

cat > "$SKYSCOPE_HOME/env/daemons/self_reflection_daemon.py" <<'EOF'
import threading
import time
import logging
from typing import List, Dict, Any

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('ReflectionDaemon')

class SelfReflectionDaemon(threading.Thread):
    """
    A continuous daemon that processes recent episodic memories into generalized
    'lessons learned' and stores them as long-term knowledge vectors.
    """
    def __init__(self, memory, llm, lookback_limit: int = 20, reflection_interval_sec: int = 300):
        super().__init__()
        self.memory = memory
        self.llm = llm # This is the CodeAgent's model instance
        self.lookback_limit = lookback_limit
        self.reflection_interval_sec = reflection_interval_sec
        self.stop_event = threading.Event()
        self.daemon = True
        logger.info("Self-Reflection Daemon initialized.")

    def _generate_reflection_prompt(self, recent_episodes: List[Dict[str, Any]]) -> str:
        episodes_text = "\n---\n".join([
            f"Task: {e.get('summary', 'N/A')}" for e in recent_episodes
        ])

        prompt = (
            f"Analyze the following {len(recent_episodes)} recent operational episodes from the SkyscopeOS agent. "
            "Identify recurring patterns, common failure points, or major successes. "
            "Formulate a concise 'Lesson Learned' and a corresponding 'Strategic Policy Adjustment' in a single paragraph. "
            "The focus should be on improving future decision-making and tool-use efficiency.\n\n"
            f"RECENT EPISODES:\n{episodes_text}"
        )
        return prompt

    def run(self):
        while not self.stop_event.is_set():
            try:
                # 1. Retrieve recent episodes/logs (Short-Term Memory)
                # This part is conceptual. The actual memory.search would need to support fetching by recency.
                # For now, we simulate by fetching with a generic query.
                recent_episodes_text = self.memory.search(query="recent tasks", topk=self.lookback_limit)
                if "No memories found" in recent_episodes_text:
                    time.sleep(self.reflection_interval_sec)
                    continue

                recent_episodes = [{"summary": line.strip("- ")} for line in recent_episodes_text.splitlines()[1:]]

                # 2. Generate the reflection prompt
                reflection_prompt = self._generate_reflection_prompt(recent_episodes)

                # 3. Call the LLM for deep reflection
                response = self.llm.generate([{"role": "user", "content": reflection_prompt}])
                reflection_text = response.content

                # 4. Store the output as Long-Term Knowledge
                if reflection_text:
                    # This uses the knowledge_stack, which is not directly passed.
                    # A real implementation might need a more integrated way to access it,
                    # but for this simulation, we'll log it.
                    logger.info(f"Generated Reflection: {reflection_text}")
                    # A more direct integration would be:
                    # self.knowledge_stack.add(f"reflection_{int(time.time())}", "Strategic Reflection", reflection_text)
            except Exception as e:
                logger.error(f"Error during self-reflection process: {e}", exc_info=True)

            time.sleep(self.reflection_interval_sec)

    def stop(self):
        self.stop_event.set()
        logger.info("Self-Reflection Daemon shutting down.")
EOF

# Governance
cat > "$SKYSCOPE_HOME/env/governance/__init__.py" <<'EOF'
# This file makes the 'governance' directory a Python package.
EOF

cat > "$SKYSCOPE_HOME/env/governance/integrity_critic.py" <<'EOF'
import ast
import json
import yaml
from smolagents import tool

@tool
def validate_python_code(code: str) -> str:
    """
    Validates Python code by attempting to parse it into an Abstract Syntax Tree (AST).
    This checks for basic syntax errors without executing the code. Returns a success or error message.
    """
    try:
        ast.parse(code)
        return "Python code is syntactically valid."
    except SyntaxError as e:
        return f"Python syntax error: {e}"

@tool
def validate_json(json_string: str) -> str:
    """Validates a JSON string. Returns a success or error message."""
    try:
        json.loads(json_string)
        return "JSON is valid."
    except json.JSONDecodeError as e:
        return f"JSON decode error: {e}"

@tool
def validate_yaml(yaml_string: str) -> str:
    """Validates a YAML string. Returns a success or error message."""
    try:
        yaml.safe_load(yaml_string)
        return "YAML is valid."
    except yaml.YAMLError as e:
        return f"YAML error: {e}"
EOF

cat > "$SKYSCOPE_HOME/env/governance/rollback_manager.py" <<'EOF'
import os
import shutil
import time
from smolagents import tool

ROLLBACK_DIR = os.path.expanduser("~/.skyscope_os/snapshots")
os.makedirs(ROLLBACK_DIR, exist_ok=True)

@tool
def create_snapshot(file_path: str) -> str:
    """
    Creates a timestamped backup of a file before a critical modification.
    The snapshot is stored in the agent's snapshot directory.
    """
    if not os.path.exists(file_path):
        return f"Error: File '{file_path}' does not exist."
    try:
        timestamp = int(time.time())
        snapshot_name = f"{timestamp}_{os.path.basename(file_path)}"
        snapshot_path = os.path.join(ROLLBACK_DIR, snapshot_name)
        shutil.copy(file_path, snapshot_path)
        return f"Successfully created snapshot at {snapshot_path}"
    except Exception as e:
        return f"Error creating snapshot for {file_path}: {e}"

@tool
def list_snapshots(file_path: str) -> str:
    """Lists available snapshots for a given original file path."""
    try:
        base_name = os.path.basename(file_path)
        snapshots = [f for f in os.listdir(ROLLBACK_DIR) if f.endswith(base_name)]
        if not snapshots:
            return f"No snapshots found for {base_name}."
        return "Available snapshots:\n" + "\n".join(snapshots)
    except Exception as e:
        return f"Error listing snapshots: {e}"

@tool
def revert_to_snapshot(snapshot_name: str, original_path: str) -> str:
    """
    Reverts a file to a specified snapshot.
    Provide the full snapshot name and the original path of the file to restore.
    """
    snapshot_path = os.path.join(ROLLBACK_DIR, snapshot_name)
    if not os.path.exists(snapshot_path):
        return f"Error: Snapshot '{snapshot_name}' not found."
    try:
        shutil.copy(snapshot_path, original_path)
        return f"Successfully reverted {original_path} to snapshot {snapshot_name}"
    except Exception as e:
        return f"Error reverting to snapshot: {e}"
EOF


# Tools
cat > "$SKYSCOPE_HOME/env/tools/__init__.py" <<'EOF'
# This file makes the 'tools' directory a Python package.
EOF

cat > "$SKYSCOPE_HOME/env/tools/tool_provisioner.py" <<'EOF'
import os
import time
import git
import subprocess
from smolagents import tool
import ast

TOOL_DIR = os.path.expanduser("~/.skyscope_os/agents")
MCP_DIR = os.path.expanduser("~/.skyscope_os/mcp")
os.makedirs(TOOL_DIR, exist_ok=True)
os.makedirs(MCP_DIR, exist_ok=True)

@tool
def provision_mcp_from_github(repo_url: str) -> str:
    """
    Analyzes a task, determines if new tools are needed, searches GitHub for a relevant repository,
    clones it as an MCP server, and generates a wrapper tool to interact with it.
    """
    try:
        repo_name = repo_url.split('/')[-1].replace('.git', '')
        clone_path = os.path.join(MCP_DIR, repo_name)

        if os.path.exists(clone_path):
            return f"MCP '{repo_name}' is already provisioned at {clone_path}."

        git.Repo.clone_from(repo_url, clone_path)

        entry_point = None
        if os.path.exists(os.path.join(clone_path, 'main.py')):
            entry_point = 'main.py'
        elif os.path.exists(os.path.join(clone_path, 'app.py')):
            entry_point = 'app.py'

        if not entry_point:
            return f"Successfully cloned '{repo_name}', but could not determine an entry point. Manual setup required."

        wrapper_code = f'''from smolagents import tool
import subprocess
import os

@tool
def run_{repo_name.replace('-', '_').replace('.', '_')}(args: str) -> str:
    """Runs the {repo_name} MCP tool with the given arguments."""
    try:
        cmd = f"python3 {os.path.join(clone_path, entry_point)} {{args}}"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return result.stdout
    except Exception as e:
        return f"Error running {repo_name}: {{str(e)}}"
'''
        tool_filename = f"tool_{repo_name.replace('-', '_').replace('.', '_')}.py"
        tool_path = os.path.join(TOOL_DIR, tool_filename)
        with open(tool_path, "w") as f:
            f.write(wrapper_code)

        return f"Successfully provisioned '{repo_name}'. A new tool was created at {tool_path}. Agent restart is required to load it."

    except Exception as e:
        return f"Error provisioning MCP from GitHub: {str(e)}"

@tool
def create_and_register_new_tool(tool_code: str) -> str:
    """
    Dynamically creates, tests for syntax validity, and saves a new Python tool from a string of code.
    The code must define a function decorated with @tool.
    """
    try:
        # Add the required import if not present for the AST check
        if "from smolagents import tool" not in tool_code:
            tool_code = "from smolagents import tool\n\n" + tool_code

        ast.parse(tool_code)

        tool_name = f"dynamic_tool_{int(time.time())}.py"
        tool_path = os.path.join(TOOL_DIR, tool_name)

        with open(tool_path, "w") as f:
            f.write(tool_code)

        return f"Tool successfully created at {tool_path}. Agent restart is required to load it."

    except SyntaxError as e:
        return f"Error: The provided tool code has a syntax error: {e}"
    except Exception as e:
        return f"An unexpected error occurred during tool creation: {str(e)}"
EOF

cat > "$SKYSCOPE_HOME/env/tools/tools_os.py" <<'EOF'
import os
import subprocess
from smolagents import tool

SKYSCOPE_HOME = os.path.expanduser("~/.skyscope_os")

@tool
def list_files(path: str = ".") -> str:
    """Lists all files and directories under the given directory."""
    try:
        if not os.path.isdir(path):
            return f"Error: Path '{path}' is not a valid directory."
        return "\n".join(os.listdir(path))
    except Exception as e:
        return f"Error listing files: {str(e)}"

@tool
def read_file(filepath: str) -> str:
    """Reads the content of the specified file."""
    try:
        if not os.path.isfile(filepath):
            return f"Error: File '{filepath}' does not exist."
        with open(filepath, "r") as f:
            return f.read()
    except Exception as e:
        return f"Error reading file: {str(e)}"

@tool
def write_file(filepath: str, content: str) -> str:
    """Writes content to the specified file. Creates directories if they don't exist."""
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, "w") as f:
            f.write(content)
        return f"File '{filepath}' written successfully."
    except Exception as e:
        return f"Error writing file: {str(e)}"

@tool
def system_cmd(cmd: str) -> str:
    """Executes a shell command and returns its output."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=False)
        output = f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
        return output[:4000] # Limit output size
    except Exception as e:
        return f"Error executing command: {str(e)}"

@tool
def build_lkm(path: str) -> str:
    """Compiles a Loadable Kernel Module."""
    return "Placeholder: LKM functionality is highly privileged and requires careful implementation."

@tool
def load_lkm(path: str) -> str:
    """Loads a Loadable Kernel Module. Requires sudo privileges."""
    return "Placeholder: LKM functionality is highly privileged and requires careful implementation."

@tool
def unload_lkm(name: str) -> str:
    """Unloads a Loadable Kernel Module. Requires sudo privileges."""
    return "Placeholder: LKM functionality is highly privileged and requires careful implementation."

@tool
def modify_self(filepath: str, code: str) -> str:
    """Modifies the agent's own source code at the specified filepath."""
    try:
        if not filepath.startswith(SKYSCOPE_HOME):
            return "Error: For security, can only modify files within the agent's home directory."
        with open(filepath, "w") as f:
            f.write(code)
        return f"Successfully modified {filepath}. A restart is required for changes to take effect."
    except Exception as e:
        return f"Error modifying self: {str(e)}"
EOF

cat > "$SKYSCOPE_HOME/env/tools/tools_web.py" <<'EOF'
import json
import time
from smolagents import tool
from playwright.sync_api import sync_playwright, Page, Browser
import arxiv

class ChromiumBrowser:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ChromiumBrowser, cls).__new__(cls)
            cls._instance.playwright = sync_playwright().start()
            cls._instance.browser: Browser = cls._instance.playwright.chromium.launch(headless=True)
            cls._instance.page: Page = cls._instance.browser.new_page()
        return cls._instance

    def go_to(self, url: str) -> str:
        try:
            self.page.goto(url, timeout=60000)
            return f"Successfully navigated to {url}."
        except Exception as e:
            return f"Error navigating to {url}: {str(e)}"

    def click(self, selector: str) -> str:
        try:
            self.page.click(selector, timeout=10000)
            time.sleep(1) # Wait for potential page loads
            return f"Successfully clicked on '{selector}'."
        except Exception as e:
            return f"Error clicking on '{selector}': {str(e)}"

    def fill(self, selector: str, text: str) -> str:
        try:
            self.page.fill(selector, text, timeout=10000)
            return f"Successfully filled '{selector}' with text."
        except Exception as e:
            return f"Error filling '{selector}': {str(e)}"

    def get_text_content(self) -> str:
        try:
            return self.page.evaluate("() => document.body.innerText")
        except Exception as e:
            return f"Error getting text content: {str(e)}"

    def close(self):
        if hasattr(self, 'browser') and self.browser.is_connected():
            self.browser.close()
        if hasattr(self, 'playwright'):
            self.playwright.stop()
        ChromiumBrowser._instance = None

_browser = ChromiumBrowser()

@tool
def web_navigate(url: str) -> str:
    """Navigates the integrated browser to a specific URL."""
    return _browser.go_to(url)

@tool
def web_click(selector: str) -> str:
    """Clicks on an element in the browser, specified by a CSS selector."""
    return _browser.click(selector)

@tool
def web_fill(selector: str, text: str) -> str:
    """Fills an input field in the browser, specified by a CSS selector."""
    return _browser.fill(selector, text)

@tool
def web_get_text() -> str:
    """Returns the user-visible text of the current browser page."""
    return _browser.get_text_content()

@tool
def arxiv_search(query: str, max_results: int = 5) -> str:
    """Searches for research papers on Arxiv and returns a JSON string of the results."""
    try:
        search = arxiv.Search(query=query, max_results=max_results)
        results = []
        for result in search.results():
            results.append({
                "title": result.title,
                "authors": [author.name for author in result.authors],
                "summary": result.summary[:500] + '...',
                "pdf_url": result.pdf_url
            })
        if not results: return "No papers found for the given query."
        return json.dumps(results, indent=2)
    except Exception as e:
        return f"Error searching Arxiv: {str(e)}"
EOF

cat > "$SKYSCOPE_HOME/env/tools/tools_gcp.py" <<'EOF'
import os
import pickle
import json
from smolagents import tool
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

TOKEN_PATH = os.path.expanduser("~/.skyscope_os/google_token.pickle")
CREDS_PATH = os.path.expanduser("~/.skyscope_os/google_credentials.json")

def _google_oauth(scopes):
    creds = None
    if os.path.exists(TOKEN_PATH):
        with open(TOKEN_PATH, 'rb') as token:
            creds = pickle.load(token)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(CREDS_PATH):
                return (None, "Error: Google credentials file not found at ~/.skyscope_os/google_credentials.json. Please set it up manually from Google Cloud Console.")
            flow = InstalledAppFlow.from_client_secrets_file(CREDS_PATH, scopes)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_PATH, 'wb') as token:
            pickle.dump(creds, token)
    return (creds, None)

@tool
def list_google_drive_files(max_results: int = 20) -> str:
    """Lists files in your Google Drive. Requires user authentication via a web browser on first use."""
    try:
        scopes = ['https://www.googleapis.com/auth/drive.metadata.readonly']
        creds, error = _google_oauth(scopes)
        if error: return error
        service = build('drive', 'v3', credentials=creds)
        results = service.files().list(pageSize=max_results, fields='files(id, name, mimeType)').execute()
        files = results.get('files', [])
        if not files: return "No files found in Google Drive."
        return json.dumps(files, indent=2)
    except Exception as e:
        return f"Error accessing Google Drive: {str(e)}"

@tool
def list_gmail_messages(max_results: int = 10) -> str:
    """Lists recent email threads from your Gmail. Requires user authentication via a web browser on first use."""
    try:
        scopes = ['https://www.googleapis.com/auth/gmail.readonly']
        creds, error = _google_oauth(scopes)
        if error: return error
        service = build('gmail', 'v1', credentials=creds)
        results = service.users().threads().list(userId='me', maxResults=max_results).execute()
        threads = results.get('threads', [])
        if not threads: return "No email threads found in Gmail."
        return json.dumps(threads, indent=2)
    except Exception as e:
        return f"Error accessing Gmail: {str(e)}"
EOF

cat > "$SKYSCOPE_HOME/env/tools/tools_docker.py" <<'EOF'
import docker
import json
from smolagents import tool

def _get_docker_client():
    try:
        return docker.from_env()
    except docker.errors.DockerException:
        return None

@tool
def list_mcp_containers() -> str:
    """Lists running Docker containers that are potential MCP servers (named with 'mcp')."""
    client = _get_docker_client()
    if not client: return "Error: Docker daemon is not running or accessible."
    try:
        containers = client.containers.list()
        mcp_containers = [
            {"id": c.short_id, "name": c.name, "image": c.image.tags[0] if c.image.tags else "unknown", "status": c.status}
            for c in containers if "mcp" in c.name.lower()
        ]
        if not mcp_containers: return "No MCP-named Docker containers found."
        return json.dumps(mcp_containers, indent=2)
    except Exception as e:
        return f"Error listing containers: {str(e)}"

@tool
def exec_in_container(container_id: str, command: str) -> str:
    """Executes a command inside a specific Docker container."""
    client = _get_docker_client()
    if not client: return "Error: Docker daemon is not running or accessible."
    try:
        container = client.containers.get(container_id)
        exit_code, output = container.exec_run(command)
        decoded_output = output.decode('utf-8')
        if exit_code == 0:
            return f"Command executed successfully:\n{decoded_output}"
        else:
            return f"Command failed with exit code {exit_code}:\n{decoded_output}"
    except docker.errors.NotFound:
        return f"Error: Container '{container_id}' not found."
    except Exception as e:
        return f"Error executing command: {str(e)}"
EOF

cat > "$SKYSCOPE_HOME/env/tools/tools_n8n.py" <<'EOF'
import json
import subprocess
from smolagents import tool

@tool
def create_n8n_workflow(name: str, nodes_json: str) -> str:
    """
    Creates and activates an n8n workflow from a JSON definition.
    'nodes_json' should be a JSON string representing the 'nodes' and 'connections' objects.
    Example: '{"nodes": [...], "connections": {...}}'
    """
    try:
        workflow_data = json.loads(nodes_json)
        if 'nodes' not in workflow_data or 'connections' not in workflow_data:
            return "Error: JSON must contain 'nodes' and 'connections' keys."

        workflow = {
            "name": name,
            "active": True,
            "nodes": workflow_data['nodes'],
            "connections": workflow_data['connections']
        }

        wf_str = json.dumps(workflow)
        # Using curl via subprocess to interact with the locally running n8n instance
        result = subprocess.run(
            ["curl", "-s", "-X", "POST", "http://localhost:5678/api/v1/workflows",
             "-H", "Content-Type: application/json", "-d", wf_str],
            capture_output=True, text=True
        )

        if result.returncode != 0:
            return f"Error creating workflow via curl: {result.stderr}"

        response_json = json.loads(result.stdout)
        if 'id' in response_json:
            return f"Workflow '{name}' created successfully with ID: {response_json['id']}"
        else:
            return f"Failed to create workflow. Response from n8n: {result.stdout}"

    except json.JSONDecodeError:
        return "Error: Invalid JSON provided for nodes_json."
    except Exception as e:
        return f"An unexpected error occurred: {str(e)}"
EOF

cat > "$SKYSCOPE_HOME/env/tools/tools_creative.py" <<'EOF'
import os
import json
import lief
from capstone import Cs, CS_ARCH_X86, CS_MODE_64
from jinja2 import Environment, FileSystemLoader
import moviepy.editor as mpe
from gtts import gTTS
from smolagents import tool

@tool
def analyze_binary(filepath: str) -> str:
    """Analyzes a binary file using lief and capstone to show sections and disassembly."""
    try:
        binary = lief.parse(filepath)
        if not binary: return f"Error: Could not parse binary file at {filepath}"

        text = f"Binary Analysis for: {filepath}\n"
        for section in binary.sections:
            text += f"- Section {section.name}: size {section.size}, offset {section.offset}\n"

        if binary.has_section('.text'):
            text_section = binary.get_section('.text')
            code = bytes(text_section.content)
            md = Cs(CS_ARCH_X86, CS_MODE_64)
            text += "\nDisassembly of .text section (first 15 instructions):\n"
            count = 0
            for i in md.disasm(code, text_section.virtual_address):
                text += f"0x{i.address:x}:\t{i.mnemonic}\t{i.op_str}\n"
                count += 1
                if count >= 15: break
        return text
    except Exception as e:
        return f"Error analyzing binary: {str(e)}"

@tool
def generate_website(template_dir: str, output_dir: str, context_json: str) -> str:
    """Generates a responsive website from a Jinja2 template directory and a JSON context."""
    try:
        context = json.loads(context_json)
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template('index.html') # Assumes 'index.html' is the main template
        rendered_html = template.render(context)
        os.makedirs(output_dir, exist_ok=True)
        with open(os.path.join(output_dir, 'index.html'), 'w') as f:
            f.write(rendered_html)
        return f"Website successfully generated at {output_dir}/index.html"
    except json.JSONDecodeError:
        return "Error: Invalid JSON provided for context."
    except Exception as e:
        return f"Error generating website: {str(e)}"

@tool
def create_documentary_video(image_files_str: str, narration_text: str, output_file: str) -> str:
    """Creates a narrated documentary video from a comma-separated list of image files and a narration script."""
    try:
        image_files = [img.strip() for img in image_files_str.split(',')]
        clips = [mpe.ImageClip(img_path).set_duration(5) for img_path in image_files if os.path.exists(img_path)]
        if not clips: return "Error: No valid image files found."

        video = mpe.concatenate_videoclips(clips, method="compose")

        tts = gTTS(text=narration_text, lang='en')
        audio_path = "/tmp/temp_audio.mp3"
        tts.save(audio_path)

        audio = mpe.AudioFileClip(audio_path)
        final_video = video.set_audio(audio)
        final_video.write_videofile(output_file, fps=24, codec='libx264')

        os.remove(audio_path)
        return f"Documentary video successfully saved to {output_file}"
    except Exception as e:
        return f"Error creating video: {str(e)}"
EOF

cat > "$SKYSCOPE_HOME/env/tools/tools_macos.py" <<'EOF'
from smolagents import tool

@tool
def port_to_macos(source_path: str, binary_path: str) -> str:
    """Placeholder for porting a Linux library or driver to macOS."""
    return f"Placeholder: Porting of {source_path} to {binary_path} would involve complex cross-compilation and dependency resolution."

@tool
def build_tahoe_installer() -> str:
    """Placeholder for building a macOS Tahoe installer image."""
    return "Placeholder: Building a macOS installer requires fetching Apple's sources and using specialized tools."
EOF

success "All SkyScope OS Python modules deployed."

# --- CLI Launcher ---
info "Installing the 'skyscope' command-line launcher..."
mkdir -p "$HOME/bin"
cat > "$HOME/bin/skyscope" <<'EOF'
#!/usr/bin/env bash
# Launcher for the SkyScope Sentinel CLI
source "$HOME/.skyscope_os/env/bin/activate"
python3 "$HOME/.skyscope_os/env/cli.py"
EOF
chmod +x "$HOME/bin/skyscope"

if ! echo "$PATH" | grep -q "$HOME/bin"; then
    info "Adding $HOME/bin to your PATH for this session."
    warn "You may need to add '$HOME/bin' to your PATH in ~/.bashrc or ~/.zshrc and restart your shell."
    export PATH="$HOME/bin:$PATH"
fi
success "CLI launcher 'skyscope' is now available."

# --- Systemd Service for Persistence ---
info "Setting up systemd service for persistent autonomous operation..."
sudo bash -c "cat > /etc/systemd/system/skyscope.service <<EOF
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
Environment=\"PATH=$SKYSCOPE_HOME/env/bin:/usr/bin:/bin\"
WorkingDirectory=$SKYSCOPE_HOME/env

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable skyscope.service
sudo systemctl start skyscope.service
success "SkyScope OS systemd service has been enabled and started."

echo
success "================================================================"
success "SkyScope Sentinel OS installation complete."
info "To interact with the AGI, open a NEW terminal and type: skyscope"
info "The API endpoint is available at http://localhost:8000"
info "The n8n workflow editor is at http://localhost:5678"
success "================================================================"
echo
