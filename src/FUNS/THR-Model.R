# 1) Define Transition Matrix (Q) ##############################################
define_tmat <- function(ParamList, 
                        j, 
                        nCycles = 60, 
                        Gender) {
  # Build Blank Transition Matrix (Q) 
  Mstates <- c("PRI_THR", "PRI_Success", 
               "REV_THR", "REV_Success", "Death")
  
  Q <- array(data = 0, 
             dim = c(length(Mstates), length(Mstates), length(1:nCycles)), 
             dimnames = list(Start = Mstates, End = Mstates, Cycle = NULL))
  
  # Apply Transition Probabilities =============================================
  ## Start: Primary THR (PRI_THR)
  Q["PRI_THR", "PRI_Success", ] <- 1 - ParamList$OMR[["PRI"]]
  Q["PRI_THR", "Death", ] <- ParamList$OMR[["PRI"]]
  
  ## Start: Primary Success (PRI_Success)
  Q["PRI_Success", "Death", ] <- ParamList$MR[, Gender]
  Q["PRI_Success", "REV_THR", ] <- ParamList$RevisionRisk[,j,Gender]
  Q["PRI_Success", "PRI_Success", ] <- 
    1 - colSums(x = Q["PRI_Success", , ], na.rm = FALSE, dims = 1)
  
  ## Start: Revision THR (REV_THR)
  Q["REV_THR", "Death", ] <- ParamList$OMR[["REV"]] + ParamList$MR[, Gender]
  Q["REV_THR", "REV_Success", ] <- 
    1 - (ParamList$OMR[["REV"]] + ParamList$MR[,Gender])
  
  ## Start: Revision Success (REV_Success)
  Q["REV_Success", "REV_THR", ] <- ParamList$RRR
  Q["REV_Success", "Death", ] <- ParamList$MR[,Gender]
  Q["REV_Success", "REV_Success", ] <- 
    1 - colSums(x = Q["REV_Success", , ], na.rm = FALSE, dims = 1)
  
  ## Death is Absorbing State
  Q["Death", "Death", ] <- 1
  
  return(Q)
}

# 2) Track Cohort (trace) ######################################################
track_cohort <- function(Q, 
                         nCycles = 60, 
                         nStart = 1000) {
  # Construct Blank Cohort Trace 
  trace <- array(data = 0, 
                 dim = c(length(1:nCycles), length(colnames(Q))), 
                 dimnames = list(Cycle = NULL, 
                                 State = colnames(Q)))
  # Populate Cohort Trace
  for (i in seq_along(1:nCycles)) {
    if (i == 1) {
      Cohort0 <- c(nStart, rep(0, 4))
      names(Cohort0) <- colnames(Q)
      
      trace[i, ] <- Cohort0 %*% Q[,,i]
    } else {
      trace[i, ] <- trace[i-1, ] %*% Q[,,i]
    }
  }
  
  return(trace)
}

# Estimate Costs (Costs) #######################################################
cost_cohort <- function(trace, 
                        Cost_j, 
                        Cost_States, 
                        cDR = 0.06,
                        nStart = 1000) {
  # Cost at Cycle = 0, all patients in PRI_THR
  Cohort0 <- c(nStart, rep(0, ncol(trace)-1))
  names(Cohort0) <- colnames(trace)
  Cost0 <- Cost_States
  Cost0["PRI_THR"] <- Cost0["PRI_THR"] + Cost_j
  Cost0 <- Cohort0[-5] * Cost0
  Cost0 <- sum(Cost0)
  
  # Estimate Costs for each Cycle and Health State
  StateCosts <- 
    replicate(n = nrow(trace), 
              expr = Cost_States, simplify = TRUE) |> 
    t()
  
  StateCosts <- 
    (trace[,!colnames(trace) %in% "Death"] * StateCosts) |> 
    rowSums(na.rm = FALSE, dims = 1)
  
  ## Discount StateCosts
  StateCosts <- StateCosts/((1+cDR)^(1:nrow(trace)))
  
  # Combine Initial and Cycle Costs
  Costs <- c(Cost0, StateCosts)
  
  # Return Output
  return(Costs)
}