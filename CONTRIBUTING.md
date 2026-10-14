# Contributing to BusSense AI

Welcome to the **BusSense AI** engineering repository. This document outlines development standards, branch naming, commit formatting, testing requirements, and pull request procedures.

---

## 1. Code of Conduct & Core Philosophy

BusSense AI is built around the ethos of **"Less UI, More Design"** and **"Privacy by Design"**.
- We never process or store facial biometrics or passenger identities.
- We never present synthetic simulations as live ground-truth telemetry.
- We write clean, typed, modular code with thorough test coverage.

---

## 2. Environment Setup

### Prerequisites
- Python 3.11+ (Python 3.14 tested and supported)
- Node.js 18+ & npm
- Git
- Access to Supabase Project `lqegmqgkymstycpzplld` or a local PostgreSQL instance

### Quick Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Antony0610/Bus_Sense_AI.git
   cd Bus_Sense_AI
   ```

2. **Backend Setup:**
   ```bash
   cd backend
   python -m venv .venv
   # Windows PowerShell:
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```

3. **Frontend Setup:**
   ```bash
   cd ../frontend
   npm install
   ```

4. **Environment Variables:**
   Copy `.env.example` to `.env` in the project root:
   ```bash
   cp .env.example .env
   ```

---

## 3. Branching & Commit Conventions

### Branch Naming
- `feat/feature-name` (e.g., `feat/offline-qr-validation`)
- `fix/bug-description` (e.g., `fix/gps-interpolator-heading`)
- `docs/documentation-topic` (e.g., `docs/add-api-specs`)
- `perf/optimization` (e.g., `perf/yolo-frame-skipping`)

### Commit Messages
Follow Conventional Commits:
```
<type>(<scope>): <short description>

[optional body]
```
Examples:
- `feat(cv): implement 3-tier crowd density classifier`
- `fix(tickets): handle expired boarding pass error state`
- `docs(db): document route_stops indexing strategy`

---

## 4. Testing Standards

Every pull request must include tests demonstrating that new or modified functionality works.

### Running Backend Tests
```bash
cd backend
pytest tests/ -v
```

### Running Frontend Typechecks & Build
```bash
cd frontend
npm run build
```

---

## 5. Pull Request Checklist

Before submitting a PR, verify:
- [ ] Code follows existing architectural patterns in `backend/app/services` and `frontend/app`.
- [ ] No hardcoded API keys, JWT secrets, or production passwords in code or commits.
- [ ] New endpoints are documented in `/docs/API.md`.
- [ ] New database schemas include an idempotent migration script in `backend/migrations/` and documentation in `/docs/DATABASE.md`.
- [ ] Synthetic or simulated data is labeled with appropriate truth badges.
- [ ] All automated tests pass without warnings or failures.
- [ ] `/docs/CHANGELOG.md` is updated under the `[Unreleased]` section.
