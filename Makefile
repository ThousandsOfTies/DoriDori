# HomeTeacherProto プロジェクト Makefile

.PHONY: help setup clone pull update-versions status

GREEN  := \033[0;32m
BLUE   := \033[0;34m
YELLOW := \033[0;33m
NC     := \033[0m

.DEFAULT_GOAL := help

REPOS_DIR := repos

# 将来追加されるサブリポジトリ定義
# 形式: リポジトリ名|GitHubユーザー/リポジトリ|ブランチ
REPOSITORIES :=

## help: ヘルプを表示
help:
	@echo "$(BLUE)HomeTeacherProto プロジェクト$(NC)"
	@echo ""
	@echo "$(GREEN)利用可能なコマンド:$(NC)"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  make /'

## setup: 初回セットアップ
setup: clone
	@echo "$(GREEN)✅ セットアップ完了$(NC)"

## clone: 依存リポジトリをクローン
clone:
	@mkdir -p $(REPOS_DIR)
	@if [ -z "$(REPOSITORIES)" ]; then \
		echo "$(YELLOW)依存リポジトリはまだ設定されていません$(NC)"; \
	fi

## pull: すべての依存リポジトリを最新に更新
pull:
	@$(foreach name,$(REPO_NAMES), \
		if [ -d "$(REPOS_DIR)/$(name)" ]; then \
			echo "$(BLUE)📥 $(name) を更新中...$(NC)"; \
			cd $(REPOS_DIR)/$(name) && git pull; \
		fi; \
	)

## update-versions: サブリポジトリのコミットIDをVERSIONSファイルに記録
update-versions:
	@bash scripts/update-versions.sh

## status: gitステータスを表示
status:
	@git status -sb
