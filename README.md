# PSTAR_Data_Processing

## Calibrating/Geotagging FLIR IR Imagery from weather station or UAV
  ### FLIR Duo Pro R and Vue Pro R data can be captured in either .rjpeg or .tiff formats with somewhat different processing procedures for each. .rjpeg files contain the radiometric calibration information recorded by the instrument and input by the user at capture time (this doesn't mean those values are correct). However, that file format is more difficult to manipulate and the only way I have managed to do so is using the exiftool.exe package. .tiff files do not contain the metadata, though that can be applied in post processing.
  ### To calibrate .rjpeg data from a single flight, copy all data to a new folder, then run the FLIR_Rjpg_Processing.m matlab script section by section as needed. exiftool.exe and the gpx.fmt (in working dir) file are required
  ### To calibrate .tiff data, a simple initial conversion to temperature can be achieved with: 0.04.*RAW_Value-273.15
  ### This is included in the FLIR_tiff_Processing.m matlab script, which also allows radiometric parameters to be input manually if desired. If radiometric parameters are not included, the data must ultimately be directly calibrated (additively) to a temperature reference within the image. Then the calibrated data can be run through the same set of additional processing steps listed in FLIR_Rjpg_Processing.m.

## Mosaicking FLIR IR UAV imagery
### See Sfm Workflow.docx
### In cold or homogenous scenes IR data can be very difficult to mosaic and might take many rounds of manually editing the point cloud and realigning or entering tie points manually to get images to align

## Mosaicking Micasense UAV imagery
### See https://support.micasense.com/hc/en-us/articles/360002693373-Process-MicaSense-sensor-data-in-Agisoft-Metashape
