# atcoder

Competitive Companion + CPH で AtCoder をやるための VS Code ワークスペース。解答はコミットしない (gitignore 済み)。コミットするのはテンプレート、スニペット、ライブラリ、設定だけ。

## 構成

```
atcoder/
├── template.cpp              # CPH が新しい問題を作るときのテンプレート
├── lib/
│   └── ac-library/           # AtCoder Library (git submodule)。#include <atcoder/all>
├── .vscode/
│   ├── settings.json         # CPH / clangd / デバッグの設定 (パスに依存しないもの)
│   ├── cp.code-snippets      # C++ スニペット。全部 _ 始まり (_bfs, _dijkstra, _uf, _memo1 など)。_ を打つと一覧が出る
│   └── extensions.json       # 推奨拡張 (CPH, Vim, clangd)
├── tools/
│   ├── setup.sh              # マシンに依存する設定 (CPH のパス、g++、.clangd) を書く (clone 後に 1 回)
│   └── cph_input.py          # デバッグ用に CPH のテストケースを in.txt に書き出す
├── compile_flags.txt         # clangd 用 (補完・診断)。clangd 本体は WSL は ~/.local/opt/clangd_* (公式バイナリ、sudo 不要)、Mac は Xcode のもの
├── .clangd                   # clangd に g++ のヘッダを使わせる。setup.sh が書く (gitignore)
├── abc326a.cpp ...           # 解答。CPH がルートに作る (gitignore)
└── .cph/                     # サンプルとバイナリ (gitignore)
```

## セットアップ (WSL)

```sh
git clone --recursive <this repo> ~/atcoder
sudo apt install g++-15 gdb         # g++-15 は ubuntu-toolchain-r/test PPA
code ~/atcoder                      # WSL 拡張で開く。推奨拡張を入れる
./tools/setup.sh                    # リポジトリの場所に依存する CPH の設定をマシン設定に書く
```

## セットアップ (Mac)

```sh
git clone --recursive <this repo> ~/atcoder
brew install gcc                    # g++-16 など。bits/stdc++.h があるのは GCC だけ (Apple の clang には無い)
code ~/atcoder                      # 推奨拡張を入れる
./tools/setup.sh                    # ~/Library/Application Support/Code/User/settings.json に書く
```

## 共通

Chrome に [Competitive Companion](https://github.com/jmerle/competitive-companion) を入れる。ポートは既定のまま (CPH の 27121 が含まれている)。

CPH はテンプレートの場所や `-I` を絶対パスでしか受け付けない (変数展開なし、相対パスの基準も拡張ホストの作業ディレクトリ) ので、その 3 つと g++ のパス (PATH 上で一番新しい `g++-NN`。`GXX=g++-15 ./tools/setup.sh` で指定もできる) だけ `tools/setup.sh` が埋めて書く。書き先は WSL ではマシン設定 (`~/.vscode-server/data/Machine/settings.json`)、Mac ではユーザー設定。デバッグ用ビルド (`tasks.json`) も同じ g++ を使う。リポジトリを動かしたり g++ を上げたりしたら実行し直す。

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
