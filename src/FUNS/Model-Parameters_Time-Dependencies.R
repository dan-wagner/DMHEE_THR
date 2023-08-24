# Life Table Transitions for background mortality ==============================
calc_MR <- function(LT, Age0 = 60, nCycles = 60) {
  # LT represents the death rates by age and sex per 1,000 population. 
  # Divide values in LT by 1000 to get yearly transition probabilities. 
  LT <- LT/1000
  # Modify row names of LT to be lower-bound of specified age range. 
  dimnames(LT)$Age <- sub(pattern = "\\+|-\\d{2}", 
                          replacement = "", x = dimnames(LT)$Age)
  # Build Age-Specific Mortality Probabilities for each gender
  ## Identify row to subset for each age range. 
  ageIndex <- findInterval(x = Age0 + 1:nCycles, 
                           vec = as.numeric(dimnames(LT)$Age))
  ## Subset LT using AgeIndex. Vector recycling will return matrix with 60 rows
  MR <- LT[ageIndex, ]
  names(dimnames(MR))[1] <- "Cycle" # Modify attributes to match req's for model. 
  dimnames(MR)$Cycle <- 1:nCycles
  
  # return output. 
  return(MR)
}

# Calculate Revision Risk ======================================================
#   A parametric survival model was fitted to a weibull distribution under a 
#   proportional hazards assumption. 
#   - Goal of functions below are to extrapolate the survival function over the 
#     necessary time horizon and then calculate the corresponding survival 
#     probability.

## scale_weibull ---------------------------------------------------------------
##  Estimate the scale parameter for the weibull distribution
scale_weibull <- function(coefs, age = 60, male = 1) {
  # detect presence of NP2 option
  np2_present <- "NP2" %in% names(coefs)
  # assign names to different alternatives for j
  j <- grep(pattern = "NP", x = names(coefs), value = TRUE)
  j <- c(sort(x = j, decreasing = TRUE), "STD")
  # set coefficient levels
  if (isTRUE(np2_present)) {
    coef_levels <- expand.grid(cons = 1, 
                               age = age, 
                               male = male, 
                               NP1 = c(1,0), 
                               NP2 = c(1,0))
    coef_levels <- subset(x = coef_levels, NP1 != 1 | NP2 != 1)
  } else {
    coef_levels <- expand.grid(cons = 1, age = age, male = male, NP1 = c(1,0))
  }
  coef_levels <- as.matrix(coef_levels)
  rownames(coef_levels) <- j
  # Calculate the scale parameter for each j
  wbl_scale <- apply(X = coef_levels, 
                     MARGIN = 1, 
                     FUN = `*`, 
                     coefs)
  wbl_scale <- colSums(x = wbl_scale, na.rm = TRUE, dims = 1)
  wbl_scale <- exp(wbl_scale)
  
  return(wbl_scale)
}
## weibull_params -------------------------------------------------------------- 
##  generate shape/scale parameters from regression coefficients
weibull_params <- function(coefs, age, male) {
  pos_shape <- which("ln.gamma" %in% names(coefs))
  # shape ----------------------------------------
  wph_shape <- exp(coefs[[pos_shape]])
  # scale ----------------------------------------
  wph_scale <- scale_weibull(coefs = coefs[-pos_shape], 
                             age = age, 
                             male = male)
  # Assemble list
  params <- list(shape = wph_shape, scale = wph_scale)
  
  return(params)
}

## extrapolate_survival --------------------------------------------------------
##  Uses the estimated parameters for the weibull distribution to estimate the
##  cdf over the model time horizon. Once complete, P(survival) is estimated and 
##  returned.

extrapolate_survival <- function(coefs, 
                                 age, 
                                 male, 
                                 n_cycles) {
  # set parameters for survival distribution
  surv_params <- weibull_params(coefs = coefs, age = age, male = male)
  # Extrapolate CDF over model time horizon ------------------------------------
  ## For each treatment at the end and beginning of each cycle
  cycle_time <- seq_len(length.out = n_cycles)
  
  CDF <- sapply(X = list(end = cycle_time, start = cycle_time-1), 
                FUN = \(TH){
                  mapply(FUN = flexsurv::pweibullPH, 
                         scale = surv_params$scale, 
                         MoreArgs = list(q = TH, 
                                         shape = surv_params$shape))
                }, 
                simplify = "array")
  # Survival Function is the complement to CDF
  p_survival <- 1-CDF
  # Calculate Ratio: tells those survived at end who were also alive at start
  p_survival <- p_survival[,,"end"]/p_survival[,,"start"]
  p_survival <- ifelse(is.nan(p_survival), 0, p_survival)
  # return result
  return(p_survival)
}

# Modify Parameter List: Insert Time-Dependencies ==============================
calc_TimeDeps <- function(ParamList, 
                          Age0 = 60, 
                          nCycles = 60) {
  # Mortality Risk for Age and Gender
  ParamList$MR <- calc_MR(LT = ParamList$LifeTables, 
                          Age0 = Age0, 
                          nCycles = nCycles)
  
  # Revision Risk stratified by j, Age and Gender
  ParamList$RevisionRisk <- 
    sapply(X = list(Male = 1, Female = 0), 
           FUN = extrapolate_survival, 
           coefs = ParamList$Survival, 
           age = Age0, 
           n_cycles = nCycles, 
           simplify = "array")
  ParamList$RevisionRisk <- 1 - ParamList$RevisionRisk
  
  names(dimnames(ParamList$RevisionRisk)) <- c("Cycle", "j", "Gender")
  
  # Arrange List, drop un-necessary list-elements: LifeTables, Survival
  ParamList <- ParamList[c("OMR", 
                           "RRR", 
                           "MR", 
                           "RevisionRisk", 
                           "Cost_j", 
                           "Cost_States", 
                           "Utilities")]
  
  
  return(ParamList)
}
