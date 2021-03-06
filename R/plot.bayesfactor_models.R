#' @rdname data_plot
#' @examples
#' library(bayestestR)
#' library(see)
#'
#' lm0 <- lm(qsec ~ 1, data = mtcars)
#' lm1 <- lm(qsec ~ drat, data = mtcars)
#' lm2 <- lm(qsec ~ wt, data = mtcars)
#' lm3 <- lm(qsec ~ drat + wt, data = mtcars)
#'
#' result <- bayesfactor_models(lm1, lm2, lm3, denominator = lm0)
#'
#' plot(result, n_pies = "one", value = "probability") + theme_modern() +
#'   scale_fill_pizza(reverse = TRUE)
#'
#' @export
plot.see_bayesfactor_models <-
  function(x,
           n_pies = c("one", "many"),
           value = c("none", "BF", "probability"),
           sort = FALSE,
           log = FALSE,
           prior_odds = NULL,
           ...) {

  n_pies <- match.arg(n_pies)
  value <- match.arg(value)

  denominator <- attr(x, "denominator")
  denominator_name <- x$Model[denominator]

  priorOdds <- rep(1, nrow(x))
  po_txt <- ""
  if (!is.null(prior_odds)) {
    priorOdds[-denominator] <- prior_odds
    po_txt <- "NOTE: Slice sizes based on custom prior odds"
  }

  if (isTRUE(sort)) {
    one_pie_sort <- "PostProb"
  } else {
    one_pie_sort <- NULL
  }

  # Prep data and bar position:
  one_pie_data <- as.data.frame(x)
  one_pie_data$PostProb = (one_pie_data$BF / sum(one_pie_data$BF)) * priorOdds
  if (isTRUE(sort)) one_pie_data <- one_pie_data[order(one_pie_data$PostProb, decreasing = TRUE), ]
  one_pie_data$pos_txt <- sum(one_pie_data$PostProb) + one_pie_data$PostProb / 2 - cumsum(one_pie_data$PostProb)
  one_pie_data$Model <- factor(one_pie_data$Model, levels = unique(one_pie_data$Model))

  many_pies_data <- suppressWarnings(
    rbind(one_pie_data %>%
            dplyr::mutate(Type     = denominator_name,
                          BF       = .data$BF[denominator],
                          PostProb = .data$PostProb[denominator]),
          one_pie_data %>%
            dplyr::mutate(Type = .data$Model)) %>%
      dplyr::group_by(.data$Model) %>%
      dplyr::mutate(pos_bar = .data$PostProb / sum(.data$PostProb),
                    pos_txt = sum(.data$pos_bar) + .data$pos_bar / 2 - cumsum(.data$pos_bar)) %>%
      dplyr::filter(.data$Model != denominator_name) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(Type = factor(.data$Type, levels = unique(.data$Type)))
  )


  if (value == "BF") {
    if (log) {
      one_pie_data$label <- round(log(one_pie_data$BF), 2)
      many_pies_data$label <- round(log(many_pies_data$BF), 2)
    } else {
      one_pie_data$label <- round(one_pie_data$BF, 2)
      many_pies_data$label <- round(many_pies_data$BF, 2)
    }
  } else if (value == "probability") {
    one_pie_data$label <- paste0(round(one_pie_data$PostProb * 100, 1),"%")
    many_pies_data$label <- paste0(round(many_pies_data$PostProb * 100, 1),"%")
  } else {
    one_pie_data$label <- ""
    many_pies_data$label <- ""
  }


  if (n_pies == "one") {
    ggplot(one_pie_data, aes(x = "", y = .data$PostProb, fill = .data$Model)) +
      geom_bar(width = 1, stat = "identity", color = "white", size = .5) +
      geom_text(aes(y = .data$pos_txt, label = .data$label), position = position_nudge(.1)) +
      coord_polar("y", start = 0) +
      scale_y_continuous(expand = c(0, 0)) +
      labs(x = "", y = "", fill = "Model") +
      theme_void() +
      labs(caption = po_txt)
  } else {
    ggplot(many_pies_data, aes(x = "", y = .data$pos_bar, fill = .data$Type)) +
      geom_bar(width = 1, stat = "identity", color = "white", size = .5) +
      geom_text(aes(y = .data$pos_txt, label = .data$label), position = position_nudge(.1)) +
      coord_polar("y", start = 0) +
      facet_wrap( ~ .data$Model) +
      labs(x = "", y = "", fill = "Model") +
      theme_void() +
      labs(caption = po_txt)
  }
}
