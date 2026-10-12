#!/usr/bin/env python3
"""CPH が保存しているテストケースの入力を in.txt に書き出す (デバッグ実行用)。

  python3 tools/cph_input.py <解答の .cpp> <ケース番号 (1 始まり)>

CPH はサンプルを .cph/.<ファイル名>_<パスの md5>.prob (JSON) に保存している。
launch.json の「Debug (CPH testcase)」が F5 のたびにこれを呼ぶ。
"""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    # 失敗したときに前の問題の in.txt が残って使われないよう、先に消しておく
    (ROOT / "in.txt").unlink(missing_ok=True)
    src = Path(sys.argv[1]).resolve()
    idx = int(sys.argv[2])
    prob = ROOT / ".cph" / f".{src.name}_{hashlib.md5(str(src).encode()).hexdigest()}.prob"
    if not prob.is_file():
        print(f"error: {src.name} のテストケースが見つかりません ({prob.name})。Competitive Companion で受け取ったファイルですか?", file=sys.stderr)
        return 1
    tests = json.loads(prob.read_text(encoding="utf-8")).get("tests", [])
    if not 1 <= idx <= len(tests):
        print(f"error: ケース番号は 1〜{len(tests)} です", file=sys.stderr)
        return 1
    t = tests[idx - 1]
    (ROOT / "in.txt").write_text(t.get("input", ""), encoding="utf-8")
    print(f"--- case {idx}/{len(tests)} の入力を in.txt に書きました ---")
    print(t.get("input", ""), end="" if t.get("input", "").endswith("\n") else "\n")
    print("--- 期待する出力 ---")
    print(t.get("output", ""), end="" if t.get("output", "").endswith("\n") else "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
