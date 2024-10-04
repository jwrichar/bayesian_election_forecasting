plots_path = normalizePath("../plots")
data_path = normalizePath("../data")

dates = c('Sept 30', 'Oct 3')

date_old = gsub(' ', '',tolower(dates[1]))
date_new = gsub(' ', '',tolower(dates[2]))

states = read.table(paste(data_path, "/state_abbreviations.txt", sep=""), header=FALSE)
state.abbrs = states[,2]


samples_old = read.table(
    paste(plots_path, '/2024/', date_old, '/samples_stateVote_2024.dat', sep=''))
names(samples_old) = state.abbrs
samples_new = read.table(
    paste(plots_path, '/2024/', date_new, '/samples_stateVote_2024.dat', sep=''))
names(samples_new) = state.abbrs

probs_old = apply(samples_old > 0.5, 2, mean)
probs_new = apply(samples_new > 0.5, 2, mean)

# Swing states:
is_swing_state = (probs_old > .01) & (probs_old < 0.99)
N_swing_state = sum(is_swing_state)

######################
# plot of movement in posterior mean by state

colvec = rep('red', N_swing_state)
colvec[probs_new[is_swing_state] > probs_old[is_swing_state]] = 'blue'

pdf(paste(
    plots_path, 
    "/change_in_state_prob_", date_old, "_", date_new, "_", year, ".pdf",sep=""),
height=6,width=8)
par(mar=c(5,3,5,1))
plot(probs_old[is_swing_state],N_swing_state:1, pch=20, axes=FALSE, ylab="",
     xlab="Probability of Democrat winning state",xlim=c(0,1), col=colvec,
     main=paste("Change in Swing State Probabilities from", dates[1], "to", dates[2]))
arrows(probs_old[is_swing_state], N_swing_state:1,
    probs_new[is_swing_state], N_swing_state:1, length=0.05, col=colvec ,lwd=4)
box()
axis(1)
axis(2, at=N_swing_state:1,labels=state.abbrs[is_swing_state],las=1,cex.axis=0.9)
abline(h=N_swing_state:1, col='#80808040')
abline(v=0.5,col=4,lty=2,lwd=2)
dev.off()

