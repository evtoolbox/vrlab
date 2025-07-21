@echo off
setlocal enabledelayedexpansion

set PATH=%PATH%;C:\Imagination Technologies\PowerVR_Graphics\PowerVR_Tools\PVRTexTool\CLI\Windows_x86_64;C:\exiftool


if "%1" == "/grayscale" (
   set "grayscale=true"
   echo Grayscale images will be processed too...
) else (
   set "grayscale="
)

if "%*" == "" (
   set true=1
)

if "%*" == "/grayscale" (
   set true=1
)


if defined true (
   set res_dirs=resources
) else (
   set res_dirs=%*
   if defined grayscale (
   for /f "tokens=1,* delims= " %%a in ("%*") do set res_dirs=%%b
)
)

for %%a in (%res_dirs%) do (
   cd %cd%
   cd %%a
   if exist textures\ (
    echo Directory %%a/textures already exists. Will be removed!
    rd /s /q textures\
   ) 

   echo %%a | findstr ":\\"  && (
      set "output_dir=%%a"
   ) || (
      set "output_dir=%cd%\%%a"
   )
      
   set "models="
   for %%f in (*.fbx) do (
    if "%%~xf"==".fbx" (
      call set "models=!models!, %%f"
      )
    if "%%~xf"==".FBX" (
      call set "models=!models!, %%f"
      )
   )
   
   for %%f in (!models!) do (
      set "continue="
      echo Model is %%f
      if exist "%%~nf.fbm\" (
         
         dir /b /s /a "%%~nf.fbm\" | findstr .>nul || (
         echo Empty textures directory, skipping...
         set "continue=1"
      )
         
      ) else (
         echo Textures for model %%f does not exist, skipping...
         set "continue=1"
      )

      if not defined continue (
         echo Processing %%~nf
         mkdir "textures/%%f"
         cd %%~nf.fbm\
         
         for %%G in (*.jpg *.png *.tga *.bmp) do (
            echo Image to be compressed is %%G
            
            if defined grayscale (
               PVRTexToolCLI -i "%%G" -j 4 -ics lRGB -pot - -m -flip y,flag -f ASTC_6x6,UBN,lRGB -q astcthorough -o "!output_dir!\textures\%%f\%%G.ktx"
            ) else (
               exiftool -ColorType "%%G" | findstr -i "grayscale" && (
               echo Grayscale image, skipping...
            ) || (
               PVRTexToolCLI -i "%%G" -j 4 -ics lRGB -pot - -m -flip y,flag -f ASTC_6x6,UBN,lRGB -q astcthorough -o "!output_dir!\textures\%%f\%%G.ktx"
            )
            )
            )
         cd ..
         )
      )
   cd ..
   )
 
