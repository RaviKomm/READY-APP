# Week 5 — Ready: Containerized Health & Readiness Application

**Author:** Ravi Chandra  
**Assignment:** Week 5 — Infrastructure as Code & Repository Hygiene  
**Course:** Cloud Systems Programming (Week 5)

---

## 🧩 Overview
This project demonstrates a **laptop-first, containerized FastAPI + PostgreSQL stack** managed using **Docker Compose**.  
It aligns with the principles of Infrastructure-as-Code (IaC) and secure, reproducible deployment practices.

### Objectives
✅ Implement `/health` (fast) and `/ready` (dependency-aware) endpoints  
✅ Apply environment layering (`.env.example` vs `.env`)  
✅ Use Docker Compose profiles (`dev` and `prod`)  
✅ Run as non-root user and handle graceful shutdown  
✅ Capture five evidence proxies:  
- Image size  
- Time-to-healthy  
- p95 burst latency  
- Docker stats snapshot  
- RTO (restart → /ready)

---

## 📁 Repository Structure

```
WEEK5-Ready/
├─ app/
│  ├─ Dockerfile
│  ├─ main.py
│  └─ requirements.txt
├─ scripts/
│  ├─ burst_test.py
│  ├─ measure_rto.sh
│  └─ docker_stats_snapshot.sh
├─ docker-compose.yml
├─ .env.example
└─ README.md
```

---

## ⚙️ Prerequisites

- **Docker Desktop** installed and running  
- **Git Bash** (recommended) or PowerShell/CMD  
- **Python 3.8+** (for running the burst test script)  
- Optional: `hey` or `wrk` load-testing tools  

---

## 🌱 Step 1: Environment Layering

Before running the stack, you must create a `.env` file based on the example template.

### `.env.example`
```bash
DATABASE_URL=postgresql://app:dev@db:5432/appdb
API_PORT=8000
```

### Commands
```bash
# On Git Bash / Linux / macOS
cp .env.example .env

# On Windows CMD
copy .env.example .env
```

**Note:** Never commit `.env` with real credentials. Only `.env.example` should be tracked.

---

## 🧱 Step 2: Docker Compose Profiles

Two profiles are available: `dev` and `prod`.

- **dev** → exposes ports to localhost, suitable for development  
- **prod** → no host port exposure, internal-only networking

### Run Commands
```bash
# Development mode
docker compose --profile dev up --build -d

# Production mode
docker compose --profile prod up --build -d
```

### Stop Containers
```bash
docker compose down
```

To remove volumes too:
```bash
docker compose down -v
```

---

## 🚀 Step 3: Build and Run the Stack

```bash
# Ensure .env is ready
cp .env.example .env

# Start the services
docker compose --profile dev up --build -d

# Verify containers are running
docker ps

# View logs
docker compose logs -f api
```

---

## 🩺 Step 4: Health & Readiness Endpoints

### `/health`
- Lightweight check to confirm that the API container is running.  
- No external dependencies involved.

**Example response:**
```json
{"status": "ok"}
```

### `/ready`
- Confirms that the database connection is healthy and pool is ready.

**Example response:**
```json
{"ready": true}
```

**When DB isn’t ready:**
```json
{"detail": "db-pool-not-created"}
```

### Check endpoints manually:
```bash
curl http://localhost:8000/health
curl http://localhost:8000/ready
```

---

## 🔒 Step 5: Non-Root Container & Graceful Shutdown

### Dockerfile excerpt
```dockerfile
FROM python:3.11-slim
RUN useradd -m app
WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir -r requirements.txt
USER app
CMD ["uvicorn","main:app","--host","0.0.0.0","--port","8000"]
```

### Graceful Shutdown Example (main.py)
```python
@app.on_event("shutdown")
async def shutdown():
    if POOL:
        await POOL.close()
    await asyncio.sleep(0.01)
```

This ensures:
- Containers don’t run as root.  
- Database connections close gracefully during shutdown.

---

## 📊 Step 6: Evidence Proxies

### 1️⃣ Image Size
```bash
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```
Record output like:
```
REPOSITORY     TAG       SIZE
week5-api      latest    122MB
postgres       16        422MB
```

### 2️⃣ Time-to-Healthy
Measure how long it takes for `/health` to respond after startup.
```bash
START=$(date +%s.%N)
docker compose --profile dev up -d
until curl -fsS http://localhost:8000/health >/dev/null 2>&1; do sleep 0.2; done
END=$(date +%s.%N)
python - <<PY
print(float("${END}") - float("${START}"))
PY
```

### 3️⃣ p95 Burst Latency
If `hey` is installed:
```bash
hey -n 50 -c 10 http://localhost:8000/ready
```

If not, run Python script:
```bash
python scripts/burst_test.py
```

Output example:
```
p95 (ms): 41.78
```

### 4️⃣ Docker Stats Snapshot
Run and take a screenshot:
```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"
```

### 5️⃣ RTO (Restart → Ready)
```bash
CONTAINER=$(docker ps --filter "name=api" --format "{{.Names}}" | head -n1)
docker restart $CONTAINER

START=$(date +%s.%N)
until curl -fsS http://localhost:8000/ready >/dev/null 2>&1; do sleep 0.2; done
END=$(date +%s.%N)
python - <<PY
print(float("${END}") - float("${START}"))
PY
```

Record: `RTO: 3.42s` (example)

---

## 🧪 Step 7: Troubleshooting

| Issue | Cause | Solution |
|-------|--------|-----------|
| `db-pool-not-created` | Database not ready | Wait or restart API container |
| `requests` module not found | Python dependency missing | Run `pip install requests` |
| Dockerfile not found | Wrong build context | Ensure `build.context: ./app` |
| Port 8000 conflict | Another app uses it | Change `API_PORT` in `.env` |
| Exit code 137 | Low memory | Restart Docker or reduce memory usage |

---

## 📈 Step 8: Final Deliverables

| Deliverable | Description |
|--------------|-------------|
| **GitHub Repository** | Contains all code, Dockerfiles, and README |
| **README.md** | Runbook with setup, endpoints, and evidence |
| **Video (5–7 mins)** | Zoom walkthrough: repo, endpoints, metrics |
| **Slides (optional)** | “Ready” presentation with diagrams & notes |

---

## 🧠 Step 9: Helpful Commands

```bash
# Build & run
docker compose --profile dev up --build -d

# Stop & remove containers
docker compose down

# Full cleanup (with volumes)
docker compose down -v

# View logs
docker compose logs -f api

# Check image sizes
docker images

# Resource usage
docker stats --no-stream

# Burst test
python scripts/burst_test.py
```

---

## 🗺️ Architecture Diagram

```
        ┌───────────────────┐
        │     FastAPI       │
        │-------------------│
        │  /health & /ready │
        │ Non-root user     │
        └────────┬──────────┘
                 │
                 │  DATABASE_URL
                 ▼
         ┌──────────────┐
         │  PostgreSQL   │
         │---------------│
         │ Persistent     │
         │ Volume: dbdata │
         └────────────────┘

  Docker Network (appnet)
  Compose Profiles: dev / prod
```

---

## 🧾 Notes
- Use **screenshots** for each evidence proxy (attach in README or PPT).  
- For your **Brightspace submission**, include:  
  - GitHub link  
  - Video recording (.mp4)  
  - README (this file)  
  - Optional PowerPoint slides

---

## ✅ You’re Ready!
This project demonstrates a secure, reproducible, and cloud-ready container architecture suitable for both local development and future deployment.

---

**End of README**
