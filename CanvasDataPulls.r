
library("tidyverse")
library("openxlsx")    # library("readxl") # this is the tidyverse installed package
library("scales")
library("lubridate")
library("rstudioapi")
library("jsonlite")

# rm(list=ls())         # remove all global environment variables


######### NOTE: carefull about how many group category you have! ##################

# set the Canvas Class ID
class_id <- "67737"   # MAE151A F24


# set some strings for the fromJSON calls
token <- "4407~cV0DPpTSmVsjyrYteGHINIXvE76TD7RTy750ASCHFUfj6yqMONUXOqlgWsoPkIXt" #Authorization token. Set this up in your Canvas profile
canvas_base <- "https://canvas.eee.uci.edu/api/v1/"
sections_call <- paste0("/sections/?include[]=students&per_page=100&access_token=",token)


#now get ids for each group category 
cats_call <- paste0("/group_categories?access_token=",token)
call4cats <- paste0(canvas_base,"courses/",class_id,cats_call)  ########## if more than one group (category), categorydata becomes a vector ################
categorydata <- fromJSON(call4cats)   # this has the ID for each group

#now find all the ids and names of each group/team in each category  
groups_call <- paste0("/groups?per_page=100&access_token=",token)
#call4groups <- paste0(canvas_base,"group_categories/",categorydata$id,groups_call)       ############## this is when there is only 1 group ##########
call4groups <- paste0(canvas_base,"group_categories/",categorydata$id[1],groups_call)     ############## this is when there are 2 groups ########## 
groupdata <- fromJSON(call4groups)
# parse the groupdata into GroupID, GroupName, and MemberCnt ... all vectors ... AND drop any groups that have zero members
group_info <- tibble(GroupID=groupdata$id,GroupName=groupdata$name,MemberCnt=groupdata$members_count) %>% filter(MemberCnt>0)    # this has 


# now get set the call string for each group/team and then loop through and get data into "teamdata"
users_call <- paste0("/users?per_page=100&access_token=",token)
call4users <- paste0(canvas_base,"groups/",group_info$GroupID,users_call)  

teamdata <- tibble(ProjectName=character(), NumMembers=numeric(), UCInetID=character(), Name=character())
for (i in 1:nrow(group_info)) {
  userdata <- fromJSON(call4users[i])
  teamdata <- teamdata %>% add_row(ProjectName=group_info$GroupName[i],NumMembers=group_info$MemberCnt[i],
                                   UCInetID=userdata$login_id,Name=userdata$name)
}


# get sections and the student names in each section
# https://canvas.eee.uci.edu/api/v1/courses/67737/sections/?include[]=students&per_page=100/
call4sections <- paste0(canvas_base,"courses/",class_id,sections_call)  ########## if more than one group (category), categorydata becomes a vector ################
sectiondata <- fromJSON(call4sections) 

sectionnames <- sectiondata$name
section_info <- tibble(SectionName=character(), Name=character())
for (i in 2:(length(sectionnames)-1)){
  for (j in 1:length(sectiondata$students[[i]][["name"]]))    {
  section_info <- section_info %>% add_row(SectionName=sectionnames[i], Name=sectiondata$students[[i]][[2]][j])
  }
}

sectionteamdata <- teamdata %>% left_join(section_info, by="Name")




#BaseDir <- setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#DataDir <- paste0(BaseDir,"/TeamTemplates/")
#setwd(DataDir)

#data = read.csv("GroupsWithNames.csv", header = TRUE, stringsAsFactors = FALSE)

write.csv(teamdata, file = "GroupsWithNames.csv",row.names=FALSE)
write.csv(sectionteamdata, file = "GroupsWithNamesAndSections.csv",row.names=FALSE)

