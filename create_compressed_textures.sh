#!/bin/sh

# NOTE:
# Download, Build and place binaries (crunch, astcenc, PVRTexToolCLI) in THIS folder before run!
# crunch: https://github.com/BinomialLLC/crunch
# astcenc: https://github.com/ARM-software/astc-encoder
# PVRTexToolCLI: https://www.imaginationtech.com/developers/powervr-sdk-tools/pvrtextool/


export PATH=/opt/Imagination\ Technologies/PowerVR_Graphics/PowerVR_Tools/PVRTexTool/CLI/Linux_x86_64:$PATH

# ASTC
#block_footprint=(4x4 5x4 5x5 6x5 6x6 8x5 8x6 8x8 10x5 10x6 10x8 10x10 12x10 12x12)

res_dirs=(
	resources_vrlab
)


for rdir in "${res_dirs[@]}"; do
  (cd $rdir

#    if [ -d "textures" ]; then
#      echo "[!] Directory '$rdir/textures' exists; Will be removed!!!"
#      rm -r textures
#    fi

    models_fbx=(*.{fbx,FBX})
    for fbx in "${models_fbx[@]}"; do
      fbx_noext="${fbx%.*}"
      tex_dir="$fbx_noext.fbm"

      if [ ! -d "$tex_dir" ]; then
        echo "[!] Cannot find '$tex_dir' directory. Skipped!"
        continue
      fi

      if [ -z "$(ls -A $tex_dir)" ]; then
        echo "[!] Directory '$tex_dir' is empty. Skipped!"
        continue
      fi


      # create output directory
      output_dir="textures/$fbx"
      echo "Creating '$output_dir' directory"
      mkdir -p $output_dir
      sh ../compressed_textures_dir.sh $tex_dir $output_dir
    done

    sh ../compressed_textures_dir.sh textures textures
  )
done



# ETC
#./PVRTexToolCLI -i ./src/etc1.png -l -m -flip y,flag -f ETC1,UBN,lRGB -o compressed_etc1.ktx
#./PVRTexToolCLI -i ./src/etc2.png -l -m -flip y,flag -f ETC2_RGBA,UBN,lRGB -o compressed_etc2.ktx
