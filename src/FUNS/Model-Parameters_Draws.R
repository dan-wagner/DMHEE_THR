# FUNCTIONS TO DRAW UNCERTAIN MODEL PARAMETERS
# Method-of-Moments (Beta Distribution) ########################################
MoM_beta <- function(Mean, SE){
  AplusB <- (Mean*(1 - Mean)/(SE^2))-1
  Alpha <- Mean*AplusB
  
  Beta <- Alpha * (1-Mean)/Mean
  
  result <- c(alpha = Alpha, beta = Beta)
  return(result)
}

# Draw Uncertain Parameters ####################################################
DrawParams <- function(ParamList, prob = 0) {
  # Note: Life Tables are not considered to be uncertain parameters. 
  
  # OMR: Operative Mortality Rate ------------------------------------------
  ## Distribution: Beta
  ## From Textbook: 
  ##   The hospital records of a sample of 100 patients receiving a primary 
  ##   THR were examined retrospectively. Of these patients, two died either 
  ##   during or immediately following the procedure. The operative mortality 
  ##   for the procedure is estimated to be 2%. 
  if (prob == 1) {
    ParamList$OMR <- 
      mapply(FUN = rbeta, 
             shape1 = ParamList$OMR*100, 
             shape2 = 100-(ParamList$OMR*100), 
             MoreArgs = list(n = 1))
  }
  
  # RRR: Re-Revision Risk --------------------------------------------------
  ## Distribution: Beta
  ## From Textbook: 
  ##  The hospital records of a sample of 100 patients having experienced a 
  ##  revision procedure to replace a failed primary THR were reviewed at 
  ##  one year. During this time, four patients had undergone a further 
  ##  revision procedure. 
  if (prob == 1) {
    ParamList$RRR <- rbeta(n = 1, 
                           shape1 = ParamList$RRR*100, 
                           shape2 = 100-(ParamList$RRR*100))
  }
  
  # Survival: To Estimate Revision Risk ------------------------------------
  ## Distribution: Multivariate Normal. 
  ## Notes: 
  ##  - Instead of using cholesky decomposition method like in Excel, we can 
  ##    use the function for the required distribution from the MASS package. 
  ##  - This will be a faster implementation.
  if (prob == 1) {
    # Check Alternatives (informs tolerance levels)
    ## Lowest tolerance I could find for 2 or 3 alternatives.  
    tol.levels <- c(j_2 = 0.013, j_3 = 0.0068)
    ## Use index position to determine which value of tol.levels to supply as 
    ## tolerance value to MASS::mvrnorm(). 
    tol.index <- length(grep(pattern = "NP", 
                      x = rownames(ParamList$Survival$Survival), 
                      value = TRUE))
    
    ParamList$Survival <- 
      MASS::mvrnorm(n = 1, 
                    mu = ParamList$Survival$Survival[,"coef"], 
                    Sigma = ParamList$Survival$CovMat, 
                    tol = tol.levels[tol.index]) # Lowest tolerance I could find.
  } else {
    ParamList$Survival <- ParamList$Survival$Survival[,"coef"]
  }
  
  
  
  # Cost_j: Prothesis Costs ------------------------------------------------
  # Cost_States: Markov State Costs ----------------------------------------
  ## Distribution: GAMMA
  if (prob == 1) {
    costsAlpha <- (ParamList$Cost_States[,"Mean"]/ParamList$Cost_States[,"SE"])^2
    costsBeta <- (ParamList$Cost_States[,"SE"]^2)/ParamList$Cost_States[,"Mean"]
    
    ParamList$Cost_States <- 
      mapply(FUN = rgamma, 
             shape = costsAlpha, 
             scale = costsBeta, 
             MoreArgs = list(n = 1))
    
  } else {
    ParamList$Cost_States <- ParamList$Cost_States[,"Mean"]
  }
  
  
  # Utilities: Markov State Utilities --------------------------------------
  ## Distribution: Beta
  if (prob == 1) {
    PRI_THR <- ParamList$Utilities[1,"Mean"]
    uMoM <- mapply(FUN = MoM_beta, 
                   Mean = ParamList$Utilities[-1,"Mean"], 
                   SE = ParamList$Utilities[-1,"SD"])
    
    ParamList$Utilities <- 
      mapply(FUN = rbeta, 
             shape1 = uMoM["alpha",], 
             shape2 = uMoM["beta",], 
             MoreArgs = list(n = 1))
    
    ParamList$Utilities <- c(PRI_THR = PRI_THR, ParamList$Utilities)
    
  } else {
    ParamList$Utilities <- ParamList$Utilities[,"Mean"]
  }
  
  return(ParamList)
}