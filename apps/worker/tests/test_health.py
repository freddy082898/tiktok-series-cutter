from fastapi.testclient import TestClient

from app.main import app


def test_health_responds():
    res = TestClient(app).get("/health")
    assert res.status_code == 200
    body = res.json()
    assert body["status"] in {"ok", "degraded"}
    assert "ffmpeg" in body
