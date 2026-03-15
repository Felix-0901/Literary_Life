# 拾字日常 (Literary Life) ✦

「拾起生活的片段，化作文學的語言。」

拾字日常是一個專為文學愛好者設計的創作與社群平台。透過記錄日常生活中的靈感，結合 AI 文學助手的引導，幫助使用者將瑣碎的感受轉化為優美的文學作品。

## 專案架構

本專案採用 Monorepo 結構，包含以下主要部分：

- **[literary_life_app](./literary_life_app)**: 基於 Flutter 打造的跨平台行動端應用（iOS / Android）。
- **[literary_life_backend](./literary_life_backend)**: 基於 FastAPI 打造的後端 API 服務，整合 PostgreSQL 資料庫與 AI 文學助手。
- **Docker 部署**: 提供一鍵啟動後端與資料庫的開發/生產環境。

## 快速啟動

### 1. 後端與資料庫 (Docker)

確保你已安裝 Docker，然後在根目錄執行：

```bash
docker compose up -d
```

這將啟動：
- **API 服務**: `http://localhost:8000`
- **PostgreSQL**: `localhost:5433`
- **API 文件 (Swagger)**: `http://localhost:8000/docs`

### 2. 前端應用 (Flutter)

進入前端目錄並啟動應用（需已安裝 Flutter SDK）：

```bash
cd literary_life_app
flutter pub get
# 啟動模擬器後執行 (Android 模擬器請使用 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## 核心功能

- **靈感記錄**: 隨手記下時間、地點與當下感受。
- **AI 文學助手**: 自動分析靈感片段，提供標題、開頭建議與文字潤飾。
- **週期創作計畫**: 建立 3 天或 7 天的寫作計畫，養成創作習慣。
- **文學社群**: 分享你的作品，與好友互動並加入感興趣的文學群組。
- **隱私控制**: 支援私密草稿、僅好友可見或完全公開發布。

## 開發指南

詳細的開發與部署說明請參閱各子目錄下的 README：
- [前端開發指南](./literary_life_app/README.md)
- [後端開發指南](./literary_life_backend/README.md)
- [發版檢查清單](./docs/release-checklist.md)

## 授權

MIT License
