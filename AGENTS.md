# DoriDori プロジェクトルール

## 対象と構成

このファイルは `D:\Yurufuwa\DoriDori` 以下に適用する。
DoriDoriは、解答・採点結果・追加質問をパネルでつなぐ、TutoTuto派生の学習アプリ。

- メタリポジトリ：このディレクトリ（`main`）
- アプリ：`repos/doridori-app`（`main`）
- 共通UI・PDF表示・保存・認証：`repos/home-teacher-common`（`main`）
- 描画基盤：`repos/drawing-common`（`main`）

旧 `C:\VibeCode` のパスを使用しない。
DoriDori固有のパネルUI・追加質問機能をTutoTutoへ自動的に取り込まない。
ルートの `index.html` は旧UIモック。公開アプリの入口は `repos/doridori-app/src/main.tsx`。

## 依存管理と修正先

依存リポジトリはGitサブモジュール。構成・追従ブランチは `.gitmodules`、使用コミットはメタリポジトリのgitlinkで管理する。
`VERSIONS` と `make update-versions` は旧方式であり、使用しない。

- DoriDori固有の変更は `repos/doridori-app` に入れる。
- 共通UI・PDF表示・保存・認証は `repos/home-teacher-common`、描画基盤は `repos/drawing-common` に入れる。
- 共通ライブラリを変更する際は、TutoTuto・DoriDori・CopiCopiで必要な互換性を確認する。各メタが固定するコミットは異なる場合がある。
- サブモジュールは初期化直後にdetached HEADになり得る。変更前に状態を確認し、作業ブランチを選ぶ。
- 既存の未コミット変更を上書きしない。

## 更新と公開の順序

**状態確認 → pull --ff-only → 修正 → 検証 → サブリポジトリをcommit・push → メタのgitlinkをcommit・push**

```bash
# サブリポジトリ側
cd repos/doridori-app
git status --short --branch
git switch main
git pull --ff-only
# 修正・検証後、対象ファイルを選んでgit addする
git commit -m "Describe the app change"
git push origin main

# メタリポジトリ側
cd ../..
git diff --submodule
git add repos/doridori-app
git diff --cached --submodule
git commit -m "Update DoriDori app"
git push origin main
git status --short --branch
```

サブリポジトリをpushする前に、未公開コミットをメタのgitlinkとして公開しない。
`make init` は固定済みコミットを復元する。`make update` は全サブモジュールを追従ブランチへ進めるため、変更内容を確認して使用する。
`make build` なども `init` に依存する。gitlink更新前の新しいサブモジュールコミットを検証する場合は、各サブリポジトリで直接ビルドする。

## パスエイリアスとデータ

アプリの `vite.config.ts` と `tsconfig.json` は、兄弟サブモジュールのソースを参照する。

- `@home-teacher/common` → `../home-teacher-common/src`
- `@thousands-of-ties/drawing-common` → `../drawing-common/src`

マシン固有の絶対パスをエイリアスに追加しない。
IndexedDB名は `DoriDoriDB`。共通ライブラリの既定値 `TutoTutoDB` に戻さない。
IndexedDBはURLパスでは分離されないため、DB名やスキーマを変更する場合は既存データの移行・互換性を検討する。

## 起動・デプロイ

- フロント：メタで `make dev`、または `repos/doridori-app` で `npm run dev`（Vite、既定3000）。
- API：メタで `make dev-server`、または `repos/doridori-app` で `npm run dev:server`（Express、既定3003）。
- TutoTutoとDoriDoriは現行のCloud Run APIを共有する。接続先は `.github/workflows/deploy.yml` で確認する。
- APIキーはサーバー側のみ。`VITE_API_URL` はAPIのベースURLで、末尾に `/api` を付けない。
- ログは起動ターミナルへ出力される。固定の `/tmp/proto-server.log` は作成されない。
- メタの `main` へのpushでGitHub Actionsが固定済みサブモジュールをビルドし、GitHub Pagesへ公開する。
- Cloud Run APIはフロントと別デプロイ。READMEと `repos/doridori-app/server/DEPLOYMENT.md` を参照する。
