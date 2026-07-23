# Wildfire and Power Outages Research Letter

This repository contains/will contain analysis code, figures, and text for a research letter exploring the co-occurance of [wildfire disasters](https://github.com/lpiep/wildfire_disasters_lite), 
wildfire smoke events, and power outages in the US over time. 


## Note on geography changes

### Changes made in data set 

#### Connecticut County Changes

Eagle-i and the Childs WFS data sets do not use the updated counties in CT after 2024,
so we aggregated WFBZs by 2023 boundaries (which use the historical counties) for 
both 2024 and 2025. This is the only county change affecting all three data sets. 

### Potential changes

These county changes only become relevant if we look at places and times not included
in all three data sets.

#### Bedford, Virginia

None of the data sets recorded events in the former independent city of 
Bedford, Virginia. Bedford County experienced smoke events throughout the
study period, and this should be interpretted as affecting both Bedford 
County and City before they were integrated in 2013 (since the WFS data set
uses 2021 county boundaries throughout time). Eagle-i records started after consolidation.

#### Oglala Lakota, South Dakota

The WFS data set records events in Oglala Lakota County, SD before its name
and FIPS change from Shannon County in 2015. WFBZ recorded no events in either version of the county. 
Eagle-i records started after the name change.

#### York County and Newport News City, Virginia

In 2007, these counties exchanged some territory (pop 293). While a WFS event occurred in both
before the swap (which would not have been reflected in the WFS county boundaries),
there were no co-ocurring events from the other data sets before the swap, and Eagle-i 
records started after this swap. This discrepency is
small and would not make sense to correct. 

#### Alaska

Several county name and boundary changes occurred in the past two decades in Alaska, 
but as the WFS data set does not cover Alaska
and the Eagle-i data set only extends to 2018 (a time period that includes only one county change),
it does not make sense to attempt to rectify this. 
