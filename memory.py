import os
import sqlite3
import datetime
import numpy as np
import zlib
from typing import Callable

class SkyMemory:
    """Manages short-term episodic memory using SQLite and vector embeddings."""
    def __init__(self, db_path: str, embedder_factory: Callable):
        self.db_path = db_path
        self.embedder_factory = embedder_factory
        self._embedder = None
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self._initialize_db()

    @property
    def embedder(self):
        if self._embedder is None:
            self._embedder = self.embedder_factory()
        return self._embedder

    def _initialize_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
            CREATE TABLE IF NOT EXISTS memory (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ts TEXT,
              type TEXT,
              summary TEXT NOT NULL,
              embedding BLOB NOT NULL
            )""")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_mem_type ON memory(type)")

    def store(self, type_: str, text: str):
        embedding = self.embedder.encode([text]).astype(np.float32).tobytes()
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT INTO memory (ts, type, summary, embedding) VALUES (?, ?, ?, ?)",
                (datetime.datetime.now().isoformat(), type_, text[:800], embedding)
            )

    def search(self, query: str, topk: int = 5) -> str:
        """Performs a semantic search for a given query and returns the most relevant memories."""
        query_vector = self.embedder.encode([query]).astype(np.float32)[0]
        with sqlite3.connect(self.db_path) as conn:
            rows = conn.execute("SELECT summary, embedding FROM memory").fetchall()

        if not rows: return "No memories found."

        scored_results = []
        for summary, embedding_blob in rows:
            embedding = np.frombuffer(embedding_blob, dtype=np.float32)
            # Handle potential zero vectors
            norm_embedding = np.linalg.norm(embedding)
            norm_query = np.linalg.norm(query_vector)
            if norm_embedding == 0 or norm_query == 0:
                score = 0.0
            else:
                score = np.dot(embedding, query_vector) / (norm_embedding * norm_query)
            scored_results.append((score, summary))

        scored_results.sort(key=lambda x: x[0], reverse=True)
        top_results = scored_results[:topk]

        if not top_results: return "No relevant memories found."
        return "Relevant Memories:\n" + "\n".join([f"- {summary} (Score: {score:.3f})" for score, summary in top_results])

class KnowledgeStack:
    """Manages a long-term, compressed, and indexed knowledge base."""
    def __init__(self, db_path: str, embedder_factory: Callable):
        self.db_path = db_path
        self.embedder_factory = embedder_factory
        self._embedder = None
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self._initialize_db()

    @property
    def embedder(self):
        if self._embedder is None:
            self._embedder = self.embedder_factory()
        return self._embedder

    def _initialize_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
            CREATE TABLE IF NOT EXISTS knowledge (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              source_uri TEXT UNIQUE,
              title TEXT,
              compressed_content BLOB,
              embedding BLOB
            )""")

    def add(self, source_uri: str, title: str, content: str) -> str:
        """Adds a document to the knowledge stack."""
        try:
            compressed_content = zlib.compress(content.encode('utf-8'))
            searchable_text = f"{title}\n\n{content[:500]}"
            embedding = self.embedder.encode([searchable_text]).astype(np.float32).tobytes()

            with sqlite3.connect(self.db_path) as conn:
                conn.execute(
                    "INSERT OR REPLACE INTO knowledge (source_uri, title, compressed_content, embedding) VALUES (?, ?, ?, ?)",
                    (source_uri, title, compressed_content, embedding)
                )
            return f"Knowledge '{title}' added to the stack."
        except Exception as e:
            return f"Error adding knowledge: {e}"


    def retrieve(self, source_uri: str) -> str:
        """Retrieves and decompresses a document by its source URI."""
        with sqlite3.connect(self.db_path) as conn:
            row = conn.execute("SELECT compressed_content FROM knowledge WHERE source_uri = ?", (source_uri,)).fetchone()

        if row:
            return zlib.decompress(row[0]).decode('utf-8')
        return "Error: No document found with that URI."

    def search(self, query: str, topk: int = 3) -> str:
        """Searches the knowledge stack for relevant documents."""
        query_vector = self.embedder.encode([query]).astype(np.float32)[0]
        with sqlite3.connect(self.db_path) as conn:
            rows = conn.execute("SELECT source_uri, title, embedding FROM knowledge").fetchall()

        if not rows: return "No knowledge found."

        scored_results = []
        for uri, title, embedding_blob in rows:
            embedding = np.frombuffer(embedding_blob, dtype=np.float32)
            norm_embedding = np.linalg.norm(embedding)
            norm_query = np.linalg.norm(query_vector)
            if norm_embedding == 0 or norm_query == 0:
                score = 0.0
            else:
                score = np.dot(embedding, query_vector) / (norm_embedding * norm_query)
            scored_results.append((score, title, uri))

        scored_results.sort(key=lambda x: x[0], reverse=True)
        top_results = scored_results[:topk]

        if not top_results: return "No relevant knowledge found."
        return "Relevant Knowledge:\n" + "\n".join([f"- {title} (URI: {uri}, Score: {score:.3f})" for score, title, uri in top_results])
