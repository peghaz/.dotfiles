# Installable AI Projects

Apply this reference when the Python task involves AI/ML project structure, training, evaluation, inference, datasets, models, prompts, or experiment tracking.

## Project Layout

Use an installable `src` layout so the project can later be built and consumed as a Python package:

```text
project-root/
├── .env                    # optional local secrets/endpoints; gitignored
├── .env.example            # committed when environment settings are required
├── cli.py                  # developer entry point; not included in the wheel
├── pyproject.toml
├── src/
│   └── project_name/
│       ├── __init__.py
│       ├── config/
│       │   ├── __init__.py
│       │   ├── environment.py
│       │   ├── models.py
│       │   └── loader.py
│       ├── defaults/
│       │   └── config/
│       │       └── prompts/
│       │           ├── system.md
│       │           └── user.md
│       ├── training/
│       ├── evaluation/
│       ├── inference/
│       ├── data/
│       └── models/
├── configs/
│   ├── train.yaml
│   ├── evaluation.yaml
│   └── prompts/
│       ├── system.md
│       └── user.md
├── tests/
├── datasets/        # raw/local data, normally gitignored
└── artifacts/       # checkpoints, weights, exports, and generated outputs
```

Keep these responsibilities distinct:

- `config/environment.py` contains the `pydantic-settings` class for environment-backed endpoints, credentials, and service connections when the project needs them.
- The rest of `config/` contains typed dataclasses and loaders for YAML configuration and prompt files. It contains code, not project-specific configuration values.
- `defaults/config/prompts/` contains built-in Markdown prompts required by the installed package.
- `training/` contains training workflows and orchestration, not CLI parsing.
- `evaluation/` contains validation, test, metrics, and comparison workflows. Prefer one workflow with a configurable split when validation and test behavior are the same.
- `inference/` contains reusable prediction and serving logic.
- `data/` contains dataset and dataloader classes, samplers, transforms, and collation code. Raw datasets never belong inside the package.
- `models/` contains model architecture and model-related source code only. Never store weights, checkpoints, or exported binaries there.
- Root `cli.py` is the developer-only Typer entry point.
- Root `.env` contains developer credentials and deployment-specific endpoints and is never committed. `.env.example` documents the contract with dummy values.
- Root `configs/` contains non-secret developer configuration and user-editable Markdown prompt overrides.
- `datasets/` contains raw or locally prepared data and is normally ignored by Git.
- `artifacts/` contains generated checkpoints, weights, exports, resolved run configuration, and metadata. It is normally ignored by Git or managed by artifact storage.

Add subpackages only when the project needs them. Do not pre-create modality folders such as `audio/`, `text/`, or `image/` for unused capabilities.

## Distribution Boundary

The wheel contains the importable package under `src/project_name/`, including any required package resources under that directory. Root `cli.py`, `configs/`, `tests/`, `datasets/`, `artifacts/`, and other development files must not be installed as package modules or wheel data.

Use `uv_build` with the `src` module layout. Package code must not assume the repository checkout or any root development directory exists after installation. Build the wheel and inspect its contents to verify that package defaults are present and developer-only files are absent.

## Root Typer CLI

Expose repository-development workflows through the Typer application in root `cli.py`:

```text
uv run cli.py train --config configs/train.yaml
uv run cli.py evaluate --config configs/evaluation.yaml --split validation
uv run cli.py infer --config configs/inference.yaml
uv run cli.py prepare-data --config configs/data.yaml
uv run cli.py export --config configs/export.yaml
```

The root script may contain the single `if __name__ == "__main__": app()` entry point. Do not add individual `__main__` blocks to training, evaluation, inference, or data modules.

Keep `cli.py` as a thin composition point that loads developer configuration and calls typed functions from `project_name`. Package modules must remain callable and testable without Typer and must never import the root script. The root CLI is not a distributed console entry point unless distribution of the CLI is requested separately.

For VS Code debugging, run `uv sync`, select the project's `.venv` interpreter, set the debugger program to `${workspaceFolder}/cli.py`, and pass the Typer command and options through the debugger's argument list.

## YAML Configuration

Represent YAML configuration sections with typed dataclasses and compose them into a top-level experiment configuration. Use Pydantic dataclasses or explicit validation for untrusted or constrained values.

Load YAML once at the CLI or public-API boundary, resolve defaults and explicit overrides, and pass the resulting configuration object into the workflow. Do not read YAML or environment variables from deep inside model, data, or training code.

Keep the two configuration domains separate:

- YAML contains non-secret experiment and workflow values such as model identifiers, batch sizes, data paths, prompt paths, seeds, devices, precision, and checkpoint policy.
- `pydantic-settings` loads deployment-specific environment values such as LLM endpoints and credentials, W&B credentials, private model-registry tokens, and service connection details. Follow [`configuration.md`](configuration.md).

Load and validate both domains in root `cli.py`, then pass them explicitly to the package workflow. Environment variables may override environment-backed settings, but must not silently replace unrelated experiment values unless the project documents that override.

Save the fully resolved configuration with every run so its artifacts can be reproduced.

## Markdown Prompts

Store all prompt text in UTF-8 `.md` files, never as Python string constants. Built-in defaults belong inside the distributable package:

```text
src/project_name/defaults/config/prompts/system.md
src/project_name/defaults/config/prompts/user.md
```

Developer or end-user overrides belong outside the package:

```text
configs/prompts/system.md
configs/prompts/user.md
```

When a project has multiple prompt-driven workflows, group each pair in a descriptive subdirectory such as `prompts/<workflow>/system.md` and `prompts/<workflow>/user.md`. Keep the filename focused on the message role rather than repeating the workflow name.

YAML configuration should select the prompt files by path:

```yaml
prompts:
  system: configs/prompts/system.md
  user: configs/prompts/user.md
```

The package's `config/` code must provide typed prompt configuration and a loader that:

- uses an explicitly configured external prompt path when provided;
- otherwise reads the corresponding packaged default with `importlib.resources`;
- reads and resolves prompts once at the application boundary;
- rejects missing, empty, or unreadable files with clear errors;
- validates required template placeholders before model execution;
- preserves Markdown formatting and Unicode content;
- resolves override paths consistently from the project root or configuration-file directory; and
- passes loaded prompt content into workflows instead of letting deep modules read files globally.

Do not import prompts from `config.py` or embed production prompt text in execution logic.

Document prompt customization for end users. The README or package documentation must show both supported approaches:

1. Copy, edit, or replace a prompt under root `configs/prompts/` and point to it from YAML. Omitting an override uses the packaged default.
2. In Python code, construct or override the typed prompt-path configuration before creating the workflow, for example:

```python
from pathlib import Path

from project_name.config import PromptPaths

prompt_paths = PromptPaths(
    system=Path("configs/prompts/custom/system.md"),
    user=Path("configs/prompts/custom/user.md"),
)
```

The public API should accept this configuration explicitly. Document every packaged default, override key, and required placeholder so users can safely customize prompts without reading implementation code. Never resolve packaged defaults through a source-tree `Path`; use package-resource APIs so they work from an installed wheel.

## Training Framework Choice

Choose one primary orchestration layer for each workflow:

- Plain PyTorch is acceptable for small or specialized training loops.
- Use PyTorch Lightning when its trainer, distributed execution, mixed precision, callbacks, checkpointing, or `LightningDataModule` materially simplifies the project. Do not require Lightning for simple workflows.
- For Transformer projects, prefer suitable Hugging Face classes such as `AutoConfig`, `AutoTokenizer`, and `AutoModel*`. Use `Trainer` and `TrainingArguments` when they fit; use Accelerate, Lightning, or a custom loop when more control is required.
- Do not wrap Hugging Face `Trainer` inside Lightning or maintain parallel training implementations without a concrete reason.

Keep model construction, tokenization, datasets, and metrics behind typed project interfaces. Preserve Hugging Face `save_pretrained()` and `from_pretrained()` compatibility when using compatible models.

## Weights & Biases

Use Weights & Biases for training and experiment logs. Record the resolved configuration, seed, code or package version, dataset reference, device information, training and validation metrics, and produced checkpoint identifiers.

Include the W&B run ID in local artifact metadata or the run directory. Use Lightning's `WandbLogger` with Lightning and the normal W&B or Hugging Face integration otherwise.

Read W&B credentials and deployment-specific W&B settings through the environment-backed configuration class; never hardcode them or store them in experiment YAML. Non-secret run metadata may remain in the experiment configuration. Support disabled or offline logging for tests and environments without network access. Tests must not contact W&B.

## Reproducibility & Resources

- Seed every training, validation, and test workflow before constructing models or dataloaders.
- Never hardcode `.cuda()`, `cuda:0`, or a physical GPU index. Respect the resolved device, `CUDA_VISIBLE_DEVICES`, and scheduler allocation.
- Configure batch size, precision, dataloader workers, devices, and checkpoint behavior instead of embedding machine-specific assumptions.
- Record whether deterministic execution is enabled.
- Keep enough metadata with every artifact to identify its configuration, framework, source version, prompts, and originating W&B run.

## Testing

Test training, evaluation, and inference functions independently from the CLI. Use tiny CPU-compatible datasets and models for routine tests, mark genuinely GPU-specific tests, and mock external model downloads and W&B communication.

Test configuration and prompt loading, including packaged-default fallback, external overrides, missing files, invalid YAML, empty prompts, missing placeholders, Unicode content, and path resolution. Test the root Typer entry point separately for command wiring, errors, and exit codes. Build and inspect the wheel to confirm that `src/project_name` and its default prompts are included while root developer resources are excluded.
