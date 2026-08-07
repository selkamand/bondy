# Extract optimisation inputs

Prepares two molecules for optimisation search for a particular
shapeclass. E.g. orients them relative to each other as mandated by the
shapeclass mapping and returns a list describing all the data we need to
generate a loss function with
[`generate_loss_function()`](https://selkamand.github.io/symbo/reference/generate_loss_function.md)

## Usage

``` r
extract_optimisation_inputs(
  mol1,
  mol2,
  mol1_binding_atom,
  mol2_binding_atom,
  shapeclass,
  invert_symmetry_axis = FALSE
)
```

## Arguments

- mol1:

  a [`Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object.

- mol2:

  a [`Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object.

- mol1_binding_atom:

  (eleno)

- mol2_binding_atom:

  (eleno)

- shapeclass:

  a string describing the exact shapeclass to extract optimisation
  inputs for (see list_all_shapeclasses() for options)

- invert_symmetry_axis:

  equivalent to rotating the molecule 180 degrees around the symmetry
  axis. Used to generate the second potential search space (-). See \#19
  for details.

## Value

an
[`OptimisationInputs()`](https://selkamand.github.io/symbo/reference/OptimisationInputs.md)
object
