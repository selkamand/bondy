# Core Function -----------------------------------------------------------

#' Screen molecules for valid Shape classes
#'
#' Screens a pair of molecules to find their most geometrically optimal configuration to produce shapeclasses
#'
#' @param molecule1 a [structures::Molecule3D()] object with symmetry axes annotated and dummy atoms representing where the mol2_binding_atom might bind.
#' @param molecule2 a [structures::Molecule3D()] object with symmetry axes annotated and dummy atoms representing where the mol1_binding_atom might bind.
#' @param mol1_binding_atom the atom you expect will bind to molecule2 (integer representing element number a.k.a eleno).
#' @param mol2_binding_atom the atom you expect will bind to molecule1 (integer representing element number a.k.a eleno).
#' @param method,lower,upper,control,hessian optimisation algorith configuration. See [stats::optim()] for details.
#'
#' @return an [OptimisationResultCollection()] object.
#' @export
screen_molecules <- function(
  molecule1,
  molecule2,
  mol1_binding_atom,
  mol2_binding_atom
) {
  # Assertions
  assertions::assert_class(molecule1, class = "structures::Molecule3D")
  assertions::assert_class(molecule2, class = "structures::Molecule3D")

  # Grab molecule names
  molecule1_name <- molecule1@name
  molecule2_name <- molecule2@name

  # Fetch Assessable shapeclasses (based on proper rotation axes)
  df_assessable <- get_assessable_shapeclasses_from_molecules(
    molecule1,
    molecule2
  ) # fallable: throws informative errors when no shapeclasses are assessable
  n_assessable_shapeclasses <- nrow(df_assessable)

  if (n_assessable_shapeclasses == 0) {
    cli::cli_abort(
      "Molecules [{molecule1_name}] and [{molecule2_name}] can not be assessed for any shape class (no viable combination of annotated symmetry axes)"
    )
  }

  assessable_shapeclass_string <- toString(df_assessable$ShapeClass)
  cli::cli_alert_info(
    "Molecules [{molecule1_name}] and [{molecule2_name}] can be assessed for [{n_assessable_shapeclasses}] shape class{?es} ({assessable_shapeclass_string})."
  )

  # Assess feasiblity for each assessable shapeclass
  ls_optimisations <- lapply(seq_len(nrow(df_assessable)), FUN = function(i) {
    shapeclass <- df_assessable$ShapeClass[i]
    cli::cli_h1("{shapeclass}")
    cli::cli_alert_info("Searching for optimal arrangement of molecules")

    # Prepare data required to generate the loss function we're going to optimsie
    optimisation_inputs_unrotated <- extract_optimisation_inputs(
      mol1 = molecule1,
      mol2 = molecule2,
      mol1_binding_atom = mol1_binding_atom,
      mol2_binding_atom = mol2_binding_atom,
      shapeclass = shapeclass,
      invert_symmetry_axis = FALSE
    )

    # Prepare a second set of input data, this time with mol2 rotated 180 degrees around a vector perpendicular to the proper rotation axis
    # (note we cheat here and just invert the rotation axis inverted so
    # we can cover the second search space (see issue #19)
    # note inverting the rotation axis does not actually mirror/ change the chirality of the molecule because these axes are actually directionless in reality
    # and we're not changing the molecule at all.
    # Proper rotation Axes have a sense of direction in our object which affects the orientation that its loaded in  relative to the other molecule

    optimisation_inputs_rotated <- extract_optimisation_inputs(
      mol1 = molecule1,
      mol2 = molecule2,
      mol1_binding_atom = mol1_binding_atom,
      mol2_binding_atom = mol2_binding_atom,
      shapeclass = shapeclass,
      invert_symmetry_axis = TRUE
    )

    # Generate the loss functions
    fn_loss_unrotated <- generate_loss_function(optimisation_inputs_unrotated)
    fn_loss_rotated <- generate_loss_function(optimisation_inputs_rotated)

    # Optimise the distance between dummy atom of 1 molecule and binding atom of the other
    cli::cli_alert_info(
      "Running optimisation (this may take a moment) ... "
    )

    # Find paramaters that minimise the loss function by L-BFGS-B (returns OptimisationResultBasic() object)
    cli::cli_h2("Optimising + orientation")
    optimisation_outputs_l_bfgs_b <- optimise_L_BFGS_B(fn_loss_unrotated)
    optimisation_outputs_sann <- optimise_surface_annealing(fn_loss_unrotated)

    # Do the same for the rotated form
    cli::cli_h2("Optimising - orientation")
    optimisation_outputs_rotated_l_bfgs_b <- optimise_L_BFGS_B(fn_loss_rotated)
    optimisation_outputs_rotated_sann <- optimise_surface_annealing(
      fn_loss_rotated
    )

    cli::cli_h2("Comparing all optimisation runs")
    # Pick the best optimisation model for non-rotated
    optimisation_outputs_unrotated <- pick_best_result(
      optimisation_outputs_l_bfgs_b,
      optimisation_outputs_sann
    )

    # Pick the best optimisation model for rotated form
    optimisation_outputs_rotated <- pick_best_result(
      optimisation_outputs_rotated_l_bfgs_b,
      optimisation_outputs_rotated_sann
    )

    unrotated_better <- is_first_optimisation_better(
      optimisation_outputs_unrotated,
      optimisation_outputs_rotated
    )

    if (unrotated_better) {
      optimisation <- OptimisationResult(
        shapeclass,
        optimisation_inputs_unrotated,
        optimisation_outputs_unrotated,
        loss_function = fn_loss_unrotated,
        minimised_value_description = "sum of squared distance",
        orientation = "+"
      )
    } else {
      optimisation <- OptimisationResult(
        shapeclass,
        optimisation_inputs_rotated,
        optimisation_outputs_rotated,
        loss_function = fn_loss_rotated,
        minimised_value_description = "sum of squared distance",
        orientation = "-"
      )
    }

    return(optimisation)
  })

  OptimisationResultCollection(
    optimisations = ls_optimisations,
    mol1_not_optimised = molecule1,
    mol2_not_optimised = molecule2
  )
}

is_first_optimisation_better <- function(
  optimisation_output_1,
  optimisation_output_2
) {
  minimised_val_1 <- optimisation_output_1@minimised_value
  minimised_val_2 <- optimisation_output_2@minimised_value

  if (is.null(minimised_val_2) | is.na(minimised_val_2)) {
    return(TRUE)
  } else if (is.null(minimised_val_1) | is.na(minimised_val_1)) {
    return(FALSE)
  } else if (minimised_val_1 >= minimised_val_2) {
    return(FALSE)
  } else if (minimised_val_1 < minimised_val_2) {
    return(TRUE)
  } else {
    stop(
      "Should never reach this fallthrough condition. Bug in symbo. Please report"
    )
  }
}

pick_best_result <- function(optimisation_output_1, optimisation_output_2) {
  if (
    is_first_optimisation_better(optimisation_output_1, optimisation_output_2)
  ) {
    return(optimisation_output_1)
  } else {
    return(optimisation_output_2)
  }
}

# Optimisation ------------------------------------------------------------

#' Generate Optimisation functoin
#'
#' @param input an [OptimisationInputs()] object created from [extract_optimisation_inputs()].
#'
#' @return a function that takes one argument x, a length-4 vector of paramaters to find optimal configuration of c(mol1_phi, mol1_slide, mol2_phi, mol2_slide)
#' and returns the sum of squared distance between mol1 binding attom and mol2 dummy atom + mol2 binding atom and mol1 dummy atom.
#'
#' @export
generate_loss_function <- function(input) {
  mol1_dummy_eleno <- as.character(input@mol1_dummy_eleno)
  mol2_dummy_eleno <- as.character(input@mol2_dummy_eleno)
  mol1_binding_atom <- as.character(input@mol1_binding_atom)
  mol2_binding_atom <- as.character(input@mol2_binding_atom)

  # Prepare matrices of atom positions (faster to modify)
  mol1_atom_mx_all <- as.matrix(input@mol1)[, c("x", "y", "z"), drop = FALSE]
  mol2_atom_mx_all <- as.matrix(input@mol2)[, c("x", "y", "z"), drop = FALSE]

  mol1_axis <- input@mol1_axis@values
  mol2_axis <- input@mol2_axis@values

  # We do NOT need to slide and rotate the whole molecule to find the optimum positions.
  # Instead we can just slide/move the binding and dummy atoms (mol1_dummy_eleno, mol2_dummy_eleno, mol1_binding_atom, mol2_binding_atom)
  # This will make compute faster so we can optimise more samples. The code below drops unnecessary atoms from our matrix
  mol1_atom_mx <- mol1_atom_mx_all[
    c(mol1_dummy_eleno, mol1_binding_atom),
    ,
    drop = FALSE
  ]
  mol2_atom_mx <- mol2_atom_mx_all[
    c(mol2_dummy_eleno, mol2_binding_atom),
    ,
    drop = FALSE
  ]

  # Return a function that takes a vector of 4 numbers and returns the distance between the two molecules
  fn <- function(x) {
    mol1_phi <- x[1]
    mol1_slide <- x[2]
    mol2_phi <- x[3]
    mol2_slide <- x[4]

    # Rotate Molecule
    mol1_rotated_mx <- move::rotate_table_around_axis(
      mol1_atom_mx,
      rotation_axis = mol1_axis,
      angle = mol1_phi
    )
    mol2_rotated_mx <- move::rotate_table_around_axis(
      mol2_atom_mx,
      rotation_axis = mol2_axis,
      angle = mol2_phi
    )

    # Slide Molecule
    mol1_slid_mx <- move::translate_table_in_direction(
      mol1_rotated_mx,
      direction = mol1_axis,
      magnitude = mol1_slide
    )
    mol2_slid_mx <- move::translate_table_in_direction(
      mol2_rotated_mx,
      direction = mol2_axis,
      magnitude = mol2_slide
    )

    # Compute distance between dummy and binding atom
    pos_mol1_dummy <- mol1_slid_mx[mol1_dummy_eleno, , drop = TRUE]
    pos_mol2_dummy <- mol2_slid_mx[mol2_dummy_eleno, , drop = TRUE]
    pos_mol1_binding_atom <- mol1_slid_mx[mol1_binding_atom, , drop = TRUE]
    pos_mol2_binding_atom <- mol2_slid_mx[mol2_binding_atom, , drop = TRUE]

    d1 <- move::measure_distance_between_two_points(
      pos_mol1_dummy,
      pos_mol2_binding_atom
    )
    d2 <- move::measure_distance_between_two_points(
      pos_mol2_dummy,
      pos_mol1_binding_atom
    )

    # Our objective is to minimise the sum of square distance between the dummy atoms of each molecule and the opposing atom binding atom
    obj <- d1^2 + d2^2
    return(obj)
  }

  return(fn)
}

#' Extract optimisation inputs
#'
#' Prepares two molecules for optimisation search for a particular shapeclass.
#' E.g. orients them relative to each other as mandated by the shapeclass mapping and
#' returns a list describing all the data we need to generate a loss function with [generate_loss_function()]
#'
#' @param mol1 a [Molecule3D()] object.
#' @param mol2 a [Molecule3D()] object.
#' @param mol1_binding_atom (eleno)
#' @param mol2_binding_atom (eleno)
#' @param shapeclass a string describing the exact shapeclass to extract optimisation inputs for (see list_all_shapeclasses() for options)
#'
#' @return an [OptimisationInputs()] object
#' @export
extract_optimisation_inputs <- function(
  mol1,
  mol2,
  mol1_binding_atom,
  mol2_binding_atom,
  shapeclass,
  invert_symmetry_axis = FALSE
) {
  # Assertions
  assertions::assert_class(mol1, class = "structures::Molecule3D")
  assertions::assert_class(mol2, class = "structures::Molecule3D")
  assertions::assert_string(shapeclass)
  mol1_name <- mol1@name
  mol2_name <- mol2@name

  # Step 1: check shapeclass is valid
  assertions::assert_one_of(shapeclass, list_all_shapeclasses())

  # Step 2: list all assessable shapeclasses
  df_assessable_all <- get_assessable_shapeclasses_from_molecules(
    mol1,
    mol2,
    verbose = FALSE
  )

  # Step 3: Grab the shapeclass mapping information for the user-supplied shapeclass
  df_assessable <- df_assessable_all[
    df_assessable_all$ShapeClass %in% shapeclass,
    ,
    drop = FALSE
  ]

  # Step 4: Throw error if trying to get optimisation inputs for a shapeclass not assessable given molecule proper rotation axes
  if (nrow(df_assessable) == 0) {
    cli::cli_abort(
      "Can not assess molecules {mol1_name} {mol2_name} for shapeclass: {shapeclass}"
    )
  }

  # Extra check in case upstream invariant (shapeclass unique) fails
  if (nrow(df_assessable) >= 2) {
    cli::cli_abort(
      "df_assessable has more than two rows .. this is a bug in the symbo codebase. Please report"
    )
  }

  # Save original mol 1 and mol2 because downstream code may change them
  mol1_original <- mol1
  mol2_original <- mol2

  # Step 5: Rotate molecules so their proper rotation axes relate in the way described by the df_assessable dataframe
  flipped <- df_assessable$flipped
  mol1_axis_cn <- df_assessable$mol1_axis
  mol2_axis_cn <- df_assessable$mol2_axis

  target_axis1_position <- c(
    x = df_assessable$Axis1x,
    y = df_assessable$Axis1y,
    z = df_assessable$Axis1z
  )

  target_axis2_position <- c(
    x = df_assessable$Axis2x,
    y = df_assessable$Axis2y,
    z = df_assessable$Axis2z
  )

  # if (invert_symmetry_axis) {
  #   target_axis2_position <- -target_axis2_position
  # }

  # Get molecule order (flip if required)
  mol1 <- if (!flipped) mol1_original else mol2_original
  mol2 <- if (!flipped) mol2_original else mol1_original

  # Get binding atom eleno (flip if required)
  mol1_binding_atom_flipped <- if (!flipped) {
    mol1_binding_atom
  } else {
    mol2_binding_atom
  }
  mol2_binding_atom_flipped <- if (!flipped) {
    mol2_binding_atom
  } else {
    mol1_binding_atom
  }

  # Fetch the proper rotation axis IDs
  mol1_axis_id <- structures::fetch_id_of_first_proper_rotation_axis_with_order(
    mol1,
    Cn = mol1_axis_cn
  )
  mol2_axis_id <- structures::fetch_id_of_first_proper_rotation_axis_with_order(
    mol2,
    Cn = mol2_axis_cn
  )

  # Optionally flip the symmetry axis position to cover the second half of the search space when invert_symmetry_axis
  if (invert_symmetry_axis) {
    # Simplify this once structures has an invert_symmetry_axis_function
    mol2_pra <- structures::fetch_symmetry_element_from_molecule(
      mol2,
      id = mol2_axis_id
    )

    posA <- mol2_pra@posA
    posB <- mol2_pra@posB
    mol2_pra_inverted <- structures::ProperRotationAxis(
      n = mol2_axis_cn,
      posA = posB,
      posB = posA
    )
    mol2@symmetry_elements@elements[[
      mol2_axis_id
    ]] <- mol2_pra_inverted
  }
  # Fetch first dummy atoms bonded to the selected binding atom in each molecule
  cli::cli_alert_info(
    "Fetching the first dummy atom bonded to each binding atom"
  )
  mol1_dummy_eleno <- fetch_first_dummy_atom_bonded_to_atom(
    molecule = mol1,
    binding_atom_eleno = mol1_binding_atom_flipped
  )
  mol2_dummy_eleno <- fetch_first_dummy_atom_bonded_to_atom(
    molecule = mol2,
    binding_atom_eleno = mol2_binding_atom_flipped
  )

  # No longer need because fetch_first_dummy_atom_bonded_to_atom should error appropriatedly
  # assertions::assert_length_greater_than(
  #   mol1_dummy_eleno,
  #   length = 0,
  #   msg = "Failed to find any dummy atoms in molecule [{mol1@name}]. Please ensure they are correctly labelled in your mol2 file (atom_type must be 'Du' or 'Du.C')"
  # )
  # assertions::assert_length_greater_than(
  #   mol2_dummy_eleno,
  #   length = 0,
  #   msg = "Failed to find any dummy atoms in molecule [{mol2@name}]. Please ensure they are correctly labelled in your mol2 file (atom_type must be 'Du' or 'Du.C')"
  # )

  # Rotate Molecules So Symmetry axes align with targets
  cli::cli_alert_info(
    "Rotating molecules so Symmetry Axes align with target vectors"
  )

  mol1 <- structures::rotate_molecule_so_symmetry_axis_aligns_with_vector(
    mol1,
    symmetry_element_id = mol1_axis_id,
    target = target_axis1_position
  )
  mol2 <- structures::rotate_molecule_so_symmetry_axis_aligns_with_vector(
    mol2,
    symmetry_element_id = mol2_axis_id,
    target = target_axis2_position
  )

  # Extract Symmetry Axes
  cli::cli_alert_info("Extracting Symmetry Axes")
  mol1_proper_rotation_axis <- structures::fetch_symmetry_element_from_molecule(
    mol1,
    id = mol1_axis_id,
    error_if_missing = TRUE
  )
  mol2_proper_rotation_axis <- structures::fetch_symmetry_element_from_molecule(
    mol2,
    id = mol2_axis_id,
    error_if_missing = TRUE
  )

  # Translate to molecule so symmetry axis is in position
  mol1 <- mol1 |>
    structures::set_anchor_by_position(mol1_proper_rotation_axis@posA) |>
    structures::translate_molecule_to_position(c(0, 0, 0))

  mol2 <- mol2 |>
    structures::set_anchor_by_position(mol2_proper_rotation_axis@posA) |>
    structures::translate_molecule_to_position(c(0, 0, 0))

  # Create a list of the information optimiser will need
  # optimisation_input <- list(
  #   mol1 = mol1,
  #   mol2 = mol2,
  #   mol1_axis = target_axis1_position,
  #   mol2_axis = target_axis2_position,
  #   mol1_dummy_eleno = mol1_dummy_eleno,
  #   mol2_dummy_eleno = mol2_dummy_eleno,
  #   mol1_binding_atom = mol1_binding_atom_flipped,
  #   mol2_binding_atom = mol2_binding_atom_flipped
  # )

  optimisation_input <- OptimisationInputs(
    mol1 = mol1,
    mol2 = mol2,
    mol1_axis = Vec3(target_axis1_position),
    mol2_axis = Vec3(target_axis2_position),
    mol1_dummy_eleno = mol1_dummy_eleno,
    mol2_dummy_eleno = mol2_dummy_eleno,
    mol1_binding_atom = mol1_binding_atom_flipped,
    mol2_binding_atom = mol2_binding_atom_flipped
  )

  return(optimisation_input)
}


# Shapeclass Utils -----------------------------------------------------------

#' Mapping Proper Rotation Axes to ShapeClasses
#'
#' Load data.frame mapping pairs of proper rotation axes to higher order ShapeClasses.
#' See [get_assessable_shapeclasses()] for more information about how it is used.
#'
#' @return data.frame mapping pairs of proper rotation axes to higher order ShapeClasses
#'
#' @examples
#' axes_to_shapeclass_reference()
#'
#' @export
axes_to_shapeclass_reference <- function() {
  df <- utils::read.csv(system.file(package = "symbo", "shapeclass_info.csv"))
  df$AxisComboKey <- paste(df$Axis1, df$Axis2)

  return(df)
}

#' List all valid shapeclasses
#'
#' @return vector of valid shapeclasses
#'
#' @examples
#' list_all_shapeclasses()
#'
#' @export
list_all_shapeclasses <- function() {
  axes_to_shapeclass_reference()[["ShapeClass"]]
}

#' Get assessable polyhedral geometries from symmetry axis orders
#'
#' Given two sets of unique proper rotation axis orders for two molecules,
#' this function returns the subset of geometries that can be assessed
#' with those symmetries.
#'
#' Geometries are matched in two orientations:
#' \itemize{
#'   \item \strong{Forward:} \code{molecule1_axes} supply \code{Axis1_order}
#'         and \code{molecule2_axes} supply \code{Axis2_order}.
#'   \item \strong{Swapped:} \code{molecule2_axes} supply \code{Axis1_order}
#'         and \code{molecule1_axes} supply \code{Axis2_order}.
#' }
#'
#' For geometries that are only assessable in the swapped orientation,
#' \code{treat_molecule2_as_1} is set to \code{TRUE} to indicate that
#' downstream code should treat molecule 2 as molecule 1.
#'
#' @param molecule1_axes A numeric or character vector of unique proper
#'   rotation axis orders present in molecule 1 (e.g. \code{c(3, 4)}).
#' @param molecule2_axes A numeric or character vector of unique proper
#'   rotation axis orders present in molecule 2 (e.g. \code{c(2)}).
#'
#' @return A \code{data.frame} containing all assessable geometries given
#'   the supplied axes. It includes all columns from [axes_to_shapeclass_reference()], plus:
#'   \itemize{
#'     \item \code{treat_molecule2_as_1}: logical; \code{FALSE} if the
#'       ShapeClass is assessable in the forward orientation
#'       (\code{mol1 -> Axis1}, \code{mol2 -> Axis2}),
#'       \code{TRUE} if only assessable when molecules are swapped.
#'   }
#'   If no geometries are assessable, an empty \code{data.frame} is returned.
#'
#' @examples
#' # Suppose molecule 1 has C3 and C4, molecule 2 has C2:
#' get_assessable_shapeclasses(molecule1_axes = c(3, 4),
#'                           molecule2_axes = 2)
#'
#' # If molecule 1 only has C2 and molecule 2 has C3, some geometries
#' # (e.g. edge-capped dodecahedron) are only assessable by swapping:
#' get_assessable_shapeclasses(molecule1_axes = 2,
#'                           molecule2_axes = 3)
#'
#' @export
get_assessable_shapeclasses <- function(molecule1_axes, molecule2_axes) {
  # Coerce to integer (in case user passes characters like "2", "3")
  # mol1 <- as.integer(molecule1_axes)
  # mol2 <- as.integer(molecule2_axes)

  df_combos <- create_combos(molecule1_axes, molecule2_axes)

  mapping <- axes_to_shapeclass_reference()

  df_combos_annotated <- df_combos |>
    dplyr::left_join(mapping, by = "AxisComboKey")

  df_combos_annotated$assessable <- !is.na(df_combos_annotated$ShapeClass)

  df_combos_annotated <- df_combos_annotated |>
    dplyr::filter(.data[["assessable"]]) |>
    dplyr::slice_head(n = 1, by = .data[["ShapeClass"]])

  df_combos_annotated$AxisComboKey <- NULL

  return(df_combos_annotated)
}


#' Get assessable shapeclasses from molecule objects
#'
#' A simple wrapper around get_assessable_shapeclasses that works from molecule3D objects,
#' not just the axes. Throws informative errors when shapeclasses cannot be found
#'
#' @inherit get_assessable_shapeclasses return details
#'
#' @param molecule1 a [Molecule3D()] object annotated with its proper rotation axes
#' @param molecule2 a [Molecule3D()] object annotated with its proper rotation axes
#'
#'
get_assessable_shapeclasses_from_molecules <- function(
  molecule1,
  molecule2,
  verbose = TRUE
) {
  assertions::assert_class(molecule1, class = "structures::Molecule3D")
  assertions::assert_class(molecule2, class = "structures::Molecule3D")

  # Fetch Assessable shapeclasses
  if (verbose) {
    cli::cli_alert_info("Figuring out which shape classes are assessable")
  }
  molecule1_name <- molecule1@name
  molecule2_name <- molecule2@name
  molecule1_proper_rotation_axes <- molecule1@symmetry_elements@unique_proper_axis_orders
  molecule2_proper_rotation_axes <- molecule2@symmetry_elements@unique_proper_axis_orders

  ## Throw errors if either molecule has no proper rotation axes annotated
  if (length(molecule1_proper_rotation_axes) == 0) {
    cli::cli_abort(
      "Molecule 1 [{molecule1_name}] has no proper rotation axes. Can NOT screen for valid shapeclasses. Please annotate molecule with a ProperRotationAxis using the [structures::add_symmetry_element_to_molecule()] function and try again"
    )
  }
  if (length(molecule2_proper_rotation_axes) == 0) {
    cli::cli_abort(
      "Molecule 2 [{molecule2_name}] has no proper rotation axes. Can NOT screen for valid shapeclasses. Please annotate molecule with a ProperRotationAxis using the [structures::add_symmetry_element_to_molecule()] function and try again"
    )
  }

  if (verbose) {
    cli::cli_alert_info(sprintf(
      "Molecule 1 [%s] has [%s]",
      molecule1_name,
      toString(paste0("C", molecule1_proper_rotation_axes))
    ))
    cli::cli_alert_info(sprintf(
      "Molecule 2 [%s] has [%s]",
      molecule2_name,
      toString(paste0("C", molecule2_proper_rotation_axes))
    ))
  }

  df_assessable <- get_assessable_shapeclasses(
    molecule1_axes = molecule1_proper_rotation_axes,
    molecule2_axes = molecule2_proper_rotation_axes
  )

  return(df_assessable)
}

create_combos <- function(molecule1_axes, molecule2_axes) {
  df_combos_unflipped <- expand.grid(
    mol1_axis = molecule1_axes,
    mol2_axis = molecule2_axes
  )
  df_combos_unflipped$flipped <- FALSE
  df_combos_flipped <- expand.grid(
    mol1_axis = molecule2_axes,
    mol2_axis = molecule1_axes
  )
  df_combos_flipped$flipped <- TRUE
  df_combos <- rbind(df_combos_unflipped, df_combos_flipped)
  df_combos$AxisComboKey <- paste(df_combos$mol1, df_combos$mol2)

  return(df_combos)
}

bind_rows_into_mx <- function(ls) {
  as.matrix(do.call(rbind, ls))
}

fetch_first_dummy_atom_bonded_to_atom <- function(
  molecule,
  binding_atom_eleno,
  dummy_atom_types = c("Du", "Du.C")
) {
  assertions::assert_class(molecule, class = "structures::Molecule3D")
  assertions::assert_length(binding_atom_eleno, length = 1)

  dummy_eleno <- structures::fetch_eleno_by_atom_type(
    molecule,
    atom_type = dummy_atom_types
  )

  if (length(dummy_eleno) == 0) {
    cli::cli_abort(
      "Failed to find any dummy atoms in molecule [{molecule@name}]. Please ensure they are correctly labelled in your mol2 file (atom_type must be 'Du' or 'Du.C')"
    )
  }

  bond_table <- structures::bonds(molecule)
  incident_bonds <- bond_table[
    bond_table$origin_atom_id == binding_atom_eleno |
      bond_table$target_atom_id == binding_atom_eleno,
    ,
    drop = FALSE
  ]

  bonded_eleno <- ifelse(
    incident_bonds$origin_atom_id == binding_atom_eleno,
    incident_bonds$target_atom_id,
    incident_bonds$origin_atom_id
  )

  bonded_dummy_eleno <- bonded_eleno[bonded_eleno %in% dummy_eleno]
  first_bonded_dummy_eleno <- utils::head(bonded_dummy_eleno, n = 1)

  if (length(first_bonded_dummy_eleno) == 0) {
    cli::cli_abort(
      "Failed to find a dummy atom bonded to binding atom [{binding_atom_eleno}] in molecule [{molecule@name}]. Please ensure the selected binding atom is directly bonded to an atom with atom_type 'Du' or 'Du.C'."
    )
  }

  return(first_bonded_dummy_eleno)
}
