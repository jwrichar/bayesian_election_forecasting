print("Loading historical election data to generate priors")

plots_path = normalizePath("../plots")

past.results = read.table(
    paste(data_path, "/1976-2020-president.csv", sep=""),
    sep=",", header=TRUE)

past.results = past.results[past.results$party_detailed %in% c("DEMOCRAT", "REPUBLICAN"),]
past.results = past.results[past.results$writein == FALSE,]

# Get prop of D/R voteshare that went to Demorat, for each state:
dem.voteshare = matrix(nrow = 51, ncol = length(past_elec_years),
    dimnames = list(state.abbrs, past_elec_years))
for(past_year in past_elec_years){
    for(state in state.abbrs){
        res = past.results[(past.results$year == past_year) & (past.results$state_po == state),]
        demvotes = res$candidatevotes[res$party_detailed == 'DEMOCRAT']
        repvotes = res$candidatevotes[res$party_detailed == 'REPUBLICAN']
        # handle missing data (make it 50%):
        if(length(demvotes) == 0){
            demvotes = repvotes
        }
        dem.voteshare[state, paste(past_year)] = demvotes / (demvotes + repvotes)
    }
}


# Prior mean and variance based on previous elections, and centered to 0.5
# Do a weighted mean, weighting more recent elections more heavily
weights = seq(length(past_elec_years), 1)^2
p0.mean = apply(dem.voteshare - 0.5, 1, weighted.mean, w=weights)
p0.var = apply(dem.voteshare, 1, var)


pdf(paste(plots_path,"/statewise_priors_", year, ".pdf",sep=""),height=8,width=8)
par(mar=c(4,6,1,1))
plot.new()
plot.window(xlim=c(-0.5,0.5), ylim=c(0,0.05))
text(x=p0.mean, y=sqrt(p0.var), labels=state.abbrs,cex=0.7)
axis(1); axis(2); box()
abline(v=0,col='gray')
title(xlab="mean p0",ylab="std p0")
dev.off()
