# Screen molecules for valid Shape classes

Screens a pair of molecules to find their most geometrically optimal
configuration to produce shapeclasses

## Usage

``` r
screen_molecules(molecule1, molecule2, mol1_binding_atom, mol2_binding_atom)
```

## Arguments

- molecule1:

  a
  [`structures::Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object with symmetry axes annotated and dummy atoms representing where
  the mol2_binding_atom might bind.

- molecule2:

  a
  [`structures::Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object with symmetry axes annotated and dummy atoms representing where
  the mol1_binding_atom might bind.

- mol1_binding_atom:

  the atom you expect will bind to molecule2 (integer representing
  element number a.k.a eleno).

- mol2_binding_atom:

  the atom you expect will bind to molecule1 (integer representing
  element number a.k.a eleno).

## Value

an
[`OptimisationResultCollection()`](https://selkamand.github.io/symbo/reference/OptimisationResultCollection.md)
object.
