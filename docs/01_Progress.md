# Progress

This document summarizes the sequence of tasks that were required to
redevelop the THR model in a reproducible fashion. 

Status indicators for each task (or sub-task) are defined as: 

:white_check_mark: Complete
:warning: In-Progress
:x: Ice-Box

| Task                                     | Status             | 
|-----------------------------------------|:------------------:|
| [Model Development](#model-development) | :white_check_mark:  | 
| [Monte Carlo Simulations](#monte-carlo-simulations) | :white_check_mark: | 
| [Nested Monte Carlo Simulations](#nested-monte-carlo-simulations)  | :white_check_mark: |
| :arrow_right: [`STD-v-NP1`](#decision-problem-1) | :white_check_mark: | 
| :arrow_right: [`STD-v-NP1-v-NP2`](#decision-problem-2) | :white_check_mark: |
| Analysis: [Adoption Decision](#adoption-decision) | :white_check_mark: | 
| Analysis: [Research Decision](#research-decision) | :white_check_mark: | 

# Model Development
Put a summary statement here. 

## Prepare Parameter Inputs from Raw Data
**STATUS:** :white_check_mark:

* Transition Probabilities
  - :white_check_mark: Add health state count data to to `data/data-raw`
* Costs
  - :white_check_mark: Add health state costs to `data/data-raw`
  - :white_check_mark: Add costs for each prosthesis (`STD`, `NP1`)
* Utilities
  - :white_check_mark: Store utility values for each health state in 
  `data/data-raw`. 
* :white_check_mark: Define Function that returns simulation ready model 
parameters. 

## Model Implementation
**STATUS:** :white_check_mark:

* :white_check_mark: Write function to define the transition matrix. 
  - :white_check_mark: Time-Independent Model Parameters
  - :white_check_mark: Time-Dependent Model Parameters. 
    - :white_check_mark: Function to calculate age-specific mortality risk 
    (`calc_MR`). 
    - :white_check_mark: Function returning revision risk as a function of Age, 
    Sex, and Time (`calc_RR`). 
* :white_check_mark: Function to track the cohort through the model. 
`track_cohort()`. 
* :white_check_mark: Function to estimate discounted costs, `cohort_costs()`. 
* :white_check_mark: Function to estimate effects, `cohort_effects()`. 
  - Will return effects measured in terms of Life Years (`LYs`) and (`QALYs)`. 
* :white_check_mark: Define a single modularized function to evaluate 
a single arm of the decision model. `runModel()`. 
  - Returns costs and effects for a single prosthesis. 

## Add Probabilistic Capability
**STATUS:** :white_check_mark:

* :white_check_mark: Add function to draw values at random based on 
assumed distributions. 
  - Include capability to switch between deterministic and probabilistic output. 

## Add Third Prosthesis
**STATUS:** :white_check_mark:

* :white_check_mark: Update Raw Data to include values for `NP2`. 
  - :white_check_mark: Update `data/data-raw/THR-Survival.rds`
    - Add values for `NP2` to survival coefficients and the covariance matrix. 
    - Stored as a separate data set, due to requirements for this 
    exercise. In a production context, would likely want to overwrite 
    the original data set to add the new NP2 values. 
* :white_check_mark: Modify Dependencies in `get_Params()` function. 
  - :white_check_mark: Add switch to include NP2 or not. 
  - :white_check_mark: Add NP2 prosthesis cost. 
* :white_check_mark: Re-load parameter sets from raw data. 
  - :white_check_mark: Two alternatives. 
  - :white_check_mark: Three alternatives. 
* :white_check_mark: Modify Dependencies in `DrawParams()` function. 
  - When comparing three alternatives, change the tolerance level for 
  the Multivariate normal draw. 

# Simulations and Analyses

Consistent with the textbook instructions, this repo considers two distinct 
decision problems: 
  1. Standard Prosthesis vs New Prosthesis 1: `STD-v-NP1`. 
  2. Standard Prosthesis vs New Prosthesis 1 vs New Prosthesis 2: 
  `STD-v-NP1-v-NP2`. 
  
For each decision problem, 6 different model configurations had to be 
evaluated. Females and males with a baseline age of 40, 60, or 80 years. As 
with the textbook, the base case was assumed to represent females with a 
baseline age of 60. 

## Monte Carlo Simulations
The output of a Monte Carlo simulation is used to inform the adoption and 
research decisions. It represents the repeated evaluation of a decision model 
using parameter values drawn at random from assigned distributions. For an 
adoption decision, the generated distributions of cost and effect can be used to 
analyze cost-effectiveness through an *incremental analysis* or an analysis of 
*net-benefits*. For a research decision, this same output is used to estimate 
the EVPI statistic in a Value of Information (VoI) analysis. 

Given the time consuming nature of each simulation, output data were preserved 
in the `data/data-gen` sub-directory. 

| Scenario        | MC `STD-v-NP1`      | MC `STD-v-NP1-v-NP2` | 
|-----------------|:-------------------:|:--------------------:|
| Female, 60 (BC) | :white_check_mark:  |:white_check_mark:    | 
| Female, 40      | :white_check_mark:  |:white_check_mark:    | 
| Female, 80      | :white_check_mark:  |:white_check_mark:    |  
| Male, 40        | :white_check_mark:  |:white_check_mark:    | 
| Male, 60        | :white_check_mark:  |:white_check_mark:    | 
| Male, 80        | :white_check_mark:  |:white_check_mark:    | 

## Nested Monte Carlo Simulations
Nested Monte Carlo simulations are used to generate distributions of 
costs and effects in order to estimate the EVPI for a specific parameter. This 
*EVPPI* statistic is required in a VoI analysis. 

Given the time consuming nature of this simulation, output data were preserved 
in the `data/data-gen` sub-directory. 

### Decision Problem 1
Alternatives Compared: `STD-v-NP1`

| Scenario        | &phi; = OMR  | &phi; = RRR  | &phi; = Survival | &phi; = Costs | &phi; = Utilities |
| --------------- |:--------------------:|:-------------------:|:-----------------------:|:--------------------:|:------------------------:|
| Female, 60 (BC) | :white_check_mark:   | :white_check_mark:  | :white_check_mark:      |:white_check_mark:    |:white_check_mark:        |
| Female, 40      | :white_check_mark:   | :white_check_mark:  | :white_check_mark:      |:white_check_mark:    |:white_check_mark:        |
| Female, 80      | :white_check_mark:   | :white_check_mark:  | :white_check_mark:      |:white_check_mark:    |:white_check_mark:        | 
| Male, 40        | :white_check_mark:   | :white_check_mark:  | :white_check_mark:      |:white_check_mark:    |:white_check_mark:        |
| Male, 60        | :white_check_mark:   | :white_check_mark:  | :white_check_mark:      |:white_check_mark:    |:white_check_mark:        |
| Male, 80        | :white_check_mark:   | :white_check_mark:  | :white_check_mark:      |:white_check_mark:    |:white_check_mark:        |

### Decision Problem 2 
Alternatives Compared: `STD-v-NP1-v-NP2`

| Scenario        | &phi; = OMR  | &phi; = RRR  | &phi; = Survival | &phi; = Costs | &phi; = Utilities |
| --------------- |:-------------:|:-------------:|:-----------------:|:--------------:|:------------------:|
| Female, 60 (BC) | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |:white_check_mark: |
| Female, 40      | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |:white_check_mark: |
| Female, 80      | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |:white_check_mark: | 
| Male, 40        | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |:white_check_mark: |
| Male, 60        | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |:white_check_mark: |
| Male, 80        | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |:white_check_mark: |

## Analyses

### Adoption Decision

| Task                       | `STD-v-NP1` | `STD-v-NP1-v-NP2` | 
|----------------------------|:--------------:|:-----------------------:|
| *DETERMINISTIC RESULTS*    | :white_check_mark:  | :white_check_mark: | 
| :arrow_right: Display Table: Incremental Analysis- Base Case | :white_check_mark: | :white_check_mark: | 
| :arrow_right: Display Table: Incremental Analysis- All Scenarios | :white_check_mark: | :white_check_mark: | 
| *PROBABILISTIC RESULTS*    | :white_check_mark: | :white_check_mark:      | 
| :arrow_right: Display Table: CEA Results - Base Case | :white_check_mark: | :white_check_mark:      | 
| :arrow_right: Display Table: CEA Results - All Scenarios | :white_check_mark: | :white_check_mark:    | 
| :arrow_right: Plot: CE Plane - Base Case  | :white_check_mark: | :white_check_mark: | 
| :arrow_right: Plot: CE Plane - All Scenarios | :white_check_mark: | :white_check_mark: | 
| :arrow_right: Plot CEAC - Base Case | :white_check_mark: | :white_check_mark: | 
| :arrow_right: Plot CEAC - All Scenarios | :white_check_mark: | :white_check_mark: | 

### Research Decision

| Task | `STD-v-NP1`        | `STD-v-NP1-v-NP2` | 
| ---  | :----------------: | ----------------------- | 
| EVPI | :white_check_mark: | :white_check_mark:      | 
| :arrow_right: Calculate EVPI for all subgroups | :white_check_mark: | :white_check_mark: | 
| :arrow_right: Plot Population EVPI | :white_check_mark: | :white_check_mark: | 
| EVPPI | :white_check_mark:| :white_check_mark: | 
| :arrow_right: &phi; = "OMR" | :white_check_mark: | :white_check_mark: | 
| :arrow_right: &phi; = "RRR" | :white_check_mark: | :white_check_mark: | 
| :arrow_right: &phi; = "Survival" | :white_check_mark: | :white_check_mark: | 
| :arrow_right: &phi; = "Cost_States" | :white_check_mark: | :white_check_mark: | 
| :arrow_right: &phi; = "Utilities" | :white_check_mark: | :white_check_mark: | 
