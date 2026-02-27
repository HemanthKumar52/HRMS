"""SQLite database for face embeddings.

Supports multiple embeddings per person with per-angle storage
(center, left, right) for multi-angle matching.
Automatically migrates from older schemas.
"""

from __future__ import annotations

import sqlite3

import numpy as np

from config import DB_PATH, ensure_dirs, get_logger

log = get_logger("database")


def _connect() -> sqlite3.Connection:
    ensure_dirs()
    return sqlite3.connect(DB_PATH)


# ---------------------------------------------------------------------------
# Schema & migration
# ---------------------------------------------------------------------------

def init_db():
    """Create tables and run any pending migrations."""
    conn = _connect()
    _migrate_if_needed(conn)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS faces (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            angle TEXT NOT NULL DEFAULT 'any',
            embedding BLOB NOT NULL,
            quality_score REAL DEFAULT 0.0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_faces_name ON faces(name)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_faces_angle ON faces(name, angle)")
    conn.commit()
    conn.close()
    log.debug("Database initialized at %s", DB_PATH)


def _migrate_if_needed(conn: sqlite3.Connection):
    """Migrate from older schemas to current (multi-angle)."""
    try:
        row = conn.execute(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name='faces'"
        ).fetchone()
        if row is None:
            return

        schema_sql = row[0]
        cols = [r[1] for r in conn.execute("PRAGMA table_info(faces)").fetchall()]

        # v1 → v2: remove UNIQUE constraint on name
        if "UNIQUE" in schema_sql.upper():
            log.info("Migrating v1 → v2: single-embedding to multi-embedding...")
            conn.execute("ALTER TABLE faces RENAME TO faces_old")
            conn.execute("""
                CREATE TABLE faces (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    angle TEXT NOT NULL DEFAULT 'any',
                    embedding BLOB NOT NULL,
                    quality_score REAL DEFAULT 0.0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.execute("""
                INSERT INTO faces (name, angle, embedding, created_at)
                SELECT name, 'any', embedding, created_at FROM faces_old
            """)
            conn.execute("DROP TABLE faces_old")
            conn.commit()
            log.info("Migration v1 → v2 complete.")
            return  # fresh table, no further checks needed

        # v2 → v3: add angle column
        if "angle" not in cols:
            log.info("Migrating v2 → v3: adding angle column...")
            conn.execute("ALTER TABLE faces ADD COLUMN angle TEXT NOT NULL DEFAULT 'any'")
            conn.commit()
            log.info("Migration v2 → v3 complete.")

        # Ensure quality_score exists
        if "quality_score" not in cols:
            conn.execute("ALTER TABLE faces ADD COLUMN quality_score REAL DEFAULT 0.0")
            conn.commit()
    except Exception as e:
        log.warning("Migration check: %s", e)


# ---------------------------------------------------------------------------
# Write operations
# ---------------------------------------------------------------------------

def add_embedding(name: str, embedding: np.ndarray,
                  angle: str = "any", quality_score: float = 0.0):
    """Add one embedding for a person + angle."""
    blob = sqlite3.Binary(embedding.astype(np.float32).tobytes())
    conn = _connect()
    conn.execute(
        "INSERT INTO faces (name, angle, embedding, quality_score) VALUES (?, ?, ?, ?)",
        (name, angle, blob, quality_score),
    )
    conn.commit()
    conn.close()
    log.debug("Added embedding for '%s' angle='%s' quality=%.1f", name, angle, quality_score)


def add_face(name: str, embedding: np.ndarray, quality_score: float = 0.0):
    """Backward-compatible alias (angle='any')."""
    add_embedding(name, embedding, "any", quality_score)


def replace_all_embeddings(name: str, embeddings: list[np.ndarray],
                           quality_scores: list[float] | None = None,
                           angles: list[str] | None = None):
    """Delete all existing embeddings for a name and insert new ones."""
    n = len(embeddings)
    if quality_scores is None:
        quality_scores = [0.0] * n
    if angles is None:
        angles = ["any"] * n
    conn = _connect()
    conn.execute("DELETE FROM faces WHERE name = ?", (name,))
    for emb, qs, ang in zip(embeddings, quality_scores, angles):
        blob = sqlite3.Binary(emb.astype(np.float32).tobytes())
        conn.execute(
            "INSERT INTO faces (name, angle, embedding, quality_score) VALUES (?, ?, ?, ?)",
            (name, ang, blob, qs),
        )
    conn.commit()
    conn.close()
    log.info("Replaced embeddings for '%s': %d stored", name, n)


def replace_angle_embeddings(name: str, angle: str, embeddings: list[np.ndarray],
                             quality_scores: list[float] | None = None):
    """Replace embeddings for a specific angle only."""
    if quality_scores is None:
        quality_scores = [0.0] * len(embeddings)
    conn = _connect()
    conn.execute("DELETE FROM faces WHERE name = ? AND angle = ?", (name, angle))
    for emb, qs in zip(embeddings, quality_scores):
        blob = sqlite3.Binary(emb.astype(np.float32).tobytes())
        conn.execute(
            "INSERT INTO faces (name, angle, embedding, quality_score) VALUES (?, ?, ?, ?)",
            (name, angle, blob, qs),
        )
    conn.commit()
    conn.close()
    log.info("Replaced '%s' angle='%s': %d embeddings", name, angle, len(embeddings))


# ---------------------------------------------------------------------------
# Read operations
# ---------------------------------------------------------------------------

def get_all_faces() -> list[tuple[str, str, np.ndarray]]:
    """Return list of (name, angle, embedding) for all stored embeddings."""
    conn = _connect()
    rows = conn.execute("SELECT name, angle, embedding FROM faces").fetchall()
    conn.close()
    return [(name, angle, np.frombuffer(blob, dtype=np.float32).copy())
            for name, angle, blob in rows]


def get_embeddings_for_name(name: str) -> list[tuple[str, np.ndarray]]:
    """Return [(angle, embedding), ...] for a specific person."""
    conn = _connect()
    rows = conn.execute(
        "SELECT angle, embedding FROM faces WHERE name = ?", (name,)
    ).fetchall()
    conn.close()
    return [(angle, np.frombuffer(blob, dtype=np.float32).copy())
            for angle, blob in rows]


def get_face_by_name(name: str) -> np.ndarray | None:
    """Return first embedding for a name (backward compat)."""
    conn = _connect()
    row = conn.execute("SELECT embedding FROM faces WHERE name = ?", (name,)).fetchone()
    conn.close()
    if row is None:
        return None
    return np.frombuffer(row[0], dtype=np.float32).copy()


def count_embeddings(name: str) -> int:
    conn = _connect()
    row = conn.execute("SELECT COUNT(*) FROM faces WHERE name = ?", (name,)).fetchone()
    conn.close()
    return row[0]


def delete_face(name: str) -> bool:
    conn = _connect()
    cursor = conn.execute("DELETE FROM faces WHERE name = ?", (name,))
    conn.commit()
    deleted = cursor.rowcount > 0
    conn.close()
    if deleted:
        log.info("Deleted all embeddings for '%s'", name)
    return deleted


def list_names() -> list[str]:
    conn = _connect()
    rows = conn.execute("SELECT DISTINCT name FROM faces ORDER BY name").fetchall()
    conn.close()
    return [r[0] for r in rows]


def get_name_counts() -> dict[str, int]:
    conn = _connect()
    rows = conn.execute(
        "SELECT name, COUNT(*) FROM faces GROUP BY name ORDER BY name"
    ).fetchall()
    conn.close()
    return {name: count for name, count in rows}


def get_angle_counts(name: str) -> dict[str, int]:
    """Return {angle: count} for a specific person."""
    conn = _connect()
    rows = conn.execute(
        "SELECT angle, COUNT(*) FROM faces WHERE name = ? GROUP BY angle", (name,)
    ).fetchall()
    conn.close()
    return {angle: count for angle, count in rows}


def total_embeddings() -> int:
    conn = _connect()
    row = conn.execute("SELECT COUNT(*) FROM faces").fetchone()
    conn.close()
    return row[0]
