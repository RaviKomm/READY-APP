import requests
from time import time

url = "http://localhost:8000/ready"
n_requests = 50  # total requests

start_time = time()
for i in range(n_requests):
    r = requests.get(url)
    print(f"{i+1}: {r.status_code}, {r.json()}")
end_time = time()

total_time = end_time - start_time
print(f"\nSent {n_requests} requests in {total_time:.2f} seconds")
