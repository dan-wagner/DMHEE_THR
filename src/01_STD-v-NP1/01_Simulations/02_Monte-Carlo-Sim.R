# Conduct Monte Carlo Simulation of THR Cohort Model
# Model with two alternatives: STD, NP1

# Setup ========================================================================
#   Load Functions -------------------------------------------------------------
source(file = file.path("src", "FUNS", "Model-Parameters.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Time-Dependencies.R"))
source(file = file.path("src", "FUNS", "THR-Model.R"))

library(foreach)
library(doParallel)

#   Load Simulation Parameters -------------------------------------------------
sim_params <- getParams(include_NP2 = FALSE)

# Execute Simulation ===========================================================
# Analysis strategy involves 6 separate scenario analyses:
#   - Female: Age 40, 60, 80
#   - Male: Age 40, 60, 80
# Instead of running each analysis separately, they can be executed in a 
# single function call. The output can be stored in an array. 

# Define Functional Variables --------------------------------------------------
# Values which nested functions will iterate over
cohort_age <- seq(from = 40, to = 80, by = 20)
names(cohort_age) <- cohort_age
cohort_sex <- c(Male = "Male", Female = "Female")
j <- c(STD = "STD", NP1 = "NP1")

# Configure Cluster for Parallel Execution -------------------------------------
n_cores <- detectCores()/2 # Half of available clusters
cl <- makeCluster(n_cores)
registerDoParallel(cl = cl)

# Monte Carlo Simulation -------------------------------------------------------
sim_start <- Sys.time()
sim_out <- foreach(n = 1:10000, .final = simplify2array) %dopar% {
  # Perform Random Draw
  param_i <- draw_params(params = sim_params, prob = TRUE)
  # Estimate Costs & Benefits
  result_i <- 
    sapply(X = cohort_age, 
           FUN = \(age){
             sapply(X = cohort_sex, 
                    FUN = \(sex){
                      sapply(X = j,
                             FUN = runModel, 
                             ParamList = param_i,
                             Age0 = age,
                             Gender = sex,
                             n_cycles = 60,
                             n_cohort = 1000,
                             cDR = 0.06,
                             oDR = 0.015,
                             simplify = "array")
                    },
                    simplify = "array")
           },
           simplify = "array")
}

stopCluster(cl = cl)
sim_stop <- Sys.time()

sim_stop - sim_start

# Name and Re-arrange array dimensions. 
names(dimnames(sim_out)) <- c("Result", "j", "Gender", "Age", "i")
sim_out <- aperm(a = sim_out, perm = c("i", "Result", "j", "Gender", "Age"))

# Save Output ==================================================================
readr::write_rds(x = sim_out, 
                 file = file.path("data", 
                                  "data-gen", 
                                  "Simulation-Output", 
                                  "01_STD-v-NP1", 
                                  "MC-Sim.rds"))