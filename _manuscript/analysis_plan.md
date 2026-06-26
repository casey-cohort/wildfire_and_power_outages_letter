# Analysis plan for a research letter

## How many people are exposed to power outage + wildfire smoke and disaster at the same time, and how has this changed over the last decade?

## Authors

heather, logan, joan, nina?, marissa?

### Roles
-	Heather to write analysis plan and write up paper, logan to clean data and create figures 
-	Nina, joan to help with developing analysis plan and potentially outline
-	nina, joan, logan, marissa to read draft and provide feedback
-	we’ll use marissa’s data 

## Intro/motivation

-	Power outage increasing with climate change and AI (demands on grid from heat, cold, extreme weather, and electrification, power outage due to extreme weather, data center demand)
-	Wildfire frequency, severity also increasing and number of people in evacuation zones or with houses in high-risk areas increasing due to increasing risk with climate change and development in WUI
-	Power outage often accompanies wildfire smoke and disaster
-	Electrical lines may start fires and then burn resulting in power outages 
-	There are preventative outages during hot and dry fire weather, and then during disasters, there are automatic fault shutoffs, infrastructure damage, shutoffs to protect emergency crews
-	Wildfire and wildfire smoke also happens when it’s hot and with heat there can be AC surges resulting in co-occurring outages not directly related to the smoke or fire 

-	Power outage is associated with adverse health outcomes (carbon monoxide poisoning, accidents especially for children, cardiovascular and respiratory disease hospitalizations, esp. COPD and asthma)
-	Smoke associated with a RANGE of acute adverse outcomes – resp and cvd outcomes, perinatal outcomes, irritation, mental illness exacerbation
-	Some studies beginning to address disaster effects beyond mental health – stress contributing to cvd + resp outcomes, accidents

-	Seems like co-exposure to both wildfire disaster and power outage could be worse for health
-	Power outage bad for DME users and people who are sensitive to heat and cold – older adults, disabled people
-	Also means elevators, lifts, communication devices, lights, etc. don’t work – can have health consequences – accidents for children, accidents for people relying on these mobility devices, or reduced mobility/isolation, communication barriers for people who use adaptive tech, communication barriers for people who are isolated other than using cellphones/internet to communicate
-	PO in a disaster setting can prevent people from escaping fires (ex. of woman who died in Camp because she couldn’t open her garage door)
-	Can worsen heat and smoke exposure – no AC, no air purifiers 
-	Potentially leading to more respiratory and cardiovascular-related hospitalizations 

-	Despite potential co-exposure risks, no studies on this so far at all.

-	In this paper we look at how many people were exposed to wf smoke or wf disaster and power outage at the same time over the last decade 2014-2025

## Data

-	Power outage data: eagle-i 2014-2025
-	Wildfire disaster: new wf disaster dataset 2014-2025
-	Smoke: childs et al. 2023

## Analysis 

Goal is to come up with ONE FIGURE that represents the co-exposure to these hazards over time, since this is meant to be a research letter. Presumably we’ll have one panel for PO + disaster and one panel for PO + smoke. 

For the analysis plan below, I’ve provided some ideas with the plan that logan can make a bunch of these figures and then we can pick the best ones.

### Po exposure assessment
-	County-level 
-	Two strategies:
-	Number of hrs without power 
-	8+ hour power outages
-	Historically we’ve defined outage with a cut point and a duration – so for example if more than 0.1% of county customers were without power for more than 8 hours, that would be a power outage. And then calculated number of hours without power as number of hrs where county had >0.1% of customers without power.
-	I think instead we should use a cut point and an absolute number like for heat waves, since some counties have hugely different numbers of people (500 vs. 10 million). This makes the percentage cut point suspect. We want to include large counties where many, many people are out as having an outage, even if that outage doesn’t surpass the cut point (ex if 200,000 people are out in LA county that is only 2% of people). So instead we could do power outage if the number of people out exceeds 1% of population OR 5000 people. It would be helpful to do an EDA of the eagle-i dataset in order to pick what these numbers should be, so logan you could adjust the 1% and 5000 to numbers that make sense. 
-	I think then for the purposes of this paper we should consider entire counties and everyone in those counties exposed to outage if there is an outage in the county. 
-	This is not great since it includes unexposed people

-	One alternative strategy is to look at counties that meet that definition (>1% or >5000 out) and take the maximum number of people without power for 8 consecutive hours, and say those people were exposed to power outage in that county
-	More on this in a second.

### Wf disaster exposure:

-	For this we have similar choices to make.
-	We can either say a county was exposed if more than a certain percentage of people were exposed (ex. >10% of people within 10km of a wf disaster boundary)
-	Or, we can find the actual number of people within 10km of the boundary and consider them exposed.

-	If we look at who was exposed within counties, instead of looking at which counties were exposed, we’re not going to know if the same people were exposed to outage and disaster at the same times. 

-	I think that this means the best strategy is to look at COUNTIES exposed to both throughout the time period

-	We also need to consider timing – what about saying a disaster co-occurred with outage if there was an outage starting 3 days before fire ignition and ending a week after fire ignition? 

### Wf smoke exposure

-	Looking at counties exposed throughout the time period can also be nice because then we can just consider counties exposed to wildfire smoke if the mean smoke concentration across the county is above 15 micrograms/cubic meter or something like that. I think 15 is a common threshold used in the epi literature. 
Suggested plots:
-	County-level map of number of people co-exposed to wildfire smoke and wildfire disaster by year (maybe an animation?) (number of people in counties with a PO in time window around a disaster, aka counties with >1% of people or >5000 people out for 8+ hours and >10% of county population within 10km of wildfire disaster boundary), and then also number of people in counties with PO on the same day as smoke concentrations >15 micrograms)
-	Line graph of number of people co-exposed by month over the time period to wf disaster and power outage and wf smoke and power outage, same definitions as above
-	Could also do number of person-hours of outage in counties affected by disaster, starting 3 days before disaster ignition and ending a week after ignition
-	And similarly could do number of person-hours of outage on days >15 micrograms of wf smoke in the county
-	Plot over time by month the number of days with power outage in counties affected by wildfire disaster starting three days before the disaster and ending a week later 
-	Number of county-days with power outage and disaster (starting three days before the disaster and ending a week later)
-	Number of county-days with power outage and smoke concentrations above 15 micograms.
-	Could also vary these thresholds – 5 micrograms, 15, 30, PO at 0.5%, 1%, 3%, 5% of population, with or without an additional raw number like ?5000 people out


