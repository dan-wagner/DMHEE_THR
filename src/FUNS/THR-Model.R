# Functions to execute the model organized into distinct steps. 
calc_mortalityRisk <- function(LT, Age, Gender, n_cycles = 60) {
  # Calculate the Background (General Population) Mortality Risk
  #
  # Args:
  #   LT: Numeric. Matrix of life table data by age-group and gender. Expects
  #     The LifeTable element from the parameter list. 
  #   Age: Numeric. The age at baseline for the simulated cohort. 
  #   Gender: Character. The gender of the simulated cohort. 
  #   n_cycles: Numeric (Default = 60). The number of cycles (year) to include
  #     in the simulation. 
  #
  # Returns:
  #   A vector of length n_cycles representing the background mortality risk
  #   for the simulated cohort. 
  
  # Adjust Life Table Estimates
  #   Life Table data represent the death rates by age and sex per 1,000 
  #   population. These values must be divided by 1000 to get annual 
  #   probabilities.
  LT <- LT/1000
  #   Modify the row names of LT to reflect the lower bound of each age range
  #   Will aid in subsetting. 
  rownames(x = LT) <- sub(pattern = "\\+|-\\d{2}",
                          replacement = "",
                          x = rownames(LT))
  # Calculate Cohort Age
  cohort_age <- Age + seq_len(length.out = n_cycles)
  # Identify Rows to Subset in LT
  age_index <- findInterval(x = cohort_age,
                            vec = as.numeric(rownames(LT)))
  # Subset LT:
  #   Rows by age_index to obtain age-specific mortality risks
  #   Columns by Gender
  risk_death <- LT[age_index, Gender]
  risk_death <- unname(risk_death)
  
  return(risk_death)
}

# Define Transition Matrix (Q) ##############################################
define_tmat <- function(j, 
                        Survival, 
                        OMR,
                        RRR,
                        LifeTables,
                        Gender,
                        Age,
                        n_cycles = 60) {
  # Define Transition Matrix for a Specific Alternative, Age, and Gender
  #
  # Args:
  #   j: Character. The arm of the decision model. Accepted values include
  #     `"STD"`, `"NP1", or "NP2` (depending on configuration).
  #   Survival: Numeric. A vector of coefficients from the parametric surival
  #     model to capture time-to-revision. Expects the "Survival" element from
  #     the parameter list.  
  #   OMR: Numeric. The operative mortality risk. Expects the OMR element from
  #      the parameter list. 
  #   RRR: Numeric. The re-revision risk. Expects the RRR element from the 
  #      parameter list. 
  #   n_cycles: Numeric (Default = 60). The number of cycles to include in the 
  #     simulation. 
  #   Gender: Character. The gender of the simulated population. Accepted values
  #     include `"Male"` or `"Female"`. 
  #   LifeTables: Numeric. Matrix of life table data by age-group and gender. 
  #     Expects the LifeTables element from the parameter list. 
  #
  # Returns:
  #   A 3-dimensional array representing the transition probabilities for the 
  #   specified configuration. Rows represent the start state, columns represent
  #   the end state, and the matrices represent each cycle of the simulation. 
  
  # Build Blank Transition Matrix (Q) 
  Mstates <- c("PRI_THR", "PRI_Success", 
               "REV_THR", "REV_Success", "Death")
  
  # Calculate Intermediate Values ==============================================
  # Background Mortality Risk 
  p_mort <- calc_mortalityRisk(LT = LifeTables,
                               Age = Age,
                               Gender = Gender,
                               n_cycles = n_cycles)
  # revision_free
  revision_free <- 
    extrapolate_survival(coefs = Survival,
                         age = Age,
                         male = ifelse(Gender == "Male", 1, 0),
                         n_cycles = n_cycles)
  
  # Prepare Blank Transition Matrix
  Q <- array(data = 0, 
             dim = c(length(Mstates), length(Mstates), n_cycles), 
             dimnames = list(Start = Mstates, End = Mstates, Cycle = NULL))
  
  # Calculate Transition Probabilities =========================================
  ## Start: Primary THR (PRI_THR)
  Q["PRI_THR", "PRI_Success", ] <- 1 - (OMR + p_mort)
  
  ## Start: Primary Success (PRI_Success)
  Q["PRI_Success", "REV_THR", ] <- (1 - revision_free[, j]) * (1 - p_mort)
  Q["PRI_Success", "PRI_Success", ] <- revision_free[, j] * (1 - p_mort)
  
  ## Start: Revision THR (REV_THR)
  Q["REV_THR", "REV_Success", ] <- 1 - (OMR + p_mort)
  
  ## Start: Revision Success (REV_Success)
  Q["REV_Success", "REV_THR", ] <- RRR * (1 - p_mort)
  Q["REV_Success", "REV_Success", ] <- (1 - RRR) * (1 - p_mort)
  
  # Transitions to Death State
  Q[, "Death", ] <- 1 - apply(X = Q, MARGIN = c("Start", "Cycle"), FUN = sum)
  
  return(Q)
}

# 2) Track Cohort (trace) ######################################################
track_cohort <- function(Q, n_cohort = 1000) {
  # Generate the Cohort Trace for the Economic Model
  #
  # Args:
  #   Q: Numeric. A 3-dimensional array representing the time-dependent 
  #      transition probabilities. 
  #   n_cohort: Numeric (Default = 1000). The size of the simulated cohort. 
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
  cohort_init <- c(n_cohort, rep(0, 4))
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
est_costs <- function(j,
                      trace,
                      Price,
                      Cost_States,
                      cDR = 0.06,
                      n_cohort = 1000){
  # Estimate Costs for the Simulated Cohort
  # 
  # Args:
  #   j: Character. The name of the prosthesis of interest.
  #   trace: Numeric. The estimates of state occupancy generated from the cohort
  #     simulation. 
  #   Price: Numeric. The unit price of the alternative prostheses.
  #   Cost_States: Numeric. The annual costs for patients in each health state.
  #     Expects the `"Costs_States"` element from the parameter list.
  #   cDR: Numeric. The discount rate to apply to costs.
  #   n_cohort: Numeric (Default = 1000). The size of the simulated cohort.
  #
  # Returns:
  #   A numeric vector whose length will match the same number of rows in the
  #   cohort trace. Values represent the discounted costs per-cycle for the
  #   simulated cohort. 
  
  # Identify alive states
  alive_states <- !colnames(trace) %in% "Death"
  # Calculate Acquisition Costs
  acquisition <- n_cohort * Price[[j]]
  # Calculate Monitoring/Follow-Up Costs
  #   By Cycle and State
  state_costs <- 
    t(apply(X = trace[, alive_states], MARGIN = 1, FUN = `*`, Cost_States))
  #   Sum Across States
  state_costs <- rowSums(x = state_costs, na.rm = FALSE, dims = 1L)
  
  # Calculate Total Costs
  total_costs <- state_costs
  total_costs[1] <- total_costs[1] + acquisition
  # Discount Values
  yrs <- 1:nrow(trace)
  total_costs <- total_costs/((1 + cDR)^yrs)
  
  return(total_costs)
}

# Estimate Effects #############################################################
est_effects <- function(trace, Utility, oDR = 0.015) {
  # Estimate Effects for the Cohort Simulation
  # 
  # Args:
  #   trace: Numeric. A matrix representing the simulated cohort's state 
  #     occupancy over time. 
  #   Utility: Numeric. A vector of the health state utility values. 
  #   oDR: Numeric. The discount rate to apply to effects. 
  #
  # Returns:
  #   A matrix of estimated model outcomes in each cycle of the simulation. 
  #   Columns represent LYs and QALYs. Rows represent cycles. 
  
  # Identify alive states
  alive_states <- !colnames(trace) %in% "Death"
  
  # Calculate Life Years
  LYs <- rowSums(x = trace[, alive_states], na.rm = FALSE, dims = 1)
  # Calculate QALYs
  QALYs <- apply(X = trace[, alive_states], MARGIN = 1, FUN = `*`, Utility)
  QALYs <- colSums(x = QALYs, na.rm = FALSE, dims = 1L)
  
  # Combine Results
  Effects <- cbind(LYs = LYs, QALYs = QALYs)
  ## Discount Effects
  yrs <- 1:nrow(trace)
  Effects <- Effects/((1+oDR)^yrs)
  
  return(Effects)
}

# RUN Whole Model: Returns Costs & Effects for one arm #########################
runModel <- function(j, 
                     ParamList,
                     Age0 = 60, 
                     Gender = "Female",
                     n_cycles = 60, 
                     cDR = 0.06, 
                     oDR = 0.015) {
  # Estimate Costs and Benefits for a Single Alternative
  #
  # Args:
  #   j: Character. The alternative of interest. Accepted values include
  #      `"STD"`, `"NP1"`, or `"NP2"` (if available). 
  #   ParamList: List. The list of sampled parameter values. Expects the output
  #     from the function DrawParams(). 
  #   Age0: Numeric. The age of the simulated cohort at baseline. 
  #   Gender: Character. The gender of the simulated cohort. 
  #   n_cycles: Numeric (integer). Refers to the total number of cycles (years)
  #     in the cohort simulation. Default = 60 (base case). 
  #   cDR: Numeric (Default = 0.06). The discount rate to apply to costs. 
  #   oDR: Numeric (Default = 0.015). The discount rate to apply to benefits. 
  #
  # Details:
  #   The model can be broken down into four distinct tasks. 
  #   1) Define the transition matrix with probabilities specific to the 
  #      declared alternative, age, and gender. 
  #   2) Track the cohort through the model structure over the specified time
  #      horizon. 
  #   3) Estimate benefits
  #   4) Estimate costs. 
  #   5) Discont costs and benefits, then calculate totals over simulated time
  #      horizon. 
  #
  # Returns:
  #   A named numeric vector of length three: Costs, LYs, and QALYs. 
  
  j <- match.arg(arg = j, choices = c("STD", "NP1", "NP2"))
  Gender <- match.arg(arg = Gender, choices = c("Male", "Female"))
  
  # Build Transition Matrix (Q)
  Q <- define_tmat(j = "STD",
                   Survival = ParamList$Survival,
                   OMR = ParamList$OMR,
                   RRR = ParamList$RRR,
                   Gender = Gender,
                   LifeTables = ParamList$LifeTables,
                   Age = 60,
                   n_cycles = 60)
  
  # Track Cohort (trace)
  trace <- track_cohort(Q = Q, n_cohort = 1000)
  
  # Estimate Costs (Costs)
  Costs <- est_costs(j = j,
                     trace = trace,
                     Price = ParamList$Prices,
                     Cost_States = ParamList$Costs_States,
                     cDR = cDR,
                     n_cohort = 1000)
  
  # Estimate Effects (Effects: LYs/QALYs) 
  Effects <- est_effects(trace = trace, 
                         Utility = ParamList$Utilities, 
                         oDR = oDR)
  
  # Assemble Results
  ## Calculate Total Per-Patient Costs & Effects
  Costs <- sum(Costs)/1000
  Effects <- colSums(x = Effects, na.rm = FALSE, dims = 1)/1000
  ## Combine Results
  Result <- c(Costs = Costs, Effects)
  
  return(Result)
}