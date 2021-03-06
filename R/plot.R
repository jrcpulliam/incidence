#' Plot function for incidence objects
#'
#' This function is used to visualise the output of the [incidence()]
#' function, using the package `ggplot2`.
#'
#'
#' @export
#'
#' @importFrom graphics plot
#'
#' @author Thibaut Jombart \email{thibautjombart@@gmail.com}
#'   Zhian N. Kamvar \email{zkamvar@@gmail.com}
#'
#' @seealso The [incidence()] function to generate the 'incidence'
#' objects.
#'
#' @param x An incidence object, generated by the function
#' [incidence()].
#'
#' @param ... Further arguments passed to other methods (currently not used).
#'
#' @param fit An 'incidence_fit' object as returned by [fit()].
#'
#' @param stack A logical indicating if bars of multiple groups should be
#' stacked, or displayed side-by-side.
#'
#' @param color The color to be used for the filling of the bars; NA for
#' invisible bars; defaults to "black".
#'
#' @param border The color to be used for the borders of the bars; NA for
#' invisible borders; defaults to NA.
#'
#' @param col_pal The color palette to be used for the groups; defaults to
#' `incidence_pal1`. See [incidence_pal1()] for other palettes implemented in
#' incidence.
#'
#' @param alpha The alpha level for color transparency, with 1 being fully
#' opaque and 0 fully transparent; defaults to 0.7.
#'
#' @param xlab The label to be used for the x-axis; empty by default.
#'
#' @param ylab The label to be used for the y-axis; by default, a label will be
#' generated automatically according to the time interval used in incidence
#' computation.
#'
#' @param labels_iso a logical value indicating whether labels x axis tick
#' marks are in ISO 8601 week format yyyy-Www when plotting ISO week-based weekly
#' incidence; defaults to be TRUE.
#'
#' @param show_cases if `TRUE` (default: `FALSE`), then each observation will be
#' colored by a border. The border defaults to a white border unless specified
#' otherwise. This is normally used outbreaks with a small number of cases.
#' Note: this can only be used if `stack = TRUE`
#'
#' @param n_breaks the ideal number of breaks to be used for the x-axis
#'   labeling
#'
#' @examples
#'
#' if(require(outbreaks) && require(ggplot2)) { withAutoprint({
#'   onset <- ebola_sim$linelist$date_of_onset
#'
#'   ## daily incidence
#'   inc <- incidence(onset)
#'   inc
#'   plot(inc)
#'
#'   ## weekly incidence
#'   inc.week <- incidence(onset, interval = 7)
#'   inc.week
#'   plot(inc.week) # default to label x axis tick marks with isoweeks
#'   plot(inc.week, labels_iso = FALSE) # label x axis tick marks with dates
#'   plot(inc.week, border = "white") # with visible border
#'
#'   ## use group information
#'   sex <- ebola_sim$linelist$gender
#'   inc.week.gender <- incidence(onset, interval = 7, groups = sex)
#'   plot(inc.week.gender)
#'   plot(inc.week.gender, labels_iso = FALSE)
#'
#'   ## show individual cases at the beginning of the epidemic
#'   inc.week.8 <- subset(inc.week.gender, to = "2014-06-01")
#'   plot(inc.week.8, show_cases = TRUE, border = "black")
#'
#'   ## customize plot with ggplot2
#'   plot(inc.week.8, show_cases = TRUE, border = "black") +
#'     theme_classic(base_size = 16) +
#'     theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
#'
#'   ## adding fit
#'   fit <- fit_optim_split(inc.week.gender)$fit
#'   plot(inc.week.gender, fit = fit)
#'   plot(inc.week.gender, fit = fit, labels_iso = FALSE)
#' })}
#'
plot.incidence <- function(x, ..., fit = NULL, stack = is.null(fit),
                           color = "black", border = NA, col_pal = incidence_pal1,
                           alpha = .7, xlab = "", ylab = NULL,
                           labels_iso = !is.null(x$isoweeks),
                           show_cases = FALSE,
                           n_breaks = 6) {
  stopifnot(is.logical(labels_iso))

  ## extract data in suitable format for ggplot2
  df <- as.data.frame(x, long = TRUE)
  n.groups <- ncol(x$counts)
  gnames   <- group_names(x)

  ## Use custom labels for usual time intervals
  if (is.null(ylab)) {
    if (is.numeric(x$interval)) {
      if (x$interval == 1) {
        ylab <- "Daily incidence"
      } else if (x$interval == 7) {
        ylab <- "Weekly incidence"
      } else if (x$interval == 14) {
        ylab <- "Biweekly incidence"
      } else {
        ylab <- sprintf("Incidence by period of %d days",
                        x$interval)
      }
    } else if (is.character(x$interval)) {
      x$interval <- gsub("^([a-z]+?)s*$", "\\1", x$interval)
      ylab <- switch(x$interval,
                     day     = "Daily incidence",
                     week    = "Weekly incidence",
                     month   = "Monthly incidence",
                     quarter = "Quarterly incidence",
                     year    = "Yearly incidence"
                    )
    }
    if (isTRUE(x$cumulative)) {
      ylab <- sub("incidence", "cumulative incidence", ylab)
    }
  }

  ## Handle stacking
  stack.txt <- if (stack) "stack" else "dodge"

  ## By default, the annotation of bars in geom_bar puts the label in the
  ## middle of the bar. This is wrong in our case as the annotation of a time
  ## interval is the lower (left) bound, and should therefore be left-aligned
  ## with the bar. Note that we cannot use position_nudge to create the
  ## x-offset as we need the 'position' argument for stacking. This can be
  ## addressed by adding interval/2 to the x-axis, but this only works until we
  ## have an interval such as "month", "quarter", or "year" where the number of
  ## days for each can vary. To alleviate this, we can create a new column that
  ## counts the number of days within each interval.

  ## Adding a variable for width in ggplot
  df$interval.days <- get_interval(x, integer = TRUE)
  ## if the date type is POSIXct, then the interval is actually interval seconds
  ## and needs to be converted to days
  if (inherits(df$dates, "POSIXct")) {
    df$interval.days <- df$interval.days * 86400 # 24h * 60m * 60s
  }
  ## Important note: it seems safest to specify the aes() as part of the geom,
  ## not in ggplot(), as it interacts badly with some other geoms like
  ## geom_ribbon - used e.g. in projections::add_projections().
  x_axis <- "dates + (interval.days/2)"
  y_axis <- "counts"
  out <- ggplot2::ggplot(df) +
    ggplot2::geom_bar(ggplot2::aes_string(
                        x = x_axis,
                        y = y_axis
                        ),
                      stat = "identity",
                      width = df$interval.days,
                      position = stack.txt,
                      color = border,
                      alpha = alpha) +
    ggplot2::labs(x = xlab, y = ylab)

  ## Handle show_cases here

  if (show_cases && stack) {
    squaredf <- df[rep(seq.int(nrow(df)), df$counts), ]
    squaredf$counts <- 1
    squares <- ggplot2::geom_bar(ggplot2::aes_string(
                                   x = x_axis,
                                   y = y_axis
                                   ),
                                 color = if (is.na(border)) "white" else border,
                                 stat = "identity",
                                 fill  = NA,
                                 position = "stack",
                                 data = squaredf,
                                 width = squaredf$interval.days
                                 )
    out <- out + squares
  }
  if (show_cases && !stack) {
    message("the argument `show_cases` requires the argument `stack = TRUE`")
  }
  ## Handle fit objects here; 'fit' can be either an 'incidence_fit' object,
  ## or a list of these. In the case of a list, we add geoms one after the
  ## other.

  if (!is.null(fit)) {
    if (inherits(fit, "incidence_fit")) {
      out <- add_incidence_fit(out, fit)
    } else if (is.list(fit)) {
      for (i in seq_along(fit)) {
        fit.i <- fit[[i]]
        if (!inherits(fit.i, c("incidence_fit", "incidence_fit_list"))) {
          stop(sprintf(
            "The %d-th item in 'fit' is not an 'incidence_fit' object, but a %s",
            i, class(fit.i)))
        }
        out <- add_incidence_fit(out, fit.i)
      }
    } else {
      stop("Fit must be a 'incidence_fit' object, or a list of these")
    }
  }


  ## Handle colors

  ## Note 1: because of the way 'fill' works, we need to specify it through
  ## 'aes' if not directly in the geom. This causes the kludge below, where we
  ## make a fake constant group to specify the color and remove the legend.

  ## Note 2: when there are groups, and the 'color' argument does not have one
  ## value per group, we generate colors from a color palette. This means that
  ## by default, the palette is used, but the user can manually specify the
  ## colors.

  if (n.groups < 2 && is.null(gnames)) {
    out <- out + ggplot2::aes(fill = 'a') +
      ggplot2::scale_fill_manual(values = color, guide = FALSE)
  } else {
    if (!is.null(names(color))) {
      tmp     <- color[gnames] 
      matched <- names(color) %in% names(tmp)
      if (!all(matched)) {
        removed <- paste(names(color)[!matched], 
                         color[!matched],
                         sep = '" = "',
                         collapse = '", "')
        message(sprintf("%d colors were not used: \"%s\"", sum(!matched), removed))
      }
      color <- tmp
    }
                                 
    ## find group colors
    if (length(color) != n.groups) {
      msg <- "The number of colors (%d) did not match the number of groups (%d)"
      msg <- paste0(msg, ".\nUsing `col_pal` instead.")
      default_color <- length(color) == 1L && color == "black"
      if (!default_color) {
        message(sprintf(msg, length(color), n.groups))
      }
      group.colors <- col_pal(n.groups)
    } else {
      group.colors <- color
    }

    ## add colors to the plot
    out <- out + ggplot2::aes_string(fill = "groups") +
      ggplot2::scale_fill_manual(values = group.colors)
    if (!is.null(fit)) {
      out <- out + ggplot2::aes_string(color = "groups") +
        ggplot2::scale_color_manual(values = group.colors)
    }
  }

  ## Replace labels of x axis tick marks with ISOweeks

  ## This is a temporary fix due to ggplot2 breaking backward compatibility. As
  ## they say, 'deprecated aint for dogs'.. anyway, we need two versions,
  ## compatible with the old, and the new version of ggplot2, to be released 15
  ## June 2018.

  breaks <- pretty(x$dates, n_breaks)

  if (labels_iso && "isoweeks" %in% names(x)) {
    breaks_info <- make_iso_breaks(x$dates, n_breaks)
    out <- out + ggplot2::scale_x_date(breaks = breaks_info$breaks,
                                       labels = breaks_info$labels)
  } else {
    if (is.character(x$interval)) {
      # if the interval is a character, we have to figure out how to split these
      # manually. Luckily, ggplot2::scale_x_date() can take something like
      # "3 months" for a date_break argument.
      ts <- x$timespan/(n_breaks*mean(df$interval.days))
      if (x$interval == "quarter") {
        db <- paste(ceiling(ts) * 3, "months")
      } else {
        db <- paste(ceiling(ts), x$interval)
      }
    } else {
      db <- ggplot2::waiver()
    }
    if (inherits(x$dates, "Date")) {
      out <- out + ggplot2::scale_x_date(breaks      = breaks,
                                         date_breaks = db
                                        )
    } else if (inherits(x$dates, "POSIXct")) {
      out <- out + ggplot2::scale_x_datetime(breaks      = breaks,
                                             date_breaks = db
                                            )
    } else {
      out <- out + ggplot2::scale_x_continuous(breaks = breaks)
    }
  }
  out
}


## This function will take an existing 'incidence' plot object ('p') and add lines from an
## 'incidence_fit' object ('x')

#' @export
#' @rdname plot.incidence
#'
#' @param p An existing incidence plot.
add_incidence_fit <- function(p, x, col_pal = incidence_pal1){
  if (inherits(x, "incidence_fit_list")) {
    x <- get_fit(x)
  }
  ## 'x' could be a list of fit, in which case all fits are added to the plot
  if (is.list(x) && !inherits(x, "incidence_fit")) {
    out <- p
    for (e in x) {
      if (inherits(e, "incidence_fit")) {
        out <- add_incidence_fit(out, e, col_pal)
      }
    }
    return(out)
  }
  df <- get_info(x, "pred")

  out <- suppressMessages(
    p + ggplot2::geom_line(
      data = df,
      ggplot2::aes_string(x = "dates", y = "fit"), linetype = 1) +
      ggplot2::geom_line(
        data = df,
        ggplot2::aes_string(x = "dates", y = "lwr"), linetype = 2) +
      ggplot2::geom_line(
        data = df,
        ggplot2::aes_string(x = "dates", y = "upr"), linetype = 2)
  )


  if ("groups" %in% names(df)) {
    n.groups <- length(levels(df$groups))
    out <- out + ggplot2::aes_string(color = "groups") +
      ggplot2::scale_color_manual(values = col_pal(n.groups))
  }

  out
}





#' @export
#' @rdname plot.incidence

plot.incidence_fit <- function(x, ...){
  base <- ggplot2::ggplot()
  out <- add_incidence_fit(base, x, ...) +
    ggplot2::labs(x = "", y = "Predicted incidence")
  out
}

#' @export
#' @rdname plot.incidence

plot.incidence_fit_list <- function(x, ...){
  base <- ggplot2::ggplot()
  fits <- get_fit(x)
  out <- add_incidence_fit(base, fits, ...) +
    ggplot2::labs(x = "", y = "Predicted incidence")
  out
}

