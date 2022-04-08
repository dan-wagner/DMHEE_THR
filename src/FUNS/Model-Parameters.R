getParams <- function(File = "THR-Params.rds") {
  Params.Dir <- file.path("data", "data-gen", "Model-Params")
  
  if (isFALSE(dir.exists(Params.Dir))) {
    usethis::ui_oops("Missing {usethis::ui_path(Params.Dir)} sub-directory!")
    
    dir.create(path = Params.Dir)
    
    usethis::ui_done("Created {usethis::ui_path(Params.Dir)} sub-directory.")
  }
  
  Dir.Content <- list.files(path = Params.Dir)
  
  if (length(Dir.Content) == 0) {
    usethis::ui_info("Model Parameters have not been generated!")
    usethis::ui_info("Preparing list from raw data")
    
    # TRANSITION PROBABILITIES -----------------------------
    # Life Tables: Age & Gender Stratified Risk of Death
    LT <- readr::read_rds(file.path("data", 
                                    "data-raw", 
                                    "Life-Tables.rds"))
    
    # Survival: Revision Risk following Primary THR. 
    SurvFit <- readr::read_rds(file.path("data", 
                                         "data-raw", 
                                         "THR-Survival.rds"))
    
    # Operative Mortality Rate
    ## Primary and Revision Assumed equal to 0.02
    OMR <- c(PRI = 0.02, REV = 0.02)
    
    # Re-Revision Risk
    RRR <- 0.04
    
    # COSTING -----------------------------------------------
    # Cost of Alternative Protheses
    Cost_j <- c(STD = 394, NP1 = 579)
    # Health State Costs
    Cost_states <- readr::read_rds(file = file.path("data", 
                                                    "data-raw", 
                                                    "THR_Costs_States.rds"))
    # UTILITIES ---------------------------------------------
    
    # Combine into List: 
    THR_Params <- 
      list(OMR = OMR, 
           RRR = RRR, 
           LifeTables = LT, 
           Survival = SurvFit)
    
    ## write to data-gen/Model-Params
    Param.Path <- file.path(Params.Dir, File)
    readr::write_rds(x = THR_Params, 
                     file = Param.Path)
    
    usethis::ui_done("{usethis::ui_field('THR_Params')} saved to {usethis::ui_path(Param.Path)}")
    
    
  } else {
    Param.Path <- file.path(Params.Dir, File)
    usethis::ui_info("Load parameters from {usethis::ui_path(Param.Path)}")
  }
  
}