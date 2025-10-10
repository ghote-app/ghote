# Contributing 指南 / Contributing Guidelines

感謝你對 Ghote 的貢獻意願！以下提供中英雙語說明。

## 流程 / Workflow
- 從 `main` 建立分支：`feature/<name>`、`fix/<name>`、`chore/<name>`
- 提交訊息（建議）：`feat|fix|chore|refactor|docs: short summary`
- 發送 Pull Request 到 `main`，CI 必須通過，請描述變更與影響
- 由 Reviewer 進行 Code Review，必要時請補完整測試或說明

> 補充：PR 建立時請參考 `.github/PULL_REQUEST_TEMPLATE.md` 檢查清單；
> CI 使用 Flutter 3.35.6，請本地版本保持一致。

## 環境 / Environment
- Flutter：3.35.6
- Android：使用專案內 gradle wrapper
- iOS：使用 `Podfile.lock`，如需 CocoaPods 請以 `Gemfile` 固定版本

## 風格 / Style
- 保持 lints=0（遵循 `analysis_options.yaml`）
- 版面一律以響應式為主，不做平台特化尺寸
- 元件化、可重用、減少巢狀層級

## PR 檢查清單 / PR Checklist
- [ ] 通過 CI（analyze / build）
- [ ] 更新必要文件（README/CHANGELOG/註解）
- [ ] 無多餘 console/log 與死程式碼

---

Thank you for contributing to Ghote!

## Workflow
- Branch from `main`: `feature/<name>`, `fix/<name>`, `chore/<name>`
- Commit style (recommended): `feat|fix|chore|refactor|docs: short summary`
- Open PR to `main`. CI must pass. Describe changes and impacts
- Reviewer will provide feedback. Add tests or docs as needed

## Environment
- Flutter 3.35.6
- Android via project Gradle wrapper
- iOS via `Podfile.lock` (optional `Gemfile` to pin CocoaPods)
 - CI uses GitHub Actions with Flutter 3.35.6

## Style
- Keep lints at 0 (see `analysis_options.yaml`)
- Responsive-first layout; no platform-specific sizing
- Componentize and reduce deep nesting

## PR Checklist
- [ ] CI passes (analyze / build)
- [ ] Docs updated (README/CHANGELOG/comments)
- [ ] No stray logs or dead code
