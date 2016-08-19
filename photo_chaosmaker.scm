; Photo-ChaosMaker v0.3
;
; Copyleft 2006 by Giacomo "jamez" Miceli <jamez at jamez dot it>
;
; Based on ideas freely available around.
; 
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;bash syntax for scripting
;gimp-2.2 -i -b '(photo-chaosmaker "/home/josh/pics/" "/home/josh/.gimp-2.2/scripts/black_gray.png" "/home/josh/wallpaper.jpg" "Reprobate" 100 9 0 )' '(gimp-quit 0)'

(define (photo-chaosmaker directory background_file save_to fontname distance limit resolution)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Configuration;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;let's initialize some variables. tweak with these parameters only if you know what you're doing!
;
;set path to the polaroid frame
(set! polaroid (string-append "" gimp-directory "/scripts/polaroid.png"))
;unused borders in px to keep the photo-chaos in the middle of the wallpaper
;right border
(set! width_coord_limit 2128) ;previously 1900
;lower border
(set! height_coord_limit 1419) ;previously 1100 
;left border
(set! width_margin 236) ;previously 400
;upper border
(set! height_margin 177) ; previously 300
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;allocate directory's file list
(set! pattern (string-append directory "*.jpg"))
(set! nfiles (car (file-glob pattern 1)))
(set! filelist (cadr (file-glob pattern 1)))

;sanity check
(if (> limit nfiles) (set! limit nfiles) )

;initializing randomizer and coordinates lists
(srand (realtime))
(set! listcoordx ())
(set! listcoordy ())
(set! recursion ())

;load the background
(set! background (gimp-file-load 0 background_file background_file))

;load polaroid frame
(set! input1_base (gimp-file-load 0 polaroid polaroid))
(set! input1_drawable_base (gimp-image-get-active-drawable (car input1_base)))

;main cycle. for "limit" times, do the following iterations
 (while (= (> limit 0) t)
(srand (realtime))
(set! randomic (rand nfiles))
(set! filetoprocess filelist)

;main subroutine. for every picture, do the following:
(while (= (> randomic 0) t) (set! filetoprocess(cdr filetoprocess)) (set! randomic (- randomic 1) ) )

;remove this picture from the selectable ones, in order to avoid repetitions
(set! temp (car filetoprocess))
(set! filelist (delq temp  filelist))
(set! nfiles (- nfiles 1))

;load the polaroid base picture
;CHANGE HERE
(set! input1 (gimp-image-new 574 644 0)) 
(gimp-layer-new (car input1) 574 644 0 "polaroid" 0 0) 
(set! input_pic (gimp-layer-new-from-drawable (car input1_drawable_base) (car input1))) 
(gimp-image-add-layer (car input1) (car input_pic) 0) 
(set! input1_drawable (gimp-image-get-active-drawable (car input1))) 

;undocumented feature, kind of a geeky surprise
(if (and (= limit 1) (= randomic 1) )
(begin (set! recursive_frame (gimp-image-new 700 525 0))  (gimp-layer-new (car recursive_frame) 700 525 0 "R" 0 0)        (set! background_drawable (gimp-image-get-active-drawable (car background))) (set! recursive_pic (gimp-layer-new-from-drawable (car background_drawable) (car recursive_frame))) (gimp-image-add-layer (car recursive_frame) (car recursive_pic) 0)  ) )
;load the picture to process 
(if (and (= limit 1) (= randomic 1) )
(set! input2 recursive_frame) 
(set! input2 (file-jpeg-load 0 (car filetoprocess) (car filetoprocess))) )
(set! input2_layer (gimp-image-get-active-layer (car input2)))

;picture title (filename) handling
(set! title (substring (car filetoprocess) (- (string-length pattern) 5) (string-length (car filetoprocess) ) ))
(if (and (= limit 1) (= randomic 1) )
(set! title "Recursion!xxxx" )
)

;set initial font dimension for resoluting most appropriate size
(set! dim_font 5)
(set! real_width 0)
(set! real_height 0)

;brute force most appropriate font size for given text frame (565*105)
(while (= (= (< real_width 565) (< real_height 105) ) t) (set! size (gimp-text-get-extents-fontname (substring title 0 (- (string-length title) 4) ) dim_font 0 fontname)) (set! real_width (car size))(set! real_height (car (cdr size))) (set! dim_font (+ dim_font 1) ) )

;actually create the picture frame with text
(gimp-text-fontname (car input1) (car input1_drawable) (- 287 (/ real_width 2)) (- 582 (/ real_height 2)) (substring title 0 (- (string-length title) 4) ) -1 TRUE (- dim_font 2) 0 fontname)

;scale the picture to more convinient size
(if (< (car(gimp-image-width (car input2))) (car(gimp-image-height (car input2))) )  (gimp-layer-scale (car input2_layer) 525 700 0)(gimp-layer-scale (car input2_layer) 700 525  0))

;copy and paste stuff
(set! input2_drawable (gimp-image-get-active-drawable (car input2)))
(set! input2_layer (gimp-layer-new-from-drawable (car input2_drawable) (car input1)))
(gimp-image-add-layer (car input1) (car input2_layer) 0)

;put the freshly attached layer on the bottom
(gimp-image-lower-layer-to-bottom (car input1) (car input2_layer))

;allign tidily the pasted picture with the frame
(if (< (car(gimp-image-width (car input2))) (car(gimp-image-height (car input2))) )(gimp-layer-translate (car input2_layer) 22 -60)(gimp-layer-translate (car input2_layer) -60 22))

;now this frame is ready to be tossed into the wallpaper!
(set! flattened (gimp-image-flatten (car input1) ) )

;deprecated: save every framed-picture overwriting the source
;(file-jpeg-save 1 (car input1)  (car (gimp-image-get-active-drawable (car input1)))  (car filelist) (car filelist) 1 0.5 1 0 "" 0 0 0 0)

;copy and paste junk
(set! input1_drawable (gimp-image-get-active-drawable (car input1)))
(set! input1_layer (gimp-layer-new-from-drawable (car input1_drawable) (car background))) 
(gimp-image-add-layer (car background) (car input1_layer) 0)
 
;randomization of picture's angle of rotation
(srand (realtime))
(set! randomic (rand 100))
(set! randomic (/ randomic 100))
(set! pariodispari (rand 2))

;rotation left or right?
(if (= pariodispari 1) (set! randomic (* randomic -1 )))
(set! rotated (gimp-rotate (car input1_layer) 1 randomic))

;try a set of coordinates
(set! randx (rand width_coord_limit)) 
(set! randx (+ randx width_margin))
(set! randy (rand height_coord_limit))
(set! randy (+ randy height_margin))
(set! listcoordx (cons randx listcoordx ))
(set! listcoordy (cons randy listcoordy ))

;save the list on a temporary for the following destructive scan
(set! listcoordxtemp listcoordx)
(set! listcoordytemp listcoordy)

;sub-routing for the search of good coordinates
(while (= (= listcoordxtemp listcoordytemp ) () )

;;DISTANTIATION OF COORDS!
;in order to avoid high concentration of picture in a specific area, we mantain a list of coords and we check not to toss the freshly created pic too close to the previously pasted.
;;kinda buggy yet!

(set! flag ())
(if  (= (= (< (+ (car listcoordxtemp) distance) randx) (< (- (car listcoordxtemp) distance) randx)) () )  (if (= (= (< (+ (car listcoordytemp) distance) randy) (< (- (car listcoordytemp) distance) randy)) ()) (set! flag t) ) )
 (if (= flag t) ( begin (set! randx (+ (rand width_coord_limit) width_margin)) (set! randy(+ (rand height_coord_limit) height_margin )) (set! listcoordxtemp listcoordx) (set! listcoordytemp listcoordy) )(begin (set! listcoordxtemp(cdr listcoordxtemp)) (set! listcoordytemp(cdr listcoordytemp)) ))
)
;We found nice coords. Let's put them in the lists
(set! listcoordx (cons randx listcoordx ))
(set! listcoordy (cons randy listcoordy ))

;place the picture in the selected coordinates
(gimp-layer-translate (car input1_layer) randx randy)

;flatten the whole thing
(set! flattened (gimp-image-flatten (car background) ) )

;go on with the cicle
(set! limit (- limit 1))

;free some memory
(gimp-image-delete (car input2))

) ;end while

(if (= resolution 0) (begin (set! final_width 1024) (set! final_height 768)) )
(if (= resolution 1) (begin (set! final_width 800) (set! final_height 600) ) )
(if (= resolution 2) (begin (set! final_width 1280) (set! final_height 960)) )

;resize and save
(gimp-image-scale (car background) final_width final_height)
(file-jpeg-save 1 (car background)  (car (gimp-image-get-active-drawable (car background)))  save_to save_to 1 0.5 1 0 "" 0 0 0 0)
)


;script fu registration
(script-fu-register "photo-chaosmaker"
"<Toolbox>/Xtns/Script-Fu/photo-chaosmaker"
"The photo-chaosmaker, a little utility to generate funny desktop wallpapers. Takes in input a directory of pictures, extracts N of them, generates nice polaroid frames along with a description (using the filename), then scatters them chaotically on a given surface (a table, a floor, blackscreen...)."
"Giacomo 'jamez' Miceli (jamez at jamez dot it)"
"You mean *copyleft*!"
"2006-02-20"
""
SF-STRING     _"Directory with source pictures (with trailing slash)"               "/home/josh/pics"
SF-FILENAME   _"Background Image"   (string-append "" gimp-directory "/scripts/black_gray.png")
SF-STRING   _"Save to"               "/home/josh/wallpaper.jpg"
SF-FONT       _"Font for photo description"               "Reprobate"
SF-ADJUSTMENT _"Minimum distance between photos (pixels)" '(100 0 180 1 1 0 1)
SF-ADJUSTMENT _"Number of photos to use in the wallpaper" '(8 1 20 1 1 0 1)
SF-OPTION     _"Resolution of the wallpaper" '(_"1024x768"
					       _"800x600"
					       _"1280x960")

)
