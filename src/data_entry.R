# Script to Create Raw Data for the Reproducible Workflow. 
# Should be executed infrequently. 

# Hospital Data ================================================================
#   Operative Mortality Rate:
#     The hospital records of a sample of 100 patients receiving a primary 
#     THR were examined retrospectively. Of these patients, two died either 
#     during or immediately following the procedure. The operative mortality 
#     for the procedure is estimated to be 2%. 
#   
#   Re-Revision Risk:
#     The hospital records of a sample of 100 patients having experienced a 
#     revision procedure to replace a failed primary THR were reviewed at 
#     one year. During this time, four patients had undergone a further 
#     revision procedure. 

HospitalData <- 
  matrix(data = c(2, 4, 100, 100), 
         nrow = 2, 
         ncol = 2, 
         dimnames = list(Outcome = c("OMR", "RRR"),
                         c("events", "N")))

readr::write_rds(x = HospitalData,
                 file = file.path("data", "data-raw", "HospitalData.rds"))