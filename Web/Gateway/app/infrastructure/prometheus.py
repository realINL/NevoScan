from prometheus_client import Counter, Histogram

class PrometheusMetrics:
    
    GATEWAY_REQUESTS_TOTAL = Counter(
        "gateway_requests_total",
        "Total number of Gateway HTTP requests",
        ["method", "endpoint", "status"]
    )

    GATEWAY_UPLOAD_SIZE = Histogram(
        "gateway_upload_size_bytes",
        "Uploaded image size in bytes"
    )

    GATEWAY_REQUEST_DURATION = Histogram(
        "gateway_request_duration_seconds",
        "Gateway HTTP request duration in seconds",
        ["method", "endpoint"]
    )

    GATEWAY_TASKS_CREATED_TOTAL = Counter(
    "gateway_tasks_created_total",
    "Total number of tasks created by Gateway"
    )