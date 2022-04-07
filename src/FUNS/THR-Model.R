define_tmat <- function(ParamList) {
  # Build Blank Transition Matrix (Q) 
  Mstates <- c("PRI_THR", "PRI_Success", 
               "REV_THR", "REV_Success", "Death")
  
  Q <- matrix(data = 0, nrow = length(Mstates), ncol = length(Mstates),
              dimnames = list(Start = Mstates, End = Mstates))
  
  # Apply Transition Probabilities =============================================
  ## Start: Primary THR (PRI_THR)
  Q["PRI_THR", "PRI_Success"] <- 1 - ParamList$OMR[["PRI"]]
  Q["PRI_THR", "Death"] <- ParamList$OMR[["PRI"]]
  
  ## Start: Primary Success (PRI_Success)
  
  ## Start: Revision THR (REV_THR)
  Q["REV_THR", "Death"] <- ParamList$OMR[["REV"]]
  Q["REV_THR", "REV_Success"] <- 1 - ParamList$OMR[["REV"]]
  
  ## Start: Revision Success (REV_Success)
  Q["REV_Success", "REV_THR"] <- ParamList$RRR
  
  ## Death is Absorbing State
  Q["Death", "Death"] <- 1
  
  return(Q)
}