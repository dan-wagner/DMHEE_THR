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
  Cost0 <- (Cost_j + Cost_States[["PRI_THR"]])*nStart
  
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

# Estimate Effects #############################################################
effects_cohort <- function(trace, 
                           State_Util, 
                           oDR = 0.015) {
  # Estimate Life Years
  LYs <- rowSums(x = trace[, !colnames(trace) %in% "Death"], 
                 na.rm = FALSE, 
                 dims = 1)
  # Estimate Utilities
  Utilities <- trace[, !colnames(trace) %in% "Death"]
  for (i in seq_along(1:nrow(Utilities))) {
    Utilities[i,] <- Utilities[i,] * State_Util
  }
  Utilities <- rowSums(x = Utilities, na.rm = FALSE, dims = 1)
  
  # Combine Results
  Effects <- cbind(LYs = LYs, QALYs = Utilities)
  ## Discount Effects
  Effects <- Effects/((1+oDR)^(1:nrow(trace)))
  
  return(Effects)
}

# RUN Whole Model: Returns Costs & Effects for one arm #########################
runModel <- function(ParamList,
                     j, 
                     Age0 = 60, 
                     Gender = "Female",
                     nCycles = 60, 
                     cDR = 0.06, 
                     oDR = 0.015) {
  j <- match.arg(arg = j, choices = c("STD", "NP1"))
  Gender <- match.arg(arg = Gender, choices = c("Male", "Female"))
  
  # Modify Parameters: Time-Dependencies 
  ParamList <- calc_TimeDeps(ParamList = ParamList, 
                             Age0 = Age0, 
                             nCycles = nCycles)
  
  # Build Transition Matrix (Q)
  Q <- define_tmat(ParamList = ParamList, 
                   j = j, 
                   Gender = Gender, 
                   nCycles = nCycles)
  
  # Track Cohort (trace)
  trace <- track_cohort(Q = Q, nCycles = nCycles, nStart = 1000)
  
  # Estimate Costs (Costs)
  Costs <- cost_cohort(trace = trace, 
                       Cost_j = ParamList$Cost_j[[j]], 
                       Cost_States = ParamList$Cost_States[,"Mean"], 
                       cDR = cDR,
                       nStart = 1000)
  
  # Estimate Effects (Effects: LYs/QALYs) 
  Effects <- effects_cohort(trace = trace, 
                            State_Util = ParamList$Utilities[,"Mean"], 
                            oDR = oDR)
  
  # Assemble Results
  ## Calculate Total Per-Patient Costs & Effects
  Costs <- sum(Costs)/1000
  Effects <- colSums(x = Effects, na.rm = FALSE, dims = 1)/1000
  ## Combine Results
  Result <- c(Costs = Costs, Effects)
  
  return(Result)
}