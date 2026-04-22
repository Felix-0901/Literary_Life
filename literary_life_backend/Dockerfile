FROM python:3.12-slim

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download the faster-whisper model so it's baked into the image and
# doesn't need to be fetched on every container restart.
ENV WHISPER_MODEL_SIZE=small \
    WHISPER_MODEL_DIR=/app/models \
    WHISPER_COMPUTE_TYPE=int8
RUN mkdir -p /app/models && \
    python -c "from faster_whisper import WhisperModel; \
WhisperModel('${WHISPER_MODEL_SIZE}', device='cpu', \
compute_type='${WHISPER_COMPUTE_TYPE}', \
download_root='${WHISPER_MODEL_DIR}')"

COPY . .

EXPOSE 8000

CMD ["sh", "./start.sh"]
