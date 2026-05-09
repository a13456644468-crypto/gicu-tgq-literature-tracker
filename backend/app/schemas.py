"""API request and response models."""
from datetime import date, datetime

from pydantic import BaseModel, Field


class JournalBase(BaseModel):
    category: str
    name: str
    issn: str | None = None
    pubmed_search_term: str | None = None
    is_active: bool = True


class JournalCreate(JournalBase):
    pass


class JournalResponse(JournalBase):
    id: int
    is_builtin: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class PaperBase(BaseModel):
    pmid: str
    title: str
    authors: str | None = None
    abstract: str | None = None
    doi: str | None = None
    pub_date: date | None = None
    pubmed_url: str | None = None


class PaperResponse(PaperBase):
    id: int
    journal_id: int | None
    is_new: bool
    is_read: bool
    fetched_at: datetime

    model_config = {"from_attributes": True}


class PaperListResponse(BaseModel):
    total: int
    items: list[PaperResponse]


class ChecklistBase(BaseModel):
    checklist_date: date
    shift: str = Field(default="day", pattern="^(day|night)$")
    bed_number: str = Field(..., max_length=20)
    patient_name: str = Field(..., max_length=100)
    diagnosis: str
    pathogen: str | None = None
    antibiotics: str | None = None
    anticoagulation: str | None = None
    nutrition: str | None = None
    planned_io: str | None = None
    actual_io: str | None = None
    notes: str | None = None


class ChecklistCreate(ChecklistBase):
    pass


class ChecklistUpdate(BaseModel):
    checklist_date: date | None = None
    shift: str | None = Field(default=None, pattern="^(day|night)$")
    bed_number: str | None = Field(default=None, max_length=20)
    patient_name: str | None = Field(default=None, max_length=100)
    diagnosis: str | None = None
    pathogen: str | None = None
    antibiotics: str | None = None
    anticoagulation: str | None = None
    nutrition: str | None = None
    planned_io: str | None = None
    actual_io: str | None = None
    notes: str | None = None


class ChecklistResponse(ChecklistBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
