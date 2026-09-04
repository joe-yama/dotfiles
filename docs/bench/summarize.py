#!/usr/bin/env python3
"""results/*_r{1,2}.json を集計して Markdown 表を出す。"""
import glob, json, os, re, statistics, sys

S = os.path.dirname(os.path.abspath(__file__))
files = sorted(glob.glob(os.path.join(S, "results", "*_r[0-9].json")))
arms = {}
for f in files:
    r = json.load(open(f))
    m = re.search(r"_r(\d)\.json$", f)
    arms.setdefault(r["arm"], {})[int(m.group(1))] = r


def fmt(x, nd=1):
    return "-" if x is None else (f"{x:.{nd}f}" if isinstance(x, (int, float)) else str(x))


def mem_gb(r):
    m = r.get("memory_after_warmup") or {}
    best = None
    for pid, v in m.items():
        if not isinstance(v, dict) or "rss_gb" not in v:
            continue
        fp = mapped = None
        for l in v.get("footprint_lines", []):
            if l.strip().startswith("phys_footprint:"):
                fp = l.split(":")[1].strip()
            if l.strip().endswith("mapped file"):
                mapped = l.split()[2] + " " + l.split()[3]
        best = f"dirty(wired) {fp} + mapped-clean {mapped} (RSS {v['rss_gb']} GB)"
    return best or "-"


print("## 速度 (decode tok/s、各周は 3 run の中央値; short=thinking on, long=thinking off ≈24k tokens)\n")
print("| arm | short R1 / R2 | prefill short R1 / R2 | TTFT R1 / R2 | long decode R1 / R2 | long prefill R1 / R2 | NIAH hit | memory after warmup (R1) |")
print("|---|---|---|---|---|---|---|---|")
for arm, rounds in arms.items():
    def pick(test, key):
        return " / ".join(fmt(rounds[k]["tests"].get(test, {}).get(key)) for k in sorted(rounds))
    niah = "/".join(f"{rounds[k]['tests'].get('long', {}).get('niah_in_content', '-')}of{len(rounds[k]['tests'].get('long', {}).get('runs', []))}" for k in sorted(rounds))
    r1 = rounds[min(rounds)]
    print(f"| {arm} | {pick('short','median_decode')} | {pick('short','median_prefill')} | {pick('short','median_ttft')} | {pick('long','median_decode')} | {pick('long','median_prefill')} | {niah} | {mem_gb(r1)} |")

print("\n## 品質・機能 (thinking off)\n")
print("| arm | tools passed (R1 / R2) | XML leak | code passed (R1 / R2) | ja ratio / loop / U+FFFD (R1 / R2) | warmup load+1st req s (R1 / R2) |")
print("|---|---|---|---|---|---|")
for arm, rounds in arms.items():
    tools = " / ".join(f"{rounds[k]['tests'].get('tools',{}).get('passed','-')}/{rounds[k]['tests'].get('tools',{}).get('total','-')}" for k in sorted(rounds))
    leak = " / ".join(str(rounds[k]['tests'].get('tools',{}).get('xml_leaks','-')) for k in sorted(rounds))
    code = " / ".join(f"{rounds[k]['tests'].get('code',{}).get('passed','-')}/{rounds[k]['tests'].get('code',{}).get('total','-')}" for k in sorted(rounds))
    ja = " / ".join((lambda c: f"{c.get('ja_ratio','-')} {'LOOP' if c.get('loop_suspect') else 'ok'} {c.get('replacement_chars','-')}")(rounds[k]['tests'].get('ja',{}).get('check',{})) for k in sorted(rounds))
    warm = " / ".join(fmt(rounds[k].get('warmup',{}).get('load_plus_first_request_s')) for k in sorted(rounds))
    print(f"| {arm} | {tools} | {leak} | {code} | {ja} | {warm} |")

print("\n## 個別 run (short decode / long decode)\n")
for arm, rounds in arms.items():
    for k in sorted(rounds):
        sh = [r["decode_tok_s"] for r in rounds[k]["tests"].get("short", {}).get("runs", [])]
        lg = [r["decode_tok_s"] for r in rounds[k]["tests"].get("long", {}).get("runs", [])]
        lp = [r["prompt_tokens"] for r in rounds[k]["tests"].get("long", {}).get("runs", [])]
        st = [ (r.get("server_timings") or {}).get("predicted_per_second") for r in rounds[k]["tests"].get("short", {}).get("runs", [])]
        print(f"- {arm} R{k}: short {sh} (server timings {[round(x,1) if x else None for x in st]}), long {lg} @ prompt_tokens {lp}")
