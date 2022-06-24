# Research Decision
# Generate Plot of Population EVPPI as a function of 
# cost-effectiveness threshold

# Import Data ==================================================================
VoI <- readr::read_rds(file = file.path("data", 
                                        "data-gen", 
                                        "VoI-Results", 
                                        "02_STD-v-NP1-v-NP2", 
                                        "VoI_EVPI-EVPPI.rds"))

## Subset Data of Interest: EVPPI Only -----------------------------------------
VoI <- dplyr::filter(.data = VoI, 
                     VoI.stat == "EVPPI")

# Plot 1: Age and Gender Facets
library(ggplot2)

EVPPI.Plot <- 
  ggplot(data = VoI, 
         mapping = aes(x = lambda, 
                       y = Pop, 
                       colour = PHI)) + 
  facet_wrap(Gender ~ Age) + 
  theme_bw() + 
  geom_line() + 
  scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  labs(title = "THR Model: Population EVPPI", 
       subtitle = "Comparators: STD vs NP1 vs NP2", 
       x = "Threshold Ratio (\U03BB)", 
       y = "Population EVPPI", 
       colour = "\U03c6")

ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "VoI_EVPPI.png"), 
       plot = EVPPI.Plot, 
       device = "png", 
       width = 10, 
       height = 10)

## 2) Sub-Group plots by Age ---------------------------------------------------
##    - Single Facet: Gender

AG <- unique(VoI$Age)

for (i in seq_along(AG)) {
  EVPPI.plot.Age <- 
    ggplot(data = dplyr::filter(VoI, Age == AG[i]), 
           mapping = aes(x = lambda, 
                         y = Pop, 
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