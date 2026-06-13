#!/usr/bin/env python3
"""
ping_check.py — Ping multiple hosts and log results
IT Support Automation Toolkit
Works on: Windows, Linux, macOS

Usage:
    python ping_check.py
    python ping_check.py --hosts 192.168.1.1 google.com 8.8.8.8
    python ping_check.py --file hosts.txt --export --count 5
"""

import subprocess
import platform
import argparse
import datetime
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

# ── Default host list (edit for your network) ────────────────
DEFAULT_HOSTS = [
    "8.8.8.8",           # Google DNS
    "1.1.1.1",           # Cloudflare DNS
    "google.com",        # Public internet
    "192.168.1.1",       # Common default gateway
]

def ping(host: str, count: int = 4) -> dict:
    """Ping a host and return result dict."""
    system = platform.system().lower()

    if system == "windows":
        cmd = ["ping", "-n", str(count), "-w", "1000", host]
    else:
        cmd = ["ping", "-c", str(count), "-W", "2", host]

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=count * 3
        )
        output = result.stdout.decode(errors="replace")
        success = result.returncode == 0

        # Parse avg latency
        latency = "—"
        if success:
            if system == "windows":
                for line in output.splitlines():
                    if "Average" in line:
                        parts = line.split("=")
                        if len(parts) >= 2:
                            latency = parts[-1].strip()
            else:
                for line in output.splitlines():
                    if "avg" in line or "rtt" in line:
                        try:
                            latency = line.split("/")[4] + " ms"
                        except IndexError:
                            pass

        return {
            "host":    host,
            "status":  "UP" if success else "DOWN",
            "latency": latency,
            "raw":     output
        }
    except subprocess.TimeoutExpired:
        return {"host": host, "status": "TIMEOUT", "latency": "—", "raw": ""}
    except Exception as e:
        return {"host": host, "status": "ERROR", "latency": "—", "raw": str(e)}


def print_result(r: dict):
    """Print a single result with color."""
    status = r["status"]
    if status == "UP":
        color, icon = "\033[92m", "✔"   # green
    elif status == "DOWN":
        color, icon = "\033[91m", "✖"   # red
    else:
        color, icon = "\033[93m", "!"   # yellow

    reset = "\033[0m"
    print(f"  {color}[{icon}] {r['host']:<30} {status:<8}  {r['latency']}{reset}")


def main():
    parser = argparse.ArgumentParser(description="IT Support Ping Checker")
    parser.add_argument("--hosts",  nargs="+", help="Hosts/IPs to ping")
    parser.add_argument("--file",   help="Text file with one host per line")
    parser.add_argument("--count",  type=int, default=4, help="Ping count per host (default: 4)")
    parser.add_argument("--export", action="store_true", help="Save results to a log file")
    parser.add_argument("--threads",type=int, default=10, help="Parallel threads (default: 10)")
    args = parser.parse_args()

    # ── Build host list
    hosts = []
    if args.hosts:
        hosts = args.hosts
    elif args.file:
        if not os.path.exists(args.file):
            print(f"[✖] File not found: {args.file}")
            sys.exit(1)
        with open(args.file) as f:
            hosts = [l.strip() for l in f if l.strip() and not l.startswith("#")]
    else:
        hosts = DEFAULT_HOSTS

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"\n{'═'*50}")
    print(f"  Ping Check — {timestamp}")
    print(f"  Hosts: {len(hosts)}  |  Threads: {args.threads}  |  Count: {args.count}")
    print(f"{'═'*50}\n")

    results = []
    with ThreadPoolExecutor(max_workers=args.threads) as executor:
        futures = {executor.submit(ping, h, args.count): h for h in hosts}
        for future in as_completed(futures):
            r = future.result()
            results.append(r)
            print_result(r)

    # ── Summary
    up   = sum(1 for r in results if r["status"] == "UP")
    down = len(results) - up
    print(f"\n  UP: {up}  |  DOWN/TIMEOUT: {down}  |  Total: {len(results)}")

    # ── Export
    if args.export:
        fname = f"ping_report_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        with open(fname, "w") as f:
            f.write(f"Ping Check Report — {timestamp}\n")
            f.write(f"{'='*50}\n")
            for r in sorted(results, key=lambda x: x["status"]):
                f.write(f"{r['host']:<30} {r['status']:<8}  {r['latency']}\n")
            f.write(f"\nUP: {up} | DOWN: {down} | Total: {len(results)}\n")
        print(f"\n[✔] Report saved: {fname}")

    print()
    return 0 if down == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
