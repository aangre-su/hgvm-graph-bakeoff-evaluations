#!/usr/bin/env bash
# Run after collateSTatistics.py.
# Makes plots comparing the graphs in each region.

set -ex

# Grab the input directory to look in
INPUT_DIR=${1}

if [[ ! -d "${INPUT_DIR}" ]]
then
    echo "Specify input directory!"
    exit 1
fi

# Set up the plot parameters
# Include both versions of the 1kg SNPs graph name
PLOT_PARAMS=(
    --categories
    snp1kg
    snp1000g
    haplo1kg
    sbg
    cactus
    camel
    curoverse
    debruijn-k31
    debruijn-k63
    level1
    level2
    level3
    prg
    refonly
    simons
    trivial
    vglr
    haplo1kg30
    haplo1kg50
    shifted1kg
    --category_labels 
    1KG
    1KG
    "1KG Haplo"
    7BG
    Cactus
    Camel
    Curoverse
    "De Bruijn 31"
    "De Bruijn 63"
    Level1
    Level2
    Level3
    PRG
    Primary
    SGDP
    Unmerged
    VGLR
    "1KG Haplo 30"
    "1KG Haplo 50"
    Control
    --colors
    "#fb9a99"
    "#fb9a99"
    "#fdbf6f"
    "#b15928"
    "#1f78b4"
    "#33a02c"
    "#a6cee3"
    "#e31a1c"
    "#ff7f00"
    "#FF0000"
    "#00FF00"
    "#0000FF"
    "#6a3d9a"
    "#000000"
    "#b2df8a"
    "#b1b300"
    "#cab2d6"
    "#00FF00"
    "#0000FF"
    "#FF0000"
    --font_size 20 --dpi 90 --no_n
)

# Where are the stats files
STATS_DIR="${INPUT_DIR}/stats"

# Where do we put the plots?
PLOTS_ROOT_DIR="${INPUT_DIR}/plots"

for MODE in `ls ${PLOTS_ROOT_DIR}`
do
    # We have normalized and absolute modes

    if [ "${MODE}" == "cache" ]
    then
        # Skip the cache directory
        continue
    fi
    
    # We want to write different axis labels in different modes
    PORTION="Portion"
    SECONDS=" (seconds)"
    RATE="rate"
    if [ "${MODE}" == "normalized" ]
    then
        PORTION="Relative portion"
        SECONDS=" (relative)"
        RATE=" relative rate"
    fi


    # We may be doing absolute or normalized plotting
    PLOTS_DIR="${PLOTS_ROOT_DIR}/${MODE}"
    mkdir -p "${PLOTS_DIR}"

    # We need overall files for mapped and multimapped
    OVERALL_MAPPING_FILE="${PLOTS_DIR}/mapping.tsv"
    OVERALL_MAPPING_PLOT="${PLOTS_DIR}/${MODE}-mapping.ALL.png"
    OVERALL_PERFECT_FILE="${PLOTS_DIR}/perfect.tsv"
    OVERALL_PERFECT_PLOT="${PLOTS_DIR}/${MODE}-perfect.ALL.png"
    OVERALL_ONE_ERROR_FILE="${PLOTS_DIR}/oneerror.tsv"
    OVERALL_ONE_ERROR_PLOT="${PLOTS_DIR}/${MODE}-oneerror.ALL.png"
    OVERALL_SINGLE_MAPPING_FILE="${PLOTS_DIR}/singlemapping.tsv"
    OVERALL_SINGLE_MAPPING_PLOT="${PLOTS_DIR}/${MODE}-singlemapping.ALL.png"

    for REGION in `ls ${PLOTS_DIR}/mapping.*.tsv | xargs -n 1 basename | sed 's/mapping.\(.*\).tsv/\1/'`
    do
        # For every region we ran
        
        # We have intermediate data files for plotting from
        MAPPING_FILE="${PLOTS_DIR}/mapping.${REGION}.tsv"
        MAPPING_PLOT="${PLOTS_DIR}/${MODE}-mapping.${REGION}.png"
        PERFECT_FILE="${PLOTS_DIR}/perfect.${REGION}.tsv"
        PERFECT_PLOT="${PLOTS_DIR}/${MODE}-perfect.${REGION}.png"
        ONE_ERROR_FILE="${PLOTS_DIR}/oneerror.${REGION}.tsv"
        ONE_ERROR_PLOT="${PLOTS_DIR}/${MODE}-oneerror.${REGION}.png"
        SINGLE_MAPPING_FILE="${PLOTS_DIR}/singlemapping.${REGION}.tsv"
        SINGLE_MAPPING_PLOT="${PLOTS_DIR}/${MODE}-singlemapping.${REGION}.png"
        ANY_MAPPING_FILE="${PLOTS_DIR}/anymapping.${REGION}.tsv"
        ANY_MAPPING_PLOT="${PLOTS_DIR}/${MODE}-anymapping.${REGION}.png"
        RUNTIME_FILE="${PLOTS_DIR}/runtime.${REGION}.tsv"
        RUNTIME_PLOT="${PLOTS_DIR}/${MODE}-runtime.${REGION}.png"
        
        NOINDEL_FILE="${PLOTS_DIR}/noindels.${REGION}.tsv"
        NOINDEL_PLOT="${PLOTS_DIR}/${MODE}-noindels.${REGION}.png"
        SUBSTRATE_FILE="${PLOTS_DIR}/substrate.${REGION}.tsv"
        SUBSTRATE_PLOT="${PLOTS_DIR}/${MODE}-substrate.${REGION}.png"
        INDELRATE_FILE="${PLOTS_DIR}/indelrate.${REGION}.tsv"
        INDELRATE_PLOT="${PLOTS_DIR}/${MODE}-indelrate.${REGION}.png"
        
        PERFECT_UNIQUE_FILE="${PLOTS_DIR}/perfect_vs_unique.${REGION}.tsv"
        PERFECT_UNIQUE_PLOT="${PLOTS_DIR}/${MODE}-perfect_vs_unique.${REGION}.png"
        
        echo "Plotting ${REGION^^}..."
        
        # Remove underscores from region names to make them human readable
        HR_REGION=`echo ${REGION^^} | sed 's/_/ /g'`
        
        # TODO: you need to run collateStatistics.py to build the per-region-and-
        # graph stats files. We expect them to exist and only concatenate the final
        # overall files and make the plots.
        
        ./scripts/boxplot.py "${MAPPING_FILE}" \
            --title "$(printf "Mapped (<=2 mismatches)\nreads in ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "${PORTION} mapped" --save "${MAPPING_PLOT}" \
            --x_sideways --hline_median refonly \
            --range \
            "${PLOT_PARAMS[@]}"
            
        ./scripts/boxplot.py "${PERFECT_FILE}" \
            --title "$(printf "Perfectly mapped\nreads in ${HR_REGION}")" \
            --x_label "Graph" --y_label "${PORTION} perfectly mapped" --save "${PERFECT_PLOT}" \
            --x_sideways --hline_median refonly \
            --range \
            "${PLOT_PARAMS[@]}"
            
        ./scripts/boxplot.py "${ONE_ERROR_FILE}" \
            --title "$(printf "One-error (<=1 mismatch)\nreads in ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "${PORTION}" --save "${ONE_ERROR_PLOT}" \
            --x_sideways --hline_median refonly \
            --range \
            "${PLOT_PARAMS[@]}"
        
        if [ "${HR_REGION}" == "CENX" ]
        then
            # There's hardly any single mapping in CENX, so we need to go down all the way.
            SINGLE_MAPPING_MIN=0
        else
            SINGLE_MAPPING_MIN=0.8
        fi
            
        ./scripts/boxplot.py "${SINGLE_MAPPING_FILE}" \
            --title "$(printf "Uniquely mapped (<=2 mismatches)\nreads in ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "${PORTION} uniquely mapped" --save "${SINGLE_MAPPING_PLOT}" \
            --x_sideways --hline_median refonly --min_min "${SINGLE_MAPPING_MIN}" \
            --range \
            "${PLOT_PARAMS[@]}"
            
        ./scripts/boxplot.py "${ANY_MAPPING_FILE}" \
            --title "$(printf "Mapped (any number of mismatches)\nreads in ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "${PORTION} mapped" --save "${ANY_MAPPING_PLOT}" \
            --x_sideways --hline_median refonly \
            --range \
            "${PLOT_PARAMS[@]}"
            
        ./scripts/boxplot.py "${RUNTIME_FILE}" \
            --title "$(printf "Per-read runtime\n in ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "Runtime per read${SECONDS}" --save "${RUNTIME_PLOT}" \
            --x_sideways --max_max 0.006 \
            --range \
            "${PLOT_PARAMS[@]}"
            
        ./scripts/boxplot.py "${NOINDEL_FILE}" \
            --title "$(printf "Mapped indel-free\nreads in ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "${PORTION} mapped" --save "${NOINDEL_PLOT}" \
            --x_sideways --hline_median refonly \
            --range \
            "${PLOT_PARAMS[@]}"
           
        if [ "${MODE}" == "absolute" ]
        then
            # Limit max Y for absolute substitution rates
            SUBSTRATE_LIMIT="--max 0.10"
        else
            SUBSTRATE_LIMIT="--max 2 --min 0"
        fi
        
        ./scripts/boxplot.py "${SUBSTRATE_FILE}" \
            --title "$(printf "Substitution rate\nin ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "Substitution ${RATE}" --save "${SUBSTRATE_PLOT}" \
            --x_sideways --hline_median refonly ${SUBSTRATE_LIMIT} --best_low \
            --range \
            "${PLOT_PARAMS[@]}"
            
        ./scripts/boxplot.py "${INDELRATE_FILE}" \
            --title "$(printf "Indels per base\nin ${HR_REGION} (${MODE})")" \
            --x_label "Graph" --y_label "Indel ${RATE}" --save "${INDELRATE_PLOT}" \
            --x_sideways --hline_median refonly --best_low \
            --range ${SUBSTRATE_LIMIT} \
            "${PLOT_PARAMS[@]}"

        # Plot perfect vs unique mapping
        scripts/scatter.py "${PERFECT_UNIQUE_FILE}" \
            --save "${PERFECT_UNIQUE_PLOT}" \
            --title "$(printf "Perfect vs. Unique\nMapping in ${REGION^^}")" \
            --x_label "Portion Uniquely Mapped" \
            --y_label "Portion Perfectly Mapped" \
            --width 12 --height 9 \
            --min_x 0 --min_y 0 \
            "${PLOT_PARAMS[@]}"
            
        
    done

    # Aggregate the overall files
    cat "${PLOTS_DIR}"/mapping.*.tsv > "${OVERALL_MAPPING_FILE}"
    cat "${PLOTS_DIR}"/perfect.*.tsv > "${OVERALL_PERFECT_FILE}"
    cat "${PLOTS_DIR}"/oneerror.*.tsv > "${OVERALL_ONE_ERROR_FILE}"
    cat "${PLOTS_DIR}"/singlemapping.*.tsv > "${OVERALL_SINGLE_MAPPING_FILE}"

    # Make the overall plots
    ./scripts/boxplot.py "${OVERALL_MAPPING_FILE}" \
        --title "$(printf "Mapped (<=2 mismatches)\nreads (${MODE})")" \
        --x_label "Graph" --y_label "Portion mapped" --save "${OVERALL_MAPPING_PLOT}" \
        --x_sideways  --hline_median trivial \
        --range \
        "${PLOT_PARAMS[@]}"
        
    ./scripts/boxplot.py "${OVERALL_PERFECT_FILE}" \
        --title "$(printf "Perfectly mapped\nreads (${MODE})")" \
        --x_label "Graph" --y_label "Portion perfectly mapped" --save "${OVERALL_PERFECT_PLOT}" \
        --x_sideways --hline_median trivial \
        --range \
        "${PLOT_PARAMS[@]}"
        
    ./scripts/boxplot.py "${OVERALL_ONE_ERROR_FILE}" \
        --title "$(printf "One-error (<=1 mismatch)\nreads (${MODE})")" \
        --x_label "Graph" --y_label "Portion" --save "${OVERALL_ONE_ERROR_PLOT}" \
        --x_sideways --hline_median trivial \
        --range \
        "${PLOT_PARAMS[@]}"

    ./scripts/boxplot.py "${OVERALL_SINGLE_MAPPING_FILE}" \
        --title "$(printf "Uniquely mapped (<=2 mismatches)\nreads (${MODE})")" \
        --x_label "Graph" --y_label "Portion uniquely mapped" --save "${OVERALL_SINGLE_MAPPING_PLOT}" \
        --x_sideways --hline_median refonly \
        --range \
        "${PLOT_PARAMS[@]}"
        
done

