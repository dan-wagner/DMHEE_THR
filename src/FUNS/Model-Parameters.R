getParams <- function(FileName = "params.rds", include_NP2 = FALSE) {
  # Get Model Parameters
  #
  # Args:
  #   FileName: Character (Default = "params.rds"). The name to give the 
  #     parameter file.
  #   include_NP2: Logical (Default = FALSE). Switch to control whether model
  #     considers 2 (Default) or 3 alternatives. 
  #
  # Returns:
  #   A list with X named elements. 
  #     {A}. 
  #     {B}. 
  #     {C}. 
  #     {D}. 
  
  # Set Path to output file
  param_path <- file.path("data", "data-gen", "Model-Params", FileName)
  # Check if File Exists
  params_exist <- file.exists(param_path)
  
  if (isFALSE(params_exist)) {
    usethis::ui_info(x = "Model Parameters have not been generated!")
    # Check if sub-directory exists
    param_dir <- 
      sub(pattern = "[\\/]params.rds", replacement = "", x = param_path)
    dir_present <- dir.exists(paths = param_dir)
    
    if (isFALSE(dir_present)) {
      usethis::ui_oops(x = "Missing directory: {usethis::ui_path(param_dir)}")
      dir.create(path = param_dir)
      usethis::ui_done(x = "Created directory: {usethis::ui_path(param_dir)}")
    }
    # Import the data in data-raw
    usethis::ui_info("Generating parameters from raw data!")
    params <- list.files(path = file.path("data", "data-raw"),
                         pattern = ".rds",
                         full.names = TRUE)
    names(params) <- sub(pattern = "data/data-raw/",
                         replacement = "",
                         x = params)
    names(params) <- sub(pattern = ".rds",
                         replacement = "", 
                         x = names(params))
    names(params) <- sub(pattern = "(THR-)|(THR_)|(THR)",
                         replacement = "",
                         x = names(params))
    names(params) <- sub(pattern = "-",
                         replacement = "",
                         x = names(params))
    # Import Data
    params <- lapply(X = params, FUN = readr::read_rds)
    # Add Prices
    params$Prices <- c(STD = 394, NP1 = 579, NP2 = 788)
    # Write data to param_path
    readr::write_rds(x = params, file = param_path)
    usethis::ui_done("Parameter list saved to {usethis::ui_path(param_path)}")
  } else {
    params <- readr::read_rds(file = param_path)
    usethis::ui_info("Loaded parameters from: {usethis::ui_path(param_path)}")
  }
  
  # Subset Comparators =======================================================
  if(isTRUE(include_NP2)) {
    # Select Correct Survival Data
    params <- params[names(params) != "Survival"]
    names(params) <- 
      sub(pattern = "Survival_NP2", replacement = "Survival", x = names(params))
    
  } else {
    # Select Correct Survival Data
    params <- params[names(params) != "Survival_NP2"]
    # Subset Prices
    params$Prices <- params$Prices[-3]
  }
  
  return(params)
}