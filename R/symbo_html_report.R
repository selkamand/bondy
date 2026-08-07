#' Create a report summarising results of screen
#'
#'  Create a report summarising results of screen
#'
#' @param optimisations an [`OptimisationResultCollection`] object produced by [screen_molecules()]
#'
#' @param outdir Directory where the HTML report should be written.
#'   Defaults to the current working directory. The final report will be saved
#'   as `{prefix}.html` inside this folder.
#'
#' @param prefix A character string used as the base filename for the report.
#'   The resulting output file will be named `{prefix}.html`. Defaults to
#'   `"screen_results"`.

#' @returns invisibly returns NULL (this function is run for its side effects)
#' @export
#'
create_summary_report <- function(
  optimisations,
  outdir = getwd(),
  prefix = "screen_results"
) {
  assertions::assert_class(
    optimisations,
    class = "symbo::OptimisationResultCollection"
  )
  path_template <- system.file(package = "symbo", "template/template.Rmd")

  # Ensure dependencies are available (fail fast with a clear message)
  required_pkgs <- c(
    "assertions",
    "cli",
    "rmarkdown",
    "knitr",
    "htmltools",
    "rgl",
    "chemviewR",
    "reactable",
    "rlang",
    "downloadthis",
    "structures"
  )

  missing <- required_pkgs[
    !vapply(required_pkgs, rlang::is_installed, logical(1))
  ]
  if (length(missing) > 0) {
    rlang::abort(c(
      "Missing packages required to render the symbo HTML report.",
      i = paste0(
        "Install: install.packages(c(",
        paste(sprintf("%s", shQuote(missing)), collapse = ", "),
        "))"
      )
    ))
  }

  outpath <- sprintf("%s/%s.html", outdir, prefix)
  cli::cli_alert_info("Saving report to {.path {outpath}}")
  rmarkdown::render(
    input = path_template,
    output_format = "html_document",
    output_file = prefix,
    output_dir = outdir,
    params = list(collection = optimisations),
    intermediates_dir = outdir
  )

  utils::browseURL(url = outpath)

  invisible(NULL)
}
