# Copyright 2025-Present Felix Sapora. All rights reserved.

# Check if glslangValidator is available
if ! command -v glslc &> /dev/null
then
    echo "glslc could not be found. Please install it."
    exit 1
fi

# Loop through all .frag and .vert files in the current directory
for shader_file in src/shaders/*.frag src/shaders/*.vert; do
    # Only process files that exist (in case no .frag or .vert files are present)
    if [ -f "$shader_file" ]; then
        # Determine the base filename without the extension
        base_filename="${shader_file%.*}"

        # Compile fragment shaders (.frag)
        if [[ "$shader_file" == *.frag ]]; then
            echo "Compiling $shader_file to $base_filename.frag.spv"
            glslc "$shader_file" -o "$base_filename.frag.spv"
        fi

        # Compile vertex shaders (.vert)
        if [[ "$shader_file" == *.vert ]]; then
            echo "Compiling $shader_file to $base_filename.vert.spv"
            glslc "$shader_file" -o "$base_filename.vert.spv"
        fi
    fi
done

echo "Shader compilation complete."
