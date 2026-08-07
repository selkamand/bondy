# Mapping Proper Rotation Axes to ShapeClasses

Load data.frame mapping pairs of proper rotation axes to higher order
ShapeClasses. See
[`get_assessable_shapeclasses()`](https://selkamand.github.io/symbo/reference/get_assessable_shapeclasses.md)
for more information about how it is used.

## Usage

``` r
axes_to_shapeclass_reference()
```

## Value

data.frame mapping pairs of proper rotation axes to higher order
ShapeClasses

## Examples

``` r
axes_to_shapeclass_reference()
#>                  ShapeClass Axis1 Axis2 Axis1x Axis1y   Axis1z Axis2x
#> 1                        D2     2     2      1      0 0.000000    0.0
#> 2                        D3     3     2      1      0 0.000000    0.0
#> 3                    D3_hom     2     2      0      1 0.000000    0.0
#> 4                        D4     4     2      1      0 0.000000    0.0
#> 5                    D4_hom     2     2      0      1 0.000000    0.0
#> 6                        D5     5     2      1      0 0.000000    0.0
#> 7                    D5_hom     2     2      0      1 0.000000    0.0
#> 8                        D6     6     2      1      0 0.000000    0.0
#> 9                    D6_hom     2     2      0      1 0.000000    0.0
#> 10                       D7     2     2      1      0 0.000000    0.0
#> 11                   D7_hom     2     2      0      1 0.000000    0.0
#> 12                       D8     2     2      1      0 0.000000    0.0
#> 13                   D8_hom     2     2      0      1 0.000000    0.0
#> 14  Edge-capped tetrahedron     3     2      1      1 1.000000    1.0
#> 15  Face-capped tetrahedron     3     3      1      1 1.000000    1.0
#> 16         Face-capped cube     4     3      1      0 0.000000    1.0
#> 17         Edge-capped cube     3     2      1      1 1.000000    1.0
#> 18   Edge-capped octahedron     4     2      0      0 1.000000    1.0
#> 19  Edge-capped icosahedron     5     2      1      0 1.618034    0.0
#> 20  Face-capped icosahedron     5     3      0      1 1.618034    0.0
#> 21 Edge-capped dodecahedron     3     2      1     -1 1.000000    0.5
#>        Axis2y     Axis2z                                  Notes AxisComboKey
#> 1   1.0000000  0.0000000                                                 2 2
#> 2   1.0000000  0.0000000                                                 3 2
#> 3   0.5000000  0.8660254                                                 2 2
#> 4   1.0000000  0.0000000                                                 4 2
#> 5   0.7071068  0.7071068                                                 2 2
#> 6   1.0000000  0.0000000                                                 5 2
#> 7   0.8090170  0.5877853                                                 2 2
#> 8   1.0000000  0.0000000                                                 6 2
#> 9   0.8660254  0.5000000                                                 2 2
#> 10  1.0000000  0.0000000                                                 2 2
#> 11  0.9009689  0.4338837                                                 2 2
#> 12  1.0000000  0.0000000                                                 2 2
#> 13  0.9238795  0.3826834                                                 2 2
#> 14  0.0000000  0.0000000                                                 3 2
#> 15  1.0000000 -1.0000000                                                 3 3
#> 16  1.0000000  1.0000000   Equivalent to face-capped octahedron          4 3
#> 17  0.0000000  1.0000000                                                 3 2
#> 18  0.0000000  1.0000000                                                 4 2
#> 19  0.0000000  1.6180340                                                 5 2
#> 20 -0.5393447  1.4120227 Equivalent to face-capped dodecahedron          5 3
#> 21 -0.8090170  1.3090170                                                 3 2
```
