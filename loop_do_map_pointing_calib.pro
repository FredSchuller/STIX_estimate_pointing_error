pro loop_do_map_pointing_calib, display_maps=display_maps
  ; loop on the events that I've been using to estimate pointing systematic error
  ; FSc, 2023-06-09
  ; updated 2023-07-25: many more events in the list now
  ; last modif: 2023-08-31

  ; Input text (csv) file with all parameters:
  in_file = '/home/fschuller/Documents/SolarOrb/Flare_location_SDO+STIX-imaging.csv'
  im_param = read_csv(in_file, n_table_header=2, table_header=tab_header)
  ; store the relevant parameters into separate variables...
  uid = im_param.field4
  ; ... but filter already out the ones for which I did not give an UID (for whatever reason,
  ; e.g. if imaging was not possible or if I could not measure the location in AIA map)
  ok = where(uid ne 0, nb)
  uid = uid[ok]
  t_peak = im_param.field1[ok]
  t_min = im_param.field5[ok]
  t_max = im_param.field6[ok]
  e_min = im_param.field7[ok]
  e_max = im_param.field8[ok]

  ; I/O directories:
  path_stix_data = '/store/data/STIX/L1_FITS_SCI/'                 ; input path where the STIX L1 files are located
  path_stix_maps = '/net/galilei/work2/fschuller/data/STIX-maps/'  ; Output path where to store the STIX maps

  ; Default parameters for imaging
  imsize = [201,201]
  pixel = [1.,1.]
  no_sas = 1  ; use s/c pointing WITHOUT applying aspect solution

  for i=0,nb-1 do begin
    this_uid = strtrim(uid[i],1)
    map_stix = stx_imaging_pipeline(this_uid, [t_min[i], t_max[i]], [e_min[i], e_max[i]], $
                                    imsize=imsize, pixel=pixel, no_sas=no_sas)

    if keyword_set(display_maps) then begin
      ; display the map
      wset, 5
      !p.background = 255  &  !p.charsize = 1.8
      loadct, 5
      plot_map, map_stix, col=0., /limb, grid_sp=5.
      pause
    endif

    ;;;;; Create the filename of the STIX FITS file
    fname_stix_fits = path_stix_maps + t_peak[i] + '_' + this_uid + '_No-SAS_mem.fits'
    ; we need the full path to the L1 SCI file:
    path_sci_file = findfile(path_stix_data+'*cpd*'+this_uid+'*.fits')
    stx_map2fits, map_stix, fname_stix_fits, path_sci_file

  endfor
end

