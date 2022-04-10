getParams <- function(include_NP2 = FALSE) {
  # Set Directory and File Names
  Params.Dir <- file.path("data", "data-gen", "Model-Params")
  if (isTRUE(include_NP2)) {
    File <- "THR-Params_j3.rds"
  } else {
    File <- "THR-Params_j2.rds"
  }
  
  # Check that DIR Exists
  if (isFALSE(dir.exists(Params.Dir))) {
    usethis::ui_oops("Missing sub-directory: {usethis::ui_path(Params.Dir)}")
    
    dir.create(path = Params.Dir)
    
    usethis::ui_done("Created sub-directory: {usethis::ui_path(Params.Dir)}")
  }
  
  # Check DIR Content
  Dir.Content <- list.files(Params.Dir)
  path2File <- file.path(Params.Dir, File)
  
  if (isFALSE(File %in% Dir.Content)) {
    usethis::ui_info("Model Parameters have not been generated!")
    usethis::ui_info("Preparing list from raw data.")
    # TRANSITION PROBABILITIES -----------------------------
    # Life Tables: Age & Gender Stratified Risk of Death
    LT <- readr::read_rds(file.path("data", 
                                    "data-raw", 
                                    "Life-Tables.rds"))
    # Survival: Revision Risk following Primary THR. 
    if (isTRUE(include_NP2)) {
      SurvFit <- readr::read_rds(file.path("data", 
                                           "data-raw", 
                                           "THR-Survival_NP2.rds"))
    } else {
      SurvFit <- readr::read_rds(file.path("data", 
                                           "data-raw", 
                                           "THR-Survival.rds"))
    }
    
    # Operative Mortality Rate
    ## Primary and Revision Assumed equal to 0.02
    OMR <- c(PRI = 0.02, REV = 0.02)
    
    # Re-Revision Risk
    RRR <- 0.04
    
    # COSTING -----------------------------------------------
    # Cost of Alternative Protheses
    Cost_j <- c(STD = 394, NP1 = 579)
    if (isTRUE(include_NP2)) {
      Cost_j <- c(Cost_j, NP2 = 788)
    }
    
    # Health State Costs
    Cost_states <- readr::read_rds(file = file.path("data", 
                                                    "data-raw", 
                                                    "THR_Costs_States.rds"))
    # UTILITIES ---------------------------------------------
    Utilities <- readr::read_rds(file = file.path("data", 
                                                  "data-raw", 
                                                  "THR-Utilities.rds"))
    
    # Combine into List: 
    THR_Params <- 
      list(OMR = OMR, 
           RRR = RRR, 
           LifeTables = LT, 
           Survival = SurvFit, 
           Cost_j = Cost_j, 
           Cost_States = Cost_states, 
           Utilities = Utilities)
    
    # Write to: data/data-gen/Model-Params/
    readr::write_rds(x = THR_Params, 
                     file = path2File)
    usethis::ui_done("Access parameters from {usethis::ui_path(path2File)}")
    
  } else {
    usethis::ui_info("Load parameters from {usethis::ui_path(path2File)}")
  }
}