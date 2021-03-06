% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/incidence.R, R/print.R
\name{incidence}
\alias{incidence}
\alias{incidence.default}
\alias{incidence.Date}
\alias{incidence.integer}
\alias{incidence.numeric}
\alias{incidence.POSIXt}
\alias{print.incidence}
\title{Compute incidence of events from a vector of dates.}
\usage{
incidence(dates, interval = 1L, ...)

\method{incidence}{default}(dates, interval = 1L, ...)

\method{incidence}{Date}(dates, interval = 1L, standard = TRUE,
  groups = NULL, na_as_group = TRUE, first_date = NULL,
  last_date = NULL, ...)

\method{incidence}{integer}(dates, interval = 1L, groups = NULL,
  na_as_group = TRUE, first_date = NULL, last_date = NULL, ...)

\method{incidence}{numeric}(dates, interval = 1L, groups = NULL,
  na_as_group = TRUE, first_date = NULL, last_date = NULL, ...)

\method{incidence}{POSIXt}(dates, interval = 1L, standard = TRUE,
  groups = NULL, na_as_group = TRUE, first_date = NULL,
  last_date = NULL, ...)

\method{print}{incidence}(x, ...)
}
\arguments{
\item{dates}{A vector of dates, which can be provided as objects of the
class: integer, numeric, Date, POSIXct. Note that decimal numbers will be
floored with a warning.}

\item{interval}{An integer or character indicating the (fixed) size of the time interval
used for computing the incidence; defaults to 1 day. This can also be a text string that corresponds to a valid date
interval: day, week, month, quarter, or year. See Note.}

\item{...}{Additional arguments passed to other methods (none are used).}

\item{standard}{(Only applicable to Date objects) When \code{TRUE} (default) and the
\code{interval} one of "week", "month", "quarter", or "year", then this will
cause the bins for the counts to start at the beginning of the interval
(See Note). This is overridden by defining a non-NULL \code{first_date}.}

\item{groups}{An optional factor defining groups of observations for which
incidence should be computed separately.}

\item{na_as_group}{A logical value indicating if missing group (NA) should be
treated as a separate group.}

\item{first_date, last_date}{optional first/last dates to be used in the
epicurve. When these are \code{NULL} (default), the dates from the first/last
dates are taken from the observations. If these dates are provided, the
observations will be trimmed to the range of [first_date, last_date].}

\item{x}{An 'incidence' object.}
}
\value{
An list with the class \code{incidence}, which contains the
following items:
\itemize{
\item \strong{dates}: The dates marking the left side of the bins used for counting
events. When ISO week-based weekly incidence is computed, the dates are the
first days of corresponding isoweeks.
\item \strong{counts}: A matrix of incidence counts, which one column per group (and
a single column if no groups were used).
\item \strong{timespan}: The length of the period for which incidence is computed, in
days.
\item \strong{interval}: The bin size, in number of days; e.g. 7 indicates weekly
incidence.
\item \strong{n}: The total number of cases.
\item \strong{isoweeks}: ISO 8601 week format yyyy-Www, which is returned only when
ISO week-based weekly incidence is computed.
}
}
\description{
This function computes incidence based on dates of events provided in
various formats. A fixed interval, provided as numbers of days, is used to
define time intervals. Counts within an interval always include the first
date, after which they are labeled, and exclude the second. For instance,
intervals labeled as 0, 3, 6, ... mean that the first bin includes days 0, 1
and 2, the second interval includes 3, 4 and 5 etc.
}
\details{
For details about the \code{incidence class}, see the dedicated
vignette:\cr \code{vignette("incidence_class", package = "incidence")}
}
\note{
If \code{interval} is a valid character (e.g. "week" or "month"), then
the bin will start at the beginning of the interval just before the first
observation by default. For example, if the first case was recorded on
Wednesday, 2018-05-09:
\itemize{
\item "week"    : first day of the ISOweek (i.e. Monday, 2018-05-07)
\item "month"   : first day of the month (i.e. 2018-05-01)
\item "quarter" : first day of the quarter (i.e. 2018-04-01)
\item "year"    : first day of the calendar year (i.e. 2018-01-01)
}

These default intervals can be overridden in two ways:
\enumerate{
\item Specify \code{standard = FALSE}, which sets the interval to begin at the first
observed case.
\item Specify a date in the \code{first_date} field.
}

The intervals for "month", "quarter", and "year" will necessarily vary in the
number of days they encompass and warnings will be generated when the first
date falls outside of a calendar date that is easily represented across the
interval.
}
\examples{
## toy example
incidence(c(1, 5, 8, 3, 7, 2, 4, 6, 9, 2))
incidence(c(1, 5, 8, 3, 7, 2, 4, 6, 9, 2), 2)

## example using simulated dataset
if(require(outbreaks)) { withAutoprint({
  onset <- ebola_sim$linelist$date_of_onset

  ## daily incidence
  inc <- incidence(onset)
  inc
  plot(inc)

  ## weekly incidence
  inc.week <- incidence(onset, interval = 7, standard = FALSE)
  inc.week
  plot(inc.week)
  plot(inc.week, border = "white") # with visible border
  inc.isoweek <- incidence(onset, interval = 7, standard = TRUE)
  inc.isoweek
  ## use group information
  sex <- ebola_sim$linelist$gender
  inc.week.gender <- incidence(onset, interval = 7,
                               groups = sex, standard = FALSE)
  inc.week.gender
  head(inc.week.gender$counts)
  plot(inc.week.gender)
  inc.isoweek.gender <- incidence(onset, interval = 7,
                                  groups = sex, standard = TRUE)
  inc.isoweek.gender
})}


}
\seealso{
The main other functions of the package include:
\itemize{
\item \code{\link[incidence:plot.incidence]{incidence::plot.incidence()}}: Plot epicurves from an incidence object.
\item \code{\link[incidence:fit]{incidence::fit()}}: Fit log-linear model to computed incidence.
\item \code{\link[incidence:fit_optim_split]{incidence::fit_optim_split()}}: Find the optimal peak of the epidemic
and fits log-linear models on either side of the peak.
\item \code{\link[incidence:subset]{incidence::subset()}}: Handling of \code{incidence}
objects.
\item \code{\link[incidence:pool]{incidence::pool()}}: Sum incidence over groups.
\item \code{\link[incidence:as.data.frame.incidence]{incidence::as.data.frame.incidence()}}: Convert an \code{incidence} object to a
\code{data.frame}.
}

The following vignettes are also available:
\itemize{
\item \code{overview}: Provides an overview of the package's features.
\item \code{customize_plot}: Provides some tips on finer plot customization.
\item \code{incidence_class}: Details the content of the \code{incidence}
class.
}
}
\author{
Thibaut Jombart, Rich Fitzjohn, Zhian Kamvar
}
