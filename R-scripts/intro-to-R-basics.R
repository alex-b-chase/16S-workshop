# Green text are comments and will be ignored when running code.
rm(list=ls())

# open-source statistical software 
# large number of “packages” for R freely downloadable from [CRAN](http://cran.us.r-project.org/) (Comprehensive R Archive Network) 
# individual packages do pretty much everything!

# R basics
# R (unlike other languages) does not care about spaces between functions
3+12
3 + 12

# assign variables into the R environment
z = 5
z
z <- 3
z

# The number [1] before the answers just means that this item is the first element of a vector (vectors can be thought of as a collection of related values, such as a column in a data table).


# vector of ten values from 1 to 10, demonstrates the basic R syntax for creating a sequence of numbers
seq(1, 10, by = 0.5)
seq(1, by = 0.5, length = 10)
rep(1, 10)
x = seq(0, 3, by = 0.01)

# combine vectors to build up data frames by “binding” them together either are rows or as columns
p = 1:10
q = 10:1
cbind(p,q)  	# bind as columns
rbind(q,p)		# bind as rows

# R can perform standard logical comparisons, syntax for the different logical operators, some of which are odd:
log(1) == 0
exp(0) != 1

###################################
##### working and saving data #####
###################################
frogs = c(1.1, 1.3, 1.7, 1.8, 1.9, 2.1, 2.3, 2.4,
          2.5, 2.8, 3.1, 3.3, 3.6, 3.7, 3.9, 4.1, 4.5,
          4.8, 5.1, 5.3)

tadpoles = rnorm(n = 20, mean = 2 * frogs, sd = 0.5)

dat <- cbind(tadpoles, frogs)
# working with data
# One of the first things you’ll do with any data set when you first load it up is some basic checks to see what you are dealing with.
# Typing the variable name will show you its contents, but if you just loaded up something with a million entries then you’ll sit for a long time as R lists every number on the screen.
# The function class will tell you the type of data you’ve just loaded.  

class(dat)


# character data in R is usually displayed in double quotes to indicate that it is character data (e.g. the character “1” rather than the number 1)
# Note that when your data is characters you'll need double-quotes in your comparison. e.g. 
a = c("north","south","east","west")
# also do logical comparisons with characters as well
a == "east"

# helpful TOOL
# Be aware that RStudio has the capacity to auto-complete function names, function arguments, and file names

# So, for example, if you type ‘read.t’ and then hit TAB, RStudio will finish typing read.table and it would also show what information you can specify for the read.table function.  
# If you type read.table( and then hit TAB, RStudio will allow you to select the function argument that you want to fill in. 
# If you type read.table(“ and then hit TAB, RStudio will show you the files in your current working directory and allow you to select one. 
# If there are a lot of files in the directory, you can start typing the file name you want and then hit TAB again and RStudio will limit what it shows to just those files that match what you’ve typed so far

# save the R environment and variables to use later
setwd('/Users/alexchase/Desktop/sio262-workshop/')
save(dat, a, x, z, file = "Lab1.RData")

rm(list=ls())

#Let's check out current working directory.
#A directory is a location on your computer.
#File outputs will be in this location unless a file path is specified.
#Alternatively, you can also use the 'Files' tab, under 'More', to go to current working directory.
getwd()

# have students close and exit R, open a new window and:
setwd('/Users/alexchase/Desktop/sio262-workshop/')
load("Lab1.RData")

# or save EVERYTHING so far:
save.image("Lab1_all.RData")

# not sure what variables you have defined,
ls()


# visualize dataframe in R environment

# save as .csv file (like Excel format)
write.table(dat, "my_frogs.csv", row.names = FALSE, sep = ",")


# get the basic structure of the data

dat <- read.table("frogs.txt", header = TRUE, sep = '\t')

class(dat)

# dat is in a “data.frame”, which is like a matrix but can also contain non-numeric data.
# basic (or atomic) data types in R are integer, numeric (decimal), logical (TRUE/FALSE), factors, and character


str(dat)

# from this we learn that there are four columns of data named “frogs”, “tadpoles”, “color”, “spots” and 
# that there are 20 rows of data, and 
# that the data is numeric for the first two, a factor for the third, and logical for the fourth.

names(dat)
# get the names of the columns (remember we used header = TRUE!!!)

dim(dat)
# get dimensions of dataframe
nrow(dat)
ncol(dat)

# We can refer to specific columns of data by name using the $ syntax
# useful with auto-complete TAB function!

dat$frogs  			# show just the ‘frogs’ column
dat$color[6:10]		# show the 6th though 10th elements of the color column

# for a single vector, use length
length(dat$frogs)

# preview the data (useful if working with really large files!)
head(dat)
tail(dat)

# get quick statisticsal summary of each vector in the dataframe
summary(dat)

# Analyzing data and basic statistical inference

# want the ability to summarize and visualize data
table(dat$color)
table(dat$color,dat$spots)

# basic statistical measurements - expanding on summary() function
mean(dat$frogs)
median(dat$tadpoles)
var(dat$frogs)  							## variance
sd(dat$frogs)								## standard deviation
cov(dat$frogs, dat$tadpoles)				## covariance
cor(dat$frogs, dat$tadpoles)				## correllation
quantile(dat$tadpoles, c(0.05,0.90))		## 5% and 90% quantiles
min(dat$frogs)								## smallest value
max(dat$frogs)								## largest value

# R also has a set of apply functions for applying any function to sets of values within a data structure.
apply(dat[,1:2], 1, sum)  	        # calculate sum of frogs & tadpoles by row (1st dimension)
apply(dat[,1:2], 2, sum)	        # calculate sum of frogs & tadpoles by column (2nd dimension)

# function "apply" will apply a function to either every row (dimension 1) or every column (dimension 2) of a matrix or data.frame. 
# In this example the commands apply the “sum” function to the first two columns of the data (frogs & tadpoles) first calculated by 
# row (the total number of individuals in each population) and 
# second by column (the total number of frogs and tadpoles)

tapply(dat$frogs, dat$color, mean)          			# calculate mean of frogs by color
tapply(dat$frogs, dat[, c("color","spots")], mean)  		# calculate mean of frogs by color & spots

# function "tapply" will apply a function to an R data object, grouping data according to a second variable or set of variables. 
# The first example applies the “mean” function to frogs grouping them by color. 
# The second shows that tapply can be used to apply a function over multiple groups, in this case color X spots. 

# PLOT DATA

plot(dat$frogs, dat$tadpoles)  					## x-y scatter plot
abline(a = 0, b = 1)							## add a 1:1 line (intercept=0, slope=1)

plot.new()

hist(dat$tadpoles)								## histogram
abline(v = mean(dat$tadpoles), col = "blue")					## add a vertical line at the mean

pairs(dat)										## all pairwise scatter plots

plot.new()

barplot(tapply(dat$frogs, dat$color, mean))		## barplot of frogs by color
abline(h = 3, col = "red")									## add a horizontal line at 3

