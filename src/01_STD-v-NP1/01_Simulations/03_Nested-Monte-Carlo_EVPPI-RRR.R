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
PHI <- "RRR"

THR.Age <- seq(from = 40, to = 80, by = 20)
THR.Gender <- c("Male", "Female")
names(THR.Age) <- THR.Age
names(THR.Gender) <- THR.Gender

library(foreach)
library(doParallel)
registerDoParallel(cores = 6)

Sim.Start <- Sys.time()

NMCOut <- 
  foreach(n = 1:1000, 
          .final = simplify2array) %dopar% {
            # Draw Outer Loop Parameter
            PHI_i <- DrawParams(ParamList = THR_Params, prob = 1)[PHI]
            
            
            replicate(n = 1000, 
                      expr = {
                        PSI_i <- DrawParams(ParamList = THR_Params, prob = 1)
                        PSI_i[PHI] <- PHI_i
                        
                        Result <- 
                          sapply(X = THR.Age, 
                                 FUN = \(age){
                                   sapply(X = THR.Gender, 
                                          FUN = \(sex){
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
                        
                        names(dimnames(Result)) <- c("Results", 
                                                     "j", 
                                                     "Gender", 
                                                     "Age")
                        Result
                      })
          }

Sim.Stop <- Sys.time()

NoDimName <- which(names(dimnames(NMCOut)) == "")

names(dimnames(NMCOut))[NoDimName] <- c("PSI", "PHI") 
NMCOut <- aperm(a = NMCOut, perm = c("PSI", 
                                     "Results", 
                                     "j", 
                                     "PHI", 
                                     "Gender", 
                                     "Age"))

Sim.Stop - Sim.Start

## Save Output to data-gen 

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
                      "RRR.rds", sep = "_"))
    
    readr::write_rds(x = Result.Data, 
                     file = Result.PATH)
    
  }
}