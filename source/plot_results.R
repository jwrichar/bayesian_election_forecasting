plots_path = normalizePath("../plots")
data_path = normalizePath("../data")

####################################
## GENERATE PLOTS OF THE RESULTS

cat("Plotting results:\n")
cat("Posterior mean for National vote proportion to Harris: ", 100*mean(muSamp), "% \n")
cat("Posterior mean for National vote spread (D): ", 100 * (mean(muSamp) - (1 - mean(muSamp))), "% \n")

######################
# plot of posterior mean proportion & CI versus (ordered state)
ind = order(statemean)

pdf(paste(plots_path,"/statewise_proportions_", year, ".pdf",sep=""),height=10,width=8)
par(mar=c(4,6,1,1))
plot(statemean[ind],1:51, pch=20, axes=FALSE, ylab="",
     xlab="Proportion of vote to Harris",xlim=c(0.2,0.95))
arrows(state025[ind], 1:51, state975[ind], 1:51, length=0,lwd=2)
points(p0.mean[ind] + 0.5, 1:51, col=2,pch=1)
box()
axis(1)
axis(2, at=1:51,labels=state.abbrs[ind],las=1,cex.axis=0.9)
abline(h=1:51, col='#80808040')
abline(v=0.5,col=4,lty=2,lwd=2)
legend('bottomright', c("Posterior","Prior (historical)"), col=c(1,2),
       pch=c(20,1),cex=1.5,bg='white')
dev.off()

cat("Average confidence interval length: ", mean(state975 - state025), "\n")

######################
# plot of house effect
ind = order(delmean)
library(jsonlite)
pollster_lean = fromJSON(paste(data_path, '/pollster_lean.json', sep=""))
ind_dem = pollsters[ind] %in% pollster_lean$DEM
ind_rep = pollsters[ind] %in% pollster_lean$REP

pdf(paste(plots_path,"/pollster_bias_", year, ".pdf",sep=""),height=28,width=12)
par(mar=c(4,18,1,1))
plot(100*delmean[ind],1:dataList$N_pollsters, pch=19, axes=FALSE, ylab="",
     xlab="Democratic Bias of Pollster", xlim=c(-4,4))
arrows(100*del025[ind], 1:dataList$N_pollsters, 100*del975[ind], 1:dataList$N_pollsters,
       length=0,lwd=3)
box()
axis(1)
axis(2, at=1:dataList$N_pollsters,labels=pollsters[ind], las=1,cex.axis=1)
axis(2, at=(1:dataList$N_pollsters)[ind_dem],
  labels=pollsters[ind][ind_dem], las=1, cex.axis=1, col.axis="blue")
axis(2, at=(1:dataList$N_pollsters)[ind_rep],
  labels=pollsters[ind][ind_rep], las=1,cex.axis=1, col.axis="red")
abline(h=1:dataList$N_pollsters, col='#80808040')
abline(v=0,col=4,lty=2,lwd=2)
dev.off()


######################
# posterior plots of FL vs VA
pdf(paste(plots_path,"/fl_va_", year, ".pdf",sep=""),height=10,width=8)
plot(stateSamp[,46],stateSamp[,9],cex=.5,xlab="VA",ylab="FL",
     pch=20,col="#00000070")
abline(h=.5,v=.5,col=4,lwd=2)
dev.off()

######################
# posterior distribution of electoral votes
evotes = read.table(paste(data_path,"/electoral_college.dat",sep=""),
  header=TRUE,sep=',')[-1,]

dem.win = (stateSamp > 0.5)

dem.evotes = dem.win %*% evotes[,2] # electoral votes
evotesMat = cbind(as.numeric(names(table(dem.evotes))), table(dem.evotes))


pdf(paste(plots_path,"/electoral_votes_", year, ".pdf",sep=""),height=7,width=8)
plot(evotesMat[evotesMat[,1]>=270,1],evotesMat[evotesMat[,1]>=270,2]/sum(evotesMat[,2]),
     typ='h',lwd=4,xlab="Electoral Votes for Harris",ylab="Probability",col=4,
     xlim=range(evotesMat[,1]))
lines(evotesMat[evotesMat[,1]<270,1],evotesMat[evotesMat[,1]<270,2]/sum(evotesMat[,2]),
     typ='h',lwd=4,col=2)
dev.off()

#### Posterior mode Evotes:
cat("Posterior Mode Harris Electoral Votes:",evotesMat[which.max(evotesMat[,2]),1],"\n")

#### PROBABILITY THAT DEMOCRAT WINS
cat("P(Harris Win) = ", mean(dem.evotes >= 270),"\n")


############
# MAP of P(Dem win) in each state
library(maps)

# P(Dem win) for each state:
dem.probstate = apply(dem.win, 2, mean)

##### CLOSEST STATE:
cat("Closest State:", paste(state.abbrs[which.min(abs(dem.probstate-0.5))]),"\n")


statenames.all = tolower(c(state.name[1:47],"District of Columbia",
  state.name[48:50]))

# figure out state names in maps R package
statevec = map("state",namesonly=TRUE,plot=FALSE)
statevec = sapply(strsplit(statevec,":"),function(x) x[[1]])

# allocate colors to each polygon in the U.S.
PDem = NULL
for(ii in statevec){
  ind = which(statenames.all==ii)
  PDem = c(PDem,dem.probstate[ind])
}

# make color vector to plot
col.dem = rep(NA,length(PDem))
col.dem[PDem>=0.5] = "#0000FF" # blue states
col.dem[PDem<0.5] = "#FF0000" # red states

###  add transparency

margin = abs(PDem - 0.5)


# define amount of transparency based on margin of victory
transparency = ceiling((margin**3 - min(margin**3))/(max(margin**3)-min(margin**3)) *100)
transparency[transparency > 99] = 99

# set transparency vector as two-digit string
transparency = paste(transparency)
transparency[nchar(transparency)==1] = 
  paste("0", transparency[nchar(transparency)==1],sep="")

# paste transparency to red/blue color vector!
col.dem.t = paste(col.dem,transparency,sep="")

# plot map with transparent colors for predicted election result
pdf(paste(plots_path,"/electoral_map_", year, ".pdf",sep=""),height=8,width=10)
map("state", col=col.dem.t, fill=TRUE)
title(paste("Predicted 2024 US Presidential Election Outcome. Harris Electoral Votes: ",
  evotesMat[which.max(evotesMat[,2]),1], sep=""))
text(state.center$x, state.center$y, round(dem.probstate[-48]*100,1),col='gray10')
dev.off()

### Draw maps for a 1% and 2% avg. polling bias
for(adjustment in c(0.01, 0.02)){

  stateSamp.adj = stateSamp - adjustment

  dem.win = (stateSamp.adj > 0.5)

  dem.evotes = dem.win %*% evotes[,2] # electoral votes

  # P(Dem win) for each state:
  dem.probstate = apply(dem.win, 2, mean)

  # allocate colors to each polygon in the U.S.
  PDem = NULL
  for(ii in statevec){
    ind = which(statenames.all==ii)
    PDem = c(PDem,dem.probstate[ind])
  }

  # make color vector to plot
  col.dem = rep(NA,length(PDem))
  col.dem[PDem>=0.5] = "#0000FF" # blue states
  col.dem[PDem<0.5] = "#FF0000" # red states

  ###  add transparency

  margin = abs(PDem - 0.5)

  # define amount of transparency based on margin of victory
  transparency = ceiling((margin**3 - min(margin**3))/(max(margin**3)-min(margin**3)) *100)
  transparency[transparency > 99] = 99

  # set transparency vector as two-digit string
  transparency = paste(transparency)
  transparency[nchar(transparency)==1] = 
    paste("0", transparency[nchar(transparency)==1],sep="")

  # paste transparency to red/blue color vector!
  col.dem.t = paste(col.dem,transparency,sep="")

  # plot map with transparent colors for predicted election result
  pdf(paste(plots_path,"/electoral_map_", year, "_adjustment", adjustment, ".pdf",sep=""),height=8,width=10)
  map("state", col=col.dem.t, fill=TRUE)
  title(paste("Predicted 2024 US Presidential Election Outcome w/ adjustment: ", adjustment,
    ". Harris Electoral Votes: ", median(dem.evotes), sep=""))
  text(state.center$x, state.center$y, round(dem.probstate[-48]*100,1),col='gray10')
  dev.off()

}

# Probability of Dem win as a function of poll bias
biases = seq(0, .02, by=0.001)
dem.win.probs = NULL
for(bias in biases){

  stateSamp.adj = stateSamp - bias
  dem.win = (stateSamp.adj > 0.5)
  dem.evotes = dem.win %*% evotes[,2] # electoral votes

  dem.win.probs = c(dem.win.probs, mean(dem.evotes >= 270))
}
pdf(paste(plots_path,"/prob_dem_win_vs_bias", year, ".pdf",sep=""),height=6,width=8)
par(mar=c(4,6,1,1))
plot(biases*100,dem.win.probs*100, pch=10, ylab="Probability Democrat Wins EC",
     xlab="Amount of Democratic Bias in Polls", type='b')
abline(h=50,col=4,lty=2,lwd=2)
dev.off()


######
## write table of statewise results
voteprop = data.frame(cbind(state.abbrs,statemean,state025,state975))
colnames(voteprop) = c("state","mean","2.5quant", "97.5quant")
write.table(voteprop,paste(plots_path,"/table_voteprop_", year, ".dat",sep=""),
            quote=FALSE,sep=",",row.names=FALSE)

# write out all state-level posterior samples
write(t(stateSamp),paste(plots_path,"/samples_stateVote_", year, ".dat",sep=""),ncolumns=51)
# write all samples for national head-to-head vote prop to Dem
write(t(muSamp),paste(plots_path,"/samples_nationalVote_", year, ".dat",sep=""),ncolumns=1)
