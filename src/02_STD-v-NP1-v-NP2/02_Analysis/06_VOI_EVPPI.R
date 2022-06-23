# Research Decision
# Calculate EVPI Statistic
# Parameter(s): Survival

# Define File Paths to EVPPI Data ==============================================
EVPPI.paths <- 
list.files(path = file.path("data", 
                            "data-gen", 
                            "Simulation-Output", 
                            "02_STD-v-NP1-v-NP2"), 
           pattern = "Nested", 
           full.names = TRUE)

## Define & Assign names to each file path -------------------------------------
##    - For functional programming to identify distinct data sets. 
EVPPI.Names <- sub(pattern = paste0(file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "02_STD-v-NP1-v-NP2"), 
                                    "/Nested_MC-Sim_"), 
                   replacement = "", 
                   x = EVPPI.paths)

EVPPI.Names <- sub(pattern = ".rds", replacement = "", x = EVPPI.Names)
EVPPI.Names <- paste(sub(pattern = "\\d{2}_(Costs|OMR|RRR|Utilities|Survival)",
                         replacement = "", 
                         x = EVPPI.Names),
                     sub(pattern = "F|M", 
                         replacement = "", 
                         x = EVPPI.Names), 
                     sep = "_")

names(EVPPI.paths) <- EVPPI.Names

# Prep for EVPPI Calculations ==================================================
library(HEEToolkit)

## Define Lambda values to consider --------------------------------------------
LDA <- seq(from = 5000, to = 50000, by = 5000)

## Calculate Effective Population Size -----------------------------------------
##    From Textbook: 
##      "For the Hip replacement example, we are going to assume an effective 
##       technology life of 10 years with 40,000 new patients eligible for 
##       treatment each year."
EP <- voi_EP(Yrs = 10, I_t = 20000, DR = 0.03)

# Run loop to Calculate EVPPI for each parameter set ---------------------------

EVPPI <- lapply(X = EVPPI.paths, 
                FUN = \(x){
                  nmc <- readr::read_rds(file = x)
                  
                  calc_EVPPI(data = nmc, 
                             lambda = LDA, 
                             EffPop = EP, 
                             Effects = "QALYs", 
                             nbType = "NMB", 
                             params = NULL)
       })


# Build Data set for Plotting ==================================================
EVPPI <- purrr::map_dfr(.x = EVPPI, 
                        .f = tibble::as_tibble, 
                        rownames = "lambda", 
                        .id = "SG_PHI")
EVPPI <- 
tidyr::separate(data = EVPPI, 
                col = "SG_PHI", 
                into = c("Gender", "Age", "PHI"), 
                sep = "_")

EVPPI <- dplyr::mutate(.data = EVPPI, 
                       lambda = as.double(lambda), 
                       Age = as.double(Age), 
                       Gender = dplyr::case_when(Gender == "F" ~ "Female", 
                                                 Gender == "M" ~ "Male"))

# Build Plot ===================================================================
library(ggplot2)
## 1) Single Facetted Plot -----------------------------------------------------
##    - Facets used to separate/distinguish gender & age sub-groups.

EVPPI.plot0 <- 
  ggplot(data = EVPPI, 
         mapping = aes(x = lambda, 
                       y = EVPPI.pop, 
                       colour = PHI)) + 
  geom_line() + 
  facet_wrap(Gender ~ Age) + 
  scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  theme_bw() + 
  labs(title = "THR Model: Population EVPPI", 
       subtitle = "Comparators: STD vs NP1 vs NP2", 
       x = "Threshold Ratio (\U03BB)", 
       y = "Population EVPPI", 
       colour = "\U03c6")

ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "VoI_EVPPI.png"), 
       plot = EVPPI.plot0, 
       device = "png", 
       width = 10, 
       height = 10)

## 2) Sub-Group plots by Age ---------------------------------------------------
##    - Single Facet: Gender

AG <- unique(EVPPI$Age)

for (i in seq_along(AG)) {
  EVPPI.plot.Age <- 
    ggplot(data = dplyr::filter(EVPPI, Age == AG[i]), 
           mapping = aes(x = lambda, 
                         y = EVPPI.pop, 
                         colour = PHI)) + 
    geom_line() + 
    facet_wrap(~ Gender) + 
    scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
    scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
    theme_bw() + 
    labs(title = "THR Model: Population EVPPI", 
         subtitle = paste("Comparators: STD vs NP1 vs NP2 |", 
                          "Baseline Age", AG[i], "Years"), 
         x = "Threshold Ratio (\U03BB)", 
         y = "Population EVPPI", 
         colour = "\U03c6")
  
  # save plot
  ggsave(filename = file.path("results", 
                              "02_STD-v-NP1-v-NP2", 
                              paste("VOI_EVPPI", 
                                    paste("Age", 
                                          paste0(AG[i], ".png"), 
                                          sep = "-"),
                                    sep = "_")), 
         plot = EVPPI.plot.Age, 
         device = "png", 
         width = 8, 
         height = 5)
}