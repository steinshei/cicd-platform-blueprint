#!/usr/bin/env python3
import argparse
import json
import os
import sys


def fmt(v, nd=2):
    if v is None:
        return "n/a"
    return f"{round(v, nd)}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report-json", required=True)
    parser.add_argument("--max-cfr", type=float, default=15.0)
    parser.add_argument("--max-mttr-hours", type=float, default=0.5)
    parser.add_argument("--min-successful-deploys", type=int, default=1)
    parser.add_argument("--out-md", default="dora/reports/kpi-check.md")
    args = parser.parse_args()

    with open(args.report_json, "r", encoding="utf-8") as f:
        report = json.load(f)

    m = report["metrics"]
    cfr = m["change_failure_rate_percent"]
    mttr = m["mttr_hours"]["average"]
    deploys = m["deployment_frequency_7d"]["total_successful_deployments"]

    checks = [
        ("Change Failure Rate", cfr, f"<= {args.max_cfr}%", cfr <= args.max_cfr),
        (
            "MTTR",
            mttr,
            f"<= {args.max_mttr_hours}h",
            (mttr is None) or (mttr <= args.max_mttr_hours),
        ),
        (
            "Successful Deployments (7d)",
            deploys,
            f">= {args.min_successful_deploys}",
            deploys >= args.min_successful_deploys,
        ),
    ]

    ok = all(x[3] for x in checks)
    status = "PASS" if ok else "FAIL"

    os.makedirs(os.path.dirname(args.out_md), exist_ok=True)
    with open(args.out_md, "w", encoding="utf-8") as f:
        f.write(f"# DORA KPI Gate: {status}\n\n")
        f.write(f"- report: `{args.report_json}`\n")
        f.write(f"- window_days: `{report.get('window_days')}`\n")
        f.write(f"- event_count: `{report.get('event_count')}`\n\n")
        f.write("| KPI | Actual | Target | Result |\n")
        f.write("|---|---:|---:|:---:|\n")
        for name, actual, target, passed in checks:
            actual_s = fmt(actual) if isinstance(actual, float) or actual is None else str(actual)
            f.write(f"| {name} | {actual_s} | {target} | {'PASS' if passed else 'FAIL'} |\n")

    print(f"KPI Gate: {status}")
    print(f"Wrote: {args.out_md}")
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
