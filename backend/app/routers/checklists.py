from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Checklist
from app.schemas import ChecklistCreate, ChecklistResponse, ChecklistUpdate

router = APIRouter()


@router.get("", response_model=list[ChecklistResponse])
def list_checklists(
    checklist_date: date | None = None,
    shift: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(Checklist)
    if checklist_date:
        query = query.filter(Checklist.checklist_date == checklist_date)
    if shift:
        query = query.filter(Checklist.shift == shift)
    return query.order_by(Checklist.bed_number.asc()).all()


@router.post("", response_model=ChecklistResponse)
def create_checklist(payload: ChecklistCreate, db: Session = Depends(get_db)):
    item = Checklist(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.post("/batch", response_model=list[ChecklistResponse])
def create_batch(payload: list[ChecklistCreate], db: Session = Depends(get_db)):
    items = [Checklist(**entry.model_dump()) for entry in payload]
    db.add_all(items)
    db.commit()
    for item in items:
        db.refresh(item)
    return items


@router.patch("/{checklist_id}", response_model=ChecklistResponse)
def update_checklist(checklist_id: int, payload: ChecklistUpdate, db: Session = Depends(get_db)):
    item = db.get(Checklist, checklist_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Checklist not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item


@router.delete("/{checklist_id}")
def delete_checklist(checklist_id: int, db: Session = Depends(get_db)):
    item = db.get(Checklist, checklist_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Checklist not found")
    db.delete(item)
    db.commit()
    return {"deleted": True}
