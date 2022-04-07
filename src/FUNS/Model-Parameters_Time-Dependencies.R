# Life Table Transitions for background mortality ==============================
calc_MR <- function(LT, Age0 = 60, nCycles = 60) {
  # LT represents the death rates by age and sex per 1,000 population. 
  # Divide values in LT by 1000 to get yearly transition probabilities. 
  LT <- LT/100
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

# Modify Parameter List: Insert Time-Dependencies
calc_TimeDeps <- function(ParamList, 
                          Age0 = 60, 
                          nCycles = 60) {
  # Mortality Risk for Age and Gender
  ParamList$MR <- calc_MR(LT = ParamList$LifeTables, 
                          Age0 = Age0, 
                          nCycles = nCycles)
  
  # Arrange List, drop un-necessary list-elements: LifeTables
  ParamList <- ParamList[c("OMR", "RRR", "MR", "Survival")]
  
  
  return(ParamList)
}
