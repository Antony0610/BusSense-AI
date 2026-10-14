"""
BusSense AI - Knowledge Document Parser, Chunking & Semantic Vector Retrieval Engine (Phase H11)
Features:
  - Document parsing with structured metadata retention
  - Deterministic section-level chunking
  - Deduplicated index management
  - TF-IDF vector indexing with n-gram tokenization and cosine similarity ranking
  - Explicit provenance: TFIDF_VECTOR_FALLBACK / DETERMINISTIC_VECTOR_RETRIEVAL
  - Evidence threshold filtering to prevent hallucinations
"""
import re
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from pydantic import BaseModel, Field
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

KNOWLEDGE_DIR = Path(__file__).resolve().parent.parent.parent / "knowledge"

class KnowledgeChunk(BaseModel):
    chunk_id: str
    document_id: str
    document_title: str
    section: str
    content: str
    source_type: str = "KNOWLEDGE"
    version: str = "1.1.0"
    updated_at: str = "October 2026"
    applicable_route: Optional[str] = None
    access_scope: str = "PUBLIC"
    keywords: List[str] = Field(default_factory=list)

class KnowledgeIndexer:
    """
    Parses, chunks, and semantically indexes verified transport markdown documents.
    """
    def __init__(self, knowledge_dir: Optional[Path] = None):
        self.knowledge_dir = knowledge_dir or KNOWLEDGE_DIR
        self.chunks: List[KnowledgeChunk] = []
        self.vectorizer: Optional[TfidfVectorizer] = None
        self.tfidf_matrix: Optional[np.ndarray] = None
        self._index_version = 1
        self.build_index()

    def parse_markdown_document(self, file_path: Path) -> List[KnowledgeChunk]:
        """
        Parses a single markdown knowledge document into structured, metadata-rich chunks.
        """
        text = file_path.read_text(encoding="utf-8")
        lines = text.splitlines()

        doc_title = file_path.stem.replace("_", " ").title()
        doc_id = f"KB-{file_path.stem.upper()}"
        version = "1.1.0"
        updated_at = "October 2026"

        # Extract front-matter metadata
        for line in lines[:10]:
            if line.startswith("# "):
                doc_title = line.replace("# ", "").strip()
            elif line.startswith("Document ID:"):
                doc_id = line.split(":", 1)[1].strip()
            elif line.startswith("Version:"):
                version = line.split(":", 1)[1].strip()
            elif line.startswith("Last Verified:"):
                updated_at = line.split(":", 1)[1].strip()

        # Split into sections using '## '
        sections = re.split(r'\n(?=##\s+)', text)
        chunks: List[KnowledgeChunk] = []

        for idx, sec_text in enumerate(sections):
            sec_text = sec_text.strip()
            if not sec_text or sec_text.startswith("# BusSense"):
                continue

            first_line = sec_text.splitlines()[0]
            section_title = first_line.replace("##", "").strip() if first_line.startswith("##") else "General Overview"

            # Deterministic slug
            sec_slug = re.sub(r'[^a-z0-9]+', '-', section_title.lower()).strip('-')
            chunk_id = f"{doc_id}-{sec_slug}"

            # Detect applicable route if present
            route_num = None
            if "route 205" in sec_text.lower() or "bus 205" in sec_text.lower():
                route_num = "205"
            elif "route 14a" in sec_text.lower() or "bus 14a" in sec_text.lower():
                route_num = "14A"
            elif "route 12" in sec_text.lower() or "bus 12" in sec_text.lower():
                route_num = "12"

            # Extract keywords (tokens > 3 chars)
            tokens = re.findall(r'[a-zA-Z0-9]+', sec_text.lower())
            keywords = list(dict.fromkeys([t for t in tokens if len(t) >= 4]))[:15]

            chunk = KnowledgeChunk(
                chunk_id=chunk_id,
                document_id=doc_id,
                document_title=doc_title,
                section=section_title,
                content=sec_text,
                source_type="KNOWLEDGE",
                version=version,
                updated_at=updated_at,
                applicable_route=route_num,
                access_scope="PUBLIC",
                keywords=keywords
            )
            chunks.append(chunk)

        return chunks

    def build_index(self) -> int:
        """
        Builds or refreshes the index from knowledge markdown documents.
        Clears previous index state to guarantee idempotent indexing without duplication.
        """
        self.chunks.clear()

        if self.knowledge_dir.exists():
            for md_file in sorted(self.knowledge_dir.glob("*.md")):
                doc_chunks = self.parse_markdown_document(md_file)
                self.chunks.extend(doc_chunks)

        if not self.chunks:
            self.vectorizer = None
            self.tfidf_matrix = None
            return 0

        corpus = [f"{c.document_title} {c.document_title} {c.section} {c.section} {c.content} {' '.join(c.keywords)}" for c in self.chunks]

        self.vectorizer = TfidfVectorizer(
            ngram_range=(1, 2),
            stop_words="english",
            sublinear_tf=True
        )
        self.tfidf_matrix = self.vectorizer.fit_transform(corpus)
        self._index_version += 1
        return len(self.chunks)

    def search(
        self,
        query: str,
        top_k: int = 3,
        threshold: float = 0.08
    ) -> List[Tuple[KnowledgeChunk, float]]:
        """
        Ranks indexed chunks against user query using TF-IDF cosine similarity + keyword boost.
        Returns empty list if top score fails to meet the evidence threshold.
        """
        if not self.chunks or self.vectorizer is None or self.tfidf_matrix is None:
            return []

        q_clean = query.strip()
        if not q_clean:
            return []

        query_vec = self.vectorizer.transform([q_clean])
        sim_scores = cosine_similarity(query_vec, self.tfidf_matrix)[0]

        # Hybrid lexical boost for key transport identifiers
        q_lower = q_clean.lower()
        q_tokens = set(re.findall(r'[a-zA-Z0-9]+', q_lower))
        scored_results: List[Tuple[KnowledgeChunk, float]] = []

        for idx, chunk in enumerate(self.chunks):
            base_score = float(sim_scores[idx])
            boost = 0.0

            # Route match boost
            if chunk.applicable_route and chunk.applicable_route.lower() in q_lower:
                boost += 0.20

            # Section title token overlap boost
            sec_tokens = [st for st in re.findall(r'[a-zA-Z0-9]+', chunk.section.lower()) if len(st) >= 3 and st not in ["and", "the", "for", "with"]]
            sec_matches = sum(1 for st in sec_tokens if st in q_tokens)
            if sec_matches > 0:
                boost += min(0.35, sec_matches * 0.10)

            # Keyword overlap boost
            matches = sum(1 for kw in chunk.keywords if kw in q_tokens)
            if matches > 0:
                boost += min(0.25, matches * 0.05)

            # Direct phrase match boost
            clean_q_stripped = re.sub(r'[^a-z0-9\s]+', '', q_lower).strip()
            if len(clean_q_stripped) > 5 and clean_q_stripped in chunk.content.lower():
                boost += 0.20

            final_score = base_score + boost
            if final_score >= threshold:
                scored_results.append((chunk, round(final_score, 4)))

        # Sort descending by score
        scored_results.sort(key=lambda x: x[1], reverse=True)
        return scored_results[:top_k]

    def get_diagnostics(self) -> Dict[str, Any]:
        """Returns index operational metadata for audit & transparency."""
        vocab_size = len(self.vectorizer.vocabulary_) if self.vectorizer else 0
        return {
            "index_status": "IMPLEMENTED / TFIDF_VECTOR_FALLBACK",
            "indexed_documents": len(set(c.document_id for c in self.chunks)),
            "total_chunks": len(self.chunks),
            "vocabulary_size": vocab_size,
            "index_version": self._index_version,
            "vector_model": "TfidfVectorizer(ngram_range=(1,2), sublinear_tf=True)",
            "knowledge_path": str(self.knowledge_dir)
        }

knowledge_indexer = KnowledgeIndexer()
