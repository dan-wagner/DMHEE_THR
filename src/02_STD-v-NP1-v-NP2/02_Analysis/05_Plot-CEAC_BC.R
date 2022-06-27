# Plot Cost-Effectiveness Acceptability Curve
# Base Case Only

# Import Data ==================================================================
THR.3j.MC <- readr::read_rds(file = file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "02_STD-v-NP1-v-NP2", 
                                              "MC-Sim.rds"))

# Conduct NB Analysis ==========================================================
## Prepare Inputs --------------------------------------------------------------
LDA <- seq(from = 0, to = 50000, by = 5000)
## Calculate Net-Benefits ------------------------------------------------------
library(HEEToolkit)

NB <- nb_analysis(data = THR.3j.MC[,,,"Female","60"], 
                  lambda = LDA, 
                  Effects = "QALYs", 
                  nbType = "NMB")

# Plot CEAC ====================================================================
## Coerce NB Output to a tbl ---------------------------------------------------
PlotData <- tibble::as_tibble(x = NB, rownames = "j")
PlotData <- tidyr::pivot_longer(data = PlotData, 
                                cols = -"j", 
                                names_to = c("stat", "lambda"), 
                                names_sep = "\\.", 
                                names_transform = list(lambda = as.double),
                                values_to = "result")
PlotData <- tidyr::pivot_wider(data = PlotData, 
                               names_from = "stat", 
                               values_from = "result")
## Build Plot ------------------------------------------------------------------
Fig.Cap <- paste("Data generated from Monte Carlo simulation of", 
                 nrow(THR.3j.MC), "iterations.")

library(ggplot2)

CEAC.BC <- 
  ggplot(data = PlotData, 
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

# Save Plot ====================================================================
ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "CEAC_BC.png"), 
       plot = CEAC.BC, 
       device = "png", 
       width = 6.11, 
       height = 5)
