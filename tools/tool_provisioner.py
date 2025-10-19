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

        # Sanitize repo_name to be a valid Python identifier
        safe_repo_name = ''.join(c for c in repo_name if c.isalnum() or c == '_')

        wrapper_code = f'''from smolagents import tool
import subprocess
import os

@tool
def run_{safe_repo_name}(args: str) -> str:
    """Runs the {repo_name} MCP tool with the given arguments."""
    try:
        # It's better to run this within the agent's venv
        python_executable = os.path.expanduser("~/.skyscope_os/env/bin/python3")
        cmd = f"{{python_executable}} {os.path.join(clone_path, entry_point)}} {{args}}"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return result.stdout
    except Exception as e:
        return f"Error running {repo_name}: {{str(e)}}"
'''
        tool_filename = f"tool_{safe_repo_name}.py"
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
