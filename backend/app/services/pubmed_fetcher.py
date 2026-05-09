"""PubMed E-utilities integration."""
from __future__ import annotations

import time
import xml.etree.ElementTree as ET
from datetime import date
from typing import Any

import httpx

from app.config import settings


class PubMedFetcher:
    def __init__(self) -> None:
        self.base_url = settings.pubmed_api_base
        self.delay = settings.pubmed_request_delay

    def _get(self, path: str, params: dict[str, Any]) -> str:
        time.sleep(self.delay)
        response = httpx.get(f"{self.base_url}/{path}", params=params, timeout=30)
        response.raise_for_status()
        return response.text

    def search_pmids(self, term: str, retmax: int | None = None) -> list[str]:
        xml_text = self._get(
            "esearch.fcgi",
            {
                "db": "pubmed",
                "term": term,
                "retmode": "xml",
                "sort": "pub date",
                "retmax": retmax or settings.pubmed_retmax,
            },
        )
        root = ET.fromstring(xml_text)
        return [node.text for node in root.findall(".//Id") if node.text]

    def fetch_details(self, pmids: list[str]) -> list[dict[str, Any]]:
        if not pmids:
            return []
        xml_text = self._get(
            "efetch.fcgi",
            {"db": "pubmed", "id": ",".join(pmids), "retmode": "xml"},
        )
        root = ET.fromstring(xml_text)
        return [self._parse_article(article) for article in root.findall(".//PubmedArticle")]

    def _parse_article(self, article: ET.Element) -> dict[str, Any]:
        pmid = article.findtext(".//PMID") or ""
        title = "".join(article.find(".//ArticleTitle").itertext()) if article.find(".//ArticleTitle") is not None else ""
        abstract_parts = ["".join(node.itertext()) for node in article.findall(".//AbstractText")]
        authors = []
        for author in article.findall(".//Author"):
            last = author.findtext("LastName")
            fore = author.findtext("ForeName")
            collective = author.findtext("CollectiveName")
            name = collective or " ".join(part for part in [fore, last] if part)
            if name:
                authors.append(name)

        doi = None
        for article_id in article.findall(".//ArticleId"):
            if article_id.attrib.get("IdType") == "doi":
                doi = article_id.text
                break

        pub_date = self._parse_date(article)
        return {
            "pmid": pmid,
            "title": title.strip() or "(Untitled)",
            "authors": ", ".join(authors),
            "abstract": "\n".join(abstract_parts),
            "doi": doi,
            "pub_date": pub_date,
            "pubmed_url": f"https://pubmed.ncbi.nlm.nih.gov/{pmid}/",
        }

    def _parse_date(self, article: ET.Element) -> date | None:
        year = article.findtext(".//PubDate/Year") or article.findtext(".//ArticleDate/Year")
        month = article.findtext(".//PubDate/Month") or article.findtext(".//ArticleDate/Month") or "1"
        day = article.findtext(".//PubDate/Day") or article.findtext(".//ArticleDate/Day") or "1"
        if not year:
            return None
        month_map = {
            "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
            "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12,
        }
        try:
            month_num = month_map[month[:3]] if month[:3] in month_map else int(month)
            return date(int(year), month_num, int(day))
        except ValueError:
            return date(int(year), 1, 1)
