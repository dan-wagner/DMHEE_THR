# Research Decision
# Calculate EVPI Statistic
# 01) Import Data ==============================================================
VoI <- readr::read_rds(file = file.path("data", 
                                        "data-gen", 
                                        "VoI-Results", 
                                        "02_STD-v-NP1-v-NP2", 
                                        "VoI_EVPI-EVPPI.rds"))


# Subset data of Interest: EVPI Only
VoI <- dplyr::filter(.data = VoI, 
                     VoI.stat == "EVPI")

# Build Plot =============

library(ggplot2)

EVPI.plot <- 
  ggplot(data = VoI, 
         mapping = aes(x = lambda, 
                       y = Pop)) + 
  facet_wrap(Gender ~ Age) + 
  theme_bw() + 
  geom_line() +
  scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  labs(title = "Population EVPI", 
       subtitle = "THR Model: STD vs NP1 vs NP2", 
       x = "Threshold Ratio (\U03BB)", 
       y = "Population EVPI")

# Export Plot
ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "VoI_EVPI.png"), 
       plot = EVPI.plot, 
       device = "png", 
       width = 10, 
       height = 10)



