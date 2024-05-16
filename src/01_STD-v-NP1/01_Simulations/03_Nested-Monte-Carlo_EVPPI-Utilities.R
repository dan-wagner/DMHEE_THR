# Nested Monte Carlo Simulation for EVPPI
#   PHI: Utilities
#   Model with two alternatives: STD, NP1

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
# Values which nested functions will iterate over. 
cohort_age <- seq(from = 40, to = 80, by = 20)
names(cohort_age) <- cohort_age
cohort_sex <- c(Male = "Male", Female = "Female")
j <- c(STD = "STD", NP1 = "NP1")

# Configure Parallel Execution -------------------------------------------------
n_cores <- detectCores()/2 # Half of available clusters
cl <- makeCluster(n_cores)
registerDoParallel(cl = cl)

# Assign Parameter of Interest (PHI) -------------------------------------------
PHI <- "Utilities"

# Nested Monte Carlo Simulation ------------------------------------------------
sim_out <- 
  foreach(i = 1:1000, .final = simplify2array) %dopar% {
    # Draw Outer Loop Parameter (PHI)
    PHI_i <- draw_params(params = sim_params)[PHI]
    # Initiate Inner Loop
    replicate(n = 1000,
              expr = {
                # Draw Inner Loop Parameters (PSI)
                PSI_i <- draw_params(params = sim_params, prob = TRUE)
                # Fix the value of PHI to the corresponding element of PSI
                PSI_i[PHI] <- PHI_i
                # Run Model
                result_i <- 
                  sapply(X = cohort_age, 
                         FUN = \(age) {
                           sapply(X = cohort_sex,
                                  FUN = \(sex) {
                                    sapply(X = j,
                                           FUN = runModel,
                                           ParamList = PSI_i,
                                           Age0 = age,
                                           Gender = sex,
                                           n_cycles = 60,
                                           n_cohort = 1000,
                                           cDR = 0.06,
                                           oDR = 0.015)
                                  },
                                  simplify = "array")
                         }, 
                         simplify = "array")
                
                names(dimnames(result_i)) <- c("Result", "j", "Gender", "Age")
                result_i
              }, 
              simplify = "array")
  }
stopCluster(cl = cl)

# Add Missing Dimnames
names(dimnames(sim_out))[5:6] <- c("PSI", "PHI")
sim_out <- aperm(a = sim_out, 
                 perm = c("PSI", "Result", "j", "PHI", "Gender", "Age"))

# Write Data to Disk ===========================================================
readr::write_rds(x = sim_out, 
                 file = file.path("data", 
                                  "data-gen",
                                  "Simulation-Output",
                                  "01_STD-v-NP1", 
                                  paste0("NMC_", PHI, ".rds")))