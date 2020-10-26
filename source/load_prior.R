data_path = normalizePath("../data")

states = read.table(paste(data_path, "/state_abbreviations.txt", sep=""), header=FALSE)
state.abbrs = states[,2]

print("Loading historical election data to generate priors")

#########################################
## load data from last 4 elections as prior data

elec.years = c(2016, 2012, 2008, 2004, 2000)

past.results = read.table(
    paste(data_path, "/statewise-results-1976-2016-president.csv", sep=""),
    sep=",", header=TRUE)

past.results = past.results[past.results$party %in% c("democrat", "republican"),]
past.results = past.results[past.results$writein == FALSE,]

# Get prop of D/R voteshare that went to Demorat, for each state:
dem.voteshare = matrix(nrow = 51, ncol = length(elec.years),
    dimnames = list(state.abbrs, elec.years))
for(year in elec.years){
    for(state in state.abbrs){
        res = past.results[(past.results$year == year) & (past.results$state_po == state),]
        demvotes = res$candidatevotes[res$party == 'democrat']
        repvotes = res$candidatevotes[res$party == 'republican']
        # handle missing data (make it 50%):
        if(length(demvotes) == 0){
            demvotes = repvotes
        }
        dem.voteshare[state, paste(year)] = demvotes / (demvotes + repvotes)
    }
}


# prior mean and variance based on previous elections, and centered to 0.5
p0.mean = apply(dem.voteshare - 0.5, 1, mean)
p0.var = apply(dem.voteshare, 1, var)


# plot.new()
# plot.window(xlim=c(-0.5,0.5), ylim=c(0,0.05))
# text(x=p0.mean, y=sqrt(p0.var), labels=state.abbrs,cex=0.7)
# axis(1); axis(2); box()
# abline(v=0,col='gray')
# title(xlab="mean p0",ylab="std p0")
