import json
import time
from pathlib import Path
from typing import Optional, Dict, Any

class SessionStore:
    def __init__(self, storage_dir: str = "./storage/sessions"):
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)

    def _get_path(self, session_id: str) -> Path:
        return self.storage_dir / f"{session_id}.json"

    def save_session(self, session_id: str, data: Dict[str, Any]):
        """Persist session metadata (e.g. current project path, simulation status)"""
        path = self._get_path(session_id)
        payload = {
            "last_access": time.time(),
            "data": data
        }
        with open(path, 'w') as f:
            json.dump(payload, f)

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        path = self._get_path(session_id)
        if not path.exists():
            return None
        
        try:
            with open(path, 'r') as f:
                payload = json.load(f)
            return payload["data"]
        except Exception:
            return None

    def delete_session(self, session_id: str):
        path = self._get_path(session_id)
        if path.exists():
            path.unlink()

session_store = SessionStore()
