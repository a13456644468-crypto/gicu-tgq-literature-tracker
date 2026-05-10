"""FastAPI application entrypoint."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.models import Journal
from app.routers import checklists, journals, papers

Base.metadata.create_all(bind=engine)


def seed_builtin_journals() -> None:
    builtin_journals = [
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
    db = SessionLocal()
    try:
        if db.query(Journal).count() > 0:
            return
        db.add_all(
            [
                Journal(category=category, name=name, issn=issn, pubmed_search_term=term, is_builtin=True)
                for category, name, issn, term in builtin_journals
            ]
        )
        db.commit()
    finally:
        db.close()


seed_builtin_journals()

app = FastAPI(title=settings.app_name, version="1.0.0")

origins = ["*"] if settings.cors_origins == "*" else [item.strip() for item in settings.cors_origins.split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(journals.router, prefix="/journals", tags=["journals"])
app.include_router(papers.router, prefix="/papers", tags=["papers"])
app.include_router(checklists.router, prefix="/checklists", tags=["checklists"])


@app.get("/")
def root() -> dict[str, object]:
    return {
        "status": "ok",
        "name": settings.app_name,
        "endpoints": ["/health", "/journals", "/papers", "/checklists"],
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
