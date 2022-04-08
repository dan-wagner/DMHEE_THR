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
calc_RevisionRisk <- function(Survival, 
                              Age0 = 60, 
                              nCycles = 60) {
  # Survival model fitted to capture intervention (STD vs NP1) and time-to-event. 
  #   Event: Prosthesis Failure. 
  #   Coefficients are on the log-scale, so hazard rate can be obtained by 
  #   exponentiating the coefficients. 
  Survival <- cbind(coef = Survival[,"coef"], 
                    HR = exp(Survival[,"coef"]))
  # Estimate Baseline Hazard: 
  ## calculate lambda and gamma from Weibull distribution. 
  ##    - lambda: The log of the lambda parameter is a linear sum of the 
  ##      coefficients multiplied by the explanatory variables in the model. 
  Lambda <- sapply(X = list(Male = 1, 
                            Female = 0), 
                   FUN = \(x){
                     c(cons = 1, Age = Age0, male = x) * 
                       Survival[c("cons", "age", "male"), "coef"]
                   })
  Lambda <- colSums(x = Lambda, na.rm = FALSE, dims = 1)
  Lambda <- exp(Lambda)
  
  ##    - gamma: exponentiate the ln.gamma coefficient in the survival model. 
  GMMA <- Survival["ln.gamma","HR"]
  
  # Estimate the Relative Risk of Revision for each Prosthesis Type
  jNames <- grep(pattern = "NP", x = rownames(Survival), value = TRUE)
  rr <- c(1, Survival[jNames, "HR"])
  names(rr) <- c("STD", jNames)
  
  ## Estimate time-dependency
  Cycle <- 1:nCycles
  
  RevisionRisk <- 
  sapply(X = Lambda, 
         FUN = \(sex){
           sapply(X = rr, 
                  FUN = \(j){
                    1- exp(sex * j * (((Cycle-1)^GMMA) - (Cycle^GMMA)))
                   }, 
                  simplify = TRUE
                   )
         }, 
         simplify = "array"
         )
  
  names(dimnames(RevisionRisk)) <- c("Cycle", "j", "Gender")
  
  # Return Output
  return(RevisionRisk)
}

# Modify Parameter List: Insert Time-Dependencies ==============================
calc_TimeDeps <- function(ParamList, 
                          Age0 = 60, 
                          nCycles = 60) {
  # Mortality Risk for Age and Gender
  ParamList$MR <- calc_MR(LT = ParamList$LifeTables, 
                          Age0 = Age0, 
                          nCycles = nCycles)
  
  # Revision Risk stratified by Age and Gender
  ParamList$RevisionRisk <- 
    calc_RevisionRisk(Survival = ParamList$Survival$Survival, 
                      Age0 = Age0, 
                      nCycles = nCycles)
  
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
