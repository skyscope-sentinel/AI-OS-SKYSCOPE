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
