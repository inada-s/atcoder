#!/usr/bin/env bash
# このリポジトリの場所に依存する CPH の設定を、VS Code (WSL) のマシン設定に書く。何度実行してもよい。
#   ./tools/setup.sh
# CPH は設定のパスをそのままの文字列で使う (変数展開なし、相対パス不可) ので、
# 絶対パスが必要な 3 つだけをここで埋めて ~/.vscode-server/data/Machine/settings.json に書く。
# それ以外の設定は .vscode/settings.json (コミット対象) にある。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="$HOME/.vscode-server/data/Machine/settings.json"

if [[ ! -d "$HOME/.vscode-server" ]]; then
  echo "error: ~/.vscode-server がありません。先に VS Code の WSL 拡張でこのフォルダを開いてください" >&2
  exit 1
fi
mkdir -p "$ROOT/.cph" "$(dirname "$SETTINGS")"

ROOT="$ROOT" SETTINGS="$SETTINGS" python3 - <<'PY'
import json, os, re
root, path = os.environ["ROOT"], os.environ["SETTINGS"]
try:
    text = open(path, encoding="utf-8").read()
    text = re.sub(r"^\s*//.*$", "", text, flags=re.M)        # 行コメント
    text = re.sub(r",(\s*[}\]])", r"\1", text)                # 末尾カンマ
    settings = json.loads(text) if text.strip() else {}
except FileNotFoundError:
    settings = {}

settings.update({
    "cph.general.defaultLanguageTemplateFileLocation": f"{root}/template.cpp",
    "cph.general.saveLocation": f"{root}/.cph",
    # AtCoder のジャッジ (C++23 GCC) に合わせたオプション。-DLOCAL で template の dump() が有効になる
    "cph.language.cpp.Args": " ".join([
        "-std=gnu++23", "-O2", "-Wall", "-Wextra", "-Wno-unused-parameter", "-DLOCAL",
        f"-I{root}/lib/ac-library", f"-I{root}/lib",
        "-march=native", "-pthread", "-ftrivial-auto-var-init=zero",
    ]),
})
with open(path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=4, ensure_ascii=False)
    f.write("\n")
print(f"wrote {path}")
PY

echo "完了。VS Code を再読み込み (Developer: Reload Window) すると反映されます"
