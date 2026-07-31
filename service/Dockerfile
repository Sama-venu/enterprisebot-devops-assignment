FROM python:3.12-slim AS build

WORKDIR /myapp

COPY requirements.txt .

RUN pip install --no-cache-dir \
    --prefix=/install \
    -r requirements.txt


FROM python:3.12-slim

WORKDIR /myapp

RUN useradd -m appuser

COPY --from=build /install /usr/local
COPY app.py .

USER appuser

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
