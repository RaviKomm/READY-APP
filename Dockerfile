FROM python:3.11-slim as base

ARG APP_USER=app
ARG APP_UID=1000

RUN apt-get update \
 && apt-get install -y --no-install-recommends gcc libpq-dev curl \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid ${APP_UID} ${APP_USER}

WORKDIR /app

COPY requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir -r /app/requirements.txt

COPY ./ /app

RUN chown -R ${APP_USER}:${APP_USER} /app

USER ${APP_USER}

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--lifespan", "on"]
