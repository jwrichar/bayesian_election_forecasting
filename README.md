# Presidential Election Forecasting

This codebase was developed as part of an Intro to Bayesian Inference class in 2012. The purpose of the code was to forecast the state-by-state result of the 2012 US Presidential Election between Barack Obama and Mitt Romney. The original code was developed in R using the JAGS package. Later, Python poll-scraping code was developed to forecast the 2016 and 2020 elections.

This codebase includes:

* Modeling code to forecast the election based on state-level polling data and past election results
* Utility code to scrape poll aggregation websites

## The Forecasting Model

The primary motivation for the model is from a 2010 paper from [Lock & Gelman](http://www.stat.columbia.edu/~gelman/research/published/election15Feb.pdf). In a nutshell, the model:

1. Considers all state- and national-level polls, using a likelihood function that models the state-level poll outcomes with parameters for both the overall national trend and state-level offsets from that trend.
2. Automatically estimates and adjusts for any pollster-level bias.
3. Down-weights older polls compared to more recent ones (based on the empirical estimate from the Lock & Gelman paper).
4. Uses the most recent presidential election results as informative prior information about each state’s voting tendency.

The model fitting is performed with Markov Chain Monte Carlo routines from the `rjags` package.

## Instructions

### To pull the most recent polling data:

NOTE: RCP has changed its website dramatically for the 2024 cycle, breaking the poll scraping code. We now recommend that you use the option `data_source='538'`:

To pull all the polls for 2024, run the following in Python:

    from source.poll_scraper import load_and_write_all_polls
    load_and_write_all_polls(2024, data_source='538', local_data=False)

### To run a model:

Modify model parameters, such as the prediction year and MCMC settings in `source/constants.R`.

    cd source/
    R CMD BATCH jags_model.R

