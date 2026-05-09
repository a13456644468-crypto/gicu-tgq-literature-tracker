"""Fetch recent PubMed papers for active journals."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(ROOT))

from app.database import SessionLocal
from app.models import Journal, Paper
from app.services.pubmed_fetcher import PubMedFetcher


def main() -> None:
    fetcher = PubMedFetcher()
    db = SessionLocal()
    try:
        journals = db.query(Journal).filter(Journal.is_active.is_(True)).all()
        for journal in journals:
            if not journal.pubmed_search_term:
                continue
            pmids = fetcher.search_pmids(journal.pubmed_search_term)
            existing = {
                row[0]
                for row in db.query(Paper.pmid).filter(Paper.pmid.in_(pmids)).all()
            }
            new_pmids = [pmid for pmid in pmids if pmid not in existing]
            for details in fetcher.fetch_details(new_pmids):
                db.add(Paper(journal_id=journal.id, **details))
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    main()
