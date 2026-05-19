# Contributing

## Did you find a bug?

* Search existing issues first: <https://github.com/crmne/ruby_llm-schema/issues>.
* If it has not been reported, open a new issue with a clear description and a small reproduction.
* Verify it is a JSON Schema DSL issue, not application-specific code.

## Did you write a patch?

* Open a pull request with focused changes and tests.
* Run `overcommit --install` before committing so style and tests run locally.
* Make sure `bundle exec rspec` and `bundle exec rubocop` pass.

## Adding Features

This gem should stay intentionally small and standards-oriented. Before adding new behavior, open an issue and describe how it maps to JSON Schema and why it belongs in the gem instead of user code.

Good candidates:

* JSON Schema behavior covered by the specification.
* Small DSL improvements that help most users.
* Bug fixes for generated schema compatibility.

Avoid:

* Application-specific schema builders.
* Provider-specific policy logic.
* Large abstractions that can live in user code.

## Quick Start

```bash
gh repo fork crmne/ruby_llm-schema --clone && cd ruby_llm-schema
bundle install
overcommit --install
# make changes, add tests
bundle exec rspec
bundle exec rubocop
gh pr create --web
```
