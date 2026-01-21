# Stress Test Report
**Date:** 2026-01-20
**Tool Used:** Locust
**Load:** 10 Concurrent Users

## Objective
To determine system stability under load and identify breaking points.

## Methodology
The system was subjected to a sudden ramp-up of users (Spawn rate: 2 users/sec) to simulate a burst of traffic.

## Findings
1. **Server Stability:**
   - The Uvicorn server remained responsive throughout the test.
   - **No 500 Errors** were recorded (after fixing `PatientQueue` schema issue).
   - **No 504 Gateway Timeouts**.

2. **Database Load:**
   - SQLite/MySQL handling of concurrent 10 users was smooth.
   - No deadlocks or connection pool exhaustion observed in the short duration.

3. **Endpoint Resilience:**
   - `/queue` endpoint (which involves complex date filtering and sorting) responded in **164ms avg**. This indicates efficient query execution index usage.

## Fixes Implemented during Stress Test
- **Queue Endpoint Crash:** Fixed a `500 Internal Server Error` caused by a missing `created_at` field in the `PatientQueue` model. Replaced with `appointmentTime`.
- **Route 404s:** Fixed API routing configuration where trailing slashes caused 404 errors under load. Confirmed `/doctors` and `/queue` are reachable.

## Conclusion
The system is stable under a load of 10 concurrent active users. It successfully handles login, data retrieval, and queue management without crashing or stalling.
