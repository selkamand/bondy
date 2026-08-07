# Get assessable polyhedral geometries from symmetry axis orders

Given two sets of unique proper rotation axis orders for two molecules,
this function returns the subset of geometries that can be assessed with
those symmetries.

## Usage

``` r
get_assessable_shapeclasses(molecule1_axes, molecule2_axes)
```

## Arguments

- molecule1_axes:

  A numeric or character vector of unique proper rotation axis orders
  present in molecule 1 (e.g. `c(3, 4)`).

- molecule2_axes:

  A numeric or character vector of unique proper rotation axis orders
  present in molecule 2 (e.g. `c(2)`).

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

## Examples

``` r
# Suppose molecule 1 has C3 and C4, molecule 2 has C2:
get_assessable_shapeclasses(molecule1_axes = c(3, 4),
                          molecule2_axes = 2)
#>   mol1_axis mol2_axis flipped               ShapeClass Axis1 Axis2 Axis1x
#> 1         3         2   FALSE                       D3     3     2      1
#> 2         3         2   FALSE  Edge-capped tetrahedron     3     2      1
#> 3         3         2   FALSE         Edge-capped cube     3     2      1
#> 4         3         2   FALSE Edge-capped dodecahedron     3     2      1
#> 5         4         2   FALSE                       D4     4     2      1
#> 6         4         2   FALSE   Edge-capped octahedron     4     2      0
#>   Axis1y Axis1z Axis2x    Axis2y   Axis2z Notes assessable
#> 1      0      0    0.0  1.000000 0.000000             TRUE
#> 2      1      1    1.0  0.000000 0.000000             TRUE
#> 3      1      1    1.0  0.000000 1.000000             TRUE
#> 4     -1      1    0.5 -0.809017 1.309017             TRUE
#> 5      0      0    0.0  1.000000 0.000000             TRUE
#> 6      0      1    1.0  0.000000 1.000000             TRUE

# If molecule 1 only has C2 and molecule 2 has C3, some geometries
# (e.g. edge-capped dodecahedron) are only assessable by swapping:
get_assessable_shapeclasses(molecule1_axes = 2,
                          molecule2_axes = 3)
#>   mol1_axis mol2_axis flipped               ShapeClass Axis1 Axis2 Axis1x
#> 1         3         2    TRUE                       D3     3     2      1
#> 2         3         2    TRUE  Edge-capped tetrahedron     3     2      1
#> 3         3         2    TRUE         Edge-capped cube     3     2      1
#> 4         3         2    TRUE Edge-capped dodecahedron     3     2      1
#>   Axis1y Axis1z Axis2x    Axis2y   Axis2z Notes assessable
#> 1      0      0    0.0  1.000000 0.000000             TRUE
#> 2      1      1    1.0  0.000000 0.000000             TRUE
#> 3      1      1    1.0  0.000000 1.000000             TRUE
#> 4     -1      1    0.5 -0.809017 1.309017             TRUE
```
