# Research Decision
# Calculate EVPI Statistic
# 01) Import Data ==============================================================
THR_result <- readr::read_rds(file = file.path("data", 
                                               "data-gen", 
                                               "Simulation-Output", 
                                               "01_STD-v-NP1", 
                                               "THR_MC-Sim_5000.rds"))

# 02) Estimate EVPI ============================================================
library(HEEToolkit)

## Calculate Effective Population Size -----------------------------------------
##    From Textbook: 
##      "For the Hip replacement example, we are going to assume an effective 
##       technology life of 10 years with 40,000 new patients eligible for 
##       treatment each year."
EP <- voi_EP(Yrs = 10, I_t = 20000, DR = 0.03)

## Estimate EVPI for Each Sub-Group -------------------------------------------
LDA <- seq(from = 0, to = 50000, by = 5000)

THR.Age <- dimnames(THR_result)$Age
THR.Gender <- dimnames(THR_result)$Gender
names(THR.Age) <- THR.Age
names(THR.Gender) <- THR.Gender

EVPI <- 
sapply(X = THR.Age, 
       FUN = \(Age){
         sapply(X = THR.Gender, 
                FUN = \(Gender){
                  calc_EVPI(data = THR_result[,,,Gender,Age], 
                            lambda = LDA, 
                            EffPop = EP, 
                            Effects = "QALYs", 
                            nbType = "NMB")
                }, 
                simplify = "array")
       }, 
       simplify = "array")

names(dimnames(EVPI))[c(3,4)] <- c("Gender", "Age")

# Build Plot =============

PlotData <- tibble::as_tibble(x = EVPI, rownames = "lambda")
PlotData <- dplyr::mutate(PlotData, lambda = as.double(lambda))
PlotData <- tidyr::pivot_longer(data = PlotData, 
                                cols = -"lambda", 
                                names_to = c("stat", "Gender", "Age"), 
                                names_sep = "\\.", 
                                values_to = "Result"
                                )
PlotData <- tidyr::pivot_wider(data = PlotData, 
                               names_from = "stat", 
                               values_from = "Result")

library(ggplot2)

EVPI.plot <- 
ggplot(data = PlotData, 
       mapping = aes(x = lambda, 
                     y = EVPIpop)) + 
  facet_wrap(Gender ~ Age) + 
  theme_bw() + 
  geom_line() + 
  scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  labs(title = "Population EVPI", 
       subtitle = "THR Model: STD vs NP1", 
       x = "Threshold Ratio (\U03BB)", 
       y = "Population EVPI")

# Export Plot
ggsave(filename = file.path("results", 
                            "01_STD-v-NP1", 
                            "VoI_EVPI.png"), 
       plot = EVPI.plot, 
       device = "png", 
       width = 10, 
       height = 10)



