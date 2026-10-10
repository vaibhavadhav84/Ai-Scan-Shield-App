from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", hide_input_in_errors=True)
    environment: str = "development"
    database_url: str = "sqlite:///./scanshield.db"
    cors_origins: list[str] = []
    access_minutes: int = 30
    refresh_days: int = 14
    rate_limit: int = 120
    auth_rate_limit: int = 15
    safe_threshold: int = 30
    high_threshold: int = 70
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    mail_from: str = ""
    model_path: str = ""
    speech_model_path: str = ""
    reputation_provider: str = "disabled"
    reputation_api_key: str = ""
    reputation_noncommercial_use: bool = False
    max_audio_bytes: int = 10 * 1024 * 1024
    max_audio_seconds: int = 180

    @model_validator(mode="after")
    def check(self):
        if not 0 <= self.safe_threshold < self.high_threshold <= 100:
            raise ValueError("Invalid risk thresholds")
        if min(self.access_minutes, self.refresh_days, self.rate_limit, self.auth_rate_limit) < 1:
            raise ValueError("Session and rate limits must be positive")
        if self.environment not in {"development", "test", "production"}:
            raise ValueError("Unknown environment")
        if self.reputation_provider not in {"disabled", "google-safe-browsing"}:
            raise ValueError("Unknown reputation provider")
        if (
            self.reputation_provider == "google-safe-browsing"
            and not self.reputation_noncommercial_use
        ):
            raise ValueError("Google Safe Browsing requires noncommercial use acknowledgement")
        if self.environment == "production":
            if not self.database_url.startswith("postgresql"):
                raise ValueError("Production requires PostgreSQL")
            if not self.smtp_host or not self.mail_from:
                raise ValueError("Production requires SMTP_HOST and MAIL_FROM")
            if "*" in self.cors_origins:
                raise ValueError("Wildcard CORS forbidden in production")
        return self


@lru_cache
def settings():
    return Settings()
