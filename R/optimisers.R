#' Minimise a loss function by L_BFGS_B
#'
#' Optimise a function produced by [generate_loss_function()] using L-BFGS-B
#'
#' Bounding strategy: phi values are bounded between 0 and 360. slide values are unbounded.
#'
#' @param fn a function that takes a vector of 4 numeric elements corresponding to c(mol1_phi, mol1_slide, mol2_phi, mol2_slide)
#'
#' @return A [OptimisationResultBasic()] object
#'
#' @export
optimise_L_BFGS_B <- function(fn, minimised_value_description) {
  assertions::assert_function(fn)
  result <- optim(
    par = c(mol1_phi = 90, mol1_slide = 0, mol2_phi = 90, mol2_slide = 0),
    method = "L-BFGS-B",
    fn = fn,
    lower = c(
      mol1_phi = 0,
      mol1_slide = -Inf,
      mol2_phi = 0,
      mol2_slide = -Inf
    ),
    upper = c(
      mol1_phi = 360,
      mol1_slide = Inf,
      mol2_phi = 360,
      mol2_slide = Inf
    )
  )
  convergence_string <- base_optim_convergence_number_to_string(
    result$convergence
  )

  OptimisationResultBasic(
    minimised_value = result$value,
    mol1_phi = result$par[1],
    mol1_slide = result$par[2],
    mol2_phi = result$par[3],
    mol2_slide = result$par[4],
    n_calls_to_fn = result$counts[1],
    n_calls_to_gr = result$counts[2],
    message = result$message,
    convergence = convergence_string
  )
}
