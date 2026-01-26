import asyncio
import aiohttp
import time
import statistics
import os

# Configuration
BASE_URL = "http://127.0.0.1:8001"
SECURITY_REPORT_PATH = "test_reports/security_report.txt"
PERF_REPORT_PATH = "test_reports/performance_report.txt"
STRESS_REPORT_PATH = "test_reports/stress_report.txt"

async def check_security():
    print("Running Security Check...")
    r_check = []
    
    # 1. Check CORS / Debug
    # Note: We can't really check "debug mode" from outside unless it leaks traceback, causing 500 error on purpose.
    # We will check if we can access swagger docs
    async with aiohttp.ClientSession() as session:
        # Check Swagger
        async with session.get(f"{BASE_URL}/docs") as resp:
            if resp.status == 200:
                r_check.append("INFO: Swagger UI is accessible at /docs (Common in dev, should be disabled in strict prod).")
            else:
                 r_check.append("PASS: Swagger UI is hidden/protected.")
        
        # Check Open Endpoint
        async with session.get(f"{BASE_URL}/patients/") as resp:
             if resp.status == 401:
                 r_check.append("PASS: /patients/ endpoint is protected (401 Unauthorized).")
             else:
                 r_check.append(f"FAIL: /patients/ endpoint returned {resp.status} without auth!")
    
    with open(SECURITY_REPORT_PATH, "w") as f:
        f.write("\n".join(r_check))
    print("Security Check Done.")

async def run_load_test(name, count, concurrency, report_path):
    print(f"Running {name} ({count} reqs, {concurrency} concurrency)...")
    
    # Login bypass: Generate token locally
    print("Generating local admin token...")
    try:
        from jose import jwt
        from datetime import datetime, timedelta
        
        SECRET_KEY = "fallback_secret_only_for_dev_warning"
        ALGORITHM = "HS256"
        
        expire = datetime.utcnow() + timedelta(minutes=30)
        to_encode = {"sub": "admin", "exp": expire}
        token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    except ImportError:
        print("SKIP: python-jose not installed.")
        return
    except Exception as e:
        print(f"SKIP: Token generation failed: {e}")
        return

    headers = {"Authorization": f"Bearer {token}"}
    latencies = []
    errors = 0
    
    start_time = time.time()
    
    async def fetch(session):
        nonlocal errors
        try:
            t1 = time.time()
            async with session.get(f"{BASE_URL}/patients", headers=headers) as resp:
                await resp.read()
                t2 = time.time()
                latencies.append((t2 - t1) * 1000) # ms
                if resp.status != 200:
                    errors += 1
        except Exception:
            errors += 1

    conn = aiohttp.TCPConnector(limit=concurrency)
    async with aiohttp.ClientSession(connector=conn) as session:
        tasks = [fetch(session) for _ in range(count)]
        await asyncio.gather(*tasks)
        
    total_time = time.time() - start_time
    
    # Analyze
    avg_lat = statistics.mean(latencies) if latencies else 0
    max_lat = max(latencies) if latencies else 0
    p95_lat = sorted(latencies)[int(len(latencies)*0.95)] if latencies else 0
    rps = count / total_time if total_time > 0 else 0
    
    report = f"""
{name} Report
======================
Total Requests: {count}
Concurrency: {concurrency}
Total Time: {total_time:.2f}s
RPS: {rps:.2f}
Errors: {errors}

Latency (ms):
  Avg: {avg_lat:.2f}
  Max: {max_lat:.2f}
  P95: {p95_lat:.2f}
"""
    with open(report_path, "w") as f:
        f.write(report)
    print(f"{name} Done.")

async def main():
    if not os.path.exists("test_reports"):
        os.makedirs("test_reports")
        
    await check_security()
    await run_load_test("Performance Test", 50, 5, PERF_REPORT_PATH) # Normal Load
    await run_load_test("Stress Test", 500, 50, STRESS_REPORT_PATH) # High Load

if __name__ == "__main__":
    asyncio.run(main())
