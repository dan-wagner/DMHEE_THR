# 1) Define Transition Matrix (Q) ##############################################
define_tmat <- function(j, 
                        ParamList, 
                        nCycles = 60, 
                        Gender) {
  # Define Transition Matrix for a Specific Alternative
  #
  # Args:
  #   j: Character. The arm of the decision model. Accepted values include
  #     `"STD"`, `"NP1", or "NP2` (depending on configuration). 
  #   ParamList: List. A modified list of the input parameters. Expects the 
  #      output from the function calc_TimeDeps(). 
  #   nCycles: Numeric (Default = 60). The number of cycles to include in the 
  #     simulation. 
  #   Gender: Character. The gender of the simulated population. Accepted values
  #     include `"Male"` or `"Female"`. 
  #
  # Returns:
  #   A 3-dimensional array representing the transition probabiltiies for the 
  #   specified configuration. Rows represent the start state, columns represent
  #   the end state, and the matrices represent each cycle of the simulation. 
  
  # Build Blank Transition Matrix (Q) 
  Mstates <- c("PRI_THR", "PRI_Success", 
               "REV_THR", "REV_Success", "Death")
  
  Q <- array(data = 0, 
             dim = c(length(Mstates), length(Mstates), nCycles), 
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
track_cohort <- function(Q, nStart = 1000) {
  # Generate the Cohort Trace for the Economic Model
  #
  # Args:
  #   Q: Numeric. A 3-dimensional array representing the time-dependent 
  #      transition probabilities. 
  #   nStart: Numeric. The total size of the cohort to simulate. 
  #
  # Returns:
  #   An array with 2 dimensions (i.e. matrix). Rows represent the cycle of the 
  #   simulation. Columns represent each markov state. Values represent the 
  #   proportion of the cohort occupying each state. 
  
  # Construct Blank Cohort Trace 
  #   Define Number of Cycles
  n_cycles <- dim(Q)[[3]]
  #   Define Health States
  states <- unique(x = c(colnames(Q), rownames(Q)))
  #   Create Array
  trace <- array(data = 0, 
                 dim = c(n_cycles, length(states)), 
                 dimnames = list(Cycle = NULL, 
                                 State = states))
  # Set Membership for Cycle 0
  cohort_init <- c(nStart, rep(0, 4))
  names(cohort_init) <- colnames(Q)
  
  # Populate Cohort Trace
  for (i in seq_along(1:n_cycles)) {
    if (i == 1) {
      trace[i, ] <- cohort_init %*% Q[,,i]
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
  j <- match.arg(arg = j, choices = c("STD", "NP1", "NP2"))
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
                       Cost_States = ParamList$Cost_States, 
                       cDR = cDR,
                       nStart = 1000)
  
  # Estimate Effects (Effects: LYs/QALYs) 
  Effects <- effects_cohort(trace = trace, 
                            State_Util = ParamList$Utilities, 
                            oDR = oDR)
  
  # Assemble Results
  ## Calculate Total Per-Patient Costs & Effects
  Costs <- sum(Costs)/1000
  Effects <- colSums(x = Effects, na.rm = FALSE, dims = 1)/1000
  ## Combine Results
  Result <- c(Costs = Costs, Effects)
  
  return(Result)
}