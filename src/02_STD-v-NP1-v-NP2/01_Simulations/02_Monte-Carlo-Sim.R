# Conduct Monte Carlo Simulation of THR Cohort Model

source(file = file.path("src", "FUNS", "Model-Parameters.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Time-Dependencies.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Draws.R"))
source(file = file.path("src", "FUNS", "THR-Model.R"))

# Get Model Parameters =========================================================
getParams(include_NP2 = TRUE)
THR_Params <- readr::read_rds(file = file.path("data", 
                                               "data-gen", 
                                               "Model-Params", 
                                               "THR-Params_j3.rds"))

# Estimate Costs and Effects ===================================================
## Analysis strategy includes 6 separate scenario analyses: 
##    - Female: Age 40, 60 (BC), 80
##    - Male: Age 40, 60, 80
## Instead of running each analysis separately, I can do them all in a single 
## function call and store the output in a deliberately formatted array.

simResult <- 
  replicate(n = 5000, 
            expr = {
              Param_i <- DrawParams(ParamList = THR_Params, prob = 1)
              
              Result_i <- 
                sapply(X = c("40" = 40, "60" = 60, "80" = 80), 
                       FUN = \(age){
                         sapply(X = c(Male = "Male", Female = "Female"), 
                                FUN = \(sex){
                                  sapply(X = c(STD = "STD", 
                                               NP1 = "NP1", 
                                               NP2 = "NP2"), 
                                         FUN = runModel, 
                                         ParamList = Param_i, 
                                         Age0 = age, 
                                         Gender = sex, 
                                         nCycles = 60, 
                                         cDR = 0.06, 
                                         oDR = 0.015, 
                                         simplify = TRUE)
                                }, 
                                simplify = "array")
                       }, 
                       simplify = "array")
            },
            simplify = "array")


# Name and Re-arrange array dimensions. 
names(dimnames(simResult)) <- c("Result", "j", "Gender", "Age", "i")
simResult <- aperm(a = simResult, perm = c("i", "Result", "j", "Gender", "Age"))

# Save Output ==================================================================
readr::write_rds(x = simResult, 
                 file = file.path("data", 
                                  "data-gen", 
                                  "Simulation-Output", 
                                  "02_STD-v-NP1-v-NP2", 
                                  "THR_MC-Sim_5000.rds"))