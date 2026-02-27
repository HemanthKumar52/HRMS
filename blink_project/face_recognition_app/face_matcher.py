"""Face matching engine with multi-angle support and weighted scoring.

Stores embeddings grouped by (person, angle) for structured matching.
Uses best-of-N per angle, with optional weighted combination.
"""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from config import (
    ANGLE_WEIGHTS, COSINE_THRESHOLD, LOW_CONFIDENCE_THRESHOLD, get_logger,
)
from database import get_all_faces

log = get_logger("matcher")


@dataclass
class MatchResult:
    matched: bool
    name: str | None
    score: float                               # final score used for decision
    confidence: str                            # "high", "low", "none"
    best_angle: str = "any"                    # which angle gave the best hit
    angle_scores: dict[str, float] | None = None  # per-angle best scores
    all_scores: dict[str, float] | None = None    # per-person final scores


class FaceMatcher:
    """Multi-angle cosine similarity matcher with weighted scoring."""

    def __init__(self, threshold: float = COSINE_THRESHOLD,
                 low_threshold: float = LOW_CONFIDENCE_THRESHOLD):
        self.threshold = threshold
        self.low_threshold = low_threshold
        # {name: {angle: np.ndarray(K, 512)}}
        self._data: dict[str, dict[str, np.ndarray]] = {}

    def load_from_db(self):
        """Load all embeddings grouped by (name, angle) into normalized matrices."""
        faces = get_all_faces()  # list of (name, angle, embedding)
        groups: dict[str, dict[str, list[np.ndarray]]] = {}
        for name, angle, emb in faces:
            groups.setdefault(name, {}).setdefault(angle, []).append(emb)

        self._data = {}
        total = 0
        for name, angle_dict in groups.items():
            self._data[name] = {}
            for angle, embs in angle_dict.items():
                mat = np.array(embs, dtype=np.float32)
                norms = np.linalg.norm(mat, axis=1, keepdims=True)
                norms = np.maximum(norms, 1e-10)
                self._data[name][angle] = mat / norms
                total += mat.shape[0]

        log.info("Loaded %d embeddings for %d people (%d angle groups)",
                 total, len(self._data),
                 sum(len(v) for v in self._data.values()))

    @property
    def num_registered(self) -> int:
        return len(self._data)

    @property
    def registered_names(self) -> list[str]:
        return sorted(self._data.keys())

    def match(self, query_embedding: np.ndarray) -> MatchResult:
        """Match query against all registered faces using multi-angle strategy.

        For each person:
        1. Compute max similarity for each angle group
        2. Final person score = max across all angles (accept if ANY exceeds threshold)
        3. If multiple angles match, compute weighted score for ranking
        """
        if not self._data:
            return MatchResult(matched=False, name=None, score=0.0, confidence="none")

        query = query_embedding.astype(np.float32)
        norm = np.linalg.norm(query)
        if norm < 1e-10:
            return MatchResult(matched=False, name=None, score=0.0, confidence="none")
        query = query / norm

        all_person_scores: dict[str, float] = {}
        all_person_details: dict[str, dict[str, float]] = {}

        for name, angle_dict in self._data.items():
            angle_best: dict[str, float] = {}
            for angle, emb_matrix in angle_dict.items():
                sims = emb_matrix @ query
                angle_best[angle] = float(np.max(sims))
            all_person_details[name] = angle_best

            # Primary: accept if ANY angle exceeds threshold
            max_score = max(angle_best.values())

            # Secondary: weighted score for ranking when multiple angles match
            matching_angles = {a: s for a, s in angle_best.items() if s >= self.low_threshold}
            if len(matching_angles) > 1:
                weighted_sum = 0.0
                weight_total = 0.0
                for a, s in matching_angles.items():
                    w = ANGLE_WEIGHTS.get(a, 0.3)
                    weighted_sum += s * w
                    weight_total += w
                weighted_score = weighted_sum / (weight_total + 1e-10)
                # Use max of raw-max and weighted (weighted boosts multi-angle matches)
                final_score = max(max_score, weighted_score)
            else:
                final_score = max_score

            all_person_scores[name] = final_score

        # Find best person
        best_name = max(all_person_scores, key=all_person_scores.get)
        best_score = all_person_scores[best_name]
        best_angle_details = all_person_details[best_name]
        best_angle = max(best_angle_details, key=best_angle_details.get)

        if best_score >= self.threshold:
            confidence = "high"
            matched = True
        elif best_score >= self.low_threshold:
            confidence = "low"
            matched = True
            log.warning("Low-confidence match: '%s' (score=%.3f)", best_name, best_score)
        else:
            confidence = "none"
            matched = False

        return MatchResult(
            matched=matched,
            name=best_name if matched else None,
            score=best_score,
            confidence=confidence,
            best_angle=best_angle,
            angle_scores=best_angle_details if matched else None,
            all_scores=all_person_scores,
        )
