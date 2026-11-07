from unittest.mock import patch

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ask_uses_llm_layer() -> None:
    with patch("app.main.complete", return_value="42") as fake:
        response = client.post("/ask", json={"prompt": "meaning of life?"})
    assert response.status_code == 200
    assert response.json() == {"answer": "42"}
    fake.assert_called_once_with("meaning of life?")
