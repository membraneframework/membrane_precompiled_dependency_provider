# Membrane Precompiled Dependency Provider

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_precompiled_dependency_provider.svg)](https://hex.pm/packages/membrane_precompiled_dependency_provider)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_precompiled_dependency_provider/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_precompiled_dependency_provider.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_precompiled_dependency_provider)

Package providing URLs for precompiled dependencies used by Membrane plugins.

## Installation

The package can be installed by adding `membrane_precompiled_dependency_provider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_precompiled_dependency_provider, "~> 0.1.0"}
  ]
end
```

## Usage

In most cases the package is intended to provide an URL to be used in your project's `bundlex.exs`. This text will assume familiarity with Bundlex and it's mechanism of managing precompiled dependencies, so if you're not acquainted with it you can read about it [here](https://hexdocs.pm/bundlex/readme.html).

Dependencies that are fully located in a correctly structured repository in `membraneframework-precompiled` organization will be referred to as _Generic_. Otherwise they will be referred to as _Non-generic_.

The simplest example of `natives/0` function in `bundlex.exs`, where we have an `:example` native that has an `:example_dep` Generic dependency and it's precompiled build is available in one of `membraneframework-precompiled` repositories:

```elixir
defp natives() do
  [
    example: [
      interface: :nif,
      sources: ["example.c"],
      os_deps: [
        example_dep: 
        [{
          :precompiled, 
          Membrane.PrecompiledDependencyProvider.get_precompiled_dependency_url(:example_dep)
        }]
      ],
      preprocessor: Unifex
    ]
  ]
```

#### Adding Non-generic dependency

When the precompiled builds of a dependency are already hosted somewhere else they can be added to this package as a Non-generic dependency. 

To achieve this add the following changes in `lib/membrane_precompiled_dependency_provider.ex`:
* Add the dependency name as one of possible values of `precompiled_dependencies()` type:
```elixir
@type precompiled_dependency() :: ... | :non_generic_example_dep
```

* Create a clause of `get_non_generic_dep_url/2` that pattern-matches on your dependency's name and returns an URL appropriate for the passed target:
```elixir
defp get_non_generic_dep_url(:non_generic_example_dep, target) do
  ...
end
```
 
For an example see implementation for `:ffmpeg`.

## Copyright and License

Copyright 2023, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)