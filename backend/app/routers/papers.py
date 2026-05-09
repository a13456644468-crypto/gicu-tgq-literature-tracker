from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Paper
from app.schemas import PaperListResponse, PaperResponse

router = APIRouter()


@router.get("", response_model=PaperListResponse)
def list_papers(
    journal_id: int | None = None,
    only_new: bool = False,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    query = db.query(Paper)
    if journal_id:
        query = query.filter(Paper.journal_id == journal_id)
    if only_new:
        query = query.filter(Paper.is_new.is_(True))

    total = query.count()
    items = (
        query.order_by(Paper.pub_date.desc().nullslast(), Paper.fetched_at.desc())
        .offset(offset)
        .limit(min(limit, 100))
        .all()
    )
    return {"total": total, "items": items}


@router.get("/{paper_id}", response_model=PaperResponse)
def get_paper(paper_id: int, db: Session = Depends(get_db)):
    paper = db.get(Paper, paper_id)
    if paper is None:
        raise HTTPException(status_code=404, detail="Paper not found")
    return paper


@router.post("/{paper_id}/read", response_model=PaperResponse)
def mark_read(paper_id: int, db: Session = Depends(get_db)):
    paper = db.get(Paper, paper_id)
    if paper is None:
        raise HTTPException(status_code=404, detail="Paper not found")
    paper.is_read = True
    paper.is_new = False
    db.commit()
    db.refresh(paper)
    return paper
