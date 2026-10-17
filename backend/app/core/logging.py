"""
BusSense AI - Centralized Structured Logging Configuration
"""
import logging
import sys
from app.core.config import settings

def setup_logging():
    """Initializes standard Python logging with structured formatting."""
    log_level = logging.DEBUG if settings.DEBUG else logging.INFO
    formatter = logging.Formatter(
        fmt="%(asctime)s [%(levelname)s] [%(name)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)

    # Avoid adding duplicate handlers if setup is called multiple times
    if not root_logger.handlers:
        root_logger.addHandler(handler)
    else:
        root_logger.handlers = [handler]

def get_logger(name: str) -> logging.Logger:
    """Returns a named logger configured for BusSense AI services."""
    return logging.getLogger(name)
