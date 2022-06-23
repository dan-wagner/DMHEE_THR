# Analyze Simulation Results
#   Adoption Decision
#   GOAL: Plot Cost-Effectiveness Plane

source(file.path("src", "FUNS", "checkFrontier.R"))

# Import Data ==================================================================
THR.3j.MC <- readr::read_rds(file = file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "02_STD-v-NP1-v-NP2", 
                                              "MC-Sim.rds"))

# Base Case: Female, Age 60 ====================================================
## Calculate Expected Values ---------------------------------------------------
EV <- colMeans(x = THR.3j.MC[,,,"Female","60"], dims = 1, na.rm = TRUE)
EV <- t(EV)

## Perform Incremental Analysis ------------------------------------------------
library(HEEToolkit)
PlotData <- inc_analysis(data = EV, Effects = "QALYs")
## ID j's on the Cost-Effectiveness Frontier -----------------------------------
PlotData <- checkFrontier(data = PlotData)
## Coerce Output to a tbl ------------------------------------------------------
PlotData <- tibble::as_tibble(x = PlotData, rownames = "j")

## Build Plot ------------------------------------------------------------------
library(ggplot2)

CEPlane.BC.MC <- 
  ggplot(data = PlotData, 
         mapping = aes(x = QALYs, y = Costs, color = j)) + 
  geom_path(data = PlotData, 
            mapping = aes(x = QALYs, y = Costs, group = onFrontier), 
            colour = "black", 
            size = 0.33) + 
  geom_point() + 
  theme_bw() + 
  scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  labs(title = "Cost-Effectiveness Plane for THR Model (Base Case)", 
       subtitle = "Females, Age 60: STD vs NP1 vs NP2", 
       caption = paste("Data generated from Monte Carlo simulation", 
                       "of 10,000 iterations."))

# Scenario Analyses ============================================================
## Calculate Expected Values ---------------------------------------------------
EV <- colMeans(x = THR.3j.MC, na.rm = TRUE, dims = 1)
EV <- aperm(a = EV, perm = c("j", "Result", "Gender", "Age"))
## Prepare Plot Data -----------------------------------------------------------
##  - Use Functional Programming tools to complete the following: 
##    - Perform incremental analyses
##    - ID j's which lie on the cost-effectiveness frontier
##    - Coerce Output to a single tbl

THR.Gender <- dimnames(EV)$Gender
names(THR.Gender) <- THR.Gender

THR.Age <- dimnames(EV)$Age
names(THR.Age) <- THR.Age

PlotData <- 
  purrr::map_dfr(.x = THR.Age, 
                 .f = \(age){
                   purrr::map_dfr(.x = THR.Gender, 
                                  .f = \(sex){
                                    result <- inc_analysis(data = EV[,,sex,age], 
                                                           Effects = "QALYs")
                                    result <- checkFrontier(data = result)
                                    tibble::as_tibble(x = result, rownames = "j")
                                  },
                                  .id = "Gender")
                 }, 
                 .id = "Age")

## Build Plot ------------------------------------------------------------------
library(ggplot2)

CEPlane.SA.MC <- 
  ggplot(data = PlotData, 
         mapping = aes(x = QALYs, y = Costs, color = j)) + 
  facet_wrap(Gender ~ Age) + 
  geom_path(data = PlotData, 
            mapping = aes(x = QALYs, y = Costs, group = onFrontier), 
            colour = "black", 
            size = 0.33) + 
  geom_point() + 
  scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  theme_bw() + 
  labs(title = "Cost-Effectiveness Plane for THR Model", 
       subtitle = "All Scenarios: STD vs NP1 vs NP2", 
       caption = paste0(paste("Data generated from a Monte Carlo simulation", 
                              "of 10,000 iterations."), 
                        "\n", 
                        "Unusual frontiers due to graph scaling."))

# Save Results to disk ========================================================
ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "CE-Plane_BC_MC.png"), 
       plot = CEPlane.BC.MC, 
       width = 5, 
       height = 4)

ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "CE-Plane_SA_MC.png"), 
       plot = CEPlane.SA.MC, 
       width = 10, 
       height = 8)





  
