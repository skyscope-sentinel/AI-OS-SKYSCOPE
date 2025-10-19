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
