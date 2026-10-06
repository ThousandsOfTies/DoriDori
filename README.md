# DoriDori

TutoTutoから派生した、本の本文を参照した質問・先生の回答・追加質問をパネルでつなぐReactアプリ。

公開用フロントエンドの設定先：[DoriDori](https://thousandsofties.github.io/DoriDori/)

## 現在の機能

- PDF・画像の取り込み、教材一覧、画像のPDF化と補正。
- PDFのA/Bページ切替・左右分割、ペン・消しゴム・テキスト入力。
- 「本の範囲を囲む → 質問を入力 → 本文を参照した先生の回答」のパネル遷移。
- テキスト・音声入力・手書きによる質問と、先生の回答の一部を囲む追加質問。
- PDF内の文字情報による本文の索引作成、意味検索・文字検索による関連本文の取得。
- Markdown・数式による回答、参照ページへの移動、先のページを参照するかの選択。
- 回答に合うWebの参考図・写真・グラフ（最大2件）、見どころ・出典・作者・利用条件の表示と画像の拡大。
- 質問・回答・分岐の保存、PDF上の履歴マーカー・パンくず・横ホイールによるパネル移動。
- 共通管理画面のSNSリンク・利用時間設定、Googleログイン、課金連携。

質問と追加質問は `/api/book/ask-agent` に質問画像・質問文・本文取得機能・直前の先生の回答を送る。
AIが `search_book`（本文検索）や `read_book_pages`（ページの文字取得）で必要な情報を要求し、ブラウザが結果を返して回答を続ける。
初回には関連本文を自動送信しない。本文確認は最大2往復、各往復で最大2要求、1要求で最大3件・各2400文字。全文画像のOCRや保存した会話履歴全体の送信は行わない。
既定では現在ページまでを参照でき、先のページは利用者が許可した場合だけ取得する。索引未完成のページも、AIが指定すればPDF内の文字を取得できる。
回答の「先生が確認した本文」で、AIの要求・検索語・返した本文を確認できる。この記録は回答履歴に保存する。
旧クライアント用の `/api/book/ask` は引き続き利用できる。プレミアム限定化とSNS機能の除外は未実装。
索引作成ではPDFページの画像をAIへ送らず、PDF内の文字をブラウザで取得してから本文テキストだけを `/api/book/embed` へ送る。
文字情報がないページは索引から除外し、[PDF24のOCR](https://tools.pdf24.org/ja/ocr-pdf)などで文字を付けたPDFの取り込みを案内する。
旧 `/api/book/ocr` は410を返してAIを呼ばない。保存済みの本文・索引は引き続き利用できる。
索引がない本でも、質問時に選択した画像・図について先生へ質問できる。
索引の作成・停止・再開は、PDF一覧の歯車から開くPDF設定画面の「本の索引」で行う。
PDF登録時に、端末内で文字情報の有無を確認する。文字を見つけると確認を終え、文字なしの判定には全ページを確認する。読み取れないページがあり文字を確認できなかった場合は未判定とする。この確認にAI通信や画像OCRは使わず、索引作成も自動では開始しない。
一覧とPDF画面で同じ表紙サムネイルを表示し、右上の丸バッジで索引状態を示す。
文字ありのPDFは、薄いグレー＝未作成、薄い黄色＝作成中・途中、薄い緑＝作成済み、薄い赤＝作成失敗・状態取得失敗。文字なし・文字の有無が未確認の場合は同じ大きさの透明なバッジにして、サムネイルの配置を保つ。停止しただけなら失敗とは区別し、失敗状態も保存して続きから再開できる。詳細はバッジの説明で確認でき、PDF画面の色付きバッジから先のページの参照許可を開ける。
PDF画面ではホームボタンの隣の歯車からPDF設定へ直接進める。表紙サムネイルは「PDF」のパンくずに代わり、質問・回答からPDFへ戻る操作も引き続き利用できる。
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
- 登録時の文字判定はPDFレコードの任意項目 `textInspection` に保存する。既存PDFや他アプリの登録処理との互換性を保ち、判定のためにDBのバージョンは変更しない。
- 共通ライブラリには既定DB名がなく、`VITE_INDEXED_DB_NAME` の指定が必須。各アプリのVite設定で明示し、同一オリジン上でもデータを分離する。未指定・空白のみの場合は起動時に例外になる。
- 本文・検索用の索引は別のIndexedDB `DoriDoriBookIndexDB` に保存する。
- 一覧用の索引状態は `DoriDoriBookIndexStatusDB` に保存する。既存索引の初回表示時は実際のPDFページ数で完了状態を判定し、AIを呼ばずに状態を保存する。本文のDBは従来のバージョンのまま使う。
- Googleログインとユーザー・課金情報はFirebase Authentication／Firestoreを使用する。
- 本の質問はブラウザからExpress APIの `/api/book/*` を経由してGeminiへ送信する。
- 現行のフロント接続先は `.github/workflows/deploy.yml` の `VITE_API_URL`。TutoTutoとDoriDoriは同じCloud Run APIを使用する。
- PWAは更新通知から適用する方式。AIへの質問、参考資料の検索・画像取得、意味検索用の索引作成、認証にはネットワーク接続が必要。PDF内の文字の取得と文字検索はブラウザ内で行う。

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
