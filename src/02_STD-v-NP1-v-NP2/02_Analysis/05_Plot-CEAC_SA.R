# Plot Cost-Effectiveness Acceptability Curve
# All Scenarios

# Import Data ==================================================================
THR.3j.MC <- readr::read_rds(file = file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "02_STD-v-NP1-v-NP2", 
                                              "THR_MC-Sim_5000.rds"))

# Conduct NB Analysis ==========================================================
## Prepare Inputs --------------------------------------------------------------
LDA <- seq(from = 0, to = 50000, by = 5000)
## Calculate Net-Benefits ------------------------------------------------------
library(HEEToolkit)
THR.Age <- dimnames(THR.3j.MC)$Age
names(THR.Age) <- THR.Age

THR.Gender <- dimnames(THR.3j.MC)$Gender
names(THR.Gender) <- THR.Gender

NB <- 
sapply(X = THR.Age, 
       FUN = \(Age){
         sapply(X = THR.Gender, 
                FUN = \(Gender){
                  nb_analysis(data = THR.3j.MC[,,,Gender,Age], 
                              lambda = LDA, 
                              Effects = "QALYs", 
                              type = "NMB")
                }, 
                simplify = "array")
       }, 
       simplify = "array")

names(dimnames(NB))[c(4,5)] <- c("Gender", "Age")

# Plot CEAC ====================================================================
## Coerce NB Output to a tbl ---------------------------------------------------
PlotData <- tibble::as_tibble(x = NB, rownames = "j")
PlotData <- tidyr::pivot_longer(data = PlotData, 
                                cols = -"j", 
                                names_to = c("stat", "lambda", "Gender", "Age"), 
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

CEAC.SA <- 
  ggplot(data = PlotData, 
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
