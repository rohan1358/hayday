"""Summarize Kebun Ceria's read-only Godot Android logcat samples.

Usage: py -3 tools/analyze_android_perf.py build/qa-programmer-v24/adb-perf-snapshot.log
       py -3 tools/analyze_android_perf.py <log> --pid 6354

The default PID is the one with the LAST KEBUN_PERF line in the input.
Session separation is important: a logcat buffer may contain multiple APK runs.
"""

import argparse
import re
import statistics
from pathlib import Path

LOG_LINE = re.compile(r"\bI/godot\s*\(\s*(\d+)\):\s+KEBUN_(PERF|TICK|DRAW|ANIM|LAYER_PROBE)\s+(.*)")
FIELD = re.compile(r"([a-z_]+)=([^\s]+)")
METRICS = {
    "PERF": ("fps", "process_ms", "draw_calls", "static_mb"),
    "TICK": ("avg_ms", "ujang", "camera", "scenery", "static", "actors", "plots"),
    "DRAW": ("total_ms", "landscape", "buildings", "plots", "misc"),
    "ANIM": ("avg_ms", "setup_ms", "preactor_ms", "fx_ms"),
}


def parse_records(content):
    """Only parse app-specific diagnostics; no private/system log data."""
    records = []
    for line in content.splitlines():
        match = LOG_LINE.search(line)
        if not match:
            continue
        pid, kind, rest = match.groups()
        values = dict(FIELD.findall(rest))
        records.append({"pid": int(pid), "kind": kind, "values": values})
    return records


def choose_pid(records, requested=None):
    if requested is not None:
        if not any(item["pid"] == requested for item in records):
            raise ValueError("PID %d tidak ada dalam log diagnostik" % requested)
        return requested
    for item in reversed(records):
        if item["kind"] == "PERF":
            return item["pid"]
    if records:
        return records[-1]["pid"]
    raise ValueError("Tidak ditemukan log KEBUN_* dari proses Godot")


def percentile(values, portion):
    ordered = sorted(values)
    if not ordered:
        raise ValueError("Sampel kosong")
    pos = (len(ordered) - 1) * portion
    lower = int(pos)
    upper = min(lower + 1, len(ordered) - 1)
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (pos - lower)


def summarize(records, pid):
    selected = [item for item in records if item["pid"] == pid]
    summary = {"pid": pid, "total": len(selected), "metrics": {}, "probes": []}
    for kind, fields in METRICS.items():
        by_metric = {}
        group = [item["values"] for item in selected if item["kind"] == kind]
        for field in fields:
            values = []
            for data in group:
                try:
                    values.append(float(data[field]))
                except (KeyError, ValueError):
                    continue
            if values:
                by_metric[field] = {
                    "n": len(values), "min": min(values),
                    "median": statistics.median(values),
                    "p90": percentile(values, 0.90), "max": max(values),
                }
        summary["metrics"][kind] = by_metric
    for item in selected:
        if item["kind"] != "LAYER_PROBE":
            continue
        values = item["values"]
        if "mode" not in values:
            continue
        try:
            summary["probes"].append({
                "mode": values["mode"],
                "fps": float(values["fps"]),
                "draw_calls": float(values["draw_calls"]),
                "process_ms": float(values["process_ms"]),
                "samples": int(values["samples"]),
            })
        except (KeyError, ValueError):
            continue
    return summary


def markdown(summary):
    lines = ["# Ringkasan log Android (PID %d)" % summary["pid"], "",
             "Hanya log KEBUN_* dari PID terpilih; nilai p90 dihitung dari sampel yang tersedia.", "",
             "| Sumber | Metrik | N | Min | Median | P90 | Maks |",
             "| --- | --- | ---: | ---: | ---: | ---: | ---: |"]
    for kind, metrics in summary["metrics"].items():
        for name, values in metrics.items():
            lines.append("| %s | %s | %d | %.2f | %.2f | %.2f | %.2f |" % (
                kind, name, values["n"], values["min"], values["median"],
                values["p90"], values["max"]))
    if summary["probes"]:
        lines.extend(["", "| Probe (urut sesuai log) | FPS rata-rata | Draw calls | Process ms | Sampel |",
                      "| --- | ---: | ---: | ---: | ---: |"])
        for probe in summary["probes"]:
            lines.append("| %s | %.1f | %.1f | %.1f | %d |" % (
                probe["mode"], probe["fps"], probe["draw_calls"],
                probe["process_ms"], probe["samples"]))
    lines.extend(["", "Catatan: FPS adalah sampling Godot; waktu process_ms bukan GPU frame time. "
                  "Phase probe berurutan dan tidak diacak, sehingga perbedaannya hanya indikasi."])
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    parser.add_argument("--pid", type=int, help="Pisahkan sesi berdasarkan PID")
    parser.add_argument("--out", type=Path, help="Simpan ringkasan Markdown")
    args = parser.parse_args()
    records = parse_records(args.log.read_text(encoding="utf-8-sig", errors="replace"))
    report = markdown(summarize(records, choose_pid(records, args.pid)))
    if args.out:
        args.out.write_text(report, encoding="utf-8")
    else:
        print(report, end="")


if __name__ == "__main__":
    main()
