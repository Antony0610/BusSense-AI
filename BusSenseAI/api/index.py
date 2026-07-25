import sys
from pathlib import Path

# Add backend and root directory to python path for Vercel imports
ROOT = Path(__file__).resolve().parents[1]
BACKEND_DIR = ROOT / "backend"

if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app import app, init_db

# Initialize database on cold start if not present
try:
    init_db(seed=True)
except Exception:
    pass

# Vercel serverless entry point
app = app
