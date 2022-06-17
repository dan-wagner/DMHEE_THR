# DMHEE_THR
This repo is a redevelopment of the Total Hip Replacement (THR) model from the 
DMHEE textbook [^1] following strategies for reproducibility. The relevant 
methodological sequence was organized into an automated workflow which was 
designed to capture the procedures of the economic evaluation as well as those 
used to estimate the parameter inputs. 

This effort was initiated in response to the fact that the original textbook 
exercises are designed and organized for a spreadsheet environment. Adapting 
this project ot a programming language (`R`) offered the ability to show how 
this model could be developed in a reproducible fashion. A collection of 
previously identified strategies for reproducibility were used to achieve a 
level of reproducibility that would allow for the reliable re-generation of 
results, including intermediate data sets. 

# Model Summary
Briggs et al. reported on the development of a Markov model which was used to 
predict the prognosis of patients who have undergone primary total hip 
replacement (THR) surgery [^2]. A diagrammatic representation of the model 
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


# Project Organization
TODO: Provide an explanation for how the project is organized here. 

```
PROJECT-DIRECTORY
|-data\
|   |-data-raw\
|   |-data-gen\
|     |-Model-Params\
|     |-Simulation-Output\
|-docs\
|-results\
|-src\
|   |-FUNS\
|   |-01_Simulations
|   |-02_Analysis
```

# Documentation

* [Documentation on Re-Development Progress](docs/01_Progress.md)


# Notes

  * :information_source: Add Function to return Display Table for  
  Cost-Effectiveness Results. 
    - There is a considerable amount of code duplication. 
    - Requirements: 
      - Deterministic vs probabilistic output. 
      - Scenarios as row groups. 
      

[^1]: Briggs AH, Claxton K, Sculpher MJ. Decision modelling for health economic
evaluation. Oxford: Oxford University Press; 2006. 237 p. (Briggs A, Gray A, 
editors. Oxford handbooks in health economic evaluation). 
[^2]: Briggs A, Sculpher M, Dawson J, Fitzpatrick R, Murray D, Malchau H. 
Modelling the cost-effectiveness of primary hip replacement: how cost-effective 
is the Spectron compared to the Charnley prosthesis? 2003 Dec;52. 