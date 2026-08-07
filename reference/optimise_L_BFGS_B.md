# Minimise a loss function by L_BFGS_B

Optimise a function produced by
[`generate_loss_function()`](https://selkamand.github.io/symbo/reference/generate_loss_function.md)
using L-BFGS-B

## Usage

``` r
optimise_L_BFGS_B(fn)
```

## Arguments

- fn:

  a function that takes a vector of 4 numeric elements corresponding to
  c(mol1_phi, mol1_slide, mol2_phi, mol2_slide)

## Value

A
[`OptimisationResultBasic()`](https://selkamand.github.io/symbo/reference/OptimisationResultBasic.md)
object

## Details

Bounding strategy: phi values are bounded between 0 and 360. slide
values are unbounded.
