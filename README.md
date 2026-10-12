# atcoder

Competitive Companion + CPH で AtCoder をやるための VS Code ワークスペース。解答はコミットしない (gitignore 済み)。コミットするのはテンプレート、スニペット、ライブラリ、設定だけ。

## 構成

```
atcoder/
├── template.cpp              # CPH が新しい問題を作るときのテンプレート
├── lib/
│   └── ac-library/           # AtCoder Library (git submodule)。#include <atcoder/all>
├── .vscode/
│   ├── settings.json         # CPH の設定。コンパイラは g++-15、ジャッジと同じオプション
│   ├── cp.code-snippets      # C++ スニペット (vin, yn, vout, dxdy, chmax, mint)
│   └── extensions.json       # 推奨拡張 (CPH, Vim, clangd)
├── compile_flags.txt         # clangd 用 (補完・診断)。clangd 本体は ~/.local/opt/clangd_* (公式バイナリ、sudo 不要)
├── abc326a.cpp ...           # 解答。CPH がルートに作る (gitignore)
└── .cph/                     # サンプルとバイナリ (gitignore)
```

## セットアップ (WSL)

```sh
git clone --recursive <this repo> ~/atcoder
sudo apt install g++-15             # ubuntu-toolchain-r/test PPA
code ~/atcoder                      # WSL 拡張で開く。推奨拡張を入れる
```

Chrome に [Competitive Companion](https://github.com/jmerle/competitive-companion) を入れる。ポートは既定のまま (CPH の 27121 が含まれている)。

リポジトリを `~/atcoder` 以外に置いたら `.vscode/settings.json` の `/home/mecha/atcoder` を直す (CPH はカレントディレクトリ未指定でコンパイラを起動するので相対パスが使えない)。

## 使い方

- コンテスト・過去問どちらも同じ。問題ページで Competitive Companion のアイコンを押すと、`abc326a.cpp` がテンプレートから作られて開く
- 書いたら CPH のジャッジビュー (`Ctrl+Alt+B`) で Run All。サンプルの追加や編集もそこでできる
- 提出はブラウザで。ファイルをコピーして貼り付ける (CPH は AtCoder への提出に未対応)
- 同じ問題をもう一度受け取ると、既存の `abc326a.cpp` がそのまま開く (上書きされない)
- `dump(x)` はローカルでだけ stderr に出る (`-DLOCAL`)
- ACL を使うときは template の `// #include <atcoder/all>` のコメントを外す
- 自作のライブラリは `.vscode/cp.code-snippets` にスニペットとして持つ (エディタの内容をそのままコピペで提出できるように、自作ヘッダの `#include` は使わない)。追加・編集は JSON を直接編集する (1 件は prefix と body の 2 行)

## デバッグ

gdb が必要: `sudo apt install gdb`

1. 解答の `.cpp` を開いてブレークポイントを置き、`F5` (「Debug (CPH testcase)」)
2. ケース番号を聞かれるので答える (1 始まり)。`tools/cph_input.py` が CPH の保存データからその入力を `in.txt` に書き出し、期待する出力をターミナルに表示する
3. `-O0 -g -D_GLIBCXX_DEBUG` でビルドされるので、vector の範囲外アクセスはその場で止まる

自分で入力を書きたいときは `in.txt` (gitignore 済み) を編集して「Debug (stdin = in.txt)」、手で打ちたいときは「Debug (stdin = terminal)」を選ぶ。
