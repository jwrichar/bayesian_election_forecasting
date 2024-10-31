path = normalizePath(".")
library(rjags)

##########################################
# THE DATA.

# source all of the data:
source(paste(path,"/constants.R",sep=""))
source(paste(path,"/load_polls.R",sep=""))
source(paste(path,"/load_prior.R",sep=""))

# if there's few or no polls, reduce the prior variance (non-battleground states)
p0.var[p0.var > 0.0002 & Nmax<2] = 0.0002

# Specify the data in R, using a list format 
# compatible with JAGS:
dataList = list(
  p0mean = p0.mean, p0var = p0.var,
  N = N, Pdem = Pdem, Npolls = Npolls,
  Ndays = days2elec, pollster = pollster,
  Pdem.nat = Pdem.nat, N.nat=N.nat,
  M = length(N.nat),
  N_pollsters = max(pollster, na.rm=TRUE)
)

###########################################
# THE MODEL

# Note: JAGS uses precision (1 / variance) for dnorm spread parameter

modelString = "
model {
# Likelihood for state-level polls:
  for ( i in 1:51 ) {
     # prior for state i
     theta[i] ~ dnorm(p0mean[i], 1/p0var[i])
        for ( j in 1:Npolls[i]){
          Pdem[i,j] ~ dnorm(mu + theta[i] + del[pollster[i,j]],
            1 / ((mu + theta[i] + del[pollster[i,j]])*(1 - mu - theta[i] - del[pollster[i,j]])/N[i,j] +
            0.02^2*Ndays[i,j]/30 + 0.05^2))T(0,1)
     }
   }
 # prior on pollster-level data
 for ( k in 1:N_pollsters){
   del[k] ~ dnorm(0,1/0.05^2)
}
 # likelihood of national level data
 for(m in 1:M){ # number of national polls used
   Pdem.nat[m] ~ dnorm(mu, 1/(mu*(1-mu)/N.nat[m]))
}
 # prior for national level parameter
 mu ~ dnorm(0.5, 1/0.005^2)

}" 

# Write the modelString to a file, using R commands:
writeLines(modelString, con="election_model.txt")

##########################################
# RUN THE CHAINS.

parameters = c("theta" , "del", "mu") # parameters to be monitored.

# This line creates, initialize, and adapt the model:
jagsModel = jags.model("election_model.txt" ,
                       data=dataList,
                       n.chains=n_chains,
                       n.adapt=n_adapt)

# Burn-in (until convergence):
cat("Burning in the MCMC chain...\n")
update(jagsModel,
       n.iter=n_burnin)

# Now sample the saved MCMC chain:
cat("Sampling final MCMC chain...\n")
codaSamples = coda.samples(jagsModel ,
                           variable.names=parameters, 
                           n.iter=n_iter,
                           thin=thin)


##########################################
# EXAMINE THE RESULTS

#traceplot(codaSamples)

# posterior samples:
postSamp = as.matrix(codaSamples)

delSamp = postSamp[,1:dataList$N_pollsters]
muSamp = postSamp[,(dataList$N_pollsters + 1)]
stateSamp = postSamp[,(dataList$N_pollsters + 2):(dataList$N_pollsters + 52)] + muSamp

delmean = apply(delSamp,2,mean)
del025 = apply(delSamp,2,quantile,prob=0.025)
del975 = apply(delSamp,2,quantile,prob=0.975)

statemean = apply(stateSamp,2,mean)
state025 = apply(stateSamp,2,quantile,prob=0.025)
state975 = apply(stateSamp,2,quantile,prob=0.975)

source(paste(path,"/plot_results.R",sep=""))
