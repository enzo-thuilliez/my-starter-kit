"""Settings loaded from environment variables and `.env`."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "{{PROJECT_NAME}}"
    environment: str = "dev"
    default_model: str = "anthropic/claude-sonnet-5-5"


@lru_cache
def get_settings() -> Settings:
    return Settings()
