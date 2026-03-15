# 拾字日常 後端 (literary_life_backend) ✦

這是拾字日常的後端 API 服務，提供數據管理、AI 文學助手與社群互動邏輯。

## 技術棧

- **框架**: [FastAPI](https://fastapi.tiangolo.com/)
- **資料庫**: PostgreSQL
- **ORM**: SQLAlchemy
- **遷移工具**: Alembic
- **AI 服務**: 量界智算 (liangjiewis.com)

## 快速啟動

### 1. 環境變數配置
建立並編輯 `.env` 檔案：
```bash
cp .env.example .env
```
填寫 `DATABASE_URL` 與 `AI_API_KEY`。

### 2. 啟動服務 (Docker 推薦)
在根目錄執行：
```bash
docker compose up -d api
```

### 3. 本地手動啟動
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 核心功能實作

- **AI 文學助手**: 整合 `httpx` 調用外部 AI 介面，支援靈感分析、標題建議、文章潤飾。
- **資料庫遷移**: 使用 Alembic 進行版本控制，確保 schema 同步。
- **社群權限控制**: 實作精確的文章可見度檢查，區分私密、好友、群組與公開狀態。
- **JWT 認證**: 安全的使用者註冊、登入與授權機制。

## API 文件

啟動服務後，造訪：
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## 測試

```bash
pytest
```
