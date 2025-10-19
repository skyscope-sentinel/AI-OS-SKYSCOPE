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
        return f"Error executing command in container: {str(e)}"
