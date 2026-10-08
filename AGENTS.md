# DoriDori プロジェクトルール

## 対象と構成

このファイルは `D:\Yurufuwa\DoriDori` 以下に適用する。
DoriDoriは、本の本文を参照した質問・先生の回答・追加質問をパネルでつなぐ、TutoTuto派生の学習アプリ。

- メタリポジトリ：このディレクトリ（`main`）
- アプリ：`repos/doridori-app`（`main`）
- TutoTutoと共有するAPI：`repos/home-teacher-api`（`main`）
- 共通UI・PDF表示・保存・認証：`repos/home-teacher-common`（`main`）
- 描画基盤：`repos/drawing-common`（`main`）

旧 `C:\VibeCode` のパスを使用しない。
DoriDori固有のパネルUI・追加質問機能をTutoTutoへ自動的に取り込まない。
TutoTutoにも採点結果への追加質問があるが、DoriDoriの本文索引・検索や読書用UIとは個別に管理する。
公開アプリのHTML入口は `repos/doridori-app/index.html`、Reactの入口は `repos/doridori-app/src/main.tsx`。旧UIモックは `docs/legacy-ui-mock.html` に保管する。

## 依存管理と修正先

依存リポジトリはGitサブモジュール。構成・追従ブランチは `.gitmodules`、使用コミットはメタリポジトリのgitlinkで管理する。
`VERSIONS` と `make update-versions` は旧方式であり、使用しない。

- DoriDori固有の変更は `repos/doridori-app` に入れる。
- 採点・追加質問・本文参照・認証・課金の共有APIは `repos/home-teacher-api` に入れる。アプリ側にサーバー実装を複製しない。
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
IndexedDB名は `DoriDoriDB`。Vite設定で `VITE_INDEXED_DB_NAME` を明示する。共通ライブラリに既定DB名はなく、未指定・空白のみは例外になる。
本文・検索用の索引は別のIndexedDB `DoriDoriBookIndexDB` に保存する。
索引作成はPDFごとの設定画面に置く。一覧用の状態は `DoriDoriBookIndexStatusDB` に保存し、PDF一覧・PDFツールバーで同じ表紙サムネイルの右上に丸バッジを表示する。文字ありの未作成は薄いグレー、作成中・途中は薄い黄色、作成済みは薄い緑、作成失敗・状態取得失敗は薄い赤。文字なし・文字の有無が未確認の場合は同じ寸法の透明なバッジにし、配置を変えない。途中停止は失敗として扱わず、失敗状態は保存して再開できる。PDFツールバーの歯車は設定画面へ直接進む。全ページの確認と本文のベクトル作成が完了した場合だけ作成済みとする。
PDF登録時の文字判定はブラウザ内で行い、最初に文字を見つけた時点で「あり」とする。「なし」は全ページの読み取りが成功した場合だけとし、読み取り失敗は未判定として扱う。判定だけをPDFレコードの任意項目 `textInspection` に保存する。自動で索引を作らず、この判定にAI通信や画像OCRを追加しない。共通Adminの `checkPDFTextOnImport` は既定で無効、DoriDoriだけ有効にする。
索引作成はPDF内の文字をブラウザで取得し、本文テキストだけを送る。本の画像ページのAI文字起こしを追加しない。
DoriDori固有の画面文言はアプリの `src/i18n/locales` の `doridori` 名前空間で管理し、共通の言語切り替えに連動させる。共通UIの翻訳は共通ライブラリの `src/i18n/locales` で管理する。画面文言・確認ダイアログ・通知・読み上げ文言をコンポーネントやHookに直書きしない。各 `ja.json` / `en.json` が翻訳の編集元で、独立HTMLの配布用JSONはアプリ側の同じファイルから生成する。言語変更を索引読み込み・作成のEffect依存に追加して処理を再実行しない。
文字のないPDFはPDF24などで事前OCRする。旧 `/api/book/ocr` は410を返してAIを呼ばない。質問時の選択画像の送信は別に扱う。
本の質問は `/api/book/ask-agent` でAIの本文要求に応じる。ブラウザは `search_book` と `read_book_pages` のみ実行し、現在ページを超える本文は利用者が許可した場合だけ返す。
本文確認は最大2往復。通信形式・上限は `repos/home-teacher-api/contracts/bookAgentProtocol.ts` で管理し、アプリの `shared/bookAgentProtocol.ts` はその定義を再エクスポートする。全文画像OCRや自動的な本文事前送信を追加しない。
IndexedDBはURLパスでは分離されないため、DB名やスキーマを変更する場合は既存データの移行・互換性を検討する。

## 起動・デプロイ

- フロント：メタで `make dev`、または `repos/doridori-app` で `npm run dev`（Vite、既定3000）。
- API：メタで `make dev-server`、または `repos/doridori-app` で `npm run dev:server`（Express、既定3003）。
- サーバーのソースは `repos/home-teacher-api/src`。依存・ビルド設定・Dockerfile・専用CIはAPIリポジトリで管理する。採点定義用にAPI内の `repos/home-teacher-common` を別途版固定する。
- API設定は実行環境の変数、API直下 `.env` の順に優先する。アプリから起動した場合だけ、互換用のアプリ `server/.env` とアプリ直下 `.env` も読む。既存の秘密設定ファイルを移行時に削除しない。
- TutoTutoとDoriDoriは現行のCloud Run APIを共有する。接続先は `.github/workflows/deploy.yml` で確認する。
- 本番・stagingのAPI公開元は `repos/home-teacher-api`。両アプリの旧公開コマンドは案内して停止する。公開したコミットはCloud Runの `git-sha` ラベルで記録する。
- APIの変更は共有リポジトリで行い、採点 `/api/grade-work`・追加質問 `/api/ask-question`・本の質問 `/api/book/*` を保持して検証する。APIのcommit・push・専用CI確認を先に行い、その後アプリとメタのgitlinkを更新する。
- APIキーはサーバー側のみ。`VITE_API_URL` はAPIのベースURLで、末尾に `/api` を付けない。
- ログは起動ターミナルへ出力される。固定の `/tmp/proto-server.log` は作成されない。
- メタの `main` へのpushでGitHub Actionsが固定済みサブモジュールをビルドし、GitHub Pagesへ公開する。
- Cloud Run APIはフロントと別デプロイ。READMEと `repos/home-teacher-api/DEPLOYMENT.md` を参照する。
