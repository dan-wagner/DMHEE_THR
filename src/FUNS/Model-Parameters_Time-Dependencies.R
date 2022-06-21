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



# Calc_RevisionRisk() ==========================================================
# Survival model fitted to capture intervention (STD vs NP1) and time-to-event. 
#   Event: Prosthesis Failure. 
#   Coefficients are on the log-scale, so hazard rate can be obtained by 
#   exponentiating the coefficients. 

scale_Weibull <- function(coefs, Age, Male, j) {
  j.NP <- grep(pattern = "NP", x = names(coefs), value = TRUE)
  j.coefs <- matrix(data = c(0, 0, 1, 0, 0, 1), 
                    nrow = 3, 
                    ncol = 2, 
                    byrow = TRUE, 
                    dimnames = list(j = c("STD", "NP1", "NP2"), 
                                    coef = c("NP1", "NP2")))
  
  if ("NP2" %in% j.NP) {
    lambda <- 
      coefs[["cons"]] + 
      coefs[["age"]]*Age + 
      coefs[["male"]]*Male + 
      coefs[["NP1"]]*j.coefs[j,"NP1"] + 
      coefs[["NP2"]]*j.coefs[j,"NP2"]
  } else {
    lambda <- 
      coefs[["cons"]] + 
      coefs[["age"]]*Age + 
      coefs[["male"]]*Male + 
      coefs[["NP1"]]*j.coefs[j,"NP1"]
  }
  lambda <- exp(lambda)
  
  return(lambda)
}

calc_RevRisk <- function(Survival, 
                         j, 
                         Age0 = 60,
                         Male = 0, 
                         nCycles = 60) {
  # Estimate Parameters from Weibull Distribution ==============================
  ## Scale (lambda) ------------------------------------------------------------
  scale <- scale_Weibull(coefs = Survival, 
                         Age = Age0, 
                         Male = Male, 
                         j = j)
  ## Shape 
  shape <- exp(Survival[["ln.gamma"]])
  
  ## Estimate Revision Risk
  t <- 1:nCycles
  
  rr <- scale*(((t-1)^shape) - t^shape)
  rr <- 1-exp(rr)
  
  return(rr)
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
  Gender <- list(Male = 1, Female = 0)
  j.ID <- c("STD", 
            grep(pattern = "NP", 
                 x = names(ParamList$Survival), 
                 value = TRUE))
  names(j.ID) <- j.ID
  
  ParamList$RevisionRisk <- 
    sapply(X = Gender, 
           FUN = \(sex){
             sapply(X = j.ID, 
                     FUN = calc_RevRisk, 
                     Survival = ParamList$Survival, 
                     Age0 = Age0, 
                     nCycles = nCycles, 
                     Male = sex)
           }, 
           simplify = "array")
  names(dimnames(ParamList$RevisionRisk)) <- c("Cycle", "j", "Gender")
  
  # Arrange List, drop un-necessary list-elements: LifeTables
  ParamList <- ParamList[c("OMR", 
                           "RRR", 
                           "MR", 
                           "RevisionRisk", 
                           "Cost_j", 
                           "Cost_States", 
                           "Utilities")]
  
  
  return(ParamList)
}
