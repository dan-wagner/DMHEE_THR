# Analyze Simulation Results
#   Adoption Decision
#   GOAL: Plot Cost-Effectiveness Plane

source(file.path("src", "FUNS", "Plots.R"))

# Import Data ==================================================================
THR.2j.MC <- readr::read_rds(file = file.path("data", 
                                           "data-gen", 
                                           "Simulation-Output", 
                                           "01_STD-v-NP1", 
                                           "THR_MC-Sim_5000.rds"))
THR.2j.D <- readr::read_rds(file = file.path("data", 
                                             "data-gen", 
                                             "Simulation-Output", 
                                             "01_STD-v-NP1", 
                                             "THR_Deter.rds"))

# Generate Plot ================================================================
## Base Case: Female, Age 60 ---------------------------------------------------
CEplane.BC.D <- viz_CEPlane(data = THR.2j.D[,,"Female","60"], 
                        Effect = "QALYs", 
                        Currency = "GBP", 
                        show.EV = FALSE)
CEplane.BC.D <- 
  CEplane.BC.D + 
  ggplot2::ggtitle(label = "Cost Effectiveness Plane for THR Model (Base Case)", 
                   subtitle = paste("Comparison: NP1 vs. STD Prosthesis", 
                                    "for Females, Age 60."))

ggplot2::ggsave(filename = file.path("results", 
                                     "01_STD-v-NP1",
                                     "CE-Plane_BC_Deter.png"), 
                plot = CEplane.BC.D, 
                device = "png", 
                width = 5.73, 
                height = 4.68)


CEplane.BC.MC <- viz_CEPlane(data = THR.2j.MC[,,,"Female","60"], 
                         Effect = "QALYs", 
                         Currency = "GBP", 
                         show.EV = TRUE, 
                         lambda = NULL)
CEplane.BC.MC <- 
  CEplane.BC.MC + 
  ggplot2::ggtitle(label = "Cost Effectiveness Plane for THR Model (Base Case)", 
                   subtitle = paste("Comparison: NP1 vs. STD Prosthesis", 
                                    "for Females, Age 60."))

ggplot2::ggsave(filename = file.path("results", 
                                     "01_STD-v-NP1",
                                     "CE-Plane_BC_MC.png"), 
                plot = CEplane.BC.MC, 
                device = "png", 
                width = 5.73, 
                height = 4.68)

## Scenario Analyses: All Genders & Ages ---------------------------------------
CEplane.SA.D <- viz_CEPlane(data = THR.2j.D, 
                            Effect = "QALYs", 
                            Currency = "GBP", 
                            show.EV = FALSE, 
                            lambda = NULL)

CEplane.SA.D <- 
  CEplane.SA.D + 
  ggplot2::facet_wrap(Gender ~ Age) + 
  ggplot2::ggtitle(label = "THR Results Plotted on the Cost-Effectiveness Plane.", 
                   subtitle = paste("Comparison: NP1 vs. STD Prosthesis", 
                                    "for all scenario configurations."))

ggplot2::ggsave(filename = file.path("results", 
                                     "01_STD-v-NP1", 
                                     "CE-Plane_All-Scenarios_Deter.png"), 
                plot = CEplane.SA.D, 
                device = "png", 
                width = 5.73, 
                height = 4.68)

CEplane.SA.MC <- viz_CEPlane(data = THR.2j.MC, 
                             Effect = "QALYs", 
                             Currency = "GBP", 
                             show.EV = TRUE, 
                             lambda = NULL)

CEplane.SA.MC <- 
  CEplane.SA.MC + 
  ggplot2::facet_wrap(Gender ~ Age) + 
  ggplot2::ggtitle(label = "THR Results Plotted on the Cost-Effectiveness Plane.", 
                   subtitle = paste("Comparison: NP1 vs. STD Prosthesis for", 
                                    "all scenario configurations."))

ggplot2::ggsave(filename = file.path("results", 
                                     "01_STD-v-NP1", 
                                     "CE-Plane_All-Scenarios_MC.png"), 
                plot = CEplane.SA.MC, 
                device = "png", 
                width = 5.73, 
                height = 4.68)



#viz_CEPlane(data = THR.2j.D, Currency = "GBP", show.EV = FALSE) + 
#  ggplot2::facet_wrap(Gender ~ Age) + 
#  ggplot2::geom_hline(yintercept = 0) + 
#  ggplot2::geom_vline(xintercept = 0)
#
#viz_CEPlane(data = THR.2j.D[,,2,2], 
#            Currency = "GBP", 
#            show.EV = FALSE, 
#            lambda = NULL) + 
#  ggplot2::geom_hline(yintercept = 0) + 
#  ggplot2::geom_vline(xintercept = 0)
#
#viz_CEPlane(data = THR.2j.MC, 
#            Currency = "GBP", 
#            show.EV = TRUE, 
#            lambda = NULL) + 
#  ggplot2::facet_wrap(Gender ~ Age) + 
#  ggplot2::geom_hline(yintercept = 0) + 
#  ggplot2::geom_vline(xintercept = 0)
#
#viz_CEPlane(data = THR.2j.MC[,,,2,2], 
#            Currency = "GBP", 
#            show.EV = TRUE) + 
#  ggplot2::geom_hline(yintercept = 0) + 
#  ggplot2::geom_vline(xintercept = 0)


## Base Case -------------------------------------------------------------------
viz_CEplane(data = THR.2j[,,,"Female","60"], 
            Effect = "QALYs", 
            Currency = "GBP", 
            show.EV = TRUE, 
            lambda = NULL)


