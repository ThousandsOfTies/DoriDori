# DoriDori

本の本文を参照しながら、質問・先生の回答・追加質問をつなぐ読書・学習アプリです。TutoTutoから派生しています。

[DoriDoriを開く](https://thousandsofties.github.io/DoriDori/)

## 主な機能

- PDF・画像の取り込み、A/Bページ切替・左右分割、手書き・文字入力。
- 本の範囲を囲み、テキスト・音声入力・手書きで先生へ質問。
- Markdown・数式による回答、参照ページ、Webの参考図・写真・グラフを表示。
- 回答への追加質問、質問の分岐と履歴の保存。
- PDF内の文字による本文索引と検索、サムネイルの索引状態バッジ。
- Googleログイン、課金連携、日本語・英語表示。

索引はPDF設定画面で作成・停止・再開します。AIが必要とした本文をブラウザが検索・取得して返し、参照対象は既定で現在ページまでです。
索引作成に送るのはPDF内の文字で、全ページの画像OCRは行いません。文字のないPDFは外部ツールでOCRしてから取り込めます。この本文参照・索引機能はDoriDori専用です。

教材・書き込み・履歴は端末内のIndexedDB `DoriDoriDB`、本文索引は別の専用DBに保存します。AIへの質問や索引作成にはネットワーク接続が必要です。

## 構成

このメタリポジトリが、Gitサブモジュールの使用コミットとビルド・公開を管理します。

| 場所 | 役割 |
|---|---|
| `repos/doridori-app` | DoriDoriのフロントエンド・本文索引 |
| `repos/home-teacher-api` | TutoTuto・DoriDoriの共有Express API |
| `repos/home-teacher-common` | 共通UI・PDF表示・保存・認証 |
| `repos/drawing-common` | 描画基盤 |

APIのソースと公開元は独立した [home-teacher-api](https://github.com/ThousandsOfTies/home-teacher-api) です。CopiCopiのAPIは別構成です。

## ローカル開発

Node.js 24（フロントCIと同じ）、npm、Gitを使用します。共有APIのCI・DockerはNode.js 20です。Makeの利用にはGNU MakeとUnix系シェルが必要です。

```bash
git clone --recurse-submodules https://github.com/ThousandsOfTies/DoriDori.git
cd DoriDori
make setup
```

フロントの `repos/doridori-app/.env.local` に `VITE_FIREBASE_*` と `VITE_API_URL=http://localhost:3003` を設定します。
APIは [設定例](https://github.com/ThousandsOfTies/home-teacher-api/blob/main/.env.example) を参考に `repos/home-teacher-api/.env` を用意します。APIキーはサーバー側のみ、ベースURL末尾に `/api` は付けません。

別々のターミナルで起動します。

```bash
make dev         # フロント: http://localhost:3000
make dev-server  # 共有API: http://localhost:3003
```

Makeなしの場合は、描画・共通UI・アプリで `npm install`、APIで `npm ci`、描画で `npm run build` を実行します。
以降はアプリ内の `npm run dev:all` で両方を起動できます。アプリから起動する場合は従来の `server/.env` も互換用に読みます。PowerShellで `npm.ps1` が拒否される場合は `npm.cmd` を使用します。

`make build` でフロントをビルドします。アプリ内では `npm run typecheck` と `npm test`、ビルド後は `npm run test:bundle` で確認できます。APIの検証はAPIリポジトリ内の `npm test` を使用します。

## 更新・公開

サブリポジトリを先にcommit・pushし、その後このリポジトリのgitlinkを更新します。手順と翻訳ルールは [AGENTS.md](AGENTS.md) を参照してください。
`make init` は固定コミットを復元し、`make update` は追従ブランチへ進めます。gitlink更新前の検証は各サブリポジトリで直接行います。

このリポジトリの `main` へのpushでGitHub Pagesへ公開します。共有Cloud Run APIはAPIリポジトリから別途公開します。
サブモジュールの固定コミットと本番APIの版は別管理です。公開は [API公開手順](https://github.com/ThousandsOfTies/home-teacher-api/blob/main/DEPLOYMENT.md)、本文参照・索引などの詳細は [UI設計メモ](UI_DESIGN_DISCUSSION.md) を参照してください。
