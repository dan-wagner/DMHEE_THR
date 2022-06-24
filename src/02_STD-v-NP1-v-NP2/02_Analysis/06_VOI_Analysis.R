# Calculate VoI Results
#   Store Output in VoI Sub-Directory of data/data-gen

# Define File Paths for Iterative Calculations =================================
simResult.DIR <- file.path("data", 
                           "data-gen", 
                           "Simulation-Output", 
                           "02_STD-v-NP1-v-NP2")

VoI <- 
  list(EVPI = list.files(path = simResult.DIR, 
                         pattern = "MC-Sim.rds", 
                         full.names = TRUE), 
       EVPPI = list.files(path = simResult.DIR, 
                          pattern = "Nested_MC-Sim_(F|M)\\d{2}_(OMR|RRR|Survival|Costs|Utilities).rds", 
                          full.names = TRUE))

# Set Names for Each EVPPI Element =============================================
names(VoI$EVPPI) <- sub(pattern = paste(simResult.DIR, 
                                        "Nested_MC-Sim_", 
                                        sep = "/"),
                        replacement = "", 
                        x = VoI$EVPPI)
names(VoI$EVPPI) <- sub(pattern = ".rds", 
                        replacement = "", 
                        x = names(VoI$EVPPI))
names(VoI$EVPPI) <- paste(sub(pattern = "\\d{2}_(OMR|RRR|Survival|Costs|Utilities)", 
                              replacement = "", 
                              x = names(VoI$EVPPI)), 
                          sub(pattern = "F|M", 
                              replacement = "", 
                              x = names(VoI$EVPPI)),
                          sep = "_")

# Calculate EVPI & EVPPI =======================================================
library(HEEToolkit)
LDA <- seq(from = 0, to = 50000, by = 5000)
EP <- voi_EP(Yrs = 10, I_t = 20000, DR = 0.03)

Gender <- c(Male = "Male", Female = "Female")
Age <- c(`40` = "40", `60` = "60", `80` = "80")

## EVPI ------------------------------------------------------------------------
VoI$EVPI <- readr::read_rds(file = VoI$EVPI)

VoI$EVPI <- sapply(X = Age, 
                   FUN = \(age){
                     sapply(X = Gender, 
                            FUN = \(sex){
                              calc_EVPI(data = VoI$EVPI[,,,sex,age], 
                                        lambda = LDA, 
                                        EffPop = EP, 
                                        Effects = "QALYs", 
                                        nbType = "NMB")
                            }, 
                            simplify = "array")
                   }, 
                   simplify = "array")

names(dimnames(VoI$EVPI))[c(3,4)] <- c("Gender", "Age")

## EVPPI -----------------------------------------------------------------------
VoI$EVPPI <- purrr::map_dfr(.x = VoI$EVPPI, 
                            .f = \(x){
                              nmc <- readr::read_rds(file = x)
                              
                              result <- calc_EVPPI(data = nmc, 
                                                   lambda = LDA, 
                                                   EffPop = EP, 
                                                   Effects = "QALYs", 
                                                   nbType = "NMB")
                              
                              tibble::as_tibble(x = result, 
                                                rownames = "lambda")
                            }, 
                            .id = "Index")

# Wrangle VoI Results ==========================================================
VoI$EVPI <- tibble::as_tibble(x = VoI$EVPI, rownames = "lambda")
VoI$EVPI <- tidyr::pivot_longer(data = VoI$EVPI, 
                                cols = -"lambda", 
                                names_to = c("Stat", "Gender", "Age"), 
                                names_sep = "\\.", 
                                names_transform = list(Age = as.double), 
                                values_to = "result")
VoI$EVPI <- tidyr::pivot_wider(data = VoI$EVPI, 
                               names_from = "Stat", values_from = "result")
VoI$EVPI <- dplyr::rename(.data = VoI$EVPI, Pt = EVPIpt, Pop = EVPIpop)
VoI$EVPI$lambda <- as.double(VoI$EVPI$lambda)
VoI$EVPPI <- tidyr::separate(data = VoI$EVPPI, 
                             col = "Index", 
                             into = c("Gender", "Age", "PHI"), 
                             sep = "_")
VoI$EVPPI <- dplyr::mutate(.data = VoI$EVPPI, 
                           Gender = dplyr::case_when(Gender == "F" ~ "Female", 
                                                     Gender == "M" ~ "Male"), 
                           Age = as.double(Age), 
                           lambda = as.double(lambda))
VoI$EVPPI <- dplyr::rename(.data = VoI$EVPPI, Pt = EVPPI.pt, Pop = EVPPI.pop)

VoI <- tibble::enframe(x = VoI, name = "VoI.stat", value = "result")
VoI <- tidyr::unnest(data = VoI, cols = "result")
VoI <- dplyr::mutate(.data = VoI, 
                     PHI = tidyr::replace_na(PHI, ""))

# Save Output
readr::write_rds(x = VoI, 
                 file = file.path("data",
                                  "data-gen", 
                                  "VoI-Results", 
                                  "02_STD-v-NP1-v-NP2", 
                                  "VoI_EVPI-EVPPI.rds"))
