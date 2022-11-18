# Analyze Simulation Results
#   Adoption Decision
#   GOAL: Plot Cost-Effectiveness Plane

# Import Data ==================================================================
THR.2j.MC <- readr::read_rds(file = file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "01_STD-v-NP1", 
                                              "MC-Sim.rds"))

# Prepare Input Data ===========================================================
LDA.seq <- seq(from = 0, to = 50000, by = 5000)
## Calculate Net-Benefits ------------------------------------------------------
library(HEEToolkit)

NB <- nb_analysis(data = THR.2j.MC[,,,"Female","60"], 
                  lambda = LDA.seq, 
                  effect_measure = "QALYs", 
                  nbType = "NMB")

## Coerce Into tbl -------------------------------------------------------------
NB <- tibble::as_tibble(x = NB, rownames = "j")
NB <- tidyr::pivot_longer(data = NB, 
                          cols = -"j", 
                          names_to = c("stat", "lambda"), 
                          names_sep = "\\.", 
                          names_transform = list(lambda = as.double),
                          values_to = "output") |> 
  tidyr::pivot_wider(names_from = "stat", values_from = "output")

# Build Plot ===================================================================
library(ggplot2)

Fig.Cap <- paste("Data generated from Monte Carlo simulation of", 
                 nrow(THR.2j.MC), "iterations.")

CEAC.BC <- 
  ggplot(data = NB, 
         mapping = aes(x = lambda, y = prob_CE, colour = j)) + 
  geom_line() + 
  geom_point() + 
  labs(x = "Value of Ceiling Ratio (\U03BB)", 
       y = "Probability Cost-Effective", 
       caption = Fig.Cap, 
       title = "THR Model: Cost-Effectiveness Acceptability Curve", 
       subtitle = "Base Case: Females, Age 60") + 
  scale_color_brewer(palette = "Set1") + 
  scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  theme_bw()

ggsave(filename = file.path("results", 
                            "01_STD-v-NP1", 
                            "CEAC_BC.png"), 
       plot = CEAC.BC,
       device = "png", 
       width = 6.11, 
       height = 4.93)


