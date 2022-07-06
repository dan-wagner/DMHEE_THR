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

Input.Gender <- dimnames(THR.2j.MC)[[4]]
names(Input.Gender) <- Input.Gender
Input.Age <- dimnames(THR.2j.MC)[[5]]
names(Input.Age) <- Input.Age



NB <- lapply(X = Input.Age, 
       FUN = \(age){
         lapply(X = Input.Gender,
                FUN = \(sex){
                  nb_analysis(data = THR.2j.MC[,,,sex,age], 
                              lambda = LDA.seq, 
                              Effects = "QALYs", 
                              nbType = "NMB", 
                              show.error = FALSE)
                })
       })

## Coerce Into tbl -------------------------------------------------------------
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

# Build Plot ===================================================================
library(ggplot2)

Fig.Cap <- paste("Data generated from Monte Carlo simulation of", 
                 nrow(THR.2j.MC), "iterations.")

CEAC.All <- 
  ggplot(data = NB, 
         mapping = aes(x = lambda, y = prob_CE, colour = j)) + 
  geom_line() + 
  geom_point() + 
  facet_wrap(facets = ~ Gender + Age) + 
  labs(x = "Value of Ceiling Ratio (\U03BB)", 
       y = "Probability Cost-Effective", 
       caption = Fig.Cap, 
       title = "THR Model: Cost-Effectiveness Acceptability Curves", 
       subtitle = "All Scenarios") + 
  scale_color_brewer(palette = "Set1") + 
  scale_x_continuous(labels = scales::label_dollar(prefix = "\U00A3")) + 
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 0.75))

ggsave(filename = file.path("results", 
                            "01_STD-v-NP1", 
                            "CEAC_All-Scenarios.png"), 
       plot = CEAC.All,
       device = "png",
       width = 8.45, 
       height = 5.92)


