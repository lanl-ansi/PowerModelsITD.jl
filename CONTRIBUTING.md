# Developer Guide for PowerModelsITD

In this guide, we aim to communicate the various code standards expected for PowerModelsITD.

## Documentation

Documentation should be included for all new publicly exported additions to the code base.

- All new formulations should have their hierarchies be documented in `/docs/src/formulations.md`.
- All new constraints should have their mathematical form in their associated docstring.
- The usage details for all new exported functions should be documented via an associated docstring, with the exception of constraint and variable creation functions, which should contain mathematical details in their docstring.
- _Summaries_ of the purpose of new _unexported_ functions should be documented via an associated docstring.

## Style Conventions

In general, the following conventions should be adhered to when making changes or additions to the code base.
These conventions should include any conventions applied across the InfrastructureModels ecosystem, specific to power systems (i.e, conventions from InfrastructureModels, PowerModels, and PowerModelsDistribution), with some additions specific to PowerModelsITD.

### Functions

Function additions should meet the following criteria:

- All functions should be clearly named, without abbreviations, and with underscores between words, e.g., `parse_files`. In Python this is known as [`lower_case_with_underscores`](https://legacy.python.org/dev/peps/pep-0008/#descriptive-naming-styles). The exception to the abbreviation rule is cases where abbreviations would be expected in the modeling of power systems.
- All functions that are not prepended by an underscore `_` will be exported by default (i.e., when a user uses `using PowerModelsITD`). Public functions should have a detailed docstring instructing on usage.
- All functions that modify data in place should end with an exclamation point `!`, and the function input that is being modified should be the first argument (or first arguments in the case where multiple inputs are being modified in place). The exceptions to this rule are constraint and variable creation functions (i.e., those functions related to JuMP model creation), which do not include the exclaimation point
- All function arguments, including keyword arguments, should have their types specified.
- Private functions, i.e., those intended to be for internal use only, should follow the same descriptive naming conventions as functions exported by default, and they should always include docstrings to describe their purpose.
- Functions should be separated by two blank lines

```julia
"this function demonstrates how an internal, in-place data altering function should be defined"
function _concise_descriptive_name!(data::Dict{String,<:Any}, a::Real, b::Vector{<:Real}, c::Matrix{<:Complex}; d::Bool=false, e::Vector{<:Function}=Vector{Function}([]))
end
```

### Constants

Whenever possible, `const` should be used to eliminate unnecesary reevaluations of code, and every `const` should have a docstring, whether internal or public.

### JuMP Variables and Constraints

For functions that create JuMP variables and constraints, we use the following naming convention:

`<jump macro id>(_<phase variant>)_<comp short name>_<quantity name>(_real|_imaginary|_magnitude|_angle|_factor)(_fr|_to)(_on_off)`

### Formulations

- All new formulations should have __clear__ error messages when they do not support existing components.
- Formulation `abstract type` and `mutable struct` must be specified in [CapitalizedWords](https://legacy.python.org/dev/peps/pep-0008/#descriptive-naming-styles), which is a subtype of [camelCase](https://en.wikipedia.org/wiki/Camel_case) with the first word also capitalized.

### Problem Specifications

- If a new problem specification is only needed due to the requirements of a new formulation, and is not a new type of problem, e.g., another OPF formulation, a `build_` function with the same name as the existing formulation should be created that accepts a specific `PowerModel` (multiple dispatch).
- If a new problem specification is a new type of problem that will accept multiple formulations, new `build_` and `solve_` functions should be created that do not collide with existing problem specification functions.

### Metaprogramming

In general, it is better to avoid metaprogramming patterns, like creating functions algorithmically, in order to aid in the debugging of code.
Metaprogramming can create significant challenges in interpreting stacktraces upon errors.

### Markdown

Markdown files should be properly formatted, particularly when including tables.
Developers are encouraged to use [markdownlint](https://github.com/markdownlint/markdownlint) and a markdown formatter (such as in VSCode).

## File Structure

It is important that new functions, variables, constraints, etc., all go into appropriate locations in the code base so that future maintenance and debugging is easier.
Pay attention to the current file structure and attempt to conform as best as possible to it.
In general:

- `src/core` contains the core logic of the package, including variable creation and constraint templates, _i.e._ things that are agnostic to the formulation
- `src/form` contains formulation specific variable and constraint functions, organized under separate files for different formulations
- `src/prob` contains problem specification-related functions, organized under separate files for different problem specifications
- `src/io` contains all of the tools to parse and save files
- `docs/src` contains all source markdown files for the documentation
- `examples` contains Jupyter notebooks with walkthroughs of PowerModelsITD for new users
- `test/data` contains all data related to example and unit test cases
- `test/` contains files with unit test cases

## Dependencies (Project.toml)

All new dependencies should be carefully considered before being added.
It is important to keep the number of external dependencies low to avoid reliance on features that may not be maintained in the future.
If possible, the Julia Standard Library should be used, particularly in the situation where reproducing the desired feature is trivial.
There will be cases where it is not simple to duplicate a feature and subsequently maintain it within the package, so adding a dependency would be appropriate in such cases.

All new dependencies are are ultimately approved should also include an entry under `[compat]` indicating the acceptable versions (Julia automerge requirement).
This includes test-only dependencies that appear under `[extras]`

Note that `Manifest.toml` __should not__ be included in the repo.

## Pull Requests

All pull requests should be reviewed by a core developer and may include a review by a subject matter expert if the area of the PR is outside that of one of the core developers.
In that case, the core developers will primarily review style and design rather than substance.

Every PR to PowerModelsITD should strive to meet the following guidelines:

### PR Title

- Should be concise and clear, describing in a phrase the content of the PR
- Should include a prefix that describes the primary type of the PR
  - ADD: feature addition
  - FIX: bugfix
  - REF: refactor
  - UPD: updates to code, e.g., for version bumps of dependencies
  - STY: style changes, no changes to function names, added features, etc.
  - DOC: documentation-only additions/changes
  - RM: dead code removal

### PR Body

- If the change is breaking, it should be clearly stated up front.
- The purpose of the PR should be clearly stated right away.
- Major changes and additions to the code should be summarized. In the case where a refactor was performed, the name changes of public functions should be documented in the body of the PR.
- Any associated Issues should be referenced in the body of the PR, and it is accepted/encouraged to use Closes #XX to automatically close Issues after the PR is merged.

### PR Code

- An entry should be added to CHANGELOG.md for every PR.
- Documentation should be updated. (See the [Documentation](##Documentation) section above for guidelines.)
- Unit tests should be added. In the case where existing unit tests were altered, an explanation for the change must be included.
- Code should be rebased to the latest version of whatever branch the PR is aimed at (i.e., no merge conflicts).

## Versions

PowerModelsITD follows the Semantic Versioning ([SemVer](https://semver.org/)) convention of `Major.minor.patch`, where `Major` indicates breaking changes, `minor` indicates non-breaking feature additions, and `patch` indicates non-breaking bugfixes.

Currently, because `Major==0`, `minor` indicates breaking changes and `patch` indicates any non-breaking change, including both feature additions and bugfixes. Once PowerModelsITD reaches `v1.0.0`, we will adhere strictly to the SemVer convention.

## Branch Management

The `main` branch is a [protected](https://help.github.com/en/github/administering-a-repository/about-protected-branches) branch, meaning that its history will always be contiguous and can never be overwritten.

Release candidate branches of the format `vM.m.0-rc` are also protected branches.
These branches will contain only breaking changes and will not be merged into main until a new version is ready to be tagged.
Pull requests including breaking changes should be directed into the next release candidate branch available, e.g., if the current version of the package is `v0.9.0`, the next release candidate branch will be `v0.10.0-rc`.

Pull requests that include only non-breaking changes can be merged directly into `main` once approved, and in the case of merge conflicts arising for release candidate branches, the `-rc` branch will need to be updated to include the latest `main`.

Pull requests will generally be merged using [squash and merge](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-request-merges#squash-and-merge-your-pull-request-commits) into the branch they are aimed at, with the exception of release candidate branches, which will generally be merged using [rebase and merge](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-request-merges#rebase-and-merge-your-pull-request-commits) into main.
