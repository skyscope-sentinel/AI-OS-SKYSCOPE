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
