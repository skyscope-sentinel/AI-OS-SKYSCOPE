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
