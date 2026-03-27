#!/usr/bin/env python3
import argparse
import csv
import glob
import json
from collections import defaultdict
from datetime import datetime, timedelta, timezone


def parse_time(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def load_events(events_dir: str, days: int):
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    events = []
    for path in glob.glob(f"{events_dir}/*.json"):
        with open(path, "r", encoding="utf-8") as f:
            obj = json.load(f)
        ts_raw = obj.get("timestamp")
        if not ts_raw:
            continue
        ts = parse_time(ts_raw)
        if ts < cutoff:
            continue
        obj["_ts"] = ts
        events.append(obj)
    events.sort(key=lambda x: x["_ts"])
    return events


def build_timeseries(events):
    by_day = defaultdict(lambda: {"success": 0, "failed": 0, "incident": 0, "restore": 0})
    for e in events:
        day = e["_ts"].date().isoformat()
        et = e.get("event_type", "")
        st = e.get("status", "")
        if et == "deployment":
            if st == "success":
                by_day[day]["success"] += 1
            elif st == "failed":
                by_day[day]["failed"] += 1
        elif et == "incident":
            by_day[day]["incident"] += 1
        elif et == "restore":
            by_day[day]["restore"] += 1

    rows = []
    for day in sorted(by_day.keys()):
        r = by_day[day]
        total = r["success"] + r["failed"]
        cfr = round((r["failed"] / total * 100.0), 2) if total else 0.0
        rows.append(
            {
                "date": day,
                "deploy_success": r["success"],
                "deploy_failed": r["failed"],
                "change_failure_rate_percent": cfr,
                "incident_count": r["incident"],
                "restore_count": r["restore"],
            }
        )
    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--events-dir", default="dora/weekly-input")
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--out-json", default="dora/reports/dora-timeseries.json")
    parser.add_argument("--out-csv", default="dora/reports/dora-timeseries.csv")
    args = parser.parse_args()

    events = load_events(args.events_dir, args.days)
    rows = build_timeseries(events)

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "window_days": args.days,
        "event_count": len(events),
        "rows": rows,
    }

    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    with open(args.out_csv, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "date",
                "deploy_success",
                "deploy_failed",
                "change_failure_rate_percent",
                "incident_count",
                "restore_count",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote: {args.out_json}")
    print(f"Wrote: {args.out_csv}")


if __name__ == "__main__":
    main()
