# Functions responsible for preparing, generating, or drawing the simulation
# parameter. 
#   get_params
#   draw_params
#   mom_params

getParams <- function(FileName = "params.rds", include_NP2 = FALSE) {
  # Get Model Parameters
  #
  # Args:
  #   FileName: Character (Default = "params.rds"). The name to give the 
  #     parameter file.
  #   include_NP2: Logical (Default = FALSE). Switch to control whether model
  #     considers 2 (Default) or 3 alternatives. 
  #
  # Returns:
  #   A list with 6 named elements. 
  #     LifeTables: 
  #       A matrix with Age and Gender specified mortality risks from the UK. 
  #     PostOp:
  #       A matrix summarizing post-operative outcomes relevant to the model. 
  #       OMR = Operative Mortality Rate (deaths following surgery); RRR = 
  #       Re-Revision Risk (patients with need for a revision surgery within 1
  #       year of prior surgery). 
  #     Survival (Revision Risk):
  #       A list with two elements: 
  #         Survival: A matrix of the fitted regression coefficients from a 
  #         parametric survival model following a weibull distribution. 
  #         CovMat: The covariance matrix of the fitted regression coefficients.
  #     Utilities:
  #       A matrix of the state specific utility values. 
  #     Costs_States:
  #       A matrix summarizing the annual costs within each health state. 
  #     Prices:
  #       A named vector of the unit prices for each prosthesis. 
  
  # Set Path to output file
  param_path <- file.path("data", "data-gen", "Model-Params", FileName)
  # Check if File Exists
  params_exist <- file.exists(param_path)
  
  if (isFALSE(params_exist)) {
    usethis::ui_info(x = "Model Parameters have not been generated!")
    # Check if sub-directory exists
    param_dir <- 
      sub(pattern = "[\\/]params.rds", replacement = "", x = param_path)
    dir_present <- dir.exists(paths = param_dir)
    
    if (isFALSE(dir_present)) {
      usethis::ui_oops(x = "Missing directory: {usethis::ui_path(param_dir)}")
      dir.create(path = param_dir)
      usethis::ui_done(x = "Created directory: {usethis::ui_path(param_dir)}")
    }
    # Import the data in data-raw
    usethis::ui_info("Generating parameters from raw data!")
    params <- list.files(path = file.path("data", "data-raw"),
                         pattern = ".rds",
                         full.names = TRUE)
    names(params) <- sub(pattern = "data/data-raw/",
                         replacement = "",
                         x = params)
    names(params) <- sub(pattern = ".rds",
                         replacement = "", 
                         x = names(params))
    names(params) <- sub(pattern = "(THR-)|(THR_)|(THR)",
                         replacement = "",
                         x = names(params))
    names(params) <- sub(pattern = "-",
                         replacement = "",
                         x = names(params))
    # Import Data
    params <- lapply(X = params, FUN = readr::read_rds)
    # Add Prices
    params$Prices <- c(STD = 394, NP1 = 579, NP2 = 788)
    # Write data to param_path
    readr::write_rds(x = params, file = param_path)
    usethis::ui_done("Parameter list saved to {usethis::ui_path(param_path)}")
  } else {
    params <- readr::read_rds(file = param_path)
    usethis::ui_info("Loaded parameters from: {usethis::ui_path(param_path)}")
  }
  
  # Subset Comparators =======================================================
  if(isTRUE(include_NP2)) {
    # Select Correct Survival Data
    params <- params[names(params) != "Survival"]
    names(params) <- 
      sub(pattern = "Survival_NP2", replacement = "Survival", x = names(params))
    
  } else {
    # Select Correct Survival Data
    params <- params[names(params) != "Survival_NP2"]
    # Subset Prices
    params$Prices <- params$Prices[-3]
  }
  
  return(params)
}

mom_params <- function(Mean, SE, dist){
  # Generate Distribution Parameters Using Method-of-Moments Approach
  #
  # Args:
  #   Mean: Numeric. The mean value for the data of interest. 
  #   SE: Numeric. The standard error for the data of interest. 
  #   dist: Character. The name of the distribution to calculate parameters
  #       for. Expects one of: `"beta"` or `"gamma"`.
  # 
  # Returns:
  #   A list with two elements. 
  #   If dist = "beta", element names will be: shape1, shape2
  #   If dist = "gamma", element names will be: shape, rate. 
  
  # Verify dist argument
  dist <- 
    match.arg(arg = dist, choices = c("beta", "gamma"), several.ok = FALSE)
  
  # Calculate Parameters
  mom <- switch(dist,
                "beta" = list(shape1 = NULL, shape2 = NULL),
                "gamma" = list(shape = NULL, rate = NULL))
  #   Element names should match the parameters of the distributions in R. 
  if (dist == "beta") {
    mom$shape1 <- Mean * ((Mean * (1 - Mean)) / (SE^2) - 1)
    mom$shape2 <- mom$shape1 * (1 - Mean) / Mean
    
    mom$shape1 <- ifelse(is.nan(mom$shape1), 0, mom$shape1)
    mom$shape2 <- ifelse(is.nan(mom$shape2), 1, mom$shape2)
  } else if (dist == "gamma") {
    mom$shape <- (Mean^2) / (SE^2)
    mom$rate <- (SE^2) / Mean
    
    mom$shape <- ifelse(is.nan(mom$shape), 0, mom$shape)
    mom$rate <- ifelse(is.nan(mom$rate), 1, mom$rate)
  }
  
  return(mom)
}

draw_params <- function(params, prob = FALSE) {
  # Draw Values for Simulation
  #
  # Args:
  #   params: A list of parameter values required by the simulation.
  #   prob: Logical (Default = `FALSE`). Controls whether the parameter values
  #         represent the mean (`FALSE`) or a random value from an assigned
  #         distribution. 
  #
  # Details:
  #   Two parameters are assumed to have no uncertainty: LifeTables and Prices. 
  #
  # Returns:
  #   A list of the sampled parameter values, comprised of 7 elements:
  #     Costs_States: Sampled health state costs. 
  #     LifeTables: Age and gender specific general population mortality risks.
  #     OMR: The operative mortality rate. 
  #     Prices: Unit prices for the comparators to be considered in the model.
  #     RRR: The re-revision risk (second or greater revision procedure).
  #     Survival: Sampled parameters for the parametric survival function of 
  #       which will predict the revision risk. 
  #     Utilities: Health State Utility values. 
  
  # Post-Operative Outcomes ===================================
  #   Operative Mortality Rate (OMR) & Re-Revision Risk (RRR)
  # Distribution: Beta
  if (isTRUE(prob)) {
    params$PostOp <- 
      mapply(FUN = rbeta, 
             shape1 = params$PostOp[, "events"],
             shape2 = params$PostOp[, "N"] - params$PostOp[, "events"],
             MoreArgs = list(n = 1),
             SIMPLIFY = TRUE)
  } else {
    params$PostOp <- params$PostOp[, "events"]/params$PostOp[, "N"]
  }
  params <- c(params, as.list(params$PostOp))
  params <- params[names(params) != "PostOp"]
  
  # Revision Risk (Survival) ===================================
  # Distribution: Multivariate Normal
  # Notes:
  #   - Instead of using cholesky decomposition method like in Excel, we can
  #     use the function for the required distribution from the MASS package.
  #     This will be a faster implementation. 
  if (isTRUE(prob)) {
    # Check Alternatives (informs tolerance levels)
    #   Lowest tolerance I could find for 2 or 3 alternatives.
    tol_lvl <- c(j2 = 0.013, j3 = 0.0068)
    # Use index positioning to determine which value of tol_lvl to use in
    # MASS::mvrnorm().
    tol_id <- length(grep(pattern = "NP",
                          x = rownames(params$Survival$Survival),
                          value = TRUE))
    # Draw values
    params$Survival <- 
      MASS::mvrnorm(n = 1,
                    mu = params$Survival$Survival[, "coef"],
                    Sigma = params$Survival$CovMat,
                    tol = tol_lvl[tol_id])
  } else {
    params$Survival <- params$Survival$Survival[, "coef"]
  }
  
  # Costs: Markov States =====================================
  # Distribution: GAMMA
  if (isTRUE(prob)) {
    # Method of moments to Prepare Distribution Parameters
    mom_costs <- mom_params(Mean = params$Costs_States[, "Mean"],
                            SE = params$Costs_States[, "SE"],
                            dist = "gamma")
    # Perform Random Draw
    
    params$Costs_States <- 
      mapply(FUN = rgamma,
             shape = mom_costs$shape,
             rate = mom_costs$rate,
             MoreArgs = list(n = 1),
             SIMPLIFY = TRUE)
    
  } else {
    params$Costs_States <- params$Costs_States[, "Mean"]
  }
  
  # Utilities: Markov States ================================
  # Distribution: Beta
  if (isTRUE(prob)) {
    # Method of Moments to Prepare Distribution Parameters
    util_mom <- mom_params(Mean = params$Utilities[, "Mean"],
                           SE = params$Utilities[, "SD"],
                           dist = "beta")
    # Perform Random Draw
    params$Utilities <- 
      mapply(FUN = rbeta,
             shape1 = util_mom$shape1,
             shape2 = util_mom$shape2,
             MoreArgs = list(n = 1),
             SIMPLIFY = TRUE)
  } else {
    params$Utilities <- params$Utilities[, "Mean"]
  }
  
  
  return(params)
}