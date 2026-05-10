FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DATABASE_URL=sqlite:////tmp/gicu_tgq.db
ENV CORS_ORIGINS=*

COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/app ./app
COPY backend/scripts ./scripts

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-80}"]
