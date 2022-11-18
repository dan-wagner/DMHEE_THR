# Analyze Simulation Results
#   Adoption Decision
#   GOAL: Plot Cost-Effectiveness Plane
source(file.path("src", "FUNS", "checkFrontier.R"))

# Import Data ==================================================================
THR.3j.D <- readr::read_rds(file = file.path("data", 
                                             "data-gen", 
                                             "Simulation-Output", 
                                             "02_STD-v-NP1-v-NP2", 
                                             "THR_Deter.rds"))

# Generate Plot (Deterministic) ================================================
## Base Case: Female, Age 60 ---------------------------------------------------
### Perform Incremental Analysis
###   - Required to construct Cost-Effectiveness Frontier.
library(HEEToolkit)
PlotData <- inc_analysis(data = THR.3j.D[,,"Female","60"], 
                         effect_measure = "QALYs")
### Identify j's which sit on the Cost-Effectiveness Frontier.
PlotData <- checkFrontier(data = PlotData)
### Coerce output to a tbl.
PlotData <- tibble::as_tibble(x = PlotData, rownames = "j")

### Build Plot
library(ggplot2)

CEPlane.BC.D <- 
  ggplot(data = PlotData, 
         mapping = aes(x = QALYs, y = Costs, color = j)) + 
  geom_path(data = PlotData, 
            mapping = aes(x = QALYs, y = Costs, group = onFrontier), 
            colour = "black", 
            size = 0.33) + 
  geom_point() + 
  theme_bw() + 
  scale_y_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  theme_bw() + 
  labs(title = "Cost-Effectiveness Plane for THR Model (Base Case)", 
       subtitle = "Females, Age 60: STD vs NP1 vs NP2", 
       caption = "Data generated deterministically")

## Scenarios -------------------------------------------------------------------
### Perform Incremental Analysis on each Sub-Group
###   -Then identify J's on the cost-effectiveness frontier. 
###   -Coerce Output to tbl
THR.Gender <- dimnames(THR.3j.D)$Gender
names(THR.Gender) <- THR.Gender

THR.Age <- dimnames(THR.3j.D)$Age
names(THR.Age) <- THR.Age

PlotData <- 
purrr::map_dfr(.x = THR.Age, 
               .f = \(age){
                 purrr::map_dfr(.x = THR.Gender, 
                                .f = \(sex){
                                  result <- inc_analysis(data = THR.3j.D[,,sex,age], 
                                                         effect_measure = "QALYs")
                                  result <- checkFrontier(data = result)
                                  tibble::as_tibble(x = result, rownames = "j")
                                  },
                                .id = "Gender")
                 }, 
               .id = "Age")



CEPlane.SA.D <- 
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
       caption = paste0("Data generated deterministically", 
                        "\n", 
                        "Unusual frontiers due to graph scaling."))

# Save Images to results dir ===================================================
ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "CE-Plane_BC_Deter.png"), 
       plot = CEPlane.BC.D, 
       width = 5, 
       height = 4)

ggsave(filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "CE-Plane_SA_Deter.png"), 
       plot = CEPlane.SA.D, 
       width = 10, 
       height = 8)



  
