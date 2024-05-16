# Conduct Deterministic Simulation of Cohort Model
# Model with three alternatives: STD, NP1, NP2

source(file = file.path("src", "FUNS", "Model-Parameters.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Time-Dependencies.R"))
source(file = file.path("src", "FUNS", "THR-Model.R"))

# Get Model Parameters =========================================================
sim_params <- getParams(include_NP2 = TRUE)

# Execute Simulation ===========================================================
# Draw Parameter Values --------------------------------------------------------
param_i <- draw_params(params = sim_params, prob = FALSE)

# Estimate Costs and Effects ---------------------------------------------------
# Analysis Strategy involves 6 separate scenario analyses:
#   - Female: Age 40, 60 (BC), 80
#   - Male: Age 40, 60, 80
# Instead of running each analysis separately, they can be executed in a single
# function call. The output can then be stored in an array. 

sim_out <- 
  sapply(X = c("40" = 40, "60" = 60, "80" = 80),
         FUN = \(age) {
           sapply(X = c("Male" = "Male", "Female" = "Female"),
                  FUN = \(sex){
                    sapply(X = c("STD" = "STD", "NP1" = "NP1", "NP2" = "NP2"), 
                           FUN = runModel,
                           ParamList = param_i,
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

# Name and Re-arrange array dimensions. 
names(dimnames(sim_out)) <- c("Result", "j", "Gender", "Age")
sim_out <- aperm(a = sim_out, perm = c("j", "Result", "Gender", "Age"))

# Save Output ==================================================================
readr::write_rds(x = sim_out, 
                 file = file.path("data", 
                                  "data-gen", 
                                  "Simulation-Output", 
                                  "02_STD-v-NP1-v-NP2", 
                                  "THR_Deter.rds"))