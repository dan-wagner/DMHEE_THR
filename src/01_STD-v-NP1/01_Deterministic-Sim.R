# Conduct Deterministic Simulation of Cohort Model

source(file = file.path("src", "FUNS", "Model-Parameters.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Time-Dependencies.R"))
source(file = file.path("src", "FUNS", "Model-Parameters_Draws.R"))
source(file = file.path("src", "FUNS", "THR-Model.R"))

# Get Model Parameters =========================================================
getParams(include_NP2 = FALSE)
THR_Params <- readr::read_rds(file = file.path("data", 
                                               "data-gen", 
                                               "Model-Params", 
                                               "THR-Params_j2.rds"))

# Estimate Costs and Effects ===================================================
## Analysis strategy includes 6 separate scenario analyses: 
##    - Female: Age 40, 60 (BC), 80
##    - Male: Age 40, 60, 80
## Instead of running each analysis separately, I can do them all in a single 
## function call and store the output in a deliberately formatted array.


Param_0 <- DrawParams(ParamList = THR_Params, prob = 0)

simResult <- 
  sapply(X = c("40" = 40, "60" = 60, "80" = 80), 
         FUN = \(age){
           sapply(X = c(Male = "Male", Female = "Female"), 
                  FUN = \(sex){
                    sapply(X = c(STD = "STD", NP1 = "NP1"), 
                           FUN = runModel, 
                           ParamList = Param_0, 
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

# Name and Re-arrange array dimensions. 
names(dimnames(simResult)) <- c("Result", "j", "Gender", "Age")
simResult <- aperm(a = simResult, perm = c("j", "Result", "Gender", "Age"))

# Save Output ==================================================================
readr::write_rds(x = simResult, 
                 file = file.path("data", 
                                  "data-gen", 
                                  "Simulation-Output", 
                                  "01_STD-v-NP1", 
                                  "THR_Deter.rds"))