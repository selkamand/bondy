# Get assessable shapeclasses from molecule objects

A simple wrapper around get_assessable_shapeclasses that works from
molecule3D objects, not just the axes. Throws informative errors when
shapeclasses cannot be found

## Usage

``` r
get_assessable_shapeclasses_from_molecules(
  molecule1,
  molecule2,
  verbose = TRUE
)
```

## Arguments

- molecule1:

  a [`Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object annotated with its proper rotation axes

- molecule2:

  a [`Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object annotated with its proper rotation axes

- verbose:

  verbose (flag)

## Value

A `data.frame` containing all assessable geometries given the supplied
axes. It includes all columns from
[`axes_to_shapeclass_reference()`](https://selkamand.github.io/symbo/reference/axes_to_shapeclass_reference.md),
plus:

- `treat_molecule2_as_1`: logical; `FALSE` if the ShapeClass is
  assessable in the forward orientation (`mol1 -> Axis1`,
  `mol2 -> Axis2`), `TRUE` if only assessable when molecules are
  swapped.

If no geometries are assessable, an empty `data.frame` is returned.

## Details

Geometries are matched in two orientations:

- **Forward:** `molecule1_axes` supply `Axis1_order` and
  `molecule2_axes` supply `Axis2_order`.

- **Swapped:** `molecule2_axes` supply `Axis1_order` and
  `molecule1_axes` supply `Axis2_order`.

For geometries that are only assessable in the swapped orientation,
`treat_molecule2_as_1` is set to `TRUE` to indicate that downstream code
should treat molecule 2 as molecule 1.
