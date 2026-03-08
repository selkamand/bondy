# Symbo Manual

## Introduction to Symbo

Symbo identifies whether two molecules can feasibly assemble into
higher-order geometric structures (e.g., tetrahedra, face/edge capped
cubes, etc.).

Symbo requires:

1.  **Two molecules** annotated with their proper rotation axes
2.  **User-supplied** information about how they bind to one another

Symbo then tests all compatible **shape classes** and determines which
ones can form valid supramolecular structures.

Symbo exclusively assesses the **geometric feasibility** of different
structures (based on symmetry properties and user-defined binding
constraints). It does NOT consider any physical properties of the
molecular structures.

## Step 0: Setting up your R environment

### Installing R, Rstudio and Rtools

Start by installing:

1\. **R** - the programming language

2\. **Rstudio Desktop** (or some other development environment like
Positron)

3\. **Rtools** - a collection of utilities that allow you to compile and
install packages from github

Once installed, open your development environment and proceed to install
Symbo.

### Installing Required R packages

Symbo and all its dependencies can be installed by running:

``` r
if (!require("remotes"))
    install.packages("remotes")

remotes::install_github("selkamand/symbo", dependencies = TRUE)
```

## Step 1: Preparing Your Molecular Structures

Symbo expects **two molecules in MOL2 format**, each containing:

- **the full atomic structure**, and

- **at least one dummy atom** marking *where* binding is expected to
  occur.

Example Scenario

- Molecule 1: An iron tripod

- Molecule 2: A palladium ion

You expect several palladium centres to bind to nitrogen sites on the
tripod. To encode this:

1.  Add **dummy atoms** to each nitrogen atom showing where palladium
    will bind
2.  Add **dummy atoms** to the palladium molecule showing where nitrogen
    would bind

> **Tip**
>
> You *only need one dummy atom per molecule* for Symbo to work, but
> adding all usually makes symmetry annotation easier.

> **Important**
>
> Ensure dummy atoms are explicitly marked as *dummy atoms* in your
> molecular editor.

After adding your dummy atoms to both molecules, export each structure
as a **.mol2 file**

## Step 2: Loading and Inspecting Your Molecules

Now that you’ve prepared your mol2 molecules, load them into R and
ensure everything worked ok.

Before loading any packages run the following code which will prevent
our 3D plots trying to render in a local graphics engine and instead
render exclusively in a web based viewer.

``` r
options(rgl.useNULL=TRUE)
```

Then parsing your mol2 files using the `read_mol()` function from the
[structures](https://github.com/selkamand/structures) package (this will
be automatically installed alongside symbo).

To run with your own mol2 files replace the calls to
[`system.file()`](https://rdrr.io/r/base/system.file.html) with a string
path to your file of interest (e.g.
`"/Users/username/Documents/my_molecule_1.mol2"`)

``` r
# Load the libraries we need
library(structures) # For reading mol2 files and annotating molecular structures
library(chemviewR) # For visualising 3D molecular structures
library(symbo) # For assessing geometrical feasibility of higher level structures

# Parse Molecules
molecule1_filepath <- system.file(package = "symbo", "fe_dummies.mol2")
molecule1 <- read_mol2(molecule1_filepath)

molecule2_filepath <- system.file(package = "symbo", "pd_dummies.mol2")
molecule2 <- read_mol2(molecule2_filepath)
#> Warning in format_atoms(atoms): Unexpected atom types found: [Pd]. Replacing
#> these with 'Any'
```

Lets investigate these molecules by printing a summary

``` r
print(molecule1)
#> ===================
#> Chemical Molecule3D
#> ===================
#> Name: fe_dummies
#> Atoms: 83 (3 dummy atoms)
#> Bonds: 90
#> Molecule type: SMALL
#> Charge type: NO_CHARGES
#> -------------------
#> Symmetry Elements: 0
#> Symmetry Axes: 0
#> Symmetry Orders (Cn): 
#> -------------------
#> See @atoms paramater for atom positions
#> See @bonds paramater for bond positions
#> See @symmetry_elements for symmetry elements
```

We see that molecule 1 (our iron tripod) contains 83 atoms, 3 of which
are dummy atoms representing the palladium binding position.

> **Task** Print the summary for `molecule2` in the same way.

## Step 3: Visualising molecules

Use **chemviewR** to generate interactive 3D plots:

``` r
plot_molecule(molecule1)
```

``` r
plot_molecule(molecule2)
```

> **Tip**
>
> To learn more about any function in R, run its name prefixed by a
> `?`.  
> For example:
> [`?plot_molecule`](https://rdrr.io/pkg/chemviewR/man/plot_molecule.html)

## Step 4: Annotating proper rotation axes

Symbo requires each molecule to be annotated with at least one **proper
rotation axes (Cn)** that describe their symmetry.

### Example: Iron tripod (C3 axis)

``` r
# Iron tripods have a C3 proper rotation axis. 
# This axis is identical to the normal of the plane formed by our three N5 nitrogen atoms. So lets first compute this plane
molecule1_plane <- molecule1 |>
  filter_atoms_by_name("N5") |>
  compute_plane_from_atoms()

## Then we can create a 'ProperRotationAxis' object based on the plane_normal & centroid of the 3 N5 irons
c3_axis_iron_tripod <- ProperRotationAxis(
      n = 3, # Axis order; as in (Cn)
      posA = molecule1_plane$centroid,
      direction = molecule1_plane$normal
  )

## Annotate our molecule with this ProperRotationAxis
molecule1 <- molecule1 |>
  add_symmetry_element_to_molecule(c3_axis_iron_tripod)

# Visualise The plot to see if it worked
plot_molecule(molecule1)
```

### Palladium complex (C4 axis)

``` r

# Palladium has a C4 symmetry axis.
# Direction is equivalent to the normal or the plane formed by the entire molecule
# (including all four dummy atoms) so lets compute that plane
molecule2_plane <- molecule2 |>
  compute_plane_from_atoms()

## Then we create a 'ProperRotationAxis' object based on the plane_normal & centroid of the entire molecule
c4_axis_palladium <- ProperRotationAxis(
  n = 4, # Axis order; as in (Cn)
  posA = molecule2_plane$centroid, 
  direction = molecule2_plane$normal
)
 
# Then we annotate our molecule with this information
molecule2 <- molecule2 |>
  add_symmetry_element_to_molecule(c4_axis_palladium)

# Plot the molecule to make the axis is present
plot_molecule(molecule2)
```

## Step 5 - Specifying binding atoms & running optimisation

### Specifying the binding atoms

Before running the optimisation, we must identify which atoms act as the
**binding atoms** for each molecule.

In this example:

- The **N5 nitrogen atoms** of the iron tripod (molecule 1) bind to  
- The **palladium atom** of molecule 2

To determine the correct atom indices (`eleno` values), inspect the atom
tables:

``` r
View(molecule1@atoms)
View(molecule2@atoms)
```

Locate:

- The nitrogen atom that should bind (e.g., element number `7`)
- The palladium atom (e.g., element number `1`)

### Running Optimisation

To find the optimal configuration of our two molecules for each
higher-order geometric structure they might form, run:

``` r
# Specify the binding atom
optimisations <- screen_molecules(
  molecule1 = molecule1,
  molecule2 = molecule2, 
  mol1_binding_atom = 7, # One of the N5 Nitrogens
  mol2_binding_atom = 1  # Palladium atom
)
#> ℹ Figuring out which shape classes are assessable
#> ℹ Molecule 1 [fe_dummies] has [C3]
#> ℹ Molecule 2 [pd_dummies] has [C4]
#> ℹ Molecules [fe_dummies] and [pd_dummies] can be assessed for [1] shape class (Face-capped cube).
#> 
#> ── Face-capped cube ────────────────────────────────────────────────────────────
#> ℹ Fetching the first dummy atom in each molecule
#> ℹ Rotating molecules so Symmetry Axes align with target vectors
#> ℹ Extracting Symmetry Axes
#> ℹ Searching for optimal arrangement of molecules
#> ℹ Running optimisation (this may take a moment) ...
#> ℹ Optimisation finished! Compiling results ...

# View result summary
print(optimisations)
#> ================================
#> Optimisation Result Collection
#> ================================
#> Shape Classes Evaluated: 1
#> -> Face-capped cube (D: 2.464957 | A: 1.957490)
```

Each evaluated shape class returns two diagnostic values:

**Minimised Sum of Squared Distances (D)**

$$D = d_{1}^{2} + d_{2}^{2}$$

where:

- $d_{1}$ = distance from mol1 dummy → mol2 binding atom
- $d_{2}$ = distance from mol2 dummy → mol1 binding atom

A lower value means a more geometrically feasible arrangement.

**Angle Between Dummy Binding Vectors (A)**

This is the angle (in radians) between:

- vector from mol1 dummy → mol1 binding atom
- vector from mol2 dummy → mol2 binding atom

A perfectly aligned arrangement approaches **π radians (~180°)**. For
each shape class evaluated, Symbo reports two values:

## Step 6: Create a summary report

Symbo can generate a HTML report summarising results:

``` r
create_summary_report(optimisations)
```

Open report in your browser.
