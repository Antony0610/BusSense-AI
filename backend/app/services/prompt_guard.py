"""
BusSense AI - Prompt Guard & Anti-Injection Sanitizer (Phase H11)
Protects against prompt-injection attacks, system prompt extraction, credential leaks,
and unauthorized data access.
"""
import re
from typing import Tuple

INJECTION_PATTERNS = [
    r"(ignore|disregard|forget|override)\s+(all\s+)?(previous|above|system|core)\s+(instructions|rules|prompts|constraints)",
    r"system\s+(override|bypass|prompt|admin)",
    r"(reveal|show|dump|leak|expose|print|output)\s+.*(api[_\s]?key|secret|password|credential|token|env\b|environment)",
    r"you\s+are\s+now\s+in\s+(developer|debug|admin)\s+mode",
    r"dan\s+mode|jailbreak",
    r"output\s+the\s+initial\s+prompt",
    r"bypass\s+(security|authorization|rbac|rules|boundaries)",
    r"what\s+is\s+your\s+(system\s+prompt|hidden\s+prompt|instruction)",
]

COMPILED_INJECTION_REGEX = [re.compile(p, re.IGNORECASE) for p in INJECTION_PATTERNS]

def inspect_for_injection(text: str) -> Tuple[bool, str]:
    """
    Scans query or document text for prompt-injection attacks or credential extraction attempts.
    Returns (is_suspicious, reason).
    """
    if not text:
        return False, ""

    for reg in COMPILED_INJECTION_REGEX:
        if reg.search(text):
            return True, "Potential prompt injection or credential leak attempt detected"

    return False, ""

def sanitize_untrusted_input(text: str) -> str:
    """
    Sanitizes untrusted content by stripping dangerous control patterns while preserving legitimate text.
    """
    if not text:
        return ""
    # Strip null bytes and non-printable control chars except standard newlines/tabs
    sanitized = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', text)
    return sanitized.strip()
