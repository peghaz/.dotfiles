---
name: cpp
description: Apply the owner's C++ architecture, ownership, API, naming, testing, and quality conventions when creating, changing, reviewing, or organizing C++ code. Use the linked CMake reference when build configuration, dependencies, tests, installation, or packaging are involved.
---

# C++ Engineering

Build maintainable C++ with explicit ownership, narrow interfaces, and automated quality checks. Follow the repository's established standard and style when they exist; otherwise use the defaults below. Direct user instructions and actual project configuration take precedence.

## Specialized Reference

For `CMakeLists.txt`, CMake presets, targets, dependencies, testing, installation, export, or packaging, read [`references/cmake.md`](references/cmake.md).

## Project Structure

For a new CMake project, prefer this separation:

```text
project-root/
├── .clang-format
├── .gitignore
├── CMakeLists.txt
├── CMakePresets.json
├── vcpkg.json              # manifest-mode dependencies, when needed
├── cmake/                  # optional CMake modules and package templates
├── include/project_name/   # public headers when the project exposes a library
├── src/                    # implementations, private headers, and executable entry point
├── tests/
├── examples/               # public API examples, when useful
├── benchmarks/             # measured performance work only
└── build/                  # generated out-of-source CMake output; always ignored
```

Do not create a separate `apps/` directory by default. Put an application's entry point in `src/main.cpp`, or another clearly named file under `src/` when the project builds multiple executables. Keep library logic out of the entry point: `main()` should parse inputs, compose dependencies, call reusable code, and translate the final result into a process exit code.

Every project uses an out-of-source `build/` directory managed through CMake presets. Add `/build/` to the root `.gitignore`; never commit its contents, place source files there, or hand-edit generated files. Do not create optional source directories merely to match the example tree.

## Language and Portability

- Use the C++ standard already declared by the project. For a new project, default to C++20 unless a dependency, target platform, or user requirement calls for another standard.
- Write standard C++ first. Isolate compiler-, operating-system-, and architecture-specific code behind a small interface and guard it explicitly.
- Do not depend on compiler extensions unless the project requires them and CMake enables them deliberately.
- Compile and test on every supported compiler and platform in CI. Avoid assuming that behavior observed with one standard library is portable.

## Naming and Organization

Preserve an established repository style. When none exists, use:

- `snake_case` for files, namespaces, functions, and local variables.
- `PascalCase` for classes, structs, enums, and type aliases.
- `kPascalCase` for constants.
- A trailing underscore for private data members, such as `socket_`.
- An uppercase project prefix for unavoidable macros, such as `PROJECT_NAME_EXPORT`.

Use namespaces that reflect the public library or domain, not the directory tree in full. Never place `using namespace` in a header. Keep source files focused on one cohesive component; split files when responsibilities or dependency boundaries differ, not at an arbitrary line count.

## Formatting

Use **Allman brace style** for all C and C++ code: opening braces belong on their own line for namespaces, types, functions, control statements, and initializer blocks. Do not retain one-line functions or control blocks that bypass the brace style.

Commit a root `.clang-format` and treat it as the formatting authority. Preserve established non-brace options in an existing file, but require `BreakBeforeBraces: Allman`. For a new project, begin with:

```yaml
BasedOnStyle: LLVM
IndentWidth: 4
ContinuationIndentWidth: 4
TabWidth: 4
UseTab: Never
ColumnLimit: 100
BreakBeforeBraces: Allman
AllowShortBlocksOnASingleLine: Never
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: None
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false
```

Format changed C and C++ files with `clang-format -i` before completion. CI should run `clang-format --dry-run --Werror` on first-party sources using the project's pinned or documented clang-format version; different clang-format releases may produce different output.

## Headers and Public APIs

- Put stable consumer-facing headers in `include/project_name/`. Keep implementation-only headers beside the relevant source or in a private `detail` area that is not installed.
- Make every header self-contained: it must compile when included first and must include what it uses.
- Minimize the public surface. Do not expose implementation types, third-party types, or transitive includes without an intentional API reason.
- Prefer forward declarations only when they are correct and materially reduce coupling. Never forward-declare entities in `std`.
- Prefer the Rule of Zero. If a type manages a resource directly, define or delete copy and move operations deliberately.
- Mark single-argument constructors `explicit` unless implicit conversion is an intentional part of the API.
- Give polymorphic base classes a virtual destructor when deletion through the base is supported. Otherwise protect or delete the destructor to make the restriction clear.
- Use `[[nodiscard]]` for results that callers should not silently discard. Use `noexcept` only when the function genuinely cannot allow an exception to escape.
- Preserve ABI compatibility only when the project promises it. Consider PImpl when ABI stability, compile-time isolation, or hiding dependencies justifies its cost.

Document public APIs with the project's documentation format, preferably Doxygen-compatible comments when generated API documentation is needed. Explain contracts, ownership, lifetime, units, thread safety, and failure behavior; do not restate obvious syntax.

## Ownership, Lifetime, and Types

- Use RAII for memory, files, sockets, locks, handles, and other resources. Destructors must not throw.
- Prefer values and references. Use `std::unique_ptr` for exclusive dynamic ownership and `std::shared_ptr` only when ownership is genuinely shared. A raw pointer is non-owning and normally nullable; use a reference for a required non-null borrowed object.
- Make lifetime requirements explicit. Do not store `std::string_view`, `std::span`, iterators, references, or raw pointers beyond the lifetime of their owner.
- Prefer `std::span` for borrowed contiguous ranges and `std::string_view` for borrowed text when their lifetime is unambiguous. Prefer owning containers or strings when data must outlive the call.
- Use `const` to express immutability and references to avoid unnecessary copies. Do not add `std::move` to a local return value when it can inhibit copy elision.
- Prefer `enum class` over unscoped enums and strong domain types over unrelated primitive values that can be confused.
- Avoid C-style casts, manual `new`/`delete`, variable-length arrays, and mutable global state. Use the narrowest appropriate named C++ cast when a cast is necessary.

## Errors and Boundaries

Choose one coherent error strategy for each API boundary and document it:

- Use exceptions for failures that cannot be handled locally when the project permits exceptions.
- Use an explicit result type for expected operational failures when callers are required to branch on the outcome. Use `std::expected` only when the selected language standard provides it; otherwise use the project's established result type.
- Do not encode failure with magic values. Use `std::optional` only for absence, not for an error that needs diagnostic information.
- Catch the narrowest exception type and only where recovery, context, cleanup beyond RAII, or translation is possible. Preserve the active exception with `throw;` when rethrowing it unchanged.
- Never allow a C++ exception to cross a C ABI, plugin ABI, thread entry point, or process boundary. Catch and translate at that boundary.
- Do not log and rethrow the same failure at every layer. Add context once at the layer that understands it, and avoid logging credentials or sensitive payloads.

Use assertions for programmer invariants, not for validating untrusted input or recoverable runtime conditions. Assertions may be compiled out.

## Concurrency

- Prefer structured lifetime management such as `std::jthread` and `std::stop_token` in C++20. Do not detach threads unless process-lifetime behavior is explicit and unavoidable.
- Protect shared state with RAII locks and keep critical sections small. Document the synchronization policy of shared classes.
- Prefer message passing, immutable data, or task-based composition over widespread shared mutable state.
- Do not mark a type or function thread-safe without tests and a clear ownership/synchronization contract.

## Testing and Quality Gates

- Use the testing framework already selected by the repository. For a new project, choose either GoogleTest or Catch2 based on dependency and integration needs; do not mix frameworks without a concrete reason.
- Test public behavior, error paths, boundary values, ownership/lifetime-sensitive behavior, and regression cases. Keep tests deterministic and independent of execution order.
- Register tests with CTest and give each test target only the dependencies it needs.
- Add property or fuzz tests for parsers, decoders, protocol handlers, and other hostile-input surfaces when their risk warrants it.
- Keep the repository's Allman-style `.clang-format` authoritative and format changed C++ files consistently. Use `.clang-tidy` for checks the project can enforce without noisy false positives.
- Enable strong compiler warnings per project target. Treat warnings as errors in the project's CI when practical, but never force `-Werror` or its equivalent on downstream consumers.
- Run AddressSanitizer and UndefinedBehaviorSanitizer in a compatible debug CI job. Run ThreadSanitizer separately for concurrent code; sanitizer combinations and platform support must be verified rather than assumed.

## Dependencies and Performance

- Prefer the standard library and small, well-maintained dependencies. Add a dependency only when it materially reduces risk or maintenance cost.
- Pin or constrain dependency versions through the project's chosen package/dependency mechanism. Do not copy third-party source into the tree without a documented reason and license review.
- Keep third-party warnings and configuration from leaking into project targets. Adapt external APIs behind a local boundary when they would otherwise spread through the codebase.
- Measure before optimizing. Preserve a benchmark or profiler result for performance-driven changes and include realistic input sizes.
- Prefer clear algorithms and data layouts over clever micro-optimizations. State any performance contract that shapes the public API.

## Completion Checklist

Before considering C++ work complete:

- Build all affected targets from a clean out-of-source build.
- Run the relevant CTest suite.
- Run formatting and configured static analysis on changed files.
- Run the applicable sanitizer job for memory-, lifetime-, or concurrency-sensitive changes.
- Confirm new public headers are self-contained and installed/exported when the project is a library.
- Update examples or API documentation when public behavior changes.
