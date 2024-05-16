source(file = file.path("src", "FUNS", "Model-Parameters.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Time-Dependencies.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Draws.R"))
source(file = file.path("src", "FUNS", "THR-Model.R"))

fit_weibull <- readr::read_rds(file = file.path("data", 
                                                "data-raw", 
                                                "THR-Survival.rds"))

fit_draw <- fit_weibull$Survival[, "coef"]
fit_draw[["ln.gamma"]] <- exp(fit_draw[["ln.gamma"]])
names(fit_draw)[c(1,2)] <- c("shape", "scale")

predicted_survival <- function(coefs, dist, log_scale = TRUE, ...) {
  # Generate Predicted Survival Probabilities
  #
  # Args: 
  #   coefs: A named vector of the coefficients for the parametric survival
  #          function. 
  #   dist: A character vector of length 1. Declares the distribution of 
  #         interest to generate the predicted values.
  #   log_scale: Logical (Default = `TRUE`). Determines whether the shape and
  #         scale parameter are on the log scale. 
  #   ... : Additional coefficients to the fitted model which should be compared.
  surv_fn <- switch(dist, 
                    "exponential" = stats::pexp,
                    "weibull (AFT)" = stats::pweibull,
                    "weibull (PH)" = flexsurv::pweibullPH,
                    "gen_gamma" = flexsurv::pgengamma,
                    "log_logistic" = flexsurv::pllogis,
                    "log_normal" = stats::plnorm,
                    "gompertz" = flexsurv::pgompertz,
                    "gamma" = stats::pgamma)
  fit_params <- switch(dist, 
                       "exponential" = names(formals(pexp)),
                       "weibull (AFT)" = names(formals(pweibull)),
                       "weibull (PH)" = names(formals(flexsurv::pweibullPH)),
                       "gen_gamma" = names(formals(flexsurv::pgengamma)),
                       "log_logistic" = names(formals(flexsurv::pllogis)),
                       "log_normal" = names(formals(plnorm)),
                       "gompertz" = names(formals(flexsurv::pgompertz)),
                       "gamma" = names(formals(pgamma)))
  fit_params <- grep(pattern = c("q|lower.tail|log.p"),
                     x = fit_params, 
                     value = TRUE,
                     invert = TRUE)
  # Test if there are additional parameters to consider from the regression
  more_params <- length(fit_params) < length(coefs)
  if (isTRUE(more_params)) {
    # TODO: Add logic to consider the value of additional parameters
    # There are an unknown number of parameters that could be added. 
    message("Setting scale parameter for the supplied configuration")
    coef_levels <- list(...)
    coef_levels <- c(scale = 1, coef_levels)
    shape_id <- which(names(coefs) == "shape")
    scale_coefs <- mapply(FUN = `*`, coef_levels, coefs[-shape_id])
    scale_coefs <- sum(scale_coefs)
    coefs <- c(coefs[shape_id], scale = scale_coefs)
  }
  
  if (isTRUE(log_scale)) {
    coefs <- exp(coefs)
  }
  
  return(coefs)
}

predicted_survival(coefs = fit_draw, dist = "weibull (PH)", age = 60, male = 1, NP1 = 0)

weibull_params(coefs = fit_weibull$Survival[, "coef"], age = 60, male = 1)