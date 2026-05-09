from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Journal
from app.schemas import JournalCreate, JournalResponse

router = APIRouter()


@router.get("", response_model=list[JournalResponse])
def list_journals(category: str | None = None, db: Session = Depends(get_db)):
    query = db.query(Journal).filter(Journal.is_active.is_(True))
    if category:
        query = query.filter(Journal.category == category)
    return query.order_by(Journal.category.asc(), Journal.name.asc()).all()


@router.post("", response_model=JournalResponse)
def create_journal(payload: JournalCreate, db: Session = Depends(get_db)):
    journal = Journal(**payload.model_dump(), is_builtin=False)
    db.add(journal)
    db.commit()
    db.refresh(journal)
    return journal


@router.patch("/{journal_id}/active", response_model=JournalResponse)
def set_active(journal_id: int, is_active: bool, db: Session = Depends(get_db)):
    journal = db.get(Journal, journal_id)
    if journal is None:
        raise HTTPException(status_code=404, detail="Journal not found")
    journal.is_active = is_active
    db.commit()
    db.refresh(journal)
    return journal
