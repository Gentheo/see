#' @importFrom effectsize change_scale
#' @export
data_plot.compare_performance <- function(x, data = NULL, ...){
  x$Model <- sprintf("%s (%s)", x$Model, x$Type)
  x$Type <- NULL
  x$Performance_Score <- NULL

  # set reference for Bayes factors to 1
  if ("BF" %in% colnames(x)) x$BF[is.na(x$BF)] <- 1

  # normalize indices, for better comparison
  x <- effectsize::change_scale(x, exclude = "Model", to = c(.1, 1))

  # recode some indices, so higher values = better fit
  for (i in c("AIC", "BIC", "RMSE")) {
    if (i %in% colnames(x)) {
      x[[i]] <- 1.1 - x[[i]]
    }
  }

  # remove indices with missing value, comparison makes no sense here
  x <- x[sapply(x, function(.x) !anyNA(.x))]

  x <- .reshape_to_long(x, names_to = "name", columns = 2:ncol(x))
  x$name <- factor(x$name, levels = unique(x$name))

  dataplot <- as.data.frame(x)
  attr(dataplot, "info") <- list(
    "xlab" = "",
    "ylab" = "",
    "title" = "Comparison of Model Indices",
    "legend_color" = "Models"
  )

  class(dataplot) <- c("data_plot", "see_compare_performance", "data.frame")
  dataplot
}




# Plot --------------------------------------------------------------------
#' @rdname data_plot
#' @importFrom rlang .data
#' @importFrom scales percent
#' @export
plot.see_compare_performance <- function(x, size = 1, ...) {

  # We may think of plotting the "performance scores" as bar plots,
  # however, the "worst" model always has a score of zero, so no bar
  # is shown - this is rather confusing. One option might be to only
  # normalize indices that have a range other than 0-1, and leave
  # indices like R2 (that have a range between 0 and 1) unchanged...

  # if ("Performance_Score" %in% colnames(x)) {
  #   if (missing(size)) size <- .7
  #   x$Model <- sprintf("%s (%s)", x$Model, x$Type)
  #   p <- ggplot(x, aes(
  #     x = .data$Model,
  #     y = .data$Performance_Score
  #   )) +
  #     geom_col(width = size) +
  #     scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
  #     labs(x = "Model", y = "Performance Score")
  # } else {

  if (!"data_plot" %in% class(x)) {
    x <- data_plot(x)
  }

  p <- ggplot(x, aes(
    x = .data$name,
    y = .data$values,
    colour = .data$Model,
    group = .data$Model,
    fill = .data$Model
  )) +
    geom_polygon(size = size, alpha = .05) +
    coord_radar() +
    scale_y_continuous(limits = c(0, 1), labels = NULL) +
    add_plot_attributes(x) +
    guides(fill = "none") +
    theme_radar()

  p
}
