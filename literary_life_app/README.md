# 拾字日常 前端 (literary_life_app) ✦

這是拾字日常的 Flutter 行動端應用程式，提供優雅的介面讓用戶進行文學創作與交流。

## 技術棧

- **框架**: [Flutter](https://flutter.dev/)
- **狀態管理**: [Provider](https://pub.dev/packages/provider)
- **字體**: Google Fonts (Noto Serif TC, Noto Sans TC)
- **導航**: 自定義 MainShell 控制器

## 快速啟動

### 1. 安裝依賴
```bash
flutter pub get
```

### 2. 執行應用
確保你的開發環境已連接模擬器或實機。

- **Android 模擬器**:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  ```
- **iOS 模擬器**:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://localhost:8000
  ```

## 核心功能實作

- **靈感收集**: 使用 `InspirationProvider` 進行非同步 API 請求與本地狀態管理。
- **文章編輯**: 整合 AI 輔助功能，提供即時標題建議、開頭與潤飾功能。
- **社群互動**: 支援作品分享、回應、收藏功能。
- **快捷操作**: 再次點擊底部導航列圖示可自動回到頂部並刷新。
- **複製功能**: 用戶編號與群組邀請碼均支援點擊複製與 SnackBar 視覺回饋。

## 目錄結構

- `lib/models/`: 資料模型與 JSON 序列化。
- `lib/pages/`: 各大功能頁面實作。
- `lib/providers/`: 狀態管理與 API 業務邏輯。
- `lib/widgets/`: 可複用的 UI 元件。
- `lib/config/`: 佈景主題與 API 路徑設定。

## 測試與分析

```bash
flutter analyze
flutter test
```
