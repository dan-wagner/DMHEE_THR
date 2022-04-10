# DMHEE_THR
The goal of this repo is to develop and execute the Total Hip Replacement (THR) 
model from the DMHEE textbook. This exercise was developed in response to the
observation that the textbook is written and organized for a spreadsheet 
environment. A different approach is required when using a programming language 
like R. 

Source Text: 
1. Briggs AH, Claxton K, Sculpher MJ. Decision modelling for health economic
evaluation. Oxford: Oxford University Press; 2006. 237 p. (Briggs A, Gray A, 
editors. Oxford handbooks in health economic evaluation). 

# Model Summary
Briggs et al. reported on the development of a Markov model which was used to 
predict the prognosis of patients who have undergone primary total hip 
replacement (THR) surgery (2). A diagrammatic representation of the model 
is presented below: 

![Structure of THR Markov Model](docs/Diagrams/THR-Model.png)

The model is conceptualized in terms of five Markov States: 

Primary THR (`PRI_THR`)
  : All patients begin the model with a primary THR procedure. 
  
Successful Primary (`PRI_Success`)
  : Patients transition to this state if their primary THR was successful. 
  
Revision THR (`REV_THR`)
  : This state represents those patients for whom a revision hip replacement is 
  required due to failure. Failure may be attributed to infection or loosening. 
  While patients can only remain in this state for one cycle, they can revisit 
  this state more than once. This is meant to reflect the fact that some 
  patients may require more than one revision operation. 
  
Successful Revision (`REV_Success`)
  : Patients transition to this state if their revision THR was successful. 
  
Death (`Death`)
  : The model assumes that patients can die at any point in the model. 
  Transitions can be attributed to operative mortality or the underlying risk of 
  death (given age and gender). 
  
The model assumes a cycle length of 1 year. It will be evaluated over time 
horizon of 60 years to estimate the lifetime costs and benefits of each 
intervention. Benefits of the intervention were measured in terms of Quality 
Adjusted Life Years. 

## Model Parameters

* Costing
  - Cost parameters were organized into two distinct groups: 
    - i) The unit cost for each prosthesis considered in the economic 
    evaluation. These values were originally obtained from manufacturer list 
    prices. 
    - ii) The costs incurred at each markov state. These values were identified 
    in a review of the different units involved in THR procedures. A successful 
    primary or revision THR was assumed to incur the same cost. Meanwhile, the 
    cost of a primary THR was set to 0 since all patients will travel through 
    this health state. The original review found that the cost of a revision 
    THR was 5294 GBP (SE 1487). 
* Utilities
  - According to the Briggs textbook, a study was initiated to identify the 
  utility weights subjects placed on different outcomes of THR. These outcomes 
  were directly related to the Markov States of the THR model. The respective 
  mean (SD) utilities were specified as: 
    - Successful Primary THR (`PRI_Success`): 0.85 (0.03)
    - Successful Revision THR (`REV_Success`): 0.75 (0.04)
    - Revision THR (`REV_THR`): 0.30 (0.03)


2. Briggs A, Sculpher M, Dawson J, Fitzpatrick R, Murray D, Malchau H. Modelling 
the cost-effectiveness of primary hip replacement: how cost-effective is the 
Spectron compared to the Charnley prosthesis? 2003 Dec;52. 


# Project Organization
TODO: Provide an explanation for how the project is organized here. 

# Progress
:white_check_mark: Complete
:warning: In-Progress
:x: Ice-Box.

## :warning: Develop THR Model

* :white_check_mark: Prepare Parameter Inputs from raw data. 
  - :white_check_mark: Transition Probabilities
    - :white_check_mark: Add raw data to `data/data-raw`. 
    - :white_check_mark: `getParams()` function to prepare parameter input list.
    - :white_check_mark: Generate Parameters from raw data. 
  - :white_check_mark: Costs
    - :white_check_mark: Add state costs to `data/data-raw`. 
    - :white_check_mark: Add costs for each prosthesis (`STD`, `NP1`).
    - :white_check_mark: Update `getParams()` to add new costing parameters. 
    - :white_check_mark: Re-generate `data/data-gen/Model-Params/THR-Params.rds` 
    with costing parameters. 
  - :white_check_mark: Utilities
    - :white_check_mark: Add raw data sets to `data/data-raw`. 
    - :white_check_mark: Update `getParams()` to add new utility parameters. 
    - :white_check_mark: Re-generate `data/data-gen/Model-Params/THR-Params.rds` 
    with utility parameters. 

* :white_check_mark: Develop Model Code | `runModel()`. 
  - :white_check_mark: Function to define the transition Matrix. `define_tmat()`. 
    - :white_check_mark: Time-Independent Model Parameters
    - :white_check_mark: Time-Dependent Model Parameters. `calc_TimeDeps()`
      - :white_check_mark: Age specific Mortality Risk `calc_MR`. 
      - :white_check_mark: Revision Risk as a function of Age, Sex, Time. `calc_RR()`. 
  - :white_check_mark: Function to track the cohort through the model. `track_cohort()`. 
  - :white_check_mark: Function to estimate Costs: `cohort_costs()`. 
      - :white_check_mark: Add discounting to `cohort_costs()` function. 
  - :white_check_mark: Function to estimate effects. `cohort_effects()`. Will return effects 
  measured in terms of Life Years (`LYs`) and QALYs (`QALY`). 
    - :white_check_mark: Add discounting to `cohort_effects()` function. 
  - :white_check_mark: Bundle Model Code into Single Function: `runModel()`. 
    - Returns costs and effects for a single prosthesis. 
    
* :white_check_mark: Add Probabilistic Capability. 
  - :white_check_mark: Add new function (`DrawParams()`) to draw values at 
  random based on assigned distribution. 
    - Include capability to switch to deterministic. 
  - :white_check_mark: Update Dependencies. 

* :white_check_mark: Add third prosthesis. 
  - :white_check_mark: Update Raw Data: 
    - `THR-Survival.rds` Add values for `NP2` to survival coefficients and the 
    covariance matrix. 
  - :white_check_mark: Modify dependencies for new values: 
    - :white_check_mark: `getParams()`. Add switch to include NP2 or not (`TRUE`/`FALSE`). 
      - :white_check_mark: Add NP2 prosthesis cost. 
    - :white_check_mark: Re-Load Parameter sets from raw data. 
      - :white_check_mark: Two Alternatives. 
      - :white_check_mark: Three Alternatives. 
      - Note: technically I could have just overwritten the original parameter 
      set data to add NP2 and could consider two or three alternatives anyhow. 
      In a production context, that is probably how I would go about doing it. 
    - :white_check_mark: `DrawParams()`. Change tolerance level for Multivariate normal draw. 

## :x: Simulations and Analysis
For the purposes of illustration, the model was evaluated using deterministic 
and probabilistic methods. In each approach, the model considered a time 
horizon of 60 years (60 cycles). In addition, costs and effects were discounted 
at 6% and 1.5%, respectively. 

The base case analysis was restricted to Females with a baseline age of 60. 
Scenario analyses were also performed for Females with baselines ages of 40 & 
80, and Males with baseline ages of 40, 60, & 80. Monte Carlo simulations were 
performed for each scenario configuration at 5,000 iterations. 

Consistent with the textbook structure, this repo considers two distinct 
decision problems: 
  1. Standard Prosthesis vs. New Prosthesis 1: 
  `STD-NP1`. 
  2. Stdandard Prosthesis vs. New Prosthesis 1 vs. New Prosthesis 2: 
  `STD-NP1-NP2`.
This will require additional sub-directories to keep simulation output and 
results separate from one another. 


### :warning: Simulations
For each decision problem, a total of 6 different model configurations must be 
evaluated. Females age 40, 60 (Base Case), and 80 as well as Males at the same 
ages. Data generated from the simulations listed below are stored in the 
following directories: 

  * 2 Alternatives: `data/data-gen/Simulation-Output/01_STD-v-NP1`. 
  * 3 Alternatives: `data/data-gen/Simulation-Output/02_STD-v-NP1-NP2`. 
  

**Comparing two alternative interventions: `STD-NP1`**

| Scenario        | MC Simulation                | Nested MC Simulation | 
| --------------- |:----------------------------:|:--------------------:|
| Female, 60 (BC) | :white_check_mark:           | :x:                  |
| Female, 40      | :white_check_mark:           | :x:                  |
| Female, 80      | :white_check_mark:           | :x:                  | 
| Male, 40        | :white_check_mark:           | :x:                  |
| Male, 60        | :white_check_mark:           | :x:                  |
| Male, 80        | :white_check_mark:           | :x:                  |

**Comparing three alternative interventions: `STD-NP1-NP2`**

| Scenario        | MC Simulation       | Nested MC Simulation | 
| --------------- |:-------------------:|:--------------------:|
| Female, 60 (BC) | :warning:           | :x:                  |
| Female, 40      | :warning:           | :x:                  |
| Female, 80      | :warning:           | :x:                  | 
| Male, 40        | :warning:           | :x:                  |
| Male, 60        | :warning:           | :x:                  |
| Male, 80        | :warning:           | :x:                  |

### :x: Analyses and Presentation of Results.
See `DOCUMENT-X` for complete model results for decision problem `STD-NP1`. 
See `DOCUMENT-Y` for complete model results for decision problem `STD-NP1-NP2`.

#### :x: Adoption Decision

  * :x: Deterministic: Calculate ICER. 
  * :x: Analysis and Presentation of Probabilistic Results. 
    - :x: Perform Incremental Analysis
    - :x: Net-Benefits Analysis. 
    - :x: Prepare CEA Results Table. 
    - :x: Plot Cost-Effectiveness Plane. 
    - :x: Plot CEAC. 

#### :x: Research Decision

  * :x: Implement VoI Methods. 
    - :x: Calculate EVPI (per patient and population). 
    - :x: Calculate EVPPI (per patient and population). 
    - :x: Plot EVPI and EVPPI as a function fo cost-effectiveness threshold. 
