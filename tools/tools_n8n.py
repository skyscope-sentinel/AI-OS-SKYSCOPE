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
            "connections": workflow_data['connections'],
            "settings": {},
            "staticData": None
        }

        wf_str = json.dumps(workflow)
        # Using curl via subprocess to interact with the locally running n8n instance
        # Note: The API endpoint and authentication might change in future n8n versions.
        # This assumes a local, unsecured n8n instance.
        result = subprocess.run(
            ["curl", "-s", "-X", "POST", "http://localhost:5678/api/v1/workflows",
             "-H", "Content-Type: application/json",
             # In a real production environment, an API key would be required:
             # "-H", "X-N8N-API-KEY: your_api_key_here",
             "-d", wf_str],
            capture_output=True, text=True
        )

        if result.returncode != 0:
            return f"Error creating workflow via curl: {result.stderr}"

        # n8n's success response for creation is often just a confirmation message or the created object
        try:
            response_json = json.loads(result.stdout)
            if 'id' in response_json or 'message' in response_json:
                return f"Workflow '{name}' created successfully. Response from n8n: {result.stdout}"
            else:
                 return f"Failed to create workflow. Response from n8n: {result.stdout}"
        except json.JSONDecodeError:
            return f"Workflow may have been created, but the response was not valid JSON: {result.stdout}"

    except json.JSONDecodeError:
        return "Error: Invalid JSON provided for nodes_json."
    except Exception as e:
        return f"An unexpected error occurred: {str(e)}"
