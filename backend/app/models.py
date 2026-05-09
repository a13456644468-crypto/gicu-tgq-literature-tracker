"""SQLAlchemy persistence models."""
from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Journal(Base):
    __tablename__ = "journals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    category: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    issn: Mapped[str | None] = mapped_column(String(20))
    pubmed_search_term: Mapped[str | None] = mapped_column(String(500))
    is_builtin: Mapped[bool] = mapped_column(Boolean, default=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    papers: Mapped[list["Paper"]] = relationship(back_populates="journal")


class Paper(Base):
    __tablename__ = "papers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    journal_id: Mapped[int | None] = mapped_column(ForeignKey("journals.id"), index=True)
    pmid: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    authors: Mapped[str | None] = mapped_column(Text)
    abstract: Mapped[str | None] = mapped_column(Text)
    doi: Mapped[str | None] = mapped_column(String(100))
    pub_date: Mapped[Date | None] = mapped_column(Date, index=True)
    pubmed_url: Mapped[str | None] = mapped_column(String(500))
    is_new: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    fetched_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now())
    created_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now())

    journal: Mapped[Journal | None] = relationship(back_populates="papers")


class Checklist(Base):
    __tablename__ = "checklists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    checklist_date: Mapped[Date] = mapped_column(Date, nullable=False, index=True)
    shift: Mapped[str] = mapped_column(String(20), default="day", index=True)
    bed_number: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    patient_name: Mapped[str] = mapped_column(String(100), nullable=False)
    diagnosis: Mapped[str] = mapped_column(Text, nullable=False)
    pathogen: Mapped[str | None] = mapped_column(Text)
    antibiotics: Mapped[str | None] = mapped_column(Text)
    anticoagulation: Mapped[str | None] = mapped_column(Text)
    nutrition: Mapped[str | None] = mapped_column(Text)
    planned_io: Mapped[str | None] = mapped_column(Text)
    actual_io: Mapped[str | None] = mapped_column(Text)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
