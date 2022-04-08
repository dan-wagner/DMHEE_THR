define_tmat <- function(ParamList, 
                        j, 
                        nCycles = 60, 
                        Gender) {
  # Build Blank Transition Matrix (Q) 
  Mstates <- c("PRI_THR", "PRI_Success", 
               "REV_THR", "REV_Success", "Death")
  
  Q <- array(data = 0, 
             dim = c(length(Mstates), length(Mstates), length(1:nCycles)), 
             dimnames = list(Start = Mstates, End = Mstates, Cycle = NULL))
  
  # Apply Transition Probabilities =============================================
  ## Start: Primary THR (PRI_THR)
  Q["PRI_THR", "PRI_Success", ] <- 1 - ParamList$OMR[["PRI"]]
  Q["PRI_THR", "Death", ] <- ParamList$OMR[["PRI"]]
  
  ## Start: Primary Success (PRI_Success)
  Q["PRI_Success", "Death", ] <- ParamList$MR[, Gender]
  Q["PRI_Success", "REV_THR", ] <- ParamList$RevisionRisk[,j,Gender]
  Q["PRI_Success", "PRI_Success", ] <- 
    1 - colSums(x = Q["PRI_Success", , ], na.rm = FALSE, dims = 1)
  
  ## Start: Revision THR (REV_THR)
  Q["REV_THR", "Death", ] <- ParamList$OMR[["REV"]] + ParamList$MR[, Gender]
  Q["REV_THR", "REV_Success", ] <- 
    1 - (ParamList$OMR[["REV"]] + ParamList$MR[,Gender])
  
  ## Start: Revision Success (REV_Success)
  Q["REV_Success", "REV_THR", ] <- ParamList$RRR
  Q["REV_Success", "Death", ] <- ParamList$MR[,Gender]
  Q["REV_Success", "REV_Success", ] <- 
    1 - colSums(x = Q["REV_Success", , ], na.rm = FALSE, dims = 1)
  
  ## Death is Absorbing State
  Q["Death", "Death", ] <- 1
  
  return(Q)
}