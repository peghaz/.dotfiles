# Django and Backend Projects

Apply this reference when the Python task involves Django, PostgreSQL, Celery, migrations, or Django Ninja APIs.

---

## 3. Django, Celery, & PostgreSQL Architecture Rules

### 3.1 Environment & Settings Rules

- **Use the shared environment configuration convention.** Read [`configuration.md`](configuration.md). Define a `pydantic-settings.BaseSettings` subclass for Django's environment-backed values and instantiate it once in `settings.py`. Never call `os.getenv()`, `os.environ.get()`, or `load_dotenv()` in views, models, tasks, services, or other feature code. Consume finalized Django settings through `django.conf.settings` everywhere else.

  ```python
  # Bad — scattered, untyped, string-only access in a view
  def checkout(request):
      stripe_key = os.environ.get("STRIPE_KEY")  # None if missing; discovered at runtime

  # Good — declared once in settings.py, consumed via settings
  # settings.py
  STRIPE_KEY: str = config.stripe_key.get_secret_value()

  # views.py
  from django.conf import settings
  stripe.api_key = settings.STRIPE_KEY
  ```

- **Validate before configuring Django.** Give endpoints, credentials, allowed hosts, debug state, database connection details, broker URLs, and similar values explicit settings fields. Missing or invalid required values must fail during Django startup. Use `SecretStr` for Django's secret key and external credentials, revealing a raw value only when assigning the framework setting or calling the external integration.

- **Connection pooling via `CONN_MAX_AGE`.** Always set `CONN_MAX_AGE` in the `DATABASES` dictionary to allow PostgreSQL connection pooling (e.g., set to 600 seconds, or let `env.db()` handle it via the database URL). Without it, Django opens and tears down a fresh PostgreSQL connection on every request, which wastes latency and hammers the database's connection slots under load.

  ```python
  # settings.py
  from pathlib import Path

  import dj_database_url
  from pydantic import PostgresDsn, SecretStr
  from pydantic_settings import BaseSettings, SettingsConfigDict

  BASE_DIR = Path(__file__).resolve().parent.parent


  class DjangoConfig(BaseSettings):
      """Validated Django process and dotenv configuration."""

      model_config = SettingsConfigDict(
          env_file_encoding="utf-8",
          case_sensitive=False,
          extra="ignore",
      )

      django_secret_key: SecretStr
      database_url: PostgresDsn


  config = DjangoConfig(_env_file=BASE_DIR / ".env")
  SECRET_KEY = config.django_secret_key.get_secret_value()
  DATABASES = {
      "default": dj_database_url.parse(
          str(config.database_url),
          conn_max_age=600,
      ),
  }
  ```

- **Keep the dotenv contract visible.** Add `.env` to `.gitignore` and `.dockerignore`, and commit a synchronized `.env.example` containing dummy values for every supported variable. Treat any secret that was ever committed as compromised and rotate it.

- **Containerized databases use the Docker skill.** When Django depends on PostgreSQL, Redis, a broker, or another containerized service, read the sibling [`Docker skill`](../../docker/SKILL.md). Use the same root `.env` as Docker Compose, while allowing non-secret topology overrides such as the Compose database hostname.

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

---

## 9. Database Migrations Discipline

- **Never edit an applied migration.** Once a migration has run anywhere beyond your local machine (CI, staging, a teammate's DB), it is immutable. Fix problems with a *new* migration.
- **Always review autogenerated migrations.** `makemigrations` output is a draft. Read every generated migration before committing — check for unintended table rewrites, wrong `on_delete`, or accidental data loss.
- **Separate schema and data migrations.** Never mix schema changes and data backfills in the same migration file. Keep `RunPython` data migrations in their own files, make them reversible where feasible, and remember they run inside a transaction (respect the Celery/`on_commit` rules if they enqueue work).
- **Backfills are idempotent and batched.** Large data migrations follow the same idempotency principle as Celery tasks (section 3.3) and should batch with `tqdm`-scoped progress (per section 1.1's scope exception if run via a management command).
- **Name migrations meaningfully.** Use `--name` to give migrations descriptive names instead of Django's autogenerated `0007_auto_...`.

---

---

## 10. Django Ninja API Conventions

The API layer is **Django Ninja**, which uses Pydantic natively — so it dovetails directly with section 1 and there is **no separate serializer layer**.

- **Schemas are the Pydantic models from section 1.2.** Request and response bodies are declared as Ninja `Schema` (a Pydantic `BaseModel` subclass) with the same `Field` constraints. Do **not** introduce DRF serializers or a parallel validation layer — the schema *is* the validation.
- **Separate input and output schemas.** Define distinct `XInput`/`XOut` schemas rather than reusing one model for both directions; never expose write-only or internal fields in a response schema.
- **Endpoints stay thin.** A Ninja operation validates via its schema, delegates to a typed service/feature function, and returns a response schema — mirroring the "thin views" rule (section 3.2). Business logic and heavy work go to services and Celery, never into the endpoint body.
- **Typed responses.** Every operation declares its response type (`response=XOut` or `response={200: XOut, 404: ErrorOut}`) so the OpenAPI schema and runtime validation stay accurate.
- **Centralized error handling.** Map the custom exception hierarchy (section 5.1) to HTTP responses with `@api.exception_handler(AppError)`; endpoints raise domain exceptions rather than building error responses inline.
