# Installable Packages with uv

Apply this reference when creating or changing an installable Python distribution managed with `uv`.

## Project Layout

- Use `pyproject.toml` as the source of truth for project metadata, supported Python versions, build configuration, dependencies, optional extras, and tool settings.
- Manage environments and dependencies with `uv`. Keep the repository's development environment reproducible with `uv.lock`.
- Place distributable code under `src/<import_name>/`. Keep tests, local scripts, generated artifacts, and host-application code outside the package directory.
- Treat the distribution name and import name as separate identifiers: a distribution such as `example-package` is normally imported as `example_package`.
- Prefer `uv_build` for pure-Python packages unless the repository requires another build backend.

## Package Boundaries

- Keep package code independent of a consuming application's settings module, concrete ORM models, filesystem layout, and deployment environment. Pass dependencies and validated configuration through explicit interfaces.
- Define the public API deliberately through package exports. Keep `__init__.py` thin and free of application logic.
- Put runtime dependencies in `[project.dependencies]`, development-only tools in dependency groups, and heavy or feature-specific dependencies in named optional extras.
- Keep optional dependency imports inside their feature boundary so the base package remains importable without the extra.
- Include required runtime resources, typing information, and package data in the built distribution.
- Preserve public interfaces during internal refactors unless the task explicitly changes the contract.

## Build & Verification

- Run formatting, linting, typing, and tests through the repository's `uv` environment.
- Build both wheel and source distribution and inspect their contents.
- Test the built artifact in a clean environment. Do not assume imports from the source checkout prove that the installed package works.
- Verify that the documented installation command, imports, optional extras, and public entry points work from the installed artifact.
