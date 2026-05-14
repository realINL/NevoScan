import time
from fastapi import FastAPI, Request
from app.infrastructure.prometheus import PrometheusMetrics

@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    start_time = time.perf_counter()
    status = "success"

    try:
        response = await call_next(request)
        if response.status_code >= 400:
            status = "error"
        return response
    
    except Exception:
        status = "error"
        raise

    finally:
        route = request.scope.get("route")
        endpoint = getattr(route, "path", request.url.path)

        PrometheusMetrics.GATEWAY_REQUESTS_TOTAL.labels(
            method=request.method,
            endpoint=endpoint,
            status=status
        ).inc()

        duration = time.perf_counter() - start_time
        PrometheusMetrics.GATEWAY_REQUEST_DURATION.labels(
            method=request.method,
            endpoint=endpoint
        ).observe(duration)
    