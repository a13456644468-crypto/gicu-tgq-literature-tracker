"""Application settings."""
from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "GICU-TGQ Literature Tracker"
    debug: bool = False
    database_url: str = "postgresql://gicu:gicu_password@localhost:5432/gicu_tgq"
    cors_origins: str = "*"
    pubmed_api_base: str = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
    pubmed_request_delay: float = 0.34
    pubmed_retmax: int = 30

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
