# Function Definition: check_Frontier
# Accepts the output from an incremental analysis and determines which j's 
# will be on the cost-effectiveness frontier. 

checkFrontier <- function(data) {
  # Coerce from Matrix to tibble
  # data <- tibble::as_tibble(x = result, rownames = "j")
  
  # Add Status Variable to Indicate if j is on Frontier
  ##  0 = Not on Frontier
  ##  1 = J is on Frontier
  
  onFrontier <- ifelse(data[,"Dom"] == 0 & 
                         data[,"ExtDom"] == 0,
                       1, 0)
  
  result <- cbind(data, onFrontier)
  
  return(result)
}