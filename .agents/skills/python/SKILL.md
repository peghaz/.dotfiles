---
name: python
description: Apply the owner's Python architecture, typing, naming, configuration, testing, and tooling conventions when creating, changing, reviewing, or organizing Python code. Route to the environment, AI/ML, Django, CLI, package, or Docker guidance only when that specialization is relevant.
---

# Python Engineering

This document defines the mandatory conventions for all Python code in this project. Every rule below is enforceable: assume that CI (via `ruff`, `mypy`/`pyright`, and `pytest`) will reject code that violates it. When in doubt, prefer the stricter interpretation.

---

## Specialized References

Apply the shared rules in this file to Python work. Read only the references relevant to the current task:

- For AI/ML projects, model training, inference, prompts, GPU use, or reproducibility, read [`references/ai.md`](references/ai.md) together with [`references/cli.md`](references/cli.md) and [`references/package.md`](references/package.md).
- For Django, PostgreSQL, Celery, migrations, or Django Ninja APIs, read [`references/django.md`](references/django.md).
- For command-line applications built with Typer and Rich, read [`references/cli.md`](references/cli.md).
- For installable Python packages managed with `uv`, read [`references/package.md`](references/package.md).
- For environment variables, `.env` files, credentials, service endpoints, or deployment configuration, read [`references/configuration.md`](references/configuration.md).
- When a Python project needs Docker, Docker Compose, a containerized database, or custom certificate authorities, also read the sibling [`Docker skill`](../docker/SKILL.md).

---

## Core Architecture & Naming

- **Strict private naming:** In production Python modules and classes, every private function or method must begin with two underscores (`__`). Do not define intentionally private callables with a single leading underscore. Preserve Python special methods such as `__init__` and names required by frameworks or public interfaces. When renaming a private callable, update all call sites and tests; do not leave a single-underscore compatibility alias.

- **Cohesive modules:** Prefer small, focused modules over single files that coordinate unrelated responsibilities. Split a module when it contains multiple concerns or becomes difficult to navigate, test, or reuse. Do not create one-function files or unnecessary abstractions merely to reduce line count.

---

## 1. Strict Static Typing & Pydantic Enforcement

The goal of this section is that a static analysis tool (mypy in strict mode, or pyright) can verify the entire codebase with zero implicit `Any` types, and that all data crossing an architectural boundary is validated at runtime by Pydantic.

### 1.1 Function Signatures & Variable Declarations

- **Mandatory Return Types:** Every single function or method definition must explicitly declare a return type hint — no exceptions, including private helpers, test functions, lambdas refactored into `def`s, dunder methods, and property getters. If a function returns nothing, it must be explicitly typed as `-> None:`. Generators must be typed with `Iterator[...]` / `Generator[YieldType, SendType, ReturnType]`, and async functions with the awaited type (e.g., `async def fetch() -> Response:`).

  ```python
  # Bad — no return annotation, even though it "obviously" returns nothing
  def clear_cache():
      cache.clear()

  # Good
  def clear_cache() -> None:
      cache.clear()

  # Good — generator explicitly typed
  from collections.abc import Iterator

  def read_lines(path: str) -> Iterator[str]:
      with open(path) as f:
          yield from f
  ```

- **Inline Variable Typing:** No variable may be initialized or passed without an explicit type hint if its type cannot be instantly and unambiguously inferred by a static analysis tool. Literals (`x = 3`, `name = "abc"`) and direct constructor calls (`items = list[str]()`) are unambiguous and do not require annotation. Anything returned from a function whose signature is not immediately visible, anything parsed from JSON, and anything coming from an external library must be annotated at the assignment site.

  - *Bad:* `data = fetch_results()`
  - *Good:* `data: dict[str, Any] = fetch_results()`

  ```python
  # Bad — reader/type checker can't know what this is without chasing definitions
  config = load_json("config.json")

  # Good — the type is stated where the variable is born
  config: dict[str, Any] = load_json("config.json")

  # Better still — parse it into a validated model immediately (see 1.2)
  config: TrainingConfig = TrainingConfig.model_validate(load_json("config.json"))
  ```

- **No Implicit Any:** The use of implicit or unmapped type references is strictly forbidden. If an external library lacks types (no inline hints and no stubs on typeshed), you must contain the untyped surface at the boundary: either explicitly cast the returned values (`typing.cast(list[str], legacy_lib.get_names())`) or wrap the library in a thin, fully-typed adapter module of your own, so the rest of the codebase only ever imports your typed wrapper. Enable `disallow_untyped_defs` and `disallow_any_generics` (mypy) or `strict` mode (pyright) so violations fail the build.

  ```python
  # wrappers/legacy_geo.py — the ONLY file allowed to touch the untyped library
  from typing import cast
  import untyped_geo_lib  # type: ignore[import-untyped]

  def geocode(address: str) -> tuple[float, float]:
      result = cast(tuple[float, float], untyped_geo_lib.lookup(address))
      return result
  ```

- **Progress-Logged Loops:** All the loops should be wrapped nicely with logs with `tqdm`. Any loop that iterates over a dataset, batch collection, file list, queryset, or other non-trivial iterable must be wrapped in `tqdm`, with a meaningful `desc=` label (and `total=` when the iterable has no `__len__`). This applies to training loops, preprocessing loops, migration/backfill scripts, and evaluation loops alike, so that long-running work is always observable.

  **Scope exception — non-interactive contexts.** `tqdm` is built for TTYs; inside Celery workers, Django request handlers, or anything writing to a log aggregator rather than a terminal, a raw progress bar produces thousands of carriage-return-laden garbage lines. In those contexts do **not** use bare `tqdm`. Instead, either (a) use the custom logger (section 2.7) to emit a structured progress line every N iterations, or (b) if you want the tqdm API, pass a file/logging redirect and disable the live bar (e.g., `tqdm(it, desc=..., mininterval=30, disable=not sys.stderr.isatty())`). Rule of thumb: live `tqdm` bars in interactive scripts (`training/`, one-off CLI tools, notebooks); periodic structured log lines in workers and services.

  ```python
  from tqdm import tqdm

  # Bad — silent loop, no visibility into progress
  for batch in dataloader:
      process(batch)

  # Good — labeled progress bar
  for batch in tqdm(dataloader, desc="Processing training batches"):
      process(batch)

  # Good — total provided for a generator
  for record in tqdm(stream_records(), desc="Backfilling users", total=expected_count):
      migrate(record)
  ```

### 1.2 Complex Data Structures & Validation

- **Pydantic Over Dicts:** Never pass unstructured dictionaries or generic `JSON` blobs between architectural layers (e.g., between views and Celery tasks, or clients and core logic). If a data structure contains nested keys, multiple fields, or requires validation, it must be defined as a Pydantic `BaseModel`. Raw dicts are only acceptable as short-lived, single-layer local variables (e.g., building kwargs immediately before a call). The moment data crosses a module or layer boundary, it must be a model. This gives you: runtime validation at the boundary, IDE autocompletion, self-documenting field names, and safe refactoring.

  ```python
  # Bad — the view and the task share an implicit, unchecked contract
  def create_report(request):
      payload = {"user_id": request.user.id, "range": request.GET.get("range"), "fmt": "pdf"}
      generate_report.delay(payload)

  # Good — the contract is explicit and validated on both sides
  from pydantic import BaseModel, Field

  class ReportRequest(BaseModel):
      user_id: int = Field(..., gt=0)
      date_range: str = Field(..., min_length=1)
      output_format: str = Field(default="pdf", pattern="^(pdf|csv)$")

  def create_report(request) -> None:
      report_request: ReportRequest = ReportRequest(
          user_id=request.user.id,
          date_range=request.GET.get("range", ""),
      )
      generate_report.delay(report_request.model_dump())

  @shared_task
  def generate_report(raw: dict[str, Any]) -> None:
      req: ReportRequest = ReportRequest.model_validate(raw)  # re-validate at the boundary
      ...
  ```

- **Field Constraints:** Use Pydantic's `Field` function to enforce strict runtime boundaries on data models (e.g., `gt`, `le`, `min_length`, `max_length`). Do not rely on downstream code to defensively check values — encode the invariant once, in the model, so invalid data is rejected the instant it enters the system. Prefer constrained fields over post-hoc `if` checks; use `pattern=` for string formats and custom `@field_validator`s only when built-in constraints cannot express the rule.

- **Modern Type Syntax:** Always use modern Python 3.10+ typing syntax. Use `|` instead of `Optional` or `Union`, and use native collections (`list[...]`, `dict[...]`, `set[...]`, `tuple[...]`) instead of importing from the legacy `typing` module. Import abstract container types (`Iterator`, `Sequence`, `Mapping`, `Callable`) from `collections.abc`, not from `typing`. Configure `ruff` with the `UP` (pyupgrade) rule set so legacy syntax is auto-flagged.

  - *Bad:* `def process(data: Optional[List[Dict[str, Any]]]) -> Union[str, None]:`
  - *Good:* `def process(data: list[dict[str, Any]] | None) -> str | None:`

### 1.3 External Configuration Models

- Every external configuration surface gets a typed Pydantic model with constrained fields. Use `pydantic-settings.BaseSettings` for values sourced from the process environment or `.env`; use `BaseModel` or typed dataclasses for non-secret file configuration such as AI experiment YAML.
- Load environment-backed configuration once at the application boundary and inject it into reusable code. Do not scatter `os.getenv()`, `os.environ.get()`, or `load_dotenv()` across feature modules.
- Follow [`references/configuration.md`](references/configuration.md) for configuration composition, secrets, `.env.example`, precedence, and testing.

For an ordinary validated value object that is not itself an environment loader, use `BaseModel`:

```python
from pydantic import BaseModel, Field


class PostgreSQLConfig(BaseModel):
    host: str = Field(..., min_length=1)
    port: int = Field(default=5432, ge=1, le=65535)
    database_name: str
```

  Notes on the pattern:
  - `...` (Ellipsis) marks the field as required with no default — startup fails loudly if it's missing rather than silently connecting to the wrong host.
  - Numeric bounds (`ge=1, le=65535`) make an invalid port unrepresentable.
  - Extend the same idea to related value objects and compose them where that improves clarity.

---

---

## 5. Error Handling, Docstrings & Code Hygiene

### 5.1 Exception Handling

- **No silent swallowing.** Never write a bare `except:` or `except Exception: pass`. Every caught exception must be either handled meaningfully, re-raised, or logged with context via the project logger. A `try` block should wrap the *smallest* statement that can fail, not a whole function body.

  ```python
  # Bad — hides every error, including bugs
  try:
      result = risky()
  except Exception:
      pass

  # Good — narrow catch, logged, re-raised or handled deliberately
  try:
      result: Response = call_ocr_api(doc_bytes)
  except requests.RequestException as exc:
      logger.error("OCR API call failed for doc", exc_info=exc)
      raise OcrUnavailableError("OCR provider unreachable") from exc
  ```

- **Catch narrowly.** Catch the most specific exception type that can actually be raised. `except Exception` is permitted only at true boundaries — a Celery task body, a Django Ninja exception handler, or a top-level script `main()` — where the job is to log and convert to a controlled failure. It is banned in library/feature code.

- **Custom exception hierarchy.** Define a project base exception (e.g., `class AppError(Exception): ...`) and derive domain-specific errors from it (`class OcrUnavailableError(AppError): ...`). This lets callers catch `AppError` to distinguish *your* known failure modes from unexpected bugs. Keep the hierarchy in a dedicated `exceptions.py` per app/feature.

- **Always chain.** When re-raising inside an `except`, use `raise NewError(...) from exc` so the original traceback is preserved. Never discard the cause.

- **Ninja error handling.** Convert domain exceptions to HTTP responses centrally with `@api.exception_handler(AppError)` rather than sprinkling `try/except` that returns error dicts inside individual endpoints.

### 5.2 Docstrings

- **Docstrings are required on everything** — every module, class, function, and method, including private helpers and test functions. Use **Google-style** docstrings. Because the codebase is fully type-annotated (section 1), **do not repeat type information** in the docstring; describe *intent, behavior, side effects, and raised exceptions* instead. Configure `ruff`'s `D` (pydocstyle) rule set with the Google convention to enforce presence and format.

  ```python
  def charge_order(order_id: int) -> None:
      """Charge the customer for a committed order.

      Fetches a fresh Order by primary key and attempts payment via the
      configured provider. Idempotent: an already-paid order is a no-op.

      Args:
          order_id: Primary key of the Order to charge.

      Raises:
          PaymentDeclinedError: If the provider declines the charge.
      """
      ...
  ```

  - Module docstring: one line on what the module contains.
  - Class docstring: purpose + noteworthy attributes.
  - Function/method: summary line, then `Args:` / `Returns:` / `Raises:` sections as applicable (omit sections that don't apply; never write `Returns: None`).
  - One-line docstrings are acceptable for trivial helpers and tests, but they must exist.

### 5.3 `__init__.py` & Public API

- **Explicit exports.** Every package `__init__.py` that re-exports names must declare an explicit `__all__: list[str]`. Prefer keeping `__init__.py` files thin — imports for the package's public surface only, no logic. This makes the public API of each package auditable and lets `ruff`'s `F401` distinguish intentional re-exports from dead imports.

### 5.4 Datetime Policy

- **Always timezone-aware.** Set `USE_TZ = True` in Django settings. **Ban naive datetimes entirely.** Never call `datetime.datetime.now()` or `datetime.datetime.utcnow()`; use `django.utils.timezone.now()` in Django code and `datetime.datetime.now(tz=datetime.UTC)` elsewhere. Store and compute in UTC; convert to local time only at the display edge. Enable `ruff`'s `DTZ` rule set to flag naive-datetime construction automatically.

---

---

## 6. Ruff Configuration

"`ruff` is configured" is not left to interpretation. The baseline rule selection lives in `pyproject.toml` and must include at least these families:

```toml
[tool.ruff]
target-version = "py310"
line-length = 100

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "F",    # pyflakes
    "I",    # isort (import sorting)
    "UP",   # pyupgrade — enforces modern 3.10+ syntax (section 1.2)
    "B",    # flake8-bugbear — likely-bug patterns
    "SIM",  # flake8-simplify
    "D",    # pydocstyle — docstring presence/format (section 5.2)
    "DTZ",  # flake8-datetimez — naive datetime detection (section 5.4)
    "ANN",  # flake8-annotations — enforces the typing rules in section 1
    "TID",  # flake8-tidy-imports
    "RUF",  # ruff-specific rules
]

[tool.ruff.lint.pydocstyle]
convention = "google"
```

- `ruff format` is the formatter (do not also run Black — pick one; ruff format is the standard here).
- Adding to `select` is encouraged; removing a family requires a comment justifying the exception.
- Per-file ignores (e.g., relaxing `D`/`ANN` for `tests/`) go under `[tool.ruff.lint.per-file-ignores]`, not scattered `# noqa` comments.

---

---

## 7. Testing (pytest) — Expanded

Building on section 2.10 (pytest, `tests/` at root, one file per AI feature):

- **Factories over fixtures for models.** Use `factory_boy` (with `pytest-django`) to build Django model instances in tests rather than hand-written fixtures or raw `.objects.create()` calls — factories keep tests readable and resilient to model changes.
- **Always mock external calls.** No test may hit a real third-party API, payment provider, or remote model endpoint. Mock at the boundary (the typed wrapper from section 1.1) with `pytest-mock` / `responses`. A test that requires the network is a broken test.
- **Coverage.** Target a meaningful line+branch coverage floor (e.g., 80%) enforced in CI via `pytest --cov`. Coverage is a floor, not a goal — prioritize testing behavior and edge cases over chasing the number.
- **GPU-dependent tests.** Mark any test that requires a GPU with `@pytest.mark.gpu`. CI runs on CPU-only runners and must skip these automatically (`addopts = "-m 'not gpu'"` by default, with an opt-in job on the cluster). Model/feature logic should be testable on CPU with tiny tensors; reserve `gpu` marks for genuine device-specific paths.
- **Determinism in tests.** Tests that touch model code must seed explicitly (section 8) so failures are reproducible.
- **Test the task, not Celery.** Unit-test Celery task *functions* by calling them synchronously with a known object PK; don't spin up a broker. Assert idempotency explicitly by invoking the task twice and checking state is unchanged the second time.

---
