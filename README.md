# ACTIVPAL processing


This repo contains [MATLAB](https://www.mathworks.com/products/matlab.html) codes to extract activity metrics from raw accelerometer data obtained from [activPAL](https://www.palt.com/) devices.

## Overview

Public health studies have been interested in measuring the activity level of different populations to assess their wellbeing.
For these studies, accelerometers are a common choice to obtain reliable activity measurements.
However, their outputs are typically endless tables describing the participant's status every second!

I created this repo to give tools to the researchers to interpret this huge amount of data.
Along with the raw accelerometer data for each participant, we also need a log describing when the accelerometer was worn during the study.
Processing these files allows to extract the sedentary and active times of each participant, along with numerous other metrics such as standing time, sitting time, time spent doing light physical activity (LPA) and moderate-vigorous physical activity (MVPA).

Detailed explanations about how to use the codes are available in the files `Code Instructions.pdf` and `Manuscript.pdf`.

## Folder organization

- [codes](codes) contains the two MATLAB codes processing the data and logs to create the desired output files.
- [data](data) contains the accelerometer data obtained from the activPAL. The name and format should respect that of the example found in this folder. The actual data cannot be released, we only provide a template file.
- [logs](logs) contains the logs of each participant tracking the times when the accelerometer was turned on and off during the study. The name and format should respect that of the example found in this folder. The actual data cannot be released, we only provide a template file.
- [outputs](outputs) contains the output files created by the codes. One file is created per participant and a summary file gather their averages.


## Codes

-`main.m` reads the accelerometer data and the log of each participant before calculating the total time they spent wearing the device, along with their sedentary, upright, moving, standing, light physical activity (LPA), and moderate-vigorous physical activity (MVPA) times per day. This needs to be run for each participant prior to launching `Summary.m`.

-`Summary.m` gathers the average times of wear, sedentary, upright, moving, standing, LPA, and MVPA of each participant in a single file.
This file contains three (3) sheets, one for the study averages, one for the weekday averages, and one for the weekend averages.
