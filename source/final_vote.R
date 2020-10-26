
path = "/Users/jwrichar/Documents/UCB_Classes/stat157_bayes_fa12/stat157fa12/Project/"


#########################################
## load results of 2012 election

e00 = read.table(paste(path,"data/election_outcome_2012.dat",sep=""),header=TRUE)
pfinal = e00$Obama / (e00$Obama + e00$Romney)

########
## model results
results = read.table(paste(path,"project/table_voteprop.dat",sep=""),header=TRUE,sep=",")

# check alignment:
print(cbind(paste(e00[1:51,1]),paste(results[,1])))


######################
# plot of posterior mean proportion & CI versus (ordered state)
ind = order(results$mean)

pdf(paste(path,"project/statewise_proportions_results.pdf",sep=""),height=10,width=8)
par(mar=c(4,6,1,1))
plot(results$mean[ind],1:51, pch=20, axes=FALSE, ylab="",
     xlab="Proportion of vote to Obama",xlim=c(0.2,0.95))
arrows(results[ind,3], 1:51, results[ind,4], 1:51, length=0,lwd=2)
points(p0.mean[ind] + 0.5, 1:51, col=2,pch=1)
points(pfinal[ind],1:51,col=4,pch=17)
box()
axis(1)
axis(2, at=1:51,labels=state.abb.all[ind],las=1,cex.axis=0.9)
abline(h=1:51, col='#80808040')
abline(v=0.5,col=4,lty=2,lwd=2)
legend('bottomright', c("Posterior","Prior (historical)", "Election Outcome"), col=c(1,2,4),
       pch=c(20,1,17),cex=1.5,bg='white')
dev.off()


#####
# do it just for swing states (compare to 538)
#swing = which(state.abb.all %in% c("WI","NV","IA","OH","NH",
#  "VA","CO","FL","NC"))
swing = which(state.abb.all %in% c("MI", "MN","OR","PA","WI","NV","IA","OH","NH",  "VA","CO","FL","NC"))
Nswing = length(swing)
ind = order(results$mean[swing])

silver = read.table("silver_predictions.txt",header=TRUE)
indorder = NULL
for(ii in 1:Nswing){
  indorder = c(indorder,which(paste(silver[,1])==state.abb.all[swing[ii]]))
}
psilver = silver$O[indorder] / (silver$O[indorder] + silver$R[indorder])
esilver = (silver$error[indorder]/100)/((silver$O[indorder] + silver$R[indorder])/100)

popsilver = 50.8/(50.8 + 48.3)

pdf(paste(path,"project/swingstate_results.pdf",sep=""),height=8,width=8)
par(mar=c(5,6,1,1))
plot(results$mean[swing[ind]],(1:Nswing)-0.1, pch=20, axes=FALSE, ylab="",
     xlab="Proportion of vote to Obama",xlim=c(0.45,0.6),cex=1.5,cex.lab=1.5)
arrows(results[swing[ind],3], (1:Nswing)-0.1, results[swing[ind],4], (1:Nswing)-0.1, length=0,lwd=2)
points(psilver[ind],(1:Nswing)+0.1,col=4,pch=18,cex=1.5)
arrows(psilver[ind]+esilver[ind], (1:Nswing)+0.1, psilver[ind]-esilver[ind], (1:Nswing)+0.1, length=0,lwd=2, col=4)
points(pfinal[swing[ind]],1:Nswing,col=2,pch=17,cex=1.5)
axis(1,cex.axis=1.5)
axis(2, at=1:Nswing,labels=state.abb.all[swing[ind]],las=1,cex.axis=1.5)
abline(v=0.5,col='grey70',lty=2,lwd=2)
legend('bottomright', c("My Prediction","538 Prediction", "Election Outcome"), col=c(1,4,2),  pch=c(20,18,17),cex=1.5,bg='white')
dev.off()


hist(results$mean - pfinal[-52])
mean(results$mean[swing[ind]] - pfinal[swing[ind]])
mean(psilver[ind] - pfinal[swing[ind]])

hist(muSamp,col=3)
abline(v=mean(muSamp),col=4)
abline(v=pfinal[52],col=3)
mean(muSamp) - pfinal[52]

######################
# look at posterior distributions for a couple of states
pdf(paste(path,"project/florida_nevada_prob.pdf",sep=""),height=6,width=10)
par(mfrow=c(1,2),mar=c(5,5,1,1))
# FLORIDA
x = seq(0.45,0.55,length.out=512)
plot(density(stateSamp[,state.abb.all=="FL"],from=0.45, to=0.55),lwd=3,xlab="Proportion Obama Vote",ylab="Probability Density",yaxt='n',main="",cex.lab=1.25)
legend("topleft","Florida",cex=1.25,bty='n')
legend("topright",c("My Model", "538 Model","Outcome"),lwd=3,lty=c(1,1,2),col=c(1,4,2))
dsilverva = dnorm(x,psilver[ind[2]],esilver[ind[2]]/2)
lines(x, dsilverva/(sum(dsilverva)*(x[2]-x[1])),lwd=3,col=4)
abline(v=pfinal[state.abb.all=="FL"],col=2,lwd=3,lty=2)
# NEVADA
x = seq(0.47,0.57,length.out=512)
plot(density(stateSamp[,state.abb.all=="NV"],from=0.45, to=0.57),lwd=3,xlab="Proportion Obama Vote",ylab="Probability Density",yaxt='n',main="",cex.lab=1.25)
legend("topleft","Nevada",cex=1.25,bty='n')
dsilverva = dnorm(x,psilver[ind[8]],esilver[ind[8]]/2)
lines(x, dsilverva/(sum(dsilverva)*(x[2]-x[1])),lwd=3,col=4)
abline(v=pfinal[state.abb.all=="NV"],col=2,lwd=3,lty=2)
dev.off()


######################
# Compute the Bayes Factor Silver vs. me
sd.me = apply(stateSamp,2,sd)
marg.me = log10(prod(dnorm(pfinal[swing[ind]],results$mean[swing[ind]], sd.me[swing[ind]])))
marg.silver = log10(prod(dnorm(pfinal[swing[ind]], psilver[ind],esilver[ind]/2)))
Bfactor = 10^(marg.me - marg.silver)

marg.me.u = -1*margprob(0.007841076,  x= pfinal[swing[ind]], mu=results$mean[swing[ind]],sd=sd.me[swing[ind]])
marg.silver.u = -1*margprob(0.004521363,  x= pfinal[swing[ind]], mu=psilver[ind],sd=esilver[ind]/2)
Bfactor.u = 10^(marg.me.u - marg.silver.u)

# optimize bayes factor over some offset
margprob = function(del,x,mu,sd){
  return(-log10(prod(dnorm(x,mu+del, sd))))
}

optimize(0, margprob, x= pfinal[swing[ind]], mu=results$mean[swing[ind]],sd=sd.me[swing[ind]])
# 0.007067871

####################
# regress on prop spanish w/ no english
noEng = read.table("no_english.txt")
noEng = noEng[order(paste(noEng[,2])),2:3]
#cbind(paste(results[-9,1]),paste(noEng[,1]))

plot(noEng[,2],pfinal[-c(9,52)] - results$mean[-9],pch=20)
