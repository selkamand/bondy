# Generate Optimisation functoin

Generate Optimisation functoin

## Usage

``` r
generate_loss_function(input)
```

## Arguments

- input:

  an
  [`OptimisationInputs()`](https://selkamand.github.io/symbo/reference/OptimisationInputs.md)
  object created from
  [`extract_optimisation_inputs()`](https://selkamand.github.io/symbo/reference/extract_optimisation_inputs.md).

## Value

a function that takes one argument x, a length-4 vector of paramaters to
find optimal configuration of c(mol1_phi, mol1_slide, mol2_phi,
mol2_slide) and returns the sum of squared distance between mol1 binding
attom and mol2 dummy atom + mol2 binding atom and mol1 dummy atom.
