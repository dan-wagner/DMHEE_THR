# Conduct Monte Carlo Simulation of THR Cohort Model

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

# Run Simulation ===============================================================
PHI <- "Utilities"

THR.Age <- seq(from = 40, to = 80, by = 20)
THR.Gender <- c("Male", "Female")
names(THR.Age) <- THR.Age
names(THR.Gender) <- THR.Gender

Sim.Start <- Sys.time()

NMCOut <- 
replicate(n = 1000, 
          expr = {
            # Draw Outer Loop Parameter
            PHI_i <- DrawParams(ParamList = THR_Params, prob = 1)[PHI]
            
            # Draw Inner Loop Values
            replicate(n = 1000, 
                      expr = {
                        PSI_i <- DrawParams(ParamList = THR_Params, 
                                            prob = 1)
                        PSI_i[PHI] <- PHI_i
                        
                        sapply(X = THR.Gender, 
                               FUN = \(sex){
                                 sapply(X = THR.Age, 
                                        FUN = \(age){
                                          sapply(X = list(STD = "STD", 
                                                          NP1 = "NP1"), 
                                                 FUN = runModel, 
                                                 ParamList = PSI_i, 
                                                 Age0 = age, 
                                                 Gender = sex, 
                                                 nCycles = 60, 
                                                 cDR = 0.06, 
                                                 oDR = 0.015, 
                                                 simplify = "array")
                                        }, 
                                        simplify = "array")
                               }, 
                               simplify = "array")
                      })
            
          })
Sim.Stop <- Sys.time()

names(dimnames(NMCOut)) <- c("Results", "j", "Age", "Gender", "PSI", "PHI")
NMCOut <- aperm(a = NMCOut, perm = c("PSI", "Results", "j", "PHI", "Age", "Gender"))

Sim.Stop - Sim.Start

## Save Output to data-gen 

NMCOut <- 
  readr::read_rds(file = file.path("data", 
                                   "data-gen", 
                                   "Simulation-Output", 
                                   "01_STD-v-NP1", 
                                   "Nested_MC-Sim_Utilities.rds"))


NMCOut <- aperm(a = NMCOut, 
                perm = c("PSI", 
                         "Results", 
                         "j", 
                         "PHI", 
                         "Gender", 
                         "Age"))
str(NMCOut)

names(THR.Gender) <- c("M", "F")

for (sex in seq_along(THR.Gender)) {
  for (age in seq_along(THR.Age)) {
    
    Result.Data <- NMCOut[,,,,THR.Gender[[sex]],names(THR.Age)[[age]]]
    
    Result.PATH <- 
      file.path("data", 
                "data-gen", 
                "Simulation-Output", 
                "01_STD-v-NP1", 
                paste("Nested", 
                      "MC-Sim", 
                      paste0(names(THR.Gender)[sex], 
                             names(THR.Age)[age]), 
                      "Utilities.rds", sep = "_"))
    
    readr::write_rds(x = Result.Data, 
                     file = Result.PATH)
    
  }
}