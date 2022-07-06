# Plot Cost-Effectiveness Acceptability Curve
# All Scenarios

# Import Data ==================================================================
simResult <- readr::read_rds(file = file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "02_STD-v-NP1-v-NP2", 
                                              "MC-Sim.rds"))

# Conduct NB Analysis ==========================================================
## Prepare Inputs --------------------------------------------------------------
LDA <- seq(from = 0, to = 50000, by = 5000)
## Calculate Net-Benefits ------------------------------------------------------
library(HEEToolkit)
THR.Age <- dimnames(simResult)$Age
names(THR.Age) <- THR.Age

THR.Gender <- dimnames(simResult)$Gender
names(THR.Gender) <- THR.Gender

NB <- lapply(X = THR.Age, 
             FUN = \(age){
               lapply(X = THR.Gender,
                      FUN = \(sex){
                        nb_analysis(data = simResult[,,,sex,age], 
                                    lambda = LDA, 
                                    Effects = "QALYs", 
                                    nbType = "NMB", 
                                    show.error = FALSE)
                      })
             })

# Plot CEAC ====================================================================
## Coerce NB Output to a tbl ---------------------------------------------------
NB <- purrr::map_dfr(.x = NB, 
                     .id = "Age",
                     .f = \(age){
                       purrr::map_dfr(.x = age, 
                                      .id = "Gender",
                                      .f = \(sex){
                                        tibble::as_tibble(x = sex, 
                                                          rownames = "j")
                                      })
                     })

NB <- tidyr::pivot_longer(data = NB, 
                          cols = -c("Age", "Gender", "j"), 
                          names_to = c("stat", "lambda"), 
                          names_sep = "\\.", 
                          names_transform = list(lambda = as.double), 
                          values_to = "output") |> 
  tidyr::pivot_wider(names_from = "stat", values_from = "output")

## Build Plot ------------------------------------------------------------------
Fig.Cap <- paste("Data generated from Monte Carlo simulation of", 
                 nrow(simResult), "iterations.")

library(ggplot2)

CEAC.SA <- 
  ggplot(data = NB, 
         mapping = aes(x = lambda, y = prob_CE, colour = j)) + 
  facet_wrap(Gender ~ Age) + 
  geom_line() + 
  geom_point() + 
  scale_color_brewer(palette = "Set1") + 
  labs(x = "Value of Ceiling Ratio (\U03BB)", 
       y = "Probability Cost-Effective", 
       title = "THR Model: Cost-Effectiveness Acceptability Curve", 
       subtitle = "All Scenarios") + 
  scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  theme_bw()

# Save Plot ====================================================================
ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "CEAC_SA.png"), 
       plot = CEAC.SA, 
       device = "png", 
       width = 10, 
       height = 5)
