plots_path = normalizePath("../plots")
data_path = normalizePath("../data")

dates = c('Oct 7', 'Oct 17')

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
    "/", year, "/change_in_state_prob_", date_old, "_", date_new, "_", year, ".pdf",sep=""),
height=6,width=8)
par(mar=c(5,3,5,1))
plot(100*probs_old[is_swing_state],N_swing_state:1, pch=20, axes=FALSE, ylab="",
     xlab="Probability of Democrat winning state",
     xlim=c(0,100), ylim=c(0.5, N_swing_state+1), col=colvec,
     main=paste("Change in Swing State Probabilities from", dates[1], "to", dates[2]))
rect(0, 0, 20, N_swing_state+2, border=NA, col = rgb(1,0,0,0.2))
rect(20, 0, 40, N_swing_state+2, border=NA, col = rgb(1,0,0,0.1))
rect(60, 0, 80, N_swing_state+2, border=NA, col = rgb(0,0,1,0.1))
rect(80, 0, 100, N_swing_state+2, border=NA, col = rgb(0,0,1,0.2))
text(10, N_swing_state+1, 'Likely R', cex=0.7)
text(30, N_swing_state+1, 'Leans R', cex=0.7)
text(50, N_swing_state+1, 'Toss Up', cex=0.7)
text(70, N_swing_state+1, 'Leans D', cex=0.7)
text(90, N_swing_state+1, 'Likely D', cex=0.7)
arrows(100*probs_old[is_swing_state], N_swing_state:1,
    100*probs_new[is_swing_state], N_swing_state:1, length=0.05, col=colvec ,lwd=4)
box()
axis(1)
axis(2, at=N_swing_state:1,labels=state.abbrs[is_swing_state],las=1,cex.axis=0.9)
abline(h=N_swing_state:1, col='#80808040')
abline(v=50,col=4,lty=2,lwd=1)
dev.off()




