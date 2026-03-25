# DORA Weekly Report Generator
#!/usr/bin/env python3
import argparse
import glob
import json
import os
import subprocess
from collections import defaultdict
from datetime import datetime, timedelta, timezone


def parse_time(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def load_events(path_glob: str, since_days: int):
    cutoff = datetime.now(timezone.utc) - timedelta(days=since_days)
    events = []
    for path in glob.glob(path_glob):
        with open(path, "r", encoding="utf-8") as f:
            obj = json.load(f)
        if "timestamp" not in obj:
            continue
        ts = parse_time(obj["timestamp"])
        if ts >= cutoff:
            obj["_ts"] = ts
            events.append(obj)
    return sorted(events, key=lambda x: x["_ts"])


def git_commit_time(version: str):
    if not version:
        return None
    if len(version) < 7:
        return None
    try:
        out = subprocess.check_output(
            ["git", "show", "-s", "--format=%cI", version],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        if not out:
            return None
        return parse_time(out)
    except Exception:
        return None


def calc_metrics(events):
    deployments = [e for e in events if e.get("event_type") == "deployment"]
    deploy_success = [e for e in deployments if e.get("status") == "success"]
    deploy_failed = [e for e in deployments if e.get("status") == "failed"]

    lead_times = []
    for e in deploy_success:
        commit_time = git_commit_time(e.get("version", ""))
        if commit_time:
            lead_times.append((e["_ts"] - commit_time).total_seconds() / 3600.0)

    incidents = defaultdict(list)
    restores = defaultdict(list)
    for e in events:
        key = f"{e.get('service','unknown')}::{e.get('environment','unknown')}"
        if e.get("event_type") == "incident":
            incidents[key].append(e["_ts"])
        if e.get("event_type") == "restore":
            restores[key].append(e["_ts"])

    mttr_hours = []
    for key, inc_list in incidents.items():
        rs = sorted(restores.get(key, []))
        for inc in sorted(inc_list):
            after = [r for r in rs if r >= inc]
            if after:
                mttr_hours.append((after[0] - inc).total_seconds() / 3600.0)

    by_env = defaultdict(int)
    for e in deploy_success:
        by_env[e.get("environment", "unknown")] += 1

    total_deploy = len(deployments)
    cfr = (len(deploy_failed) / total_deploy * 100.0) if total_deploy else 0.0
    lead_avg = (sum(lead_times) / len(lead_times)) if lead_times else None
    mttr_avg = (sum(mttr_hours) / len(mttr_hours)) if mttr_hours else None

    return {
        "deployment_frequency_7d": {
            "total_successful_deployments": len(deploy_success),
            "by_environment": dict(by_env),
        },
        "lead_time_for_changes_hours": {
            "average": lead_avg,
            "sample_count": len(lead_times),
        },
        "mttr_hours": {"average": mttr_avg, "sample_count": len(mttr_hours)},
        "change_failure_rate_percent": round(cfr, 2),
        "deployment_totals": {
            "all": total_deploy,
            "failed": len(deploy_failed),
            "successful": len(deploy_success),
        },
    }


def to_markdown(repo: str, days: int, metrics: dict, event_count: int) -> str:
    lt = metrics["lead_time_for_changes_hours"]["average"]
    mttr = metrics["mttr_hours"]["average"]
    return "\n".join(
        [
            f"# DORA Weekly Report ({days}d)",
            "",
            f"- Repository: `{repo}`",
            f"- Events analyzed: `{event_count}`",
            "",
            "## Core Metrics",
            f"- Lead Time for Changes (avg, hours): `{round(lt, 2) if lt is not None else 'n/a'}`",
            f"- Deployment Frequency (7d successful): `{metrics['deployment_frequency_7d']['total_successful_deployments']}`",
            f"- MTTR (avg, hours): `{round(mttr, 2) if mttr is not None else 'n/a'}`",
            f"- Change Failure Rate (%): `{metrics['change_failure_rate_percent']}`",
            "",
            "## Deployment Frequency by Environment",
            f"- dev: `{metrics['deployment_frequency_7d']['by_environment'].get('dev', 0)}`",
            f"- staging: `{metrics['deployment_frequency_7d']['by_environment'].get('staging', 0)}`",
            f"- prod: `{metrics['deployment_frequency_7d']['by_environment'].get('prod', 0)}`",
            "",
            "## Notes",
            "- Lead Time uses commit timestamp inferred from deployment `version` when it matches a git commit.",
            "- MTTR requires paired `incident` and `restore` events in the same service/environment.",
        ]
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--events-dir", default="dora/weekly-input")
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--out-json", default="dora/reports/weekly-report.json")
    parser.add_argument("--out-md", default="dora/reports/weekly-report.md")
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.out_json), exist_ok=True)
    os.makedirs(os.path.dirname(args.out_md), exist_ok=True)

    events = load_events(f"{args.events_dir}/*.json", args.days)
    metrics = calc_metrics(events)
    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "window_days": args.days,
        "event_count": len(events),
        "repository": os.environ.get("GITHUB_REPOSITORY", "local/local"),
        "metrics": metrics,
    }

    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    with open(args.out_md, "w", encoding="utf-8") as f:
        f.write(to_markdown(payload["repository"], args.days, metrics, len(events)))

    print(f"Wrote: {args.out_json}")
    print(f"Wrote: {args.out_md}")


if __name__ == "__main__":
    main()
