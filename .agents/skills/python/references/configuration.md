# Environment and Application Configuration

Apply this reference when a Python project depends on environment variables, `.env` files, credentials, service endpoints, database connection details, or other deployment-specific values.

## Configuration Boundary

- Use `pydantic-settings.BaseSettings` as the standard environment-backed configuration class. Its dotenv support replaces direct application calls to `load_dotenv()`.
- Declare `pydantic-settings` as a runtime dependency in `pyproject.toml` and manage it with `uv` like the project's other dependencies. Do not add direct `python-dotenv` calls alongside it.
- Declare every supported variable as a typed field. Use constrained types such as `AnyHttpUrl`, `PostgresDsn`, bounded integers, enums, and `SecretStr` where appropriate.
- Instantiate settings once at an application boundary such as root `cli.py`, a web application factory, or Django `settings.py`. Pass the validated settings object, or a focused subsection of it, into reusable code.
- Keep credentials on the settings object rather than copying them into module-level string constants. A cached application-level settings instance is acceptable when the framework requires one, but it must be created at the boundary and remain replaceable in tests.
- Do not read environment variables from models, datasets, services, views, tasks, or other deep modules. Package code must remain usable with an explicitly supplied configuration object.
- Fail during startup when a required setting is missing or invalid. Give optional behavior an explicit, documented default.

Use a pattern like this:

```python
from pathlib import Path

from pydantic import AnyHttpUrl, PostgresDsn, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppConfig(BaseSettings):
    """Validated process and dotenv configuration."""

    model_config = SettingsConfigDict(
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    llm_endpoint: AnyHttpUrl
    llm_api_key: SecretStr
    database_url: PostgresDsn | None = None


def load_config(env_file: Path | None) -> AppConfig:
    """Load configuration once at the application boundary."""
    return AppConfig(_env_file=env_file)
```

Uppercase environment names such as `LLM_ENDPOINT`, `LLM_API_KEY`, and `DATABASE_URL` map to these fields when settings are case-insensitive. Use explicit validation aliases when an external variable name does not correspond cleanly to the field name.

Pass a deliberate path such as `project_root / ".env"` from repository entry points rather than relying on an incidental working directory. Pass `None` in a production environment that supplies process variables without a dotenv file. An installed library must not search for a repository checkout; let its consuming application provide the settings object or dotenv path.

## Configuration Sources and Precedence

- Real process environment variables override dotenv values. This lets CI, production, containers, and VS Code debugging replace local defaults without editing files.
- Explicit constructor values may be used for tests and programmatic embedding.
- Keep non-secret defaults in code only when they are safe and valid in every intended environment.
- Use `.env` for deployment-specific endpoints, credentials, tokens, database settings, and feature switches.
- Use structured files such as `configs/*.yaml` for non-secret domain or experiment configuration. Never put API keys, passwords, or access tokens in YAML committed to the repository.
- If an application uses both settings and YAML, load each once at the same boundary, validate both, and compose or pass them explicitly. Do not let deep modules decide precedence.

## Secrets and Repository Files

- Add `.env` to both `.gitignore` and `.dockerignore`. Never copy it into an image, wheel, source distribution, test fixture, or generated artifact.
- Commit `.env.example` with every supported variable, safe dummy values, and brief comments where intent is not obvious. Keep its keys synchronized with the settings class.
- Values in `.env.example` must not be usable credentials. Use placeholders such as `replace-me`, local-only hostnames, or intentionally invalid tokens.
- Use `SecretStr` for passwords, tokens, and API keys so routine model representations do not reveal them. Call `get_secret_value()` only at the integration boundary that needs the raw value.
- Do not log secrets, complete credential-bearing URLs, or the unredacted settings model. Redact sensitive query parameters and headers in error messages.
- If a secret was committed, removing it from the latest revision is insufficient; rotate it and follow the repository's incident procedure.

An example should resemble:

```dotenv
LLM_ENDPOINT=https://llm.example.invalid/v1
LLM_API_KEY=replace-me
DATABASE_URL=postgresql://app:replace-me@localhost:5432/app
```

## Composition

For a small application, one `AppConfig` is enough. For a larger application, group related concerns into focused settings or Pydantic models such as `LLMConfig`, `DatabaseConfig`, `RedisConfig`, and `WandbConfig`, then expose one top-level application configuration. Do not create layers of configuration classes without a real separation of ownership or lifecycle.

Use one canonical variable name for each value. Avoid keeping both a credential-bearing `DATABASE_URL` and a second independent set of database fields unless a framework or container image genuinely requires both; if both are necessary, validate that they cannot silently disagree.

## Tests

- Construct settings with explicit values or an isolated temporary dotenv file. Tests must not depend on the developer's real `.env`.
- Clear or isolate relevant process variables so CI and workstation state cannot change test outcomes.
- Test missing required variables, malformed URLs, invalid numeric ranges, precedence, secret redaction, and any computed configuration.
- Never include real credentials in snapshots, exception assertions, or test reports.
