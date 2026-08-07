# Minimise a loss function by surface annealing

Optimise a function produced by
[`generate_loss_function()`](https://selkamand.github.io/symbo/reference/generate_loss_function.md)
using surface annealing

## Usage

``` r
optimise_surface_annealing(fn)
```

## Arguments

- fn:

  a function that takes a vector of 4 numeric elements corresponding to
  c(mol1_phi, mol1_slide, mol2_phi, mol2_slide)

## Value

A
[`OptimisationResultBasic()`](https://selkamand.github.io/symbo/reference/OptimisationResultBasic.md)
object
