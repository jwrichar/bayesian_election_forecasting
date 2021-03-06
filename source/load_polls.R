
print(paste("Loading all polls from election year ", year))

####################################
# LOAD POLLING DATA from specified year

# Get list of files in the polls_2008 dir
files = list.files(paste(data_path, "/polls_", year, sep=""))

# Initialize polling data object
polldata = list()

# Fill in list with poll data from each state
for(ii in 1:length(states[,2])){
  abbr = tolower(states[ii, 2])
  filename = paste(abbr, year, "poll.dat",sep="_")
  # only open the polling data file if it exists
  if(filename %in% files){
    polldata[[abbr]] = read.table(paste(data_path, "/polls_", year, "/", filename,sep=""),
                                        sep=",", header=TRUE)
  } else{
    polldata[[abbr]] = NULL
  }
}

####################################
# Parse out polling data into matrices

# polling agency names
agencies = unlist(sapply(polldata, function(x) x[,1]))

# Only consider pollsters working across multiple states
agency_st_count = table(unlist(sapply(polldata, function(x) levels(x[,1]))))

pollsters = names(agency_st_count[agency_st_count > 1])
print(pollsters)

maxpoll = max(sapply(polldata,nrow))

# Initialize output variables to be used in the model:
N = matrix(NA, 51, maxpoll)  # Poll size
Pdem = matrix(NA, 51, maxpoll)  # Prop. voting for Democrat
Npolls = rep(NA, 51)  # Number of total polls
days2elec =  matrix(NA, 51, maxpoll)  # Days until election for each
pollster =  matrix(NA, 51, maxpoll)  # Pollster

for(jj in 1:length(states[,2])){
  nn = 0
  polls_state_j = polldata[tolower(tolower(states[jj, 2]))][[1]]

  if(length(polls_state_j) > 0){

    for(kk in 1:nrow(polls_state_j)){
      # Use only polls matching approved pollster list
      pollsterind = pmatch(pollsters, paste(polls_state_j$Name[kk]))
      polldate = strptime(
          strsplit(paste(polls_state_j$Date[kk]), " - ")[[1]][2], "%m/%d")
      num_days_to_elec = election_day$yday - polldate$yday
      # Polls are reverse-ordered by date (but don't have year specified!)
      # once we reach 9 months from election, don't add any more polls:
      if(num_days_to_elec > 270){break}

      if(sum(pollsterind,na.rm=TRUE)>0){
        nn = nn + 1
        pollster[jj,nn] = which(is.na(pollsterind)==FALSE)
        N[jj,nn] = polls_state_j$Size[kk]
        Pdem[jj,nn] = polls_state_j$Democrat[kk] / (
          polls_state_j$Democrat[kk] + polls_state_j$Republican[kk])
        days2elec[jj,nn] = num_days_to_elec
      }
    }
  }
  Npolls[jj] = nn
}


# how many qualifying polls for each state?
print("Number of valid polls for each state:\n")
Nmax = maxpoll - apply(N,1, function(x) sum(is.na(x)))
print(data.frame(states=paste(states[,2]), n_polls=Nmax))


######### NATIONAL POLLS 
national_dat = read.table(paste(data_path, "/polls_", year, "/national_", year, "_poll.dat", sep=""),
                                    sep=",", header=TRUE)

# Use only latest polls:
national_dat = national_dat[1:n_latest_national_polls,]

# Prop of voters for Dem, plus size of poll for each poll:
Pdem.nat = national_dat$Democrat / (national_dat$Democrat + national_dat$Republican)
N.nat = national_dat$Size
