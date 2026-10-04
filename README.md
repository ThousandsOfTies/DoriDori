# DoriDori

TutoTutoから派生した、本の本文を参照した質問・先生の回答・追加質問をパネルでつなぐReactアプリ。

公開用フロントエンドの設定先：[DoriDori](https://thousandsofties.github.io/DoriDori/)

## 現在の機能

- PDF・画像の取り込み、教材一覧、画像のPDF化と補正。
- PDFのA/Bページ切替・左右分割、ペン・消しゴム・テキスト入力。
- 「本の範囲を囲む → 質問を入力 → 本文を参照した先生の回答」のパネル遷移。
- テキスト・音声入力・手書きによる質問と、先生の回答の一部を囲む追加質問。
- PDF本文の索引作成、文字が少ないページのOCR、意味検索・文字検索による関連本文の取得。
- Markdown・数式による回答、参照ページへの移動、先のページを参照するかの選択。
- 回答に合うWebの参考図・写真・グラフ（最大2件）、見どころ・出典・作者・利用条件の表示と画像の拡大。
- 質問・回答・分岐の保存、PDF上の履歴マーカー・パンくず・横ホイールによるパネル移動。
- 共通管理画面のSNSリンク・利用時間設定、Googleログイン、課金連携。

質問と追加質問は専用の `/api/book/ask` に、質問画像・質問文・検索で取得した本文・直前の先生の回答を送る。
PDF全体を一度に送る方式ではなく、索引済みの本文から関連箇所を選ぶ。保存した会話履歴全体は送らない。
索引が未完成でも現在ページを読み取り、利用できる本文で質問できる。プレミアム限定化とSNS機能の除外は未実装。
先生の回答を先に表示し、`/api/book/reference-media` でWikimedia Commonsの参考資料を後から検索する。
検索結果は回答履歴に保存し、検索や画像の取得に失敗しても本文は読める。参考資料は本の原図や最新統計を保証するものではなく、各出典を確認できる。
詳しくは [UI設計メモ](UI_DESIGN_DISCUSSION.md) を参照。

HTMLの入口は `repos/doridori-app/index.html`、Reactの入口は `repos/doridori-app/src/main.tsx`。
旧UIモックは `docs/legacy-ui-mock.html` に保管しており、公開アプリには含めない。
主要画面は `src/App.tsx` と `src/components/study/StudyPanel.tsx`。

## 構成

```text
DoriDori/
├── .gitmodules              # サブモジュールと追従ブランチ
├── .github/workflows/       # GitHub Pagesへのデプロイ
├── Makefile                 # 統合ビルド・開発コマンド
├── docs/                    # 旧UIモックなどの参考資料
└── repos/
    ├── drawing-common/      # Canvas描画基盤
    ├── home-teacher-common/ # 教材管理・PDF表示・保存・認証・API通信
    └── doridori-app/ # アプリ固有のReact UI・Express API
```

依存コミットはGitサブモジュールのgitlinkで固定する。`VERSIONS`、`Repos.mk`、`make update-versions` は使用しない。
アプリのVite/TypeScriptエイリアスは兄弟サブモジュールの `src` を参照する。

## データとAPI

- PDF・書き込み・設定・質問と回答の履歴は端末のIndexedDB `DoriDoriDB` に保存する。既存の採点履歴用ストアも残っている。
- 共通ライブラリには既定DB名がなく、`VITE_INDEXED_DB_NAME` の指定が必須。各アプリのVite設定で明示し、同一オリジン上でもデータを分離する。未指定・空白のみの場合は起動時に例外になる。
- 本文・検索用の索引は別のIndexedDB `DoriDoriBookIndexDB` に保存する。
- Googleログインとユーザー・課金情報はFirebase Authentication／Firestoreを使用する。
- 本の質問はブラウザからExpress APIの `/api/book/*` を経由してGeminiへ送信する。
- 現行のフロント接続先は `.github/workflows/deploy.yml` の `VITE_API_URL`。TutoTutoとDoriDoriは同じCloud Run APIを使用する。
- PWAは更新通知から適用する方式。AIへの質問、参考資料の検索・画像取得、OCR・意味検索用の索引作成、認証にはネットワーク接続が必要。

## ローカル開発

Node.js 24（CIと同じメジャーバージョン）、npm、Git、GNU MakeとUnix系シェルを使用する。
WindowsのPowerShellでは下記のnpmコマンドを直接実行できる。MakeコマンドはGNU Makeのある環境で実行する。
PowerShellの実行ポリシーで `npm.ps1` が拒否される場合は、`npm` を `npm.cmd` に読み替える。

```bash
git clone --recurse-submodules https://github.com/ThousandsOfTies/DoriDori.git
cd DoriDori
make setup
make dev
# 別ターミナルでAPIを起動
make dev-server
```

Makeなしの初期設定は、メタで `git submodule update --init --recursive`、
3つのサブモジュールそれぞれで `npm install`、`repos/doridori-app/server` で `npm ci`、
`repos/drawing-common` で `npm run build` を実行する。

`repos/doridori-app` 内では次を使用する。

```bash
npm run dev          # Vite: http://localhost:3000
npm run dev:server   # Express: http://localhost:3003
npm run build:server # サーバーの型確認・本番ビルド
npm run test:server  # サーバーの設定互換性・API起動テスト
npm run dev:all      # 両方を起動
npm run build       # フロントエンドの本番ビルド
npm run typecheck
```

サーバー用の依存・設定・Dockerfileは `repos/doridori-app/server`、ソースはその `src/` にまとめる。
サーバーの [.env.example](repos/doridori-app/server/.env.example) を参考に `server/.env` へ `GEMINI_API_KEY` を設定する。
実行環境の変数、`server/.env`、従来のアプリ直下 `.env` の順に優先するため、既存の設定も引き続き利用できる。
サーバー単体の起動・ビルドは [API README](repos/doridori-app/server/README.md) を参照。
認証・課金を試す場合はサーバーのFirebase/Stripe設定も必要。
フロント用の `.env.local` には `VITE_FIREBASE_*` と必要に応じて
`VITE_API_URL=http://localhost:3003` を設定する。ベースURL末尾に `/api` を付けない。
APIキーなどの秘密情報を `VITE_*` に入れない。

## ビルド・依存更新・公開

`make build` は描画ライブラリとフロントエンドをビルドする。
`main` へのpushでGitHub Actionsが固定済みサブモジュールをcheckoutし、npmでビルド、
`repos/doridori-app/dist` をGitHub Pagesに公開する。Cloud Run APIは別デプロイ。

共有Cloud Run APIの本番・stagingの公開元は **TutoTutoの `repos/tutotuto-app`** に一本化する。
DoriDori側の `npm run deploy:server` と `npm run deploy:server:staging` は案内を表示して停止し、Google Cloudへ接続しない。
DoriDoriのAPI変更は必要な部分を公開元へ反映し、両アプリの採点・追加質問・本の質問を検証して公開する。
詳しくは [APIデプロイ手順](repos/doridori-app/server/DEPLOYMENT.md) を参照。

サブリポジトリの変更を先にcommit・pushし、その後メタで対象gitlinkをcommit・pushする。

```bash
# サブリポジトリの変更・検証・pushが完了した後、メタで実行
git diff --submodule
git add repos/doridori-app
git diff --cached --submodule
git commit -m "Update DoriDori app"
git push origin main
```

共通ライブラリの場合も同様に対象の `repos/home-teacher-common` または `repos/drawing-common` を更新する。
サブモジュールは初期化後にdetached HEADになり得るため、編集前に作業ブランチと状態を確認する。

- `make init`：メタに固定されたコミットを復元。
- `make update`：全サブモジュールを追従ブランチの最新へ移動。更新内容を確認してgitlinkをコミットする。
- `make status`：メタと各サブモジュールの状態を表示。
- `make clean`：生成されたビルド成果物を削除。サブモジュールは残す。

`make build` などは `init` に依存するため、gitlink更新前の新しいコミットの検証は各サブリポジトリで直接行う。
