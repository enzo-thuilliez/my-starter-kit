"""FastAPI application."""

from fastapi import FastAPI
from pydantic import BaseModel

from app.config import get_settings
from app.llm import complete

app = FastAPI(title=get_settings().app_name)


class AskRequest(BaseModel):
    prompt: str


class AskResponse(BaseModel):
    answer: str


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/ask")
def ask(body: AskRequest) -> AskResponse:
    return AskResponse(answer=complete(body.prompt))
