#' @importFrom magrittr %>%
#' @export
magrittr::`%>%`


.as.data.frame_density <- function(x, ...) {
  data.frame(x = x$x, y = x$y)
}



.normalize <- function(x) {
  as.vector((x - min(x, na.rm = TRUE)) / diff(range(x, na.rm = TRUE), na.rm = TRUE))
}



.compact_list <- function(x) {
  if (!is.null(x) && length(x) > 0 && is.list(x)) {
    x[!sapply(x, function(i) length(i) == 0 || is.null(i) || any(i == "NULL"))]
  } else {
    x
  }
}



# is string empty?
.is_empty_object <- function(x) {
  if (is.list(x)) {
    x <- tryCatch(
      {.compact_list(x)},
      error = function(x) { x }
    )
  }
  # this is an ugly fix because of ugly tibbles
  if (inherits(x, c("tbl_df", "tbl"))) x <- as.data.frame(x)
  x <- suppressWarnings(x[!is.na(x)])
  length(x) == 0 || is.null(x)
}




# safe conversion from factor to numeric
#' @importFrom stats na.omit
.factor_to_numeric <- function(x) {
  if (is.numeric(x))
    return(x)

  if (anyNA(suppressWarnings(as.numeric(as.character(stats::na.omit(x)))))) {
    if (is.character(x)) {
      x <- as.factor(x)
    }
    levels(x) <- 1:nlevels(x)
  }

  as.numeric(as.character(x))
}



#' @importFrom stats setNames
.clean_parameter_names <- function(params, grid = FALSE) {

  params <- unique(params)
  labels <- params

  # clean parameters names
  params <- gsub("(b_|bs_|bsp_|bcs_)(.*)", "\\2", params, perl = TRUE)
  params <- gsub("^zi_(.*)", "\\1 (Zero-Inflated)", params, perl = TRUE)
  params <- gsub("(.*)_zi$", "\\1 (Zero-Inflated)", params, perl = TRUE)
  # clean random effect parameters names
  params <- gsub("r_(.*)\\.(.*)\\.", "(re) \\1", params)
  params <- gsub("b\\[\\(Intercept\\) (.*)\\]", "(re) \\1", params)
  params <- gsub("b\\[(.*) (.*)\\]", "(re) \\2", params)
  # clean smooth terms
  params <- gsub("^smooth_sd\\[(.*)\\]", "\\1 (smooth)", params)
  params <- gsub("^sds_", "\\1 (Smooth)", params)
  # remove ".1" etc. suffix
  params <- gsub("(.*)(\\.)(\\d)$", "\\1 \\3", params)
  # fix zero-inflation part in random effects
  params <- gsub("(.*)__zi\\s(.*)", "\\1 \\2 (Zero-Inflated)", params, perl = TRUE)
  # fix temporary random effects token
  params <- gsub("\\(re\\)\\s(.*)", "\\1 (Random)", params, perl = TRUE)

  if (grid) {
    params <- trimws(gsub("(Zero-Inflated)", "", params, fixed = TRUE))
    params <- trimws(gsub("(Random)", "", params, fixed = TRUE))
  } else {
    params <- gsub("(Zero-Inflated) (Random)", "(Random, Zero-Inflated)", params, fixed = TRUE)
  }

  stats::setNames(params, labels)
}



.fix_facet_names <- function(x) {
  if ("Component" %in% names(x)) {
    x$Component <- as.character(x$Component)
    if (!"Effects" %in% names(x)) {
      x$Component[x$Component == "conditional"] <- "Conditional"
      x$Component[x$Component == "zero_inflated"] <- "Zero-Inflated"
    } else {
      x$Component[x$Component == "conditional"] <- "(Conditional)"
      x$Component[x$Component == "zero_inflated"] <- "(Zero-Inflated)"
    }
  }
  if ("Effects" %in% names(x)) {
    x$Effects <- as.character(x$Effects)
    x$Effects[x$Effects == "fixed"] <- "Fixed Effects"
    x$Effects[x$Effects == "random"] <- "Random Effects"
  }
  x
}



.intercepts <- function() {
  c("(intercept)_zi", "intercept (zero-inflated)", "intercept", "zi_intercept", "(intercept)", "b_intercept", "b_zi_intercept")
}


.has_intercept <- function(x) {
  tolower(x) %in% .intercepts() | grepl("^intercept", tolower(x))
}


.in_intercepts <- function(x) {
  tolower(x) %in% .intercepts() | grepl("^intercept", tolower(x))
}


.remove_intercept <- function(x, column = "Parameter", show_intercept) {
  if (!show_intercept) {
    remove <- which(.in_intercepts(x[[column]]))
    if (length(remove)) x <- x[-remove, ]
  }
  x
}
