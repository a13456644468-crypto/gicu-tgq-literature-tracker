"""Dependency-free development API for local mini program testing.

This server mirrors the subset of the FastAPI API used by the mini program.
It uses only Python standard library modules so it can run on a fresh Windows
machine without Docker, PostgreSQL, or compiled Python wheels.
"""
from __future__ import annotations

import json
import sqlite3
from datetime import date, datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "dev.db"


JOURNALS = [
    ("critical_care", "Critical Care Medicine", "0090-3493", '"Critical Care Medicine"[Journal]'),
    ("critical_care", "Intensive Care Medicine", "0342-4642", '"Intensive Care Medicine"[Journal]'),
    ("critical_care", "Critical Care", "1364-8535", '"Critical Care"[Journal]'),
    ("critical_care", "Journal of Critical Care", "0883-9441", '"Journal of Critical Care"[Journal]'),
    ("critical_care", "Annals of Intensive Care", "2110-5820", '"Annals of Intensive Care"[Journal]'),
    ("lung_transplant", "Journal of Heart and Lung Transplantation", "1053-2498", '"Journal of Heart and Lung Transplantation"[Journal]'),
    ("lung_transplant", "Transplantation", "0041-1337", '"Transplantation"[Journal]'),
    ("lung_transplant", "American Journal of Transplantation", "1600-6135", '"American Journal of Transplantation"[Journal]'),
    ("lung_transplant", "Lung Cancer", "0169-5002", '"Lung Cancer"[Journal]'),
    ("lung_transplant", "Respiratory Care", "0020-1324", '"Respiratory Care"[Journal]'),
]

SAMPLE_PAPERS = [
    (1, "41000001", "Sepsis resuscitation bundles in modern intensive care practice", "Zhang Y, Li H, Wang J", "A practical review of sepsis bundle implementation in intensive care units.", "10.1000/gicu.1", "2026-05-01"),
    (2, "41000002", "Ventilator-associated pneumonia prevention after lung transplantation", "Chen Q, Xu M", "A focused summary of infection prevention strategies after lung transplantation.", "10.1000/gicu.2", "2026-04-22"),
    (6, "41000003", "Early graft dysfunction monitoring in lung transplant recipients", "Liu S, Huang X", "This paper describes bedside indicators for early graft dysfunction surveillance.", "10.1000/gicu.3", "2026-04-12"),
]


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with connect() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS journals (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT NOT NULL,
                name TEXT NOT NULL,
                issn TEXT,
                pubmed_search_term TEXT,
                is_builtin INTEGER DEFAULT 1,
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS papers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                journal_id INTEGER,
                pmid TEXT UNIQUE NOT NULL,
                title TEXT NOT NULL,
                authors TEXT,
                abstract TEXT,
                doi TEXT,
                pub_date TEXT,
                pubmed_url TEXT,
                is_new INTEGER DEFAULT 1,
                is_read INTEGER DEFAULT 0,
                fetched_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS checklists (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                checklist_date TEXT NOT NULL,
                shift TEXT DEFAULT 'day',
                bed_number TEXT NOT NULL,
                patient_name TEXT NOT NULL,
                diagnosis TEXT NOT NULL,
                pathogen TEXT,
                antibiotics TEXT,
                anticoagulation TEXT,
                nutrition TEXT,
                planned_io TEXT,
                actual_io TEXT,
                notes TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
            """
        )
        if conn.execute("SELECT COUNT(*) FROM journals").fetchone()[0] == 0:
            conn.executemany(
                "INSERT INTO journals (category, name, issn, pubmed_search_term) VALUES (?, ?, ?, ?)",
                JOURNALS,
            )
        if conn.execute("SELECT COUNT(*) FROM papers").fetchone()[0] == 0:
            conn.executemany(
                """
                INSERT INTO papers (journal_id, pmid, title, authors, abstract, doi, pub_date, pubmed_url)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'https://pubmed.ncbi.nlm.nih.gov/' || ? || '/')
                """,
                [paper + (paper[1],) for paper in SAMPLE_PAPERS],
            )


def row_to_dict(row: sqlite3.Row) -> dict:
    value = dict(row)
    for key in ["is_builtin", "is_active", "is_new", "is_read"]:
        if key in value:
            value[key] = bool(value[key])
    return value


class Handler(BaseHTTPRequestHandler):
    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PATCH,DELETE,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Accept")
        super().end_headers()

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.end_headers()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        if parsed.path == "/health":
            self.json({"status": "ok", "server": "dev"})
        elif parsed.path == "/journals":
            self.list_journals(query)
        elif parsed.path == "/papers":
            self.list_papers(query)
        elif parsed.path.startswith("/papers/"):
            self.get_paper(parsed.path)
        elif parsed.path == "/checklists":
            self.list_checklists(query)
        else:
            self.error(404, "Not found")

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/checklists/batch":
            self.create_checklist_batch()
        elif parsed.path.startswith("/papers/") and parsed.path.endswith("/read"):
            self.mark_paper_read(parsed.path)
        else:
            self.error(404, "Not found")

    def list_journals(self, query: dict[str, list[str]]) -> None:
        sql = "SELECT * FROM journals WHERE is_active = 1"
        params: list[str] = []
        if "category" in query:
            sql += " AND category = ?"
            params.append(query["category"][0])
        sql += " ORDER BY category, name"
        with connect() as conn:
            rows = conn.execute(sql, params).fetchall()
        self.json([row_to_dict(row) for row in rows])

    def list_papers(self, query: dict[str, list[str]]) -> None:
        sql = "SELECT * FROM papers WHERE 1 = 1"
        params: list[object] = []
        if "journal_id" in query:
            sql += " AND journal_id = ?"
            params.append(int(query["journal_id"][0]))
        if query.get("only_new", ["false"])[0].lower() == "true":
            sql += " AND is_new = 1"
        with connect() as conn:
            total = conn.execute(f"SELECT COUNT(*) FROM ({sql})", params).fetchone()[0]
            rows = conn.execute(sql + " ORDER BY pub_date DESC, fetched_at DESC LIMIT ? OFFSET ?", params + [int(query.get("limit", ["20"])[0]), int(query.get("offset", ["0"])[0])]).fetchall()
        self.json({"total": total, "items": [row_to_dict(row) for row in rows]})

    def get_paper(self, path: str) -> None:
        paper_id = int(path.strip("/").split("/")[1])
        with connect() as conn:
            row = conn.execute("SELECT * FROM papers WHERE id = ?", (paper_id,)).fetchone()
        if row is None:
            self.error(404, "Paper not found")
        else:
            self.json(row_to_dict(row))

    def mark_paper_read(self, path: str) -> None:
        paper_id = int(path.strip("/").split("/")[1])
        with connect() as conn:
            conn.execute("UPDATE papers SET is_new = 0, is_read = 1 WHERE id = ?", (paper_id,))
            row = conn.execute("SELECT * FROM papers WHERE id = ?", (paper_id,)).fetchone()
        if row is None:
            self.error(404, "Paper not found")
        else:
            self.json(row_to_dict(row))

    def list_checklists(self, query: dict[str, list[str]]) -> None:
        sql = "SELECT * FROM checklists WHERE 1 = 1"
        params: list[str] = []
        if "checklist_date" in query:
            sql += " AND checklist_date = ?"
            params.append(query["checklist_date"][0])
        if "shift" in query:
            sql += " AND shift = ?"
            params.append(query["shift"][0])
        with connect() as conn:
            rows = conn.execute(sql + " ORDER BY bed_number", params).fetchall()
        self.json([row_to_dict(row) for row in rows])

    def create_checklist_batch(self) -> None:
        payload = self.read_json()
        now = datetime.now().isoformat(timespec="seconds")
        with connect() as conn:
            inserted = []
            for item in payload:
                cursor = conn.execute(
                    """
                    INSERT INTO checklists (
                        checklist_date, shift, bed_number, patient_name, diagnosis, pathogen,
                        antibiotics, anticoagulation, nutrition, planned_io, actual_io, notes,
                        created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        item["checklist_date"],
                        item.get("shift", "day"),
                        item["bed_number"],
                        item["patient_name"],
                        item["diagnosis"],
                        item.get("pathogen"),
                        item.get("antibiotics"),
                        item.get("anticoagulation"),
                        item.get("nutrition"),
                        item.get("planned_io"),
                        item.get("actual_io"),
                        item.get("notes"),
                        now,
                        now,
                    ),
                )
                inserted.append(cursor.lastrowid)
            rows = conn.execute(
                f"SELECT * FROM checklists WHERE id IN ({','.join('?' for _ in inserted)}) ORDER BY bed_number",
                inserted,
            ).fetchall()
        self.json([row_to_dict(row) for row in rows])

    def read_json(self) -> object:
        length = int(self.headers.get("Content-Length", "0"))
        return json.loads(self.rfile.read(length).decode("utf-8") or "null")

    def json(self, payload: object) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def error(self, status: int, message: str) -> None:
        body = json.dumps({"detail": message}, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:
        print(f"[{datetime.now().isoformat(timespec='seconds')}] {self.address_string()} {format % args}")


def main() -> None:
    init_db()
    server = ThreadingHTTPServer(("0.0.0.0", 8000), Handler)
    print(f"GICU-TGQ dev API running at http://0.0.0.0:8000 ({date.today().isoformat()})")
    server.serve_forever()


if __name__ == "__main__":
    main()
