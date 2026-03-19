#!/bin/bash
# サブリポジトリのコミットIDをVERSIONSファイルに記録

REPOS_DIR="repos"

echo "# 依存リポジトリのバージョン" > VERSIONS
echo "# 更新: make update-versions" >> VERSIONS
echo "" >> VERSIONS

# サブリポジトリが追加されたらここに追記する
# 例:
# if [ -d "$REPOS_DIR/proto-core/.git" ]; then
#     COMMIT=$(cd "$REPOS_DIR/proto-core" && git rev-parse HEAD)
#     echo "proto-core=$COMMIT" >> VERSIONS
# fi

echo "VERSIONSファイルを更新しました:"
cat VERSIONS
