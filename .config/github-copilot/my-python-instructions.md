# Python Architecture Rules

This document defines the mandatory conventions for all Python code in this project. Every rule below is enforceable: assume that CI (via `ruff`, `mypy`/`pyright`, and `pytest`) will reject code that violates it. When in doubt, prefer the stricter interpretation.

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

- **Inline Variable Typing:** No variable may be initialized or passed without an explicit type hint if its type cannot be instantly and unambiguously inferred by a static analysis tool. Literals (`x = 3`, `name = "abc"`) and direct constructor calls (`items = list[str]()`) are unambiguous and do not require annotation. Anything returned from a function whose signature is not immediately visible, anything parsed from JSON/YAML, and anything coming from an external library must be annotated at the assignment site.

  - *Bad:* `data = fetch_results()`
  - *Good:* `data: dict[str, Any] = fetch_results()`

  ```python
  # Bad — reader/type checker can't know what this is without chasing definitions
  config = load_yaml("config.yaml")

  # Good — the type is stated where the variable is born
  config: dict[str, Any] = load_yaml("config.yaml")

  # Better still — parse it into a validated model immediately (see 1.2)
  config: TrainingConfig = TrainingConfig.model_validate(load_yaml("config.yaml"))
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

  **Scope exception — non-interactive contexts.** `tqdm` is built for TTYs; inside Celery workers, Django request handlers, or anything writing to a log aggregator rather than a terminal, a raw progress bar produces thousands of carriage-return-laden garbage lines. In those contexts do **not** use bare `tqdm`. Instead, either (a) use the custom logger (section 2.8) to emit a structured progress line every N iterations, or (b) if you want the tqdm API, pass a file/logging redirect and disable the live bar (e.g., `tqdm(it, desc=..., mininterval=30, disable=not sys.stderr.isatty())`). Rule of thumb: live `tqdm` bars in interactive scripts (`training/`, one-off CLI tools, notebooks); periodic structured log lines in workers and services.

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

### 1.3 Type Check Execution Examples

- **Configuration Model:** Every external configuration surface (database, cache, model hyperparameters, third-party API credentials) gets its own Pydantic model with constrained fields, following this pattern:

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
  - Extend the same idea to related configs (`RedisConfig`, `CeleryConfig`, `WandbConfig`) and compose them into a single top-level `AppConfig(BaseModel)` if useful.

---
## 2. AI/ML Project Structure

The repository layout is fixed. Every AI capability is decomposed by *reusability* (utils vs. features), by *artifact type* (code vs. model weights vs. datasets), and by *modality* (audio, text, image, ...). The canonical tree looks like this:

```
project-root/
├── main.py                  # Entry point: runnable samples for training + inference of every feature
├── pyproject.toml           # uv-managed; ruff configured here as a dev dependency
├── utils/                   # Reusable, project-agnostic AI code (incl. the OmegaConf wrapper)
│   ├── audio/
│   ├── text/
│   └── image/
├── features/                # Project-specific AI feature code
│   ├── audio/
│   ├── text/
│   ├── image/
│   └── inference/           # Inference entry points, one subfolder per feature + yaml config
│       ├── audio/
│       ├── text/
│       ├── image/
│       └── inference.yaml
├── models/                  # Project-specific model artifacts (weights/checkpoints), per modality
│   ├── audio/
│   ├── text/
│   └── image/
├── training/
│   ├── train/               # + train.yaml, subfolders per feature
│   ├── test/                # + test.yaml, subfolders per feature
│   └── validate/            # + validate.yaml, subfolders per feature
├── data/                    # Dataset classes & dataloaders (torch) — tracked by git
│   ├── audio/
│   ├── text/
│   └── image/
├── datasets/                # Raw dataset files — gitignored by default
├── tests/                   # pytest suite, one test file per AI feature
└── logs/                    # Custom logger output — gitignored
```

The numbered rules, elaborated:

1. **`utils` — reusable AI code.** `utils` is for AI features that are not specific to the project and can be reused in other projects. Utils should have subfolders for each AI feature/modality, such as `audio`, `text`, `image`, etc. The litmus test: if you could copy the module into a different repository and it would work without modification (no project-specific imports, no hardcoded paths, no project business logic), it belongs in `utils`. Examples: generic audio resampling, tokenization helpers, image augmentation pipelines.

2. **`features` — project-specific AI code.** `features` is for AI features that are specific to the project and cannot be reused in other projects. Features should have subfolders for each AI feature/modality, such as `audio`, `text`, `image`. This is where project business logic lives: the specific model architectures wired to this project's data, the domain-specific pre/post-processing, the glue between utils and this project's requirements.

3. **`models` — weights, not code.** `models` is for AI models that are specific to the project and cannot be reused in other projects, with subfolders for each AI model/modality (`audio`, `text`, `image`). The separation of concerns is strict: **AI model artifacts (weights, checkpoints, exported ONNX/TorchScript files) are stored in the `models` folder, and their code (architecture definitions, LightningModules) is stored in the `features` folder.** Never mix serialized weights into code directories or vice versa.

4. **`training/` with `train`, `test`, `validate`.** For training, testing and validation, use the `train`, `test`, and `validate` folders, respectively, under `training`. Each of these folders should have subfolders for each AI feature (`audio`, `text`, `image`). These folders contain the runnable scripts/orchestration for their respective phase — a training run for the text feature lives at `training/train/text/`, its evaluation at `training/test/text/`, and so on. Keeping the three phases parallel in structure makes it trivial to locate the counterpart of any script.

5. **PyTorch Lightning + Weights & Biases.** If possible, models should be trained using PyTorch Lightning (`LightningModule` for the model, `LightningDataModule` for data, `Trainer` for the loop) rather than hand-rolled training loops — this standardizes checkpointing, multi-GPU, and mixed precision. Weights & Biases should be configured for logging and tracking experiments (use Lightning's `WandbLogger` so metrics, hyperparameters, and artifacts are tracked per run). The `train`, `test`, and `validate` folders should each have a `yaml` file that contains the configuration for the training, testing, and validation processes respectively (e.g., `training/train/train.yaml` holding learning rate, batch size, epochs, checkpoint paths, W&B project name).

6. **OmegaConf with a project-wide wrapper.** All of the configuration `yaml` files should be able to be read using OmegaConf, with a custom wrapper class for the whole project located in the `utils` folder. Every config load in the codebase goes through this one wrapper — never call `OmegaConf.load()` ad-hoc in feature code. The wrapper is the single place to implement config merging, environment-variable interpolation, validation (e.g., handing the loaded config to a Pydantic model per section 1.3), and defaulting.

   ```python
   # utils/config_loader.py
   from pathlib import Path
   from omegaconf import DictConfig, OmegaConf


   class ProjectConfig:
       """Single entry point for reading any project YAML via OmegaConf."""

       @staticmethod
       def load(path: str | Path) -> DictConfig:
           config: DictConfig = OmegaConf.load(Path(path))  # type: ignore[assignment]
           return config
   ```

7. **`inference` under `features`.** For inference, use the `inference` folder under `features`. The `inference` folder should have subfolders for each AI feature (`audio`, `text`, `image`), and should have a `yaml` file that contains the configuration (checkpoint path, device, batch size, decoding parameters, etc.). Inference code loads weights from `models/` and configuration through the OmegaConf wrapper — it must never duplicate architecture code that already exists elsewhere in `features/`.

8. **Custom logger for the training process.** A custom logger should always be implemented for the training process (including testing and validation). This is in addition to W&B: W&B tracks experiments remotely, the custom logger produces local, structured, human-readable logs. The logs should be written to a `logs` folder that is ignored by git (add `logs/` to `.gitignore`). The logger should record at minimum: run start/end timestamps, config used, per-epoch metrics, and any exceptions.

9. **Everything is runnable.** All the scripts there should have their own `__main__` methods (i.e., an `if __name__ == "__main__":` block invoking a typed `main() -> None` function) and be runnable directly. `main.py` of the project should include samples for training and inference for each AI feature, and should be runnable as well. The `main.py` should be the entry point of the project — a new contributor should be able to run `python main.py` (or `uv run main.py`) and see a working demonstration of each feature's train + inference path.

10. **Tooling: `uv` + `ruff`.** The project should use `uv` as its package manager — dependencies are declared in `pyproject.toml` and locked with `uv.lock`; never use bare `pip install` or `requirements.txt`. `ruff` should be configured in `pyproject.toml` as a dev dependency (under `[dependency-groups]` / dev), with its lint and format settings living in `[tool.ruff]` in the same file.

11. **Testing: `pytest`.** The project should use `pytest` for testing, and the tests should be located in a `tests` folder at the root of the project. Each AI feature should have its own test file in the `tests` folder (e.g., `tests/test_audio.py`, `tests/test_text.py`, `tests/test_image.py`). Tests follow all typing rules from section 1 (annotated test functions returning `-> None`).

12. **Dataset classes and dataloaders (`data/`).** Dataset classes and dataloaders should be created with the help of `torch` (`torch.utils.data.Dataset` / `DataLoader`, or Lightning `DataModule`s built on them). These dataset *classes* live inside the `data` folder, with subfolders for each AI feature (`audio`, `text`, `image`). The `data` folder should **not** be ignored by git — it contains code, not data files.

13. **Raw datasets (`datasets/`).** Datasets themselves (the actual audio files, corpora, image archives, parquet files, etc.) should be stored in a `datasets` folder at the root of the project. They should be ignored by git by default (add `datasets/` to `.gitignore`); use download scripts or a data-versioning tool to reproduce them rather than committing them.

> **`data/` vs `datasets/` in one line:** `data/` = Python code defining `Dataset`/`DataLoader` classes (tracked). `datasets/` = the raw files those classes read (gitignored).

---
## 3. Django, Celery, & PostgreSQL Architecture Rules

### 3.1 Environment & Settings Rules

- **No `os.environ.get()` outside settings.** Never use `os.environ.get()` directly inside your code or views. All environment variables must be fetched, typed, and defaulted inside `settings.py`, then imported from `django.conf.settings` everywhere else. This creates a single, auditable inventory of every environment dependency, guarantees each variable is read exactly once with an explicit type and default, and means a missing variable fails at startup — not deep inside a request three weeks later.

  ```python
  # Bad — scattered, untyped, string-only access in a view
  def checkout(request):
      stripe_key = os.environ.get("STRIPE_KEY")  # None if missing; discovered at runtime

  # Good — declared once in settings.py, consumed via settings
  # settings.py
  STRIPE_KEY: str = env.str("STRIPE_KEY")

  # views.py
  from django.conf import settings
  stripe.api_key = settings.STRIPE_KEY
  ```

- **Use a configuration library.** Use a dedicated configuration library like `django-environ` or `pydantic-settings` to parse the `.env` file into `settings.py`. These libraries handle type casting (`env.int(...)`, `env.bool(...)`), defaults, and URL-style parsing (`env.db()`, `env.cache_url()`), so `settings.py` never contains hand-rolled `os.environ` string juggling. If using `pydantic-settings`, define a `BaseSettings` subclass with constrained, typed fields (consistent with section 1) and instantiate it once in `settings.py`.

- **Connection pooling via `CONN_MAX_AGE`.** Always set `CONN_MAX_AGE` in the `DATABASES` dictionary to allow PostgreSQL connection pooling (e.g., set to 600 seconds, or let `env.db()` handle it via the database URL). Without it, Django opens and tears down a fresh PostgreSQL connection on every request, which wastes latency and hammers the database's connection slots under load.

  ```python
  # settings.py (django-environ style)
  import environ

  env = environ.Env()
  environ.Env.read_env()

  DATABASES = {
      "default": env.db("DATABASE_URL"),  # parses postgres://user:pass@host:port/name
  }
  DATABASES["default"]["CONN_MAX_AGE"] = 600  # keep connections alive for 10 minutes
  ```

- **Never commit `.env`.** Never commit the `.env` file to version control. Ensure it is added to `.gitignore`. Commit a `.env.example` with dummy values instead so new developers know which variables are required. Treat any secret that was ever committed as compromised and rotate it.

### 3.2 Django Models & Database Rules

- **Views stay thin; heavy work goes to Celery.** Never run heavy API calls, file processing, or complex data transformations inside a Django view, signal, or model method. Offload these entirely to Celery tasks. A view's job is: validate input, enqueue work, return a response — typically in well under 100ms. Anything that touches a third-party API, processes an upload, renders a large export, or transforms data at scale blocks a WSGI/ASGI worker and can time out the request; behind a signal or model method it's even worse, because the cost is invisible at the call site.

  ```python
  # Bad — the user waits while we call an external API and crunch a file
  def upload_view(request):
      result = external_ocr_api(request.FILES["doc"].read())   # slow network call
      build_searchable_index(result)                            # heavy CPU work
      return JsonResponse({"status": "done"})

  # Good — persist, enqueue, respond
  def upload_view(request) -> JsonResponse:
      doc: Document = Document.objects.create(file=request.FILES["doc"])
      transaction.on_commit(lambda: process_document.delay(doc.id))
      return JsonResponse({"status": "queued", "id": doc.id})
  ```

- **Explicit transactions for multi-row writes.** Use explicit database transactions (`transaction.atomic`) when a view or task modifies multiple related rows, ensuring data integrity in PostgreSQL. If step 3 of 5 raises, everything rolls back and the database never holds a half-applied state (e.g., an `Order` without its `OrderItems`, or a debit without the matching credit).

  ```python
  from django.db import transaction

  def transfer(from_id: int, to_id: int, amount: Decimal) -> None:
      with transaction.atomic():
          from_acct = Account.objects.select_for_update().get(pk=from_id)
          to_acct = Account.objects.select_for_update().get(pk=to_id)
          from_acct.balance -= amount
          to_acct.balance += amount
          from_acct.save()
          to_acct.save()
  ```

- **Kill N+1 queries at the source.** Always optimize database queries using `.select_related()` (for `ForeignKey`/`OneToOne` — resolved with a SQL JOIN) or `.prefetch_related()` (for `ManyToMany` and reverse FKs — resolved with a second batched query) to prevent the N+1 query problem. A loop that accesses `obj.related_thing` on a queryset without these will silently issue one query per row; with 1,000 rows that's 1,001 queries instead of 1–2.

  ```python
  # Bad — 1 query for books + 1 query per book for its author
  for book in Book.objects.all():
      print(book.author.name)

  # Good — single JOINed query
  for book in Book.objects.select_related("author"):
      print(book.author.name)

  # Good — two queries total for M2M
  for book in Book.objects.prefetch_related("tags"):
      print([t.name for t in book.tags.all()])
  ```

### 3.3 Celery Task Architecture Rules

- **Idempotency:** Every Celery task must be designed to be idempotent. If a task executes twice due to a network glitch or a retry, it must not corrupt data or double-charge a user. Celery's delivery guarantees are effectively *at-least-once*: broker redeliveries, visibility-timeout expiries, and `autoretry_for` all mean duplicate executions are a matter of *when*, not *if*. Techniques: use `get_or_create`/`update_or_create` instead of blind `create`; make external calls with idempotency keys (Stripe, etc.); check a status field before acting (`if order.status == OrderStatus.PAID: return`); use database constraints (unique indexes) as the last line of defense.

- **Pass IDs, Not Objects:** Never pass complex Django Model instances as arguments to a Celery task (e.g., `my_task.delay(user)`). Always pass the primary key instead (`my_task.delay(user.id)`) and fetch the fresh object from PostgreSQL inside the task. This avoids stale data bugs: a serialized model instance is a snapshot of the row *at enqueue time*, which may be minutes old by the time a busy worker picks it up — and pickling model instances also bloats the broker and breaks whenever the model class changes between deploys. Fetching by PK inside the task guarantees the task sees current data (and can gracefully handle the row having been deleted).

  ```python
  # Bad
  send_welcome_email.delay(user)

  # Good
  send_welcome_email.delay(user.id)

  @shared_task
  def send_welcome_email(user_id: int) -> None:
      user: User | None = User.objects.filter(pk=user_id).first()
      if user is None:
          return  # row deleted before the task ran — nothing to do
      ...
  ```

  (For richer payloads that aren't model rows, this pairs with section 1.2: define a Pydantic model, pass `model_dump()`, and `model_validate()` inside the task.)

- **Atomic Commits:** Never trigger a Celery task inside a database transaction block before the transaction commits. Use `transaction.on_commit(lambda: my_task.delay(obj.id))` to ensure the data actually exists in PostgreSQL before Celery tries to read it. The failure mode without this: the worker is often faster than your transaction — it dequeues the task, queries for `obj.id`, finds nothing (the row isn't committed yet, or the transaction later rolls back entirely), and raises `DoesNotExist`. `on_commit` defers the enqueue until the commit succeeds, and skips it altogether on rollback — exactly the semantics you want.

  ```python
  # Bad — task may run before the row is visible
  with transaction.atomic():
      order = Order.objects.create(...)
      charge_order.delay(order.id)

  # Good — enqueue only after a successful commit
  with transaction.atomic():
      order = Order.objects.create(...)
      transaction.on_commit(lambda: charge_order.delay(order.id))
  ```

### 3.4 Celery Configuration & Error Handling

- **Strict visibility timeouts + explicit retry policy.** Always configure strict visibility timeouts (set the broker's `visibility_timeout` comfortably above your longest task's runtime, so in-flight tasks aren't redelivered mid-execution) and explicit task retry logic using the `@shared_task` decorator:

  ```python
  @shared_task(bind=True, autoretry_for=(Exception,), retry_backoff=True, max_retries=5)
  def my_task(self, obj_id):
      ...
  ```

  What each option buys you:
  - `bind=True` — the task receives `self`, giving access to `self.request` (retry count, task id) and `self.retry(...)` for manual retries with custom countdowns.
  - `autoretry_for=(Exception,)` — any uncaught exception automatically schedules a retry instead of silently failing. **Prefer narrowing this to transient failures** once you know a task's failure modes: retrying a `ValidationError`, `TypeError`, or other deterministic bug just burns five backoff cycles before failing anyway, and can mask the real error. Reserve the blanket `(Exception,)` for tasks whose failures are genuinely unknown or mostly transient; otherwise list the specific recoverable exceptions, e.g. `autoretry_for=(requests.RequestException, django.db.OperationalError, TimeoutError)`. Pair with `dont_autoretry_for` or an early re-raise for known-permanent errors.
  - `retry_backoff=True` — retries use exponential backoff (1s, 2s, 4s, ...), which prevents a struggling downstream service from being hammered in lockstep.
  - `max_retries=5` — a hard ceiling so a permanently-broken task doesn't retry forever; after the last attempt the failure surfaces in monitoring.
  - Remember: because retries mean re-execution, this rule only works in combination with the **idempotency** rule in 3.3.

---

## 4. Additional Instructions

- **Prompts live in `config.py`, not in logic.** Never mix prompt strings directly into the execution logic; store them as constants in `config.py`. Inline prompt literals inside functions make prompts impossible to review, diff, reuse, or A/B test, and they bloat the logic they're embedded in. Define them as typed module-level constants (e.g., `SUMMARIZE_SYSTEM_PROMPT: str = """..."""`) in `config.py` and import them where needed; use `str.format()`/f-string templating at the call site for dynamic values.

  ```python
  # config.py
  SUMMARIZE_SYSTEM_PROMPT: str = (
      "You are a precise summarizer. Summarize the following text in {max_words} words."
  )

  # features/text/summarize.py
  from config import SUMMARIZE_SYSTEM_PROMPT

  def build_prompt(max_words: int) -> str:
      return SUMMARIZE_SYSTEM_PROMPT.format(max_words=max_words)
  ```

- **No hardcoded `.cuda()`.** Never hardcode `.cuda()`. Always check `torch.cuda.is_available()` and select the device accordingly, so the same code runs on GPU machines, CPU-only CI runners, and developer laptops without modification. Resolve the device once and pass/inject it, rather than sprinkling availability checks everywhere.

  ```python
  import torch

  # Bad — crashes on any machine without a GPU
  model = MyModel().cuda()

  # Good — device resolved from the environment
  device: torch.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
  model = MyModel().to(device)
  batch = batch.to(device)
  ```

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

## 7. Testing (pytest) — Expanded

Building on section 2.11 (pytest, `tests/` at root, one file per AI feature):

- **Factories over fixtures for models.** Use `factory_boy` (with `pytest-django`) to build Django model instances in tests rather than hand-written fixtures or raw `.objects.create()` calls — factories keep tests readable and resilient to model changes.
- **Always mock external calls.** No test may hit a real third-party API, payment provider, or remote model endpoint. Mock at the boundary (the typed wrapper from section 1.1) with `pytest-mock` / `responses`. A test that requires the network is a broken test.
- **Coverage.** Target a meaningful line+branch coverage floor (e.g., 80%) enforced in CI via `pytest --cov`. Coverage is a floor, not a goal — prioritize testing behavior and edge cases over chasing the number.
- **GPU-dependent tests.** Mark any test that requires a GPU with `@pytest.mark.gpu`. CI runs on CPU-only runners and must skip these automatically (`addopts = "-m 'not gpu'"` by default, with an opt-in job on the cluster). Model/feature logic should be testable on CPU with tiny tensors; reserve `gpu` marks for genuine device-specific paths.
- **Determinism in tests.** Tests that touch model code must seed explicitly (section 8) so failures are reproducible.
- **Test the task, not Celery.** Unit-test Celery task *functions* by calling them synchronously with a known object PK; don't spin up a broker. Assert idempotency explicitly by invoking the task twice and checking state is unchanged the second time.

---

## 8. ML Reproducibility & Shared-Cluster Discipline

Because training runs on a **shared GPU cluster**, code must never assume a specific device, a free GPU, or exclusive machine access.

- **Seed everything.** Every training/validation/test entry point must call `lightning.seed_everything(cfg.seed, workers=True)` before any model or data construction, and the seed must be a field in the run's YAML config and logged to W&B. No unseeded runs.
- **Never assume `cuda:0`.** Do not hardcode a device index. Resolve devices through Lightning's `Trainer(accelerator="auto", devices="auto")` (or `devices=cfg.devices`), and let the cluster scheduler / `CUDA_VISIBLE_DEVICES` decide which physical GPUs you get. The `.cuda()` ban in section 4 applies with extra force here — always go through the resolved `device` or Lightning.
- **Deterministic mode when required.** For runs that must be bit-reproducible, set `Trainer(deterministic=True)` and document the (small) throughput cost; otherwise log that determinism is off so results are interpreted accordingly.
- **Checkpoint naming tied to W&B.** Checkpoints written to `models/<modality>/` must embed the W&B run id (and epoch/metric) in the filename, e.g. `models/text/{wandb_run_id}-epoch{epoch:02d}-val_loss{val_loss:.3f}.ckpt`, so any weight file is traceable back to the exact experiment, config, and metrics that produced it.
- **No exclusive-resource assumptions.** Don't assume all GPUs on a node are yours, don't pin CPU affinity, and set dataloader `num_workers` from config (not a hardcoded max) so a job co-scheduled with others doesn't oversubscribe the node.
- **Fail fast on OOM/config mismatch.** Validate batch size × model size against the *requested* memory allocation at startup (via the config model, section 1.3) rather than discovering an OOM three hours into a run.

---

## 9. Database Migrations Discipline

- **Never edit an applied migration.** Once a migration has run anywhere beyond your local machine (CI, staging, a teammate's DB), it is immutable. Fix problems with a *new* migration.
- **Always review autogenerated migrations.** `makemigrations` output is a draft. Read every generated migration before committing — check for unintended table rewrites, wrong `on_delete`, or accidental data loss.
- **Separate schema and data migrations.** Never mix schema changes and data backfills in the same migration file. Keep `RunPython` data migrations in their own files, make them reversible where feasible, and remember they run inside a transaction (respect the Celery/`on_commit` rules if they enqueue work).
- **Backfills are idempotent and batched.** Large data migrations follow the same idempotency principle as Celery tasks (section 3.3) and should batch with `tqdm`-scoped progress (per section 1.1's scope exception if run via a management command).
- **Name migrations meaningfully.** Use `--name` to give migrations descriptive names instead of Django's autogenerated `0007_auto_...`.

---

## 10. Django Ninja API Conventions

The API layer is **Django Ninja**, which uses Pydantic natively — so it dovetails directly with section 1 and there is **no separate serializer layer**.

- **Schemas are the Pydantic models from section 1.2.** Request and response bodies are declared as Ninja `Schema` (a Pydantic `BaseModel` subclass) with the same `Field` constraints. Do **not** introduce DRF serializers or a parallel validation layer — the schema *is* the validation.
- **Separate input and output schemas.** Define distinct `XInput`/`XOut` schemas rather than reusing one model for both directions; never expose write-only or internal fields in a response schema.
- **Endpoints stay thin.** A Ninja operation validates via its schema, delegates to a typed service/feature function, and returns a response schema — mirroring the "thin views" rule (section 3.2). Business logic and heavy work go to services and Celery, never into the endpoint body.
- **Typed responses.** Every operation declares its response type (`response=XOut` or `response={200: XOut, 404: ErrorOut}`) so the OpenAPI schema and runtime validation stay accurate.
- **Centralized error handling.** Map the custom exception hierarchy (section 5.1) to HTTP responses with `@api.exception_handler(AppError)`; endpoints raise domain exceptions rather than building error responses inline.
