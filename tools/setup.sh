#!/usr/bin/env bash
# このマシンに依存する設定を書く。WSL と Mac に対応。何度実行してもよい。
#   ./tools/setup.sh
#   GXX=g++-15 ./tools/setup.sh   # 使う g++ を指定する (既定は PATH 上で一番新しい g++-NN)
# CPH は設定のパスをそのままの文字列で使う (変数展開なし、相対パス不可) ので、
# 絶対パスが必要なもの (と g++ のコマンド名) だけをここで埋めて VS Code の設定に書く:
#   WSL: ~/.vscode-server/data/Machine/settings.json (マシン設定)
#   Mac: ~/Library/Application Support/Code/User/settings.json (ユーザー設定)
# ついでに clangd が g++ のヘッダを使うよう .clangd (gitignore 済み) を書く。
# それ以外の設定は .vscode/settings.json (コミット対象) にある。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
  Darwin)
    SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
    ;;
  Linux)
    SETTINGS="$HOME/.vscode-server/data/Machine/settings.json"
    if [[ ! -d "$HOME/.vscode-server" ]]; then
      echo "error: ~/.vscode-server がありません。先に VS Code の WSL 拡張でこのフォルダを開いてください" >&2
      exit 1
    fi
    ;;
  *)
    echo "error: 未対応の OS です: $(uname -s)" >&2
    exit 1
    ;;
esac

GXX="${GXX:-$(compgen -c g++- | grep -E '^g\+\+-[0-9]+$' | sort -t- -k2 -n | tail -n 1 || true)}"
if [[ -z "$GXX" ]] || ! GXX_PATH="$(command -v "$GXX")"; then
  echo "error: g++-NN が見つかりません (Mac: brew install gcc / WSL: sudo apt install g++-15)" >&2
  exit 1
fi
echo "g++: $GXX ($GXX_PATH)"

# clangd.path も書く。Windows 側の VS Code で clangd 拡張が clangd を自動インストールすると、ユーザー設定に
# Windows の clangd.exe のパスが入り、WSL でもそれを使おうとして clangd が起動しなくなる (マシン設定の方が優先される)
CLANGD_PATH="$(command -v clangd || true)"
if [[ -z "$CLANGD_PATH" && -x "$HOME/.local/bin/clangd" ]]; then
  CLANGD_PATH="$HOME/.local/bin/clangd"
fi
echo "clangd: ${CLANGD_PATH:-(見つからない。補完は効かない)}"

if [[ ! -f "$ROOT/lib/ac-library/atcoder/all" ]]; then
  git -C "$ROOT" submodule update --init
fi
mkdir -p "$ROOT/.cph" "$(dirname "$SETTINGS")"

# Boost (ヘッダのみ)。AtCoder のジャッジと同じ版を ~/.local/opt に置き、lib/boost (gitignore 済み) からリンクする。
# CPH・デバッグビルド・clangd は -isystem lib/boost で読む (-I だと Boost 内の警告が -Wall で大量に出る)
BOOST=boost_1_87_0
if [[ ! -f "$HOME/.local/opt/$BOOST/boost/version.hpp" ]]; then
  echo "Boost を取得: $BOOST"
  mkdir -p "$HOME/.local/opt"
  curl -fsSL "https://archives.boost.io/release/1.87.0/source/$BOOST.tar.bz2" |
    tar xj -C "$HOME/.local/opt" "$BOOST/boost" "$BOOST/LICENSE_1_0.txt"
fi
ln -sfn "$HOME/.local/opt/$BOOST" "$ROOT/lib/boost"

# clangd は compile_flags.txt だけだと clang 自身のヘッダ (Mac では libc++) を使い、bits/stdc++.h が見つからない
cat > "$ROOT/.clangd" <<EOF
# tools/setup.sh が書く。clangd が $GXX のシステムヘッダを使うようにする
CompileFlags:
  Compiler: $GXX_PATH
EOF

ROOT="$ROOT" SETTINGS="$SETTINGS" GXX_PATH="$GXX_PATH" CLANGD_PATH="$CLANGD_PATH" python3 - <<'PY'
import json, os, re
root, path, gxx_path = os.environ["ROOT"], os.environ["SETTINGS"], os.environ["GXX_PATH"]
clangd_path = os.environ["CLANGD_PATH"]
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
    "cph.language.cpp.Command": gxx_path,  # GUI から起動した VS Code の PATH に Homebrew が無くても動くようにフルパス
    # AtCoder のジャッジ (C++23 GCC) に合わせたオプション。-DLOCAL でローカルでだけ有効にしたいコードが書ける
    "cph.language.cpp.Args": " ".join([
        "-std=gnu++23", "-O2", "-Wall", "-Wextra", "-Wno-unused-parameter", "-DLOCAL",
        f"-I{root}/lib/ac-library", f"-I{root}/lib", f"-isystem{root}/lib/boost",
        "-march=native", "-pthread", "-ftrivial-auto-var-init=zero",
    ]),
})
if clangd_path:
    settings["clangd.path"] = clangd_path
with open(path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=4, ensure_ascii=False)
    f.write("\n")
print(f"wrote {path}")
PY

echo "完了。VS Code を再読み込み (Developer: Reload Window) すると反映されます"
