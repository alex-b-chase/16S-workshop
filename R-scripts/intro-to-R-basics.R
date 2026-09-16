############################################################
##################### INTRODUCTION TO R #####################
############################################################

# Lines beginning with # are comments.
# R ignores comments when running code.
#
# To run a line of code:
#   Windows: Ctrl + Enter
#   Mac:     Command + Enter
#
# You can also highlight several lines and run them together.
#
# Results and messages will appear in the Console.


############################################################
####################### R BASICS ############################
############################################################

# R can be used like a calculator.

3 + 12
10 / 2
2^3


# R generally ignores spaces around operators.
# These commands do exactly the same thing:

3+12
3 + 12


# We can save a value as an object using <- 
#
# Read this as:
# "z gets 5"

z <- 5

# Type the name of an object to see what it contains.

z


# We can replace the value stored in an object.

z <- 3
z


# You may see output like this in the Console:
#
# [1] 3
#
# The [1] means that the value shown is the first element
# of the object being printed.


############################################################
####################### VECTORS #############################
############################################################

# A vector is a collection of values.
#
# The function c() combines values into a vector.

numbers <- c(1, 2, 3, 4, 5)

numbers


# There are several convenient ways to generate sequences.

1:10

seq(1, 10, by = 0.5)

seq(1, by = 0.5, length.out = 10)

rep(1, 10)


# Save a sequence as an object.

x <- seq(0, 3, by = 0.01)

x


# We can combine vectors as columns or rows.

p <- 1:10
q <- 10:1

cbind(p, q)     # bind as columns

rbind(p, q)     # bind as rows


############################################################
################## LOGICAL COMPARISONS ######################
############################################################

# R can ask whether statements are TRUE or FALSE.
#
# == means "is equal to"
# != means "is not equal to"
# >  means "greater than"
# <  means "less than"

log(1) == 0

exp(0) != 1

5 > 3

5 < 3


############################################################
##################### CHARACTER DATA ########################
############################################################

# Text is called "character" data in R.
# Character values must be placed inside quotation marks.

direction <- c("north", "south", "east", "west")

direction


# Logical comparisons also work with character data.

direction == "east"


############################################################
################ WORKING WITH DATA ##########################
############################################################

# Create a vector containing 20 values.

frogs <- c(
  1.1, 1.3, 1.7, 1.8, 1.9,
  2.1, 2.3, 2.4, 2.5, 2.8,
  3.1, 3.3, 3.6, 3.7, 3.9,
  4.1, 4.5, 4.8, 5.1, 5.3
)


# We will generate some fake tadpole data.
#
# set.seed() makes the random numbers reproducible.
# Everyone running this script should therefore get
# the same values.

set.seed(123)

tadpoles <- rnorm(
  n = length(frogs),
  mean = 2 * frogs,
  sd = 0.5
)


# Combine these vectors into a data frame.
#
# A data frame is one of the most common ways that
# tabular data are stored in R.
#
# Rows usually represent observations or samples.
# Columns represent variables.

dat <- data.frame(
  frogs = frogs,
  tadpoles = tadpoles
)

dat


# Check what type of object dat is.

class(dat)


# str() is one of the most useful commands in R.
# It shows the structure of an object.

str(dat)


# In RStudio, View() opens the data in a spreadsheet-like window.

View(dat)


############################################################
################ FILES AND DIRECTORIES ######################
############################################################

# A directory is a folder on your computer.
#
# getwd() tells you R's current working directory.

getwd()


# list.files() shows the files and folders that R can
# currently see.

list.files()


# For this workshop, your working directory should be the
# main "16S-workshop" folder that you downloaded from GitHub.
#
# You should see folders including:
#
# "materials"
# "R-scripts"
# "images"
#
# If you do NOT see these, use:
#
# Session > Set Working Directory > Choose Directory...
#
# and select the main 16S-workshop folder.
#
# We avoid typing a path such as:
#
# /Users/alex/Desktop/...
#
# because that path would only work on one computer.


############################################################
##################### READING DATA ##########################
############################################################

# Check that R can find the example data file.

file.exists("materials/frogs.txt")


# TRUE means R found the file.
#
# If you get FALSE, your working directory is probably
# not the main 16S-workshop folder.


# Stop with a helpful message if the file cannot be found.

if (!file.exists("materials/frogs.txt")) {
  stop(
    "R cannot find materials/frogs.txt. Set your working directory to the main 16S-workshop folder."
  )
}


# Read the tab-delimited data file into R.

dat <- read.delim(
  "materials/frogs.txt",
  header = TRUE
)


############################################################
################## INSPECTING THE DATA ######################
############################################################

# Start by looking at the structure of any new dataset.

str(dat)


# The dataset contains:
#
# frogs      numeric data
# tadpoles   numeric data
# color      character data
# spots      logical data (TRUE/FALSE)


# Column names

names(dat)


# Dimensions of the data:
# number of rows followed by number of columns

dim(dat)


# Number of rows

nrow(dat)


# Number of columns

ncol(dat)


# Preview the beginning of the dataset.

head(dat)


# Preview the end.

tail(dat)


# Quick statistical summary of each variable.

summary(dat)


############################################################
#################### SELECTING DATA #########################
############################################################

# The $ symbol selects a column by name.

dat$frogs

dat$color


# We can select specific positions from a vector.

dat$color[6:10]


# Data frames can be indexed using:
#
# dat[rows, columns]


# First five rows, all columns

dat[1:5, ]


# All rows, first two columns

dat[, 1:2]


# Select columns by name

dat[, c("frogs", "tadpoles")]


# Logical comparisons are especially useful for filtering data.
#
# Show only rows where color is blue.

dat[dat$color == "blue", ]


# Show only rows where spots is TRUE.

dat[dat$spots == TRUE, ]


############################################################
###################### DATA TYPES ###########################
############################################################

# Common types of data in R include:
#
# numeric      decimal numbers
# integer      whole numbers
# character    text
# logical      TRUE/FALSE


class(dat$frogs)

class(dat$color)

class(dat$spots)


# A factor represents categorical data.
#
# We can explicitly tell R that "color" represents categories.

dat$color <- factor(dat$color)

class(dat$color)

levels(dat$color)


############################################################
#################### SUMMARIZING DATA #######################
############################################################

# table() counts how often different categories occur.

table(dat$color)


# We can also compare two categorical variables.

table(dat$color, dat$spots)


# Common numerical summaries

mean(dat$frogs)

median(dat$tadpoles)

var(dat$frogs)                    # variance

sd(dat$frogs)                     # standard deviation

cov(dat$frogs, dat$tadpoles)      # covariance

cor(dat$frogs, dat$tadpoles)      # correlation

quantile(
  dat$tadpoles,
  probs = c(0.05, 0.90)
)

min(dat$frogs)

max(dat$frogs)


# We can calculate values separately for different groups
# using tapply().
#
# Mean frog value for each color:

tapply(
  dat$frogs,
  dat$color,
  mean
)


# Mean frog value for every combination of color and spots:

tapply(
  dat$frogs,
  list(
    color = dat$color,
    spots = dat$spots
  ),
  mean
)


############################################################
###################### SAVING DATA ##########################
############################################################

# write.csv() saves a data frame as a comma-separated file.
#
# row.names = FALSE prevents R from adding an extra column
# containing row numbers.

write.csv(
  dat,
  "my_frogs.csv",
  row.names = FALSE
)


# Check that the file was created.

file.exists("my_frogs.csv")


# For most analyses, your R SCRIPT is the important record
# of what you did.
#
# If you close R and reopen it, you should be able to rerun
# your script to recreate your analysis.
#
# We therefore will NOT rely on saving and restoring the
# entire R workspace.


############################################################
###################### BASIC PLOTS ##########################
############################################################

# Scatter plot

plot(
  dat$frogs,
  dat$tadpoles,
  xlab = "Frogs",
  ylab = "Tadpoles"
)


# Add a 1:1 line.
#
# a = intercept
# b = slope

abline(
  a = 0,
  b = 1
)


# Histogram showing the distribution of tadpole values.

hist(
  dat$tadpoles,
  xlab = "Tadpoles",
  main = "Distribution of tadpole values"
)


# Add a vertical line at the mean.

abline(
  v = mean(dat$tadpoles),
  col = "blue"
)


# Pairwise plots should generally be made using numeric data.

pairs(
  dat[, c("frogs", "tadpoles")]
)


# Compare the distribution of frog values between colors.

boxplot(
  frogs ~ color,
  data = dat,
  xlab = "Color",
  ylab = "Frogs"
)


############################################################
#################### USEFUL RSTUDIO TIPS ####################
############################################################

# RStudio can automatically complete commands.
#
# Try typing:
#
# read.d
#
# and press TAB.
#
# RStudio should suggest functions beginning with those letters.


# You can also ask R for help about any function.

?mean

?read.delim

?plot


# If the Console shows a + instead of a > prompt,
# R thinks your command is unfinished.
#
# This often happens when you forget a closing parenthesis
# or quotation mark.
#
# Press ESC to cancel the unfinished command.


############################################################
######################## FINISHED ###########################
############################################################

# You now know enough R to:
#
#   - create and store objects
#   - work with vectors
#   - understand TRUE/FALSE comparisons
#   - read a data file
#   - inspect a data frame
#   - select rows and columns
#   - calculate basic summaries
#   - make simple plots
#
# These are the same basic operations we will use when
# working with microbiome data.
