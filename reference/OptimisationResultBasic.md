# Basic optimisation result

`OptimisationResultBasic` stores the optimiser output needed by
higher-level Symbo result objects. It describes the minimised objective
value, the four fitted rotation/slide parameters, call counts,
convergence status, and any optimiser message.

## Usage

``` r
OptimisationResultBasic(
  minimised_value = NaN,
  method = "Not specified",
  mol1_phi = NaN,
  mol2_phi = NaN,
  mol1_slide = NaN,
  mol2_slide = NaN,
  n_calls_to_fn = 0,
  n_calls_to_gr = 0,
  convergence = c("successful", "out of iterations", "simplex degeneracy", "warning",
    "error"),
  message = NA_character_
)
```

## Arguments

- minimised_value:

  Numeric scalar giving the objective value at the selected parameter
  vector. Defaults to `NaN`.

- method:

  Character scalar naming the optimisation method or optimiser. Defaults
  to `"Not specified"`.

- mol1_phi, mol2_phi:

  Numeric scalars giving the fitted rotation angles for molecule 1 and
  molecule 2. Defaults to `NaN`.

- mol1_slide, mol2_slide:

  Numeric scalars giving the fitted slide distances for molecule 1 and
  molecule 2. Defaults to `NaN`.

- n_calls_to_fn:

  Numeric scalar giving the number of objective-function calls. Defaults
  to `0`.

- n_calls_to_gr:

  Numeric scalar giving the number of gradient-function calls. Defaults
  to `0`.

- convergence:

  Character scalar giving the convergence status. Defaults to
  `"successful"` and must be one of the values listed in the fields
  section.

- message:

  Character scalar containing any optimiser message. `NULL` is stored as
  `""`; values longer than length one are rejected.

## Value

A new `OptimisationResultBasic` S7 object.

## Fields

The class has the following properties:

- minimised_value:

  Numeric scalar giving the objective value at the selected parameter
  vector.

- method:

  Character scalar naming the optimisation method or optimiser that
  produced the result.

- mol1_phi:

  Numeric scalar giving the rotation angle applied to molecule 1 about
  its optimisation axis.

- mol2_phi:

  Numeric scalar giving the rotation angle applied to molecule 2 about
  its optimisation axis.

- mol1_slide:

  Numeric scalar giving the translation distance applied to molecule 1
  along its optimisation axis.

- mol2_slide:

  Numeric scalar giving the translation distance applied to molecule 2
  along its optimisation axis.

- par:

  Read-only numeric vector containing the optimised parameters in
  loss-function order: `c(mol1_phi, mol1_slide, mol2_phi, mol2_slide)`.

- n_calls_to_fn:

  Numeric scalar giving the number of calls made to the objective
  function.

- n_calls_to_gr:

  Numeric scalar giving the number of calls made to the gradient
  function, where applicable.

- convergence:

  Character scalar summarising the optimiser convergence status. Must be
  one of `"successful"`, `"out of iterations"`, `"simplex degeneracy"`,
  `"warning"`, or `"error"`.

- message:

  Character scalar containing any optimiser message, warning, or
  diagnostic text.
