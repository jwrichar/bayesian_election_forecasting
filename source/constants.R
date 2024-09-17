
data_path = normalizePath("../data")


##########################################
# Basic data for election model:
year = 2024
election_day = as.POSIXlt("2024-11-05")


##########################################
# MCMC Parameters
n_chains = 3
n_adapt = 200
n_burnin = 200
n_iter = 10000
thin = 1


##########################################
# Priors
# Which past elec years to use for state-wise priors:
past_elec_years = c(2020, 2016, 2012, 2008, 2004)
# How many national polls to use for modeling:
n_latest_national_polls = 25


##########################################
# Static data
states = read.table(paste(data_path, "/state_abbreviations.txt", sep=""), header=FALSE)
state.abbrs = states[,2]
