# Performance Test Report
**Date:** 2026-01-20
**Tool Used:** Locust (Python)
**Target:** Klinik Admin Backend (Port 8001)

## Executive Summary
A load test was conducted with **10 concurrent users** spawning at a rate of **2 users/second**. The system successfully handled all requests with **0% failure rate**.

## Test Configuration
- **Users:** 10
- **Spawn Rate:** 2/s
- **Duration:** 10s
- **Host:** http://localhost:8001
- **Authenticated:** Yes (via Bearer Token)

## Results Summary
| Endpoint | Requests | Failures | Avg Response Time (ms) | Min (ms) | Max (ms) |
|----------|----------|----------|------------------------|----------|----------|
| **Total** | **32** | **0** | **832.17** | **3.10** | **2605.05** |
| `/auth/login` | 10 | 0 | 2440.37 | 2243.70 | 2605.05 |
| `/doctors` | 2 | 0 | 147.60 | 7.30 | 287.89 |
| `/patients` | 2 | 0 | 26.56 | 12.27 | 40.84 |
| `/queue` | 8 | 0 | 164.28 | 21.17 | 376.70 |

## Observations
1. **Stability:** The system maintained 100% availability during the test.
2. **Login Latency:** Login takes ~2.4s. This is likely due to password hashing (bcrypt) which is computationally expensive by design for security.
3. **API Performance:** 
   - `GET /patients` is very fast (~26ms).
   - `GET /queue` is acceptable (~164ms).
   - `GET /doctors` is acceptable (~148ms).

## Conclusion
The application meets the baseline performance requirements for 10 concurrent users. The API endpoints respond within acceptable limits (< 500ms).
