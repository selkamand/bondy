# Optimisation Inputs

A class describing molecular information required the generation of an
optimisation function and for reapplying optimised paramaters to
generate the molecule resulting from optimisation

## Usage

``` r
OptimisationInputs(
  mol1,
  mol2,
  mol1_axis,
  mol2_axis,
  mol1_dummy_eleno,
  mol2_dummy_eleno,
  mol1_binding_atom,
  mol2_binding_atom
)
```

## Arguments

- mol1:

  [`structures::Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object aligned to mol1_axis ready for optimisation

- mol2:

  [`structures::Molecule3D()`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object aligned to mol1_axis ready for optimisation

- mol1_axis, mol2_axis:

  the axes who the mol1 & mol2 proper rotations are aligned to. Their
  relative relationship is defined by the shapeclass being evaluated

- mol1_dummy_eleno, mol2_dummy_eleno:

  element numbers of the dummy atoms describing where we expect the
  opposing molecule's binding atom to bind

- mol1_binding_atom, mol2_binding_atom:

  element numbers of the atom in each molecule involved in the binding

## Value

OptimisationInputs
