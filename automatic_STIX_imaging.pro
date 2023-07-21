; ****************************************************************************
; Automatic STIX imaging for Frederic's events
; 
; Before running this code, the STIX cpd and aux data have to be automatically
; downloaded using download_STIX-cpd-aux_stixpy.ipynb
; 
; Last version: 18-Jul-2023
; ****************************************************************************



; ******************** INPUT PARAMETERS ********************

;;;;; Path to Frederic's table
path_csv_list = '/home/afbattaglia/Software/STIX_estimate_pointing_error/Flare-location_test-table.csv'

;;;;; Path to the folder containing folders with the files for each flare
path_folders_stix_data = '/home/afbattaglia/Documents/ETHZ/PhD/Codes/automatic_STIX-AIA_location_comparison/Data/SO_STIX/'

;;;;; Path where to store the STIX maps
path_stix_maps = '/home/afbattaglia/Documents/ETHZ/PhD/Codes/automatic_STIX-AIA_location_comparison/STIX-maps/'

;;;;; Standard imaging parameters
subc_index = stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c','6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])
imsize = [257,257]
pixel = [1.,1.]

; **********************************************************










;;;;; Get the folder delimiter (different for different OS)
folder_delimiter = path_sep()

;;;;; Check if path_stix_maps and path_folders_stix_data are effectively folders
if not path_stix_maps.endswith(folder_delimiter) then path_stix_maps = path_stix_maps.insert(folder_delimiter,path_stix_maps.strlen())
if not path_folders_stix_data.endswith(folder_delimiter) then path_folders_stix_data = path_folders_stix_data.insert(folder_delimiter,path_folders_stix_data.strlen())

;;;;; Read Frederic CSV
data_csv = read_csv(path_csv_list, HEADER=header_csv, $
  N_TABLE_HEADER=1, TABLE_HEADER=table_header)
peak_times  = data_csv.field1
uids        = data_csv.field4
start_times = data_csv.field5
end_times   = data_csv.field6
erange_min  = data_csv.field7
erange_max  = data_csv.field8
nflares = n_elements(peak_times)

;;;;; Get the list of folders containing the STIX data
list_stix_folders = findfile(path_folders_stix_data)

;;;;; Loop on all elements in the list and do imaging.
; Then, store the image as a FITS file
for this_el = 0, nflares-1 do begin
  
  ;;;;; Variables of interest
  this_peak_time  = peak_times[this_el]
  this_uid        = uids[this_el]
  this_time_range = [start_times[this_el], end_times[this_el]]
  this_erange     = [erange_min[this_el], erange_max[this_el]]
  
  ;;;;; Get the sci and aux files of interest
  path_sci_file = findfile(path_folders_stix_data+'*'+num2str(this_uid)+'*'+folder_delimiter+'*cpd*')
  aux_fits_file = findfile(path_folders_stix_data+'*'+num2str(this_uid)+'*'+folder_delimiter+'*aux*')
  
  ;;;;; Create aux data
  aux_data = stx_create_auxiliary_data(aux_fits_file, this_time_range)
  
  ;;;;; Estimate flare location
  stx_estimate_flare_location, path_sci_file, this_time_range, aux_data, flare_loc=flare_loc;, path_bkg_file=path_bkg_file
  xy_flare_stix = flare_loc
  mapcenter = flare_loc
  
  ;;;;; Coordinate transformaion
  ; from Helioprojective Cartesian to STIX coordinate frame
  mapcenter_stix = stx_hpc2stx_coord(mapcenter, aux_data)
  xy_flare_stix  = stx_hpc2stx_coord(xy_flare_stix, aux_data)
  
  ;;;;; Create visibility structure
  vis = stx_construct_calibrated_visibility(path_sci_file, this_time_range, this_erange, mapcenter_stix, $
    xy_flare=xy_flare_stix, subc_index=subc_index);, path_bkg_file=path_bkg_file)
  
  ;;;;; MEM
  mem_map = stx_mem_ge(vis,imsize,pixel,aux_data,total_flux=max(abs(vis.obsvis)))
  
  ;;;;; Create the filename of the STIX FITS file
  fname_stix_fits = path_stix_maps + this_peak_time + '_' + num2str(this_uid) + '_mem.fits'
  stx_map2fits,mem_map,fname_stix_fits,path_sci_file
  
endfor


end ; End of the script