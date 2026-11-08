from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuration du worker. Toute valeur absente désactive la fonctionnalité liée."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    supabase_url: str | None = None
    supabase_service_role_key: str | None = None
    llm_provider: str | None = None
    transcription_provider: str = "local"
    worker_concurrency: int = 1
    jobs_dir: str = "/tmp/jobs"


settings = Settings()
