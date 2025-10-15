import os
import asyncio
from fastapi import FastAPI, HTTPException
import asyncpg

app = FastAPI()
POOL = None

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://app:dev@db:5432/appdb")

@app.on_event("startup")
async def startup():
    global POOL
    retries = 10  # number of attempts
    for i in range(retries):
        try:
            POOL = await asyncpg.create_pool(dsn=DATABASE_URL, min_size=1, max_size=5)
            print("DB pool created successfully")
            break
        except Exception as e:
            print(f"DB connection failed ({i+1}/{retries}): {e}")
            await asyncio.sleep(2)  # wait 2 seconds before retrying
    else:
        print("Could not connect to DB after several retries")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/ready")
async def ready():
    if POOL is None:
        raise HTTPException(status_code=503, detail="db-pool-not-created")
    try:
        async with POOL.acquire() as conn:
            await conn.execute("SELECT 1;")
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"db-unreachable: {e}")
    return {"ready": True}

@app.on_event("shutdown")
async def shutdown():
    global POOL
    if POOL:
        await POOL.close()
    await asyncio.sleep(0.01)
