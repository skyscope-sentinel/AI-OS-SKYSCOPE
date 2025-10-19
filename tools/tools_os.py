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
        with open(filepath, "r", encoding='utf-8', errors='ignore') as f:
            return f.read()
    except Exception as e:
        return f"Error reading file: {str(e)}"

@tool
def write_file(filepath: str, content: str) -> str:
    """Writes content to the specified file. Creates directories if they don't exist."""
    try:
        # Prevent writing outside of the home directory for safety
        abs_path = os.path.abspath(filepath)
        if not abs_path.startswith(os.path.expanduser("~")):
             return f"Error: For security, writing files is restricted to the user's home directory."

        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, "w") as f:
            f.write(content)
        return f"File '{filepath}' written successfully."
    except Exception as e:
        return f"Error writing file: {str(e)}"

@tool
def system_cmd(cmd: str) -> str:
    """Executes a shell command and returns its output. For security, dangerous commands are blocked."""
    # A basic security check to prevent obvious catastrophic commands.
    # A more robust solution would involve a more sophisticated parser or a sandboxed environment.
    blocked_commands = ['sudo', 'rm -rf /', 'mkfs', '> /dev/sd']
    if any(blocked in cmd for blocked in blocked_commands):
        return "Error: Execution of potentially dangerous commands is restricted."
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=False)
        output = f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
        return output[:4000] # Limit output size
    except Exception as e:
        return f"Error executing command: {str(e)}"

@tool
def build_lkm(path: str) -> str:
    """Compiles a Loadable Kernel Module."""
    return "Placeholder: LKM functionality is highly privileged and requires careful, secure implementation. This tool is disabled by default."

@tool
def load_lkm(path: str) -> str:
    """Loads a Loadable Kernel Module. Requires sudo privileges."""
    return "Placeholder: LKM functionality is highly privileged and requires careful, secure implementation. This tool is disabled by default."

@tool
def unload_lkm(name: str) -> str:
    """Unloads a Loadable Kernel Module. Requires sudo privileges."""
    return "Placeholder: LKM functionality is highly privileged and requires careful, secure implementation. This tool is disabled by default."

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
