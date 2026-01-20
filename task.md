# Task Checklist

## 1. Security Audit & Fixes
- [x] Run Bandit scan on backend
- [x] Fix critical vulnerabilities (timeouts, silent errors)
- [x] Generate vulnerability report

## 2. Automated Login Testing
- [x] Install Playwright & dependencies
- [x] Create automation script (`login_automation.py`) with 9 scenarios
- [x] Implement robust selectors for Flutter Web
- [x] Add Word report generation with Pass/Fail status
- [x] Validate against local Flutter app

## 3. ERPNext Integration (Local Setup)
- [x] Configure Environment (WSL, Python, Node.js)
- [x] Install Frappe Bench & ERPNext
- [x] Connect Backend to ERPNext
- [x] Install Healthcare Module
- [x] Sync Existing Data
- [x] Resolve Port Conflict (8000 -> 8001)

## 4. Feature Enhancements
- [x] Daily Queue Cleanup (Filter & Lazy Reset)
- [x] Implement Medicine Concoctions (Racikan) Feature
- [x] Integrate Kafka (KRaft Mode setup)
- [x] Refactor Table Names (*core suffix) & Migrate Data
- [x] Seed Patient Vitals (Height/Weight)
- [x] Update Dependencies (flutter_tts ^4.2.5)
- [x] Implement General Payment Sub-methods (Cash, QRIS, etc.)
- [x] Sync Patients to SatuSehat (Sandbox)
- [x] Sync Doctors to SatuSehat (Practitioner)

## 5. Documentation
- [x] Update Implementation History
- [x] Update Vulnerability Report

## 6. Comprehensive Testing
- [x] Security & Vulnerability Test (Bandit)
- [x] Performance & Stress Test (Locust)
- [x] Fix Identified Issues (Routes, 500 Error, Auth, Port Conflict)
- [x] Generate Test Reports
