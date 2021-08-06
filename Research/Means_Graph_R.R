setwd("C:/Users/vitor/OneDrive/Research_Resources/GasRegulation_Resources/Data")
getwd()

install.packages("readr")
install.packages("anytime")
install.packages("ggplot2")
install.packages("dplyr")
install.packages("tidyverse")
install.packages("ggthemes")

library("readr")
library("anytime")
library("ggplot2")
library("dplyr")
library("tidyverse")
library("ggthemes")

gd <- read.csv("MeansTrends.csv")

Date <- anytime(gd$monthly_date)

str(gd$treated)

gd <- mutate(gd, Group = ifelse(treated==1,"Treated","Control"))

date_vline <- as.Date(c("2017-12-01"))
date_vline <- which(gd$Date %in% date_vline)

gd <- cbind(gd, Date)

gd %>%
  ggplot(aes(x = Date, y = Rcashprice, color = Group)) +
  geom_line() + 
  labs(title = "Average Gasoline Prices for Treated and Untreated Oregon Counties",
       y = "Average Gasoline Prices",
       x = "Date",
       color = "Group:") +
  theme_fivethirtyeight() +
  theme(axis.title = element_text())

gd_graph


gd_graph + 
  geom_vline(xintercept = as.numeric(gd$Date[date_vline]), col = "red", lwd = 2)

gd_graph + geom_vline(xintercept = as.Date(gd$Date[date_vline]))


