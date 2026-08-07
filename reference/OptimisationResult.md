# Optimisation result for two aligned molecules

`OptimisationResult` is an S7 object that stores the outcome of a
geometric optimisation used to align two
[`structures::Molecule3D`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
objects. It records the optimised geometries of each molecule, the
optimisation objective, key geometric parameters (angles, slides and
axes) and bookkeeping information returned by the optimiser.

## Usage

``` r
OptimisationResult(
  shapeclass = "NotSpecified",
  optimisation_inputs,
  optimisation_outputs,
  minimised_value_description,
  loss_function,
  orientation = "+"
)
```

## Arguments

- shapeclass:

  Name of the shape class being evaluated (character scalar). See
  [`list_all_shapeclasses()`](https://selkamand.github.io/symbo/reference/list_all_shapeclasses.md)
  for valid terms

- optimisation_inputs:

  An
  [`OptimisationInputs`](https://selkamand.github.io/symbo/reference/OptimisationInputs.md)
  object describing the oriented molecules and atom IDs used by the
  objective function, created using
  [`extract_optimisation_inputs()`](https://selkamand.github.io/symbo/reference/extract_optimisation_inputs.md).

- optimisation_outputs:

  An
  [`OptimisationResultBasic`](https://selkamand.github.io/symbo/reference/OptimisationResultBasic.md)
  object containing the selected optimiser output.

- minimised_value_description:

  Character scalar describing the minimised objective value, for example
  `"sum of squared distance"`.

- loss_function:

  Function that was optimised.

- orientation:

  Character scalar indicating which search-space orientation produced
  the best result. Defaults to `"+"`;
  [`screen_molecules()`](https://selkamand.github.io/symbo/reference/screen_molecules.md)
  uses `"+"` for the normal orientation and `"-"` for the inverted
  orientation.

## Value

A new `OptimisationResult` S7 object.

A new `OptimisationResult` S7 object with the supplied molecules and all
other fields initialised to their type-appropriate defaults.

## Fields

The class has the following properties:

- shapeclass:

  Character scalar naming the assessed shape class.

- optimisation_inputs:

  An
  [`OptimisationInputs`](https://selkamand.github.io/symbo/reference/OptimisationInputs.md)
  object containing the oriented molecules, symmetry-axis vectors, dummy
  atom IDs, and binding atom IDs used to build the loss function.

- optimisation_outputs:

  An
  [`OptimisationResultBasic`](https://selkamand.github.io/symbo/reference/OptimisationResultBasic.md)
  object returned by the selected optimiser. It stores the optimal
  rotation/slide parameters, minimised objective value, method,
  convergence status, call counts, and message.

- loss_function:

  The objective function that was optimised.

- minimised_value_description:

  Character scalar describing what the stored objective value
  represents.

- orientation:

  Character scalar identifying which of the two search-space
  orientations produced the best result. `"+"` is the normal
  orientation; `"-"` is the inverted symmetry-axis orientation.

- mol1_optimal:

  Read-only
  [`structures::Molecule3D`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object giving molecule 1 after applying the optimal rotation and slide
  from `optimisation_outputs`. Dummy atoms are retained.

- mol2_optimal:

  Read-only
  [`structures::Molecule3D`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object giving molecule 2 after applying the optimal rotation and slide
  from `optimisation_outputs`. Dummy atoms are retained.

- mol:

  Read-only
  [`structures::Molecule3D`](https://rdrr.io/pkg/structures/man/Molecule3D.html)
  object containing the optimised combined molecule. The two binding
  atoms are bonded, dummy atoms are removed, and atoms/bonds are
  renumbered for export.

- min_sum_of_squared_distance:

  Numeric scalar giving the minimised sum of squared distances between
  the dummy atoms of each molecule and the opposing binding atom.
  Formally: \\d_1^2 + d_2^2\\, where \\d_1\\ is the distance from the
  mol1 dummy atom to the mol2 binding atom, and \\d_2\\ is the distance
  from the mol2 dummy atom to the mol1 binding atom, evaluated at the
  optimum.

- angle_between_dummy_binding_vectors:

  Numeric scalar (radians) giving the angle between the vector from mol1
  dummy \\\to\\ mol1 binding atom and the vector from mol2 dummy \\\to\\
  mol2 binding atom, computed for the optimised geometry. For a
  “perfect” solution this angle would be \\\pi\\ (180 degrees).

## Typical usage

Instances of `OptimisationResult` are usually created internally by
higher-level methods and returned as a structured record of the
optimisation outcome for a given shape class, molecule orientation, or
optimisation approach
