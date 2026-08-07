# Utility Classes ---------------------------------------------------------

#' A three-dimensional numeric vector
#'
#' Represents a numeric vector of length three, with components stored in
#' x, y, z order. Individual components are available through the `x`, `y`,
#' and `z` properties, while `values` returns the complete vector.
#'
#' @export
Vec3 <- S7::new_class(
  name = "Vec3",
  properties = list(
    values = S7::new_property(
      class = S7::class_numeric,
      validator = function(value) {
        if (length(value) != 3) {
          "must be a numeric vector of length 3"
        }
      }
    ),

    x = S7::new_property(
      class = S7::class_numeric,
      getter = function(self) {
        self@values[[1]]
      }
    ),

    y = S7::new_property(
      class = S7::class_numeric,
      getter = function(self) {
        self@values[[2]]
      }
    ),

    z = S7::new_property(
      class = S7::class_numeric,
      getter = function(self) {
        self@values[[3]]
      }
    )
  )
)


# OptimisationResult ------------------------------------------------------

#' Optimisation Inputs
#'
#' A class describing molecular information required the generation of an optimisation function
#' and for reapplying optimised paramaters to generate the molecule resulting from optimisation
#'
#' @param mol1 [structures::Molecule3D()] object aligned to mol1_axis ready for optimisation
#' @param mol2 [structures::Molecule3D()] object aligned to mol1_axis ready for optimisation
#' @param mol1_axis,mol2_axis the axes who the mol1 & mol2 proper rotations are aligned to.
#' Their relative relationship is defined by the shapeclass being evaluated
#' @param mol1_dummy_eleno,mol2_dummy_eleno element numbers of the dummy atoms describing where we expect the opposing molecule's binding atom to bind
#' @param mol1_binding_atom,mol2_binding_atom element numbers of the atom in each molecule involved in the binding
#'
#' @return OptimisationInputs
#'
#' @export
OptimisationInputs <- S7::new_class(
  name = "OptimisationInputs",
  properties = list(
    mol1 = structures::Molecule3D,
    mol2 = structures::Molecule3D,
    mol1_axis = Vec3,
    mol2_axis = Vec3,
    mol1_dummy_eleno = S7::class_numeric,
    mol2_dummy_eleno = S7::class_numeric,
    mol1_binding_atom = S7::class_numeric,
    mol2_binding_atom = S7::class_numeric
  ),
  constructor = function(
    mol1,
    mol2,
    mol1_axis,
    mol2_axis,
    mol1_dummy_eleno,
    mol2_dummy_eleno,
    mol1_binding_atom,
    mol2_binding_atom
  ) {
    S7::new_object(
      S7::S7_object(),
      mol1 = mol1,
      mol2 = mol2,
      mol1_axis = mol1_axis,
      mol2_axis = mol2_axis,
      mol1_dummy_eleno = mol1_dummy_eleno,
      mol2_dummy_eleno = mol2_dummy_eleno,
      mol1_binding_atom = mol1_binding_atom,
      mol2_binding_atom = mol2_binding_atom
    )
  }
)

#' Basic Optimisation Result
#'
#' A container describing the basic metrics of an optimisation result (doesn't store all the meta information).
#' This class lets us add as many custom optimisers as we want, so long as the results can be summarised into the following fields.
#'
#' Convergence is a string describing whether or not the model converged successfully
#' "successful" = model converged
#' "out of iterations" = the model ran out of iterations before converging
#' "simplex degeneracy" = indicates degeneracy of the Nelder-Mead simplex
#' "warning" = optimisation algorithm returned a warning. See 'message' parameter for details
#' "error" = optimisation algorithm threw an error. See 'message' parameter for details
#'
#' par is the optimised 4-parameter vector that if fed into the loss function will produce minimised_value
#'
#' @export
OptimisationResultBasic <- S7::new_class(
  name = "OptimisationResultBasic",
  properties = list(
    minimised_value = S7::class_numeric,
    method = S7::class_character,
    mol1_phi = S7::class_numeric,
    mol2_phi = S7::class_numeric,
    mol1_slide = S7::class_numeric,
    mol2_slide = S7::class_numeric,
    par = S7::new_property(
      class = S7::class_numeric,
      getter = function(self) {
        c(
          self@mol1_phi,
          self@mol1_slide,
          self@mol2_phi,
          self@mol2_slide
        )
      },
      setter = function(self, value) {
        stop(
          "the par property of OptimisationResultBasic is a read-only computed property"
        )
      }
    ),
    n_calls_to_fn = S7::class_numeric,
    n_calls_to_gr = S7::class_numeric,
    convergence = S7::new_property(
      class = S7::class_character,
      getter = function(self) {
        self@convergence
      },
      validator = function(value) {
        #:character
        valid_values <-
          c(
            "successful",
            "out of iterations",
            "simplex degeneracy",
            "warning",
            "error"
          )
        if (!value %in% valid_values) {
          sprintf(
            "Invalid convergence value: [%s]. Expected one of [%s]",
            value,
            toString(valid_values)
          )
        }
      }
    ),
    message = S7::new_property(
      class = S7::class_character,
      setter = function(self, value) {
        # Assert value is a string (length 1 character vector)
        if (length(value) > 1) {
          stop(sprintf(
            "@message must be a string, not a vector of length (%d)",
            length(value)
          ))
        }
        self@message <- if (is.null(value)) "" else value
        self
      }
    )
  ),
  constructor = function(
    minimised_value = NaN,
    method = "Not specified",
    mol1_phi = NaN,
    mol2_phi = NaN,
    mol1_slide = NaN,
    mol2_slide = NaN,
    n_calls_to_fn = 0,
    n_calls_to_gr = 0,
    convergence = c(
      "successful",
      "out of iterations",
      "simplex degeneracy",
      "warning",
      "error"
    ),
    message = NA_character_
  ) {
    convergence <- rlang::arg_match(convergence)

    S7::new_object(
      S7::S7_object(),
      minimised_value = minimised_value,
      method = method,
      mol1_phi = mol1_phi,
      mol2_phi = mol2_phi,
      mol1_slide = mol1_slide,
      mol2_slide = mol2_slide,
      n_calls_to_fn = n_calls_to_fn,
      n_calls_to_gr = n_calls_to_gr,
      convergence = convergence,
      message = message
    )
  }
)


#' Optimisation result for two aligned molecules
#'
#' @description
#' `OptimisationResult` is an S7  object that stores the outcome of
#' a geometric optimisation used to align two [`structures::Molecule3D`]
#' objects. It records the optimised geometries of each molecule, the
#' optimisation objective, key geometric parameters (angles, slides and
#' axes) and bookkeeping information returned by the optimiser.
#'
#' @section Fields:
#'
#' The class has the following properties:
#'
#' \describe{
#'
#'   \item{shapeclass}{Character scalar naming the assessed shape class.}
#'
#'   \item{optimisation_inputs}{An [`OptimisationInputs`] object containing the
#'   oriented molecules, symmetry-axis vectors, dummy atom IDs, and binding atom
#'   IDs used to build the loss function.}
#'
#'   \item{optimisation_outputs}{An [`OptimisationResultBasic`] object returned
#'   by the selected optimiser. It stores the optimal rotation/slide parameters,
#'   minimised objective value, method, convergence status, call counts, and
#'   message.}
#'
#'   \item{loss_function}{The objective function that was optimised.}
#'
#'   \item{minimised_value_description}{Character scalar describing what the
#'   stored objective value represents.}
#'
#'   \item{orientation}{Character scalar identifying which of the two
#'   search-space orientations produced the best result. `"+"` is the normal
#'   orientation; `"-"` is the inverted symmetry-axis orientation.}
#'
#'   \item{mol1_optimal}{Read-only [`structures::Molecule3D`] object giving
#'   molecule 1 after applying the optimal rotation and slide from
#'   `optimisation_outputs`. Dummy atoms are retained.}
#'
#'   \item{mol2_optimal}{Read-only [`structures::Molecule3D`] object giving
#'   molecule 2 after applying the optimal rotation and slide from
#'   `optimisation_outputs`. Dummy atoms are retained.}
#'
#'   \item{mol}{Read-only [`structures::Molecule3D`] object containing the
#'   optimised combined molecule. The two binding atoms are bonded, dummy atoms
#'   are removed, and atoms/bonds are renumbered for export.}
#'
#'   \item{min_sum_of_squared_distance}{Numeric scalar giving the
#'   minimised sum of squared distances between the dummy atoms of each
#'   molecule and the opposing binding atom. Formally:
#'   \eqn{d_1^2 + d_2^2}, where \eqn{d_1} is the distance from the mol1
#'   dummy atom to the mol2 binding atom, and \eqn{d_2} is the distance
#'   from the mol2 dummy atom to the mol1 binding atom, evaluated at the
#'   optimum.}
#'
#'   \item{angle_between_dummy_binding_vectors}{Numeric scalar (radians)
#'   giving the angle between the vector from mol1 dummy \eqn{\to} mol1
#'   binding atom and the vector from mol2 dummy \eqn{\to} mol2 binding
#'   atom, computed for the optimised geometry. For a “perfect” solution
#'   this angle would be \eqn{\pi} (180 degrees).}
#'
#' }
#'
#' @section Typical usage:
#'
#' Instances of `OptimisationResult` are usually created internally by
#' higher-level methods and returned as a structured
#' record of the optimisation outcome for a given shape class, molecule orientation, or optimisation approach
#'
#' @param optimisation_inputs An [`OptimisationInputs`] object describing the
#'   oriented molecules and atom IDs used by the objective function, created using [extract_optimisation_inputs()].
#' @param optimisation_outputs An [`OptimisationResultBasic`] object containing
#'   the selected optimiser output.
#' @param minimised_value_description Character scalar describing the minimised
#'   objective value, for example `"sum of squared distance"`.
#' @param loss_function Function that was optimised.
#' @param orientation Character scalar indicating which search-space orientation
#'   produced the best result. Defaults to `"+"`; `screen_molecules()` uses
#'   `"+"` for the normal orientation and `"-"` for the inverted orientation.
#'
#' @return
#' A new `OptimisationResult` S7 object.
#'
#' @return
#' A new `OptimisationResult` S7 object with the supplied molecules and
#' all other fields initialised to their type-appropriate defaults.
#'
#'
#' @export
OptimisationResult <- S7::new_class(
  name = "OptimisationResult",
  properties = list(
    shapeclass = S7::class_character,
    # Get optimised combined molecule (no dummy atoms)
    mol = S7::new_property(
      class = structures::Molecule3D,
      getter = function(self) {
        mol1_optimal <- self@mol1_optimal
        mol2_optimal <- self@mol2_optimal
        mol1_binding_atom <- self@optimisation_inputs@mol1_binding_atom
        mol2_binding_atom <- self@optimisation_inputs@mol2_binding_atom

        mol_combined_optimal <- structures::combine_molecules(
          molecule1 = mol1_optimal,
          molecule2 = mol2_optimal,
          create_bonds = data.frame(
            eleno1 = mol1_binding_atom,
            eleno2 = mol2_binding_atom,
            bond_type = "single"
          )
        )

        # Drop dummy atoms
        mol_combined_optimal <- structures::remove_dummy_atoms(
          mol_combined_optimal
        )

        # Renumber atom and bonds to be contiguous (important for file export)
        mol_combined_optimal <- structures::renumber_atoms_and_bonds(
          mol_combined_optimal
        )

        return(mol_combined_optimal)
      }
    ),
    # Optimal mol1 structure with dummy atoms included
    mol1_optimal = S7::new_property(
      class = structures::Molecule3D,
      getter = function(self) {
        # Get data
        mol1 <- self@optimisation_inputs@mol1
        mol1_axis <- self@optimisation_inputs@mol1_axis@values
        optimal_mol1_phi <- self@optimisation_outputs@mol1_phi
        optimal_mol1_slide <- self@optimisation_outputs@mol1_slide

        # Apply optimal params
        mol1 |>
          structures::rotate_molecule_around_vector(
            axis = mol1_axis,
            angle = optimal_mol1_phi
          ) |>
          structures::translate_molecule_by_vector(
            move::normalise(mol1_axis) * optimal_mol1_slide
          )
      }
    ),

    # Optimal mol2 structure with dummy atoms included
    mol2_optimal = S7::new_property(
      class = structures::Molecule3D,
      getter = function(self) {
        # Get data
        mol2 <- self@optimisation_inputs@mol2
        mol2_axis <- self@optimisation_inputs@mol2_axis@values
        optimal_mol2_phi <- self@optimisation_outputs@mol2_phi
        optimal_mol2_slide <- self@optimisation_outputs@mol2_slide

        # Apply optimal params
        mol2 |>
          structures::rotate_molecule_around_vector(
            axis = mol2_axis,
            angle = optimal_mol2_phi
          ) |>
          structures::translate_molecule_by_vector(
            move::normalise(mol2_axis) * optimal_mol2_slide
          )
      }
    ),
    # Compute the value between dummy binding vectors (in radians)
    angle_between_dummy_binding_vectors = S7::new_property(
      class = S7::class_numeric,
      getter = function(self) {
        # Fetch data
        mol1_optimal <- self@mol1_optimal
        mol2_optimal <- self@mol2_optimal
        mol1_dummy_eleno <- self@optimisation_inputs@mol1_dummy_eleno
        mol2_dummy_eleno <- self@optimisation_inputs@mol2_dummy_eleno
        mol1_binding_atom <- self@optimisation_inputs@mol1_binding_atom
        mol2_binding_atom <- self@optimisation_inputs@mol2_binding_atom

        # Compute angle created by vectors dummy -> binding atom for each molecule. We'd expect this to be zero
        mol1_pos_dummy <- structures::fetch_atom_position(
          mol1_optimal,
          eleno = mol1_dummy_eleno
        )
        mol1_pos_binding <- structures::fetch_atom_position(
          mol1_optimal,
          eleno = mol1_binding_atom
        )
        mol2_pos_dummy <- structures::fetch_atom_position(
          mol2_optimal,
          eleno = mol2_dummy_eleno
        )
        mol2_pos_binding <- structures::fetch_atom_position(
          mol2_optimal,
          eleno = mol2_binding_atom
        )
        v1 <- move::create_vector_from_start_end(
          mol1_pos_dummy,
          mol1_pos_binding
        )
        v2 <- move::create_vector_from_start_end(
          mol2_pos_dummy,
          mol2_pos_binding
        )
        angle_between_dummy_binding_vectors <- move::measure_angle_between_vectors(
          a = v1,
          b = v2,
          degrees = FALSE
        )
        return(angle_between_dummy_binding_vectors)
      }
    ),
    # Get sum of squared distance between binding and dummy atoms in optimised molecule
    # Yes this is typic what we minimise but if in future we choose to minimise something else, we should still be able to compute this as a key metric
    min_sum_of_squared_distance = S7::new_property(
      class = S7::class_numeric,
      getter = function(self) {
        # Get data
        mol1_optimal <- self@mol1_optimal
        mol2_optimal <- self@mol2_optimal

        mol1_dummy_eleno <- self@optimisation_inputs@mol1_dummy_eleno
        mol2_dummy_eleno <- self@optimisation_inputs@mol2_dummy_eleno
        mol1_binding_atom <- self@optimisation_inputs@mol1_binding_atom
        mol2_binding_atom <- self@optimisation_inputs@mol2_binding_atom

        # Compute angle created by vectors dummy -> binding atom for each molecule. We'd expect this to be zero
        mol1_pos_dummy <- structures::fetch_atom_position(
          mol1_optimal,
          eleno = mol1_dummy_eleno
        )
        mol1_pos_binding <- structures::fetch_atom_position(
          mol1_optimal,
          eleno = mol1_binding_atom
        )
        mol2_pos_dummy <- structures::fetch_atom_position(
          mol2_optimal,
          eleno = mol2_dummy_eleno
        )
        mol2_pos_binding <- structures::fetch_atom_position(
          mol2_optimal,
          eleno = mol2_binding_atom
        )

        d1 <- move::measure_distance_between_two_points(
          mol1_pos_dummy,
          mol2_pos_binding
        )
        d2 <- move::measure_distance_between_two_points(
          mol2_pos_dummy,
          mol1_pos_binding
        )

        # Calculate the sum of square distance between the dummy atoms of each molecule and the opposing atom binding atom
        d1^2 + d2^2
      }
    ),
    # angle_between_dummy_binding_vectors = S7::class_numeric,
    optimisation_inputs = OptimisationInputs,
    optimisation_outputs = OptimisationResultBasic,
    loss_function = S7::class_function,
    minimised_value_description = S7::class_character,
    orientation = S7::class_character
  ),
  constructor = function(
    shapeclass = "NotSpecified",
    optimisation_inputs,
    optimisation_outputs,
    minimised_value_description,
    loss_function,
    orientation = "+"
  ) {
    S7::new_object(
      S7::S7_object(),
      shapeclass = shapeclass,
      optimisation_inputs = optimisation_inputs,
      optimisation_outputs = optimisation_outputs,
      loss_function = loss_function,
      minimised_value_description = minimised_value_description,
      orientation = orientation
    )
  }
)


## Map the convergence integer returned by base::optim() to a valid OptimisationResultBasic convergence string.
base_optim_convergence_number_to_string <- function(convergence_numeric) {
  cv <- as.character(convergence_numeric)
  switch(
    cv,
    "0" = "successful",
    "1" = "out of iterations",
    "10" = "simplex degeneracy",
    "51" = "warning",
    "52" = "error",
    "error"
  )
}


S7::method(print, OptimisationResultBasic) <- function(x, ...) {
  outcome <- sprintf(
    "-> Minimised Value: %f",
    x@minimised_value
  )
  optimal_paramaters <- sprintf(
    "-> mol1_phi: %f | mol2_phi: %f | mol1_slide: %f | mol2_slide %f",
    x@mol1_phi,
    x@mol2_phi,
    x@mol1_slide,
    x@mol2_slide
  )
  optimisation_metrics <- sprintf(
    "-> Method: %s | Number of function calls: %d | Number of gradient calls: %d",
    x@method,
    x@n_calls_to_fn,
    x@n_calls_to_gr
  )
  cat(
    sep = "\n",
    "================================",
    "Optimisation Result (Basic)",
    "================================",
    outcome,
    optimal_paramaters,
    optimisation_metrics,
    "\nSee @par for optimal parameter vector"
  )
}

## Generics ----------------------------------------------------------------

#' @export
S7::method(print, OptimisationResult) <- function(x, ...) {
  cat(
    sep = "\n",
    "================================",
    "Optimisation Result",
    "================================",
    sprintf("Shape Classes: %s", x@shapeclass),
    sprintf("Orientation: %s", x@orientation),
    sprintf(
      "Minimised %s: %f",
      x@minimised_value_description,
      x@optimisation_outputs@minimised_value
    ),
    sprintf(
      "Minimised Angle (pi = perfect): %f",
      x@angle_between_dummy_binding_vectors
    ),
    sprintf("Convergence: %s", x@optimisation_outputs@convergence)
  )
}


## Non-Generics  ---------------------------------------------------------------
is_optimisation_result <- function(x) {
  inherits(x, "symbo::OptimisationResult")
}

get_optimistation_stats <- function(x) {
  stats <- c(
    "Shape Class" = x@shapeclass,
    "Molecule orientation (best of 2 search spaces)" = x@orientation,
    "Minimised Sum of Squared Distance" = x@min_sum_of_squared_distance,
    "Minimised Angle (pi = perfect)" = x@angle_between_dummy_binding_vectors,
    "Method" = x@optimisation_outputs@method,
    "Convergence" = x@optimisation_outputs@convergence,
    "Calls to Optimisation Function" = unname(
      x@optimisation_outputs@n_calls_to_fn
    ),
    "Messages/Warnings: " = unname(x@optimisation_outputs@message)
  )

  df <- data.frame(
    Property = names(stats),
    Values = as.character(stats)
  )
  rownames(df) <- NULL
  return(df)
}

# OptimisationResultCollection --------------------------------------------

#' Collection of optimisation results
#'
#' @description
#' `OptimisationResultCollection` is an S7 container object that stores one or
#' more [`symbo::OptimisationResult`] objects, typically corresponding to
#' different shape classes or binding modes evaluated in a single alignment /
#' docking run.
#'
#' It provides:
#' \itemize{
#'   \item a list-like slot \code{@optimisations} containing the individual
#'         optimisation results; and
#'   \item a read-only \code{@shapeclasses} property that extracts the
#'         \code{shapeclass} field from each contained result.
#' }
#'
#' A convenience [base::as.data.frame()] method is provided so that key
#' summary quantities (distance, angle, rotations, slides, axes) can be
#' inspected and compared in a tabular form.
#'
#' @section Fields:
#'
#' The class has the following properties:
#'
#' \describe{
#'
#'   \item{optimisations}{A list of [`symbo::OptimisationResult`] objects.
#'   The list may be empty. A validator enforces that every element in this
#'   list is a valid `OptimisationResult`; otherwise an error is raised.}
#'
#'   \item{shapeclasses}{Character vector (read-only) giving the
#'   \code{shapeclass} value of each element in \code{@optimisations}, in the
#'   same order. This is computed on the fly via the getter and cannot be set
#'   directly.}
#'
#' }
#'
#' @section Typical usage:
#'
#' Instances of `OptimisationResultCollection` are usually constructed by
#' higher-level routines that evaluate multiple shape classes. Each shape
#' class produces an [`symbo::OptimisationResult`], and these are collected
#' into a single object for printing, summarising, or coercion to a data frame.
#'
#' @param optimisations A list of [`symbo::OptimisationResult`] objects,
#'   each corresponding to the optimisation conducted for one shape class.
#'   Defaults to an empty list.
#' @param mol1_not_optimised A [`structures::Molecule3D`] object
#'   representing the *original*, unaligned version of molecule 1.
#'   This is included in the collection so reports and summaries can
#'   display both the starting geometry and the optimised structures.
#' @param mol2_not_optimised A [`structures::Molecule3D`] object
#'   representing the *original*, unaligned version of molecule 2.
#'
#' @return
#' A new `OptimisationResultCollection` S7 object containing the supplied
#' optimisation results.
#'
#' @export
OptimisationResultCollection <- S7::new_class(
  name = "OptimisationResultCollection",

  properties = list(
    mol1_not_optimised = S7::new_property(
      class = structures::Molecule3D
    ),
    mol2_not_optimised = S7::new_property(
      class = structures::Molecule3D
    ),

    optimisations = S7::new_property(
      class = S7::class_list,
      validator = function(value) {
        for (val in value) {
          if (!is_optimisation_result(val)) {
            return(sprintf(
              "All @optimisations in OptimisationResultCollection must be an OptimisationResult object, not a [%s]",
              toString(class(val))
            ))
          }
        }
      }
    ),
    # Shape Classes that were Evaluated
    shapeclasses = S7::new_property(
      class = S7::class_character,
      setter = function(self, value) {
        stop("@shapeclasses is a read only property")
      },
      getter = function(self) {
        vapply(
          X = self@optimisations,
          function(o) {
            o@shapeclass
          },
          FUN.VALUE = character(1)
        )
      }
    )
  ),
  constructor = function(
    optimisations = list(),
    mol1_not_optimised,
    mol2_not_optimised
  ) {
    S7::new_object(
      S7::S7_object(),
      optimisations = optimisations,
      mol1_not_optimised = mol1_not_optimised,
      mol2_not_optimised = mol2_not_optimised
    )
  }
)


# Generics ----------------------------------------------------------------
#' @export
S7::method(print, OptimisationResultCollection) <- function(x, ...) {
  optimisations <- x@optimisations
  n_optimisations <- length(optimisations)
  df <- as.data.frame(x)

  df$summary_string <- with(
    df,
    {
      sprintf(
        "-> %s (D: %f | A: %f | O: %s)",
        shapeclass,
        min_sum_of_squared_distance,
        angle_between_dummy_binding_vectors,
        orientation # Orientation (which of the two search spaces was this solution found in)
      )
    }
  )
  shapeclass_summary_string <- if (n_optimisations == 0) {
    ""
  } else {
    paste0(df$summary_string, collapse = "\n")
  }

  cat(
    sep = "\n",
    "================================",
    "Optimisation Result Collection",
    "================================",
    sprintf("Shape Classes Evaluated: %s", length(optimisations)),
    shapeclass_summary_string
  )
}

#' @export
S7::method(as.data.frame, OptimisationResultCollection) <- function(x, ...) {
  optimisations <- x@optimisations

  data.frame(
    shapeclass = vapply(
      optimisations,
      function(o) o@shapeclass,
      character(1)
    ),

    orientation = vapply(
      optimisations,
      function(o) o@orientation,
      character(1)
    ),

    min_sum_of_squared_distance = vapply(
      optimisations,
      function(o) o@min_sum_of_squared_distance,
      numeric(1)
    ),

    angle_between_dummy_binding_vectors = vapply(
      optimisations,
      function(o) o@angle_between_dummy_binding_vectors,
      numeric(1)
    ),

    mol1_name = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol1@name,
      character(1)
    ),

    mol2_name = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol2@name,
      character(1)
    ),

    mol1_phi = vapply(
      optimisations,
      function(o) o@optimisation_outputs@mol1_phi,
      numeric(1)
    ),

    mol2_phi = vapply(
      optimisations,
      function(o) o@optimisation_outputs@mol2_phi,
      numeric(1)
    ),

    mol1_slide = vapply(
      optimisations,
      function(o) o@optimisation_outputs@mol1_slide,
      numeric(1)
    ),

    mol2_slide = vapply(
      optimisations,
      function(o) o@optimisation_outputs@mol2_slide,
      numeric(1)
    ),

    mol1_axis_x = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol1_axis@x,
      numeric(1)
    ),

    mol1_axis_y = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol1_axis@y,
      numeric(1)
    ),

    mol1_axis_z = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol1_axis@z,
      numeric(1)
    ),

    mol2_axis_x = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol2_axis@x,
      numeric(1)
    ),

    mol2_axis_y = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol2_axis@y,
      numeric(1)
    ),

    mol2_axis_z = vapply(
      optimisations,
      function(o) o@optimisation_inputs@mol2_axis@z,
      numeric(1)
    )
  )
}
