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
THR.Age <- seq(from = 40, to = 80, by = 20)
THR.Gender <- c("Male", "Female")
names(THR.Age) <- THR.Age
names(THR.Gender) <- THR.Gender

library(foreach)

simResult <- 
  foreach(n = 1:10000, .final = simplify2array) %do% {
    Param_i <- DrawParams(ParamList = THR_Params, prob = 1)
    
    Result_i <- 
      sapply(X = THR.Age, 
             FUN = \(age){
               sapply(X = THR.Gender, 
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
  }




# Name and Re-arrange array dimensions. 
names(dimnames(simResult)) <- c("Result", "j", "Gender", "Age", "i")
simResult <- aperm(a = simResult, perm = c("i", "Result", "j", "Gender", "Age"))

# Save Output ==================================================================
readr::write_rds(x = simResult, 
                 file = file.path("data", 
                                  "data-gen", 
                                  "Simulation-Output", 
                                  "02_STD-v-NP1-v-NP2", 
                                  "MC-Sim.rds"))