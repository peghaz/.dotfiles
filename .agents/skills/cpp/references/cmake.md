# CMake Projects

Use modern, target-based CMake. A target must carry its own sources, include paths, compile features, definitions, options, and link dependencies so consumers receive exactly the usage requirements they need.

## Configure the Project

Declare the oldest CMake version the project actually supports. Do not claim compatibility with a version that CI does not test. Keep the root `CMakeLists.txt` small and use subdirectories for real targets:

```cmake
cmake_minimum_required(VERSION 3.24)

project(
    example
    VERSION 0.1.0
    DESCRIPTION "Example C++ project"
    LANGUAGES CXX
)

include(CTest)

option(EXAMPLE_BUILD_APPS "Build example executables" ON)
option(EXAMPLE_WARNINGS_AS_ERRORS "Treat project warnings as errors" OFF)

add_subdirectory(src)

if(EXAMPLE_BUILD_APPS)
    add_subdirectory(apps)
endif()

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
```

Replace `3.24` with the real supported baseline. Prefix project-specific cache options with the project name. Use CMake's conventional `BUILD_TESTING` switch rather than inventing a second tests option.

Require out-of-source builds so generated state does not pollute the source tree. Put every preset under `build/<preset-name>/`, add `/build/` to the root `.gitignore`, and never use the source tree itself as a CMake binary directory.

## Define Targets, Not Global State

Prefer this shape for a library:

```cmake
add_library(example_core)
add_library(example::core ALIAS example_core)

target_sources(
    example_core
    PRIVATE
        widget.cpp
    PUBLIC
        FILE_SET HEADERS
        BASE_DIRS "${PROJECT_SOURCE_DIR}/include"
        FILES "${PROJECT_SOURCE_DIR}/include/example/widget.hpp"
)

target_compile_features(example_core PUBLIC cxx_std_20)

target_include_directories(
    example_core
    PUBLIC
        "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
        "$<INSTALL_INTERFACE:include>"
)
```

- Use namespaced aliases such as `example::core` everywhere outside the target's defining directory.
- Express the language level with `target_compile_features`; disable compiler extensions when portability requires strict standard conformance.
- Use `PRIVATE`, `PUBLIC`, and `INTERFACE` according to whether a requirement affects only the implementation, both implementation and consumers, or consumers only.
- Avoid directory-wide commands such as `include_directories`, `link_directories`, `add_compile_options`, and `add_definitions` for project behavior. Never mutate `CMAKE_CXX_FLAGS`.
- List source files explicitly. Avoid `file(GLOB ...)` for build inputs because adding a file may not reliably trigger reconfiguration in every workflow.
- Do not put unrelated targets and platform logic into one large `CMakeLists.txt`; keep configuration beside the targets it defines.

Use an `INTERFACE` target for reusable warning, sanitizer, or project-option settings. Link it privately to project targets so these settings do not leak into consumers.

## Dependencies

Prefer imported targets supplied by packages:

```cmake
find_package(fmt CONFIG REQUIRED)
target_link_libraries(example_core PRIVATE fmt::fmt)
```

- Prefer `find_package(... CONFIG REQUIRED)` with a package manager or documented system dependency for stable project dependencies.
- Use `FetchContent` only when repository-local acquisition is intentional. Pin an immutable commit or release archive hash; never track an unpinned branch.
- Do not use `ExternalProject` for an ordinary target dependency unless a true separate build is required.
- Mark third-party include directories as `SYSTEM` only when appropriate, and do not weaken warnings globally to accommodate a dependency.
- A public dependency of an installed library must be discoverable by the installed package configuration, normally with `find_dependency`.

Keep one documented dependency strategy per repository. For new projects that need external C or C++ dependencies, prefer **vcpkg manifest mode** unless the user or repository has selected another strategy. Do not introduce a second package manager merely for convenience.

### vcpkg Manifest Mode

Use project-local manifest mode, not classic mode or a developer's machine-global installed package set. Commit `vcpkg.json` at the project root beside the top-level `CMakeLists.txt`:

```json
{
  "$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg.schema.json",
  "name": "example",
  "version-semver": "0.1.0",
  "builtin-baseline": "<full-vcpkg-registry-commit>",
  "dependencies": [
    "fmt"
  ],
  "features": {
    "tests": {
      "description": "Dependencies required by the test targets",
      "dependencies": [
        "gtest"
      ]
    }
  }
}
```

- Use lowercase manifest names accepted by vcpkg. Declare every direct dependency; do not rely on a transitive dependency remaining available.
- Set `builtin-baseline` to a full registry commit so dependency resolution is reproducible. Update it deliberately, review the resulting version changes, then build and test all supported triplets.
- Use `version>=` only when the project needs a minimum newer than the selected baseline. Use `overrides` sparingly for an exact version and document why normal baseline resolution is insufficient.
- Use manifest features for optional components such as tests, tools, or examples. Keep the default dependency set limited to what the normal library or application build requires.
- Mark build tools that execute on the build machine as host dependencies with `"host": true`; target libraries must remain target dependencies.
- Add `vcpkg_installed/` to `.gitignore`. Never commit downloaded packages, build trees, binary cache contents, or a developer-specific vcpkg root.

The registry baseline pins port definitions, but the team must also use a documented vcpkg tool revision. Pin the vcpkg checkout in CI, a development-container image, or a repository submodule when the project needs fully reproducible tooling. Do not silently run an arbitrary moving vcpkg checkout.

### CMake and Preset Integration

Set the vcpkg toolchain before the first `project()` call. Prefer the shared `CMakePresets.json` rather than hard-coding a machine path in `CMakeLists.txt`:

```json
{
  "version": 5,
  "configurePresets": [
    {
      "name": "dev",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
        "CMAKE_TOOLCHAIN_FILE": {
          "type": "FILEPATH",
          "value": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
        },
        "BUILD_TESTING": "ON",
        "VCPKG_MANIFEST_FEATURES": "tests"
      }
    }
  ]
}
```

Developers set `VCPKG_ROOT` in their shell or an ignored `CMakeUserPresets.json`; never commit an absolute local path. With the vcpkg toolchain active, CMake configuration automatically restores the manifest dependencies. Consume them only through normal CMake discovery and imported targets:

```cmake
find_package(fmt CONFIG REQUIRED)
target_link_libraries(example_core PRIVATE fmt::fmt)
```

All variables that influence vcpkg—such as `VCPKG_TARGET_TRIPLET`, `VCPKG_HOST_TRIPLET`, `VCPKG_MANIFEST_FEATURES`, and overlay paths—must be defined before `project()`, normally in a configure preset or toolchain. Changing them requires a clean reconfiguration when the cached ABI or dependency graph is no longer valid.

Use built-in triplets when they express the target correctly. Add a custom triplet only for real ABI, linkage, compiler, runtime, or platform requirements, keep it in the repository, and select it explicitly with `VCPKG_TARGET_TRIPLET`. When cross-compiling with another CMake toolchain, integrate it through `VCPKG_CHAINLOAD_TOOLCHAIN_FILE` or a well-defined custom triplet instead of replacing the vcpkg toolchain accidentally.

### Registries, Overlays, and Caches

- Use `vcpkg-configuration.json` only when custom registries or repository-owned overlay ports/triplets are required. Commit it, use repository-relative overlay paths, and pin Git registries to immutable baselines.
- Put private-registry and binary-cache credentials in the environment or the CI secret store. Never place tokens in manifests, presets, configuration files, command output, or source control.
- Keep overlay ports small and owned: record upstream source hashes, patches, licenses, and the reason an official port cannot be used. Prefer contributing generally useful fixes upstream.
- Use vcpkg binary caching in CI and for expensive local dependency builds. Configure it with `VCPKG_BINARY_SOURCES`; prefer the binary cache over archiving `vcpkg_installed/` or an entire CMake build tree.
- Treat binary caches as compiler-, triplet-, feature-, toolchain-, and port-revision-sensitive. Do not share writable caches across trust boundaries, and do not expose cache credentials in debug logs.

When vcpkg dependency resolution changes, review `vcpkg.json`, `vcpkg-configuration.json` when present, the selected baseline/tool revision, enabled features, and target triplets together. A successful build on one developer machine is not evidence that an undeclared or globally installed dependency has been removed.

## Presets and Developer Workflows

Commit `CMakePresets.json` for shared configure, build, and test workflows. Add `CMakeUserPresets.json` to `.gitignore` and reserve it for machine-local paths or developer overrides. Do not store secrets in either file.

Useful shared presets normally include:

- A developer debug build with compile commands exported.
- A release build.
- A sanitizer build when supported.
- Matching build and test presets so developers and CI use the same configuration path.

Use a predictable binary directory such as `${sourceDir}/build/${presetName}`. Prefer:

```text
cmake --preset dev
cmake --build --preset dev
ctest --preset dev
```

over undocumented collections of `-D` flags. Keep IDEs, local commands, and CI aligned on the same presets. For single-config generators, set `CMAKE_BUILD_TYPE` in the configure preset; for multi-config generators, select the configuration in build and test presets.

Set `CMAKE_EXPORT_COMPILE_COMMANDS=ON` in developer presets where the generator supports it, enabling clangd and static-analysis tools without changing release packaging.

## Warnings, Sanitizers, and Tooling

- Detect the compiler and apply supported warning flags through a project-owned target or helper function. Account for MSVC and Clang-cl separately from GNU-like command lines.
- Keep warnings-as-errors behind a project option that defaults off for consumers and dependency builds. CI may enable it for first-party targets.
- Enable sanitizers only for compatible compilers and platforms, and apply both compile and link options to the relevant project targets.
- Do not combine ThreadSanitizer with AddressSanitizer in the same build. Verify platform support before exposing a preset.
- Integrate clang-tidy through a developer/CI preset or target property. Do not unexpectedly impose it on users building the installed package.
- Use generator expressions when a setting truly varies by compiler, configuration, language, or build/install context. Keep them readable; move repeated complex expressions into a focused helper.

## Tests

Guard test targets with `BUILD_TESTING` and register them with CTest:

```cmake
add_executable(example_core_tests widget_test.cpp)

target_link_libraries(
    example_core_tests
    PRIVATE
        example::core
        GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(example_core_tests)
```

Use the equivalent supported integration when the project chooses Catch2. Do not make test-only dependencies part of the installed library's public interface. Set working directories, environment variables, fixtures, labels, timeouts, and resource locks explicitly when tests depend on them.

Prefer testing through targets and CTest rather than custom commands that bypass CMake's dependency graph. A test requiring external services should be clearly labeled and separate from fast deterministic unit tests.

## Installation and Package Export

For an installable library, use standard install directories and export CMake targets:

```cmake
include(GNUInstallDirs)

install(
    TARGETS example_core
    EXPORT exampleTargets
    FILE_SET HEADERS DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(
    EXPORT exampleTargets
    FILE exampleTargets.cmake
    NAMESPACE example::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/example"
)
```

Also generate and install `exampleConfig.cmake` plus a version file with `CMakePackageConfigHelpers`. Put the config template under `cmake/` and call `find_dependency` there for public transitive dependencies. Test the installed package from a small external consumer project; a successful build in the source tree does not prove that install interfaces are correct.

Install only runtime binaries, libraries, public headers, licenses, and package metadata. Do not install tests, private headers, build outputs, local presets, or developer-only resources unless the project explicitly publishes an SDK that needs them.

Use CPack only when the user needs platform or archive packages. CMake installation and package discovery should work correctly before adding packaging layers.

## Cross-Compilation and Platforms

- Describe cross-compilers, sysroots, and target-platform settings in a toolchain file, not scattered cache flags.
- Do not hard-code `/usr/local`, library suffixes, executable extensions, or one platform's path separators. Use CMake variables, imported targets, and `GNUInstallDirs`.
- Guard platform-specific sources and libraries with clear conditions and keep a common target/API when possible.
- Prefer `Threads::Threads` from `find_package(Threads REQUIRED)` over direct `-pthread` flags.
- Set runtime search paths deliberately for deployed shared libraries; do not rely on a developer machine's environment.

## CMake Completion Checklist

Before considering build-system work complete:

- Configure from a clean out-of-source directory using a supported preset.
- Build all affected targets without relying on undeclared environment state.
- When vcpkg is used, verify manifest restoration from an empty `vcpkg_installed` directory with the documented tool revision and target triplet.
- Run tests through CTest.
- Verify at least one intended Debug and Release workflow when configuration-sensitive behavior changed.
- Install to a temporary prefix and, for a library, build a minimal external consumer with `find_package`.
- Confirm project warnings, sanitizers, and analysis settings do not leak into third-party or downstream targets.
- Update CI and developer documentation when preset names, options, dependencies, or supported toolchains change.
