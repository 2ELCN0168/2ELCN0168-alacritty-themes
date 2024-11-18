#! /bin/bash

create_configuration() {

        local a=""
        
        printf "${R}[!]${N} It seems that you have no alacritty configuration "
        printf "file.\n"
        printf "Would you like to create one? ${Y}[Y/n]${N} "

        read -r a
        : "${a:=Y}"

        if [[ "${a}" =~ ^[yY]$ ]]; then
                cat <<-EOF > "${1}"
                [General]
                import = [
                        
                ]
EOF
        elif [[ "${a}" =~ ^[nN]$ ]]; then
                printf "${R}[!]${N} We cannot set a theme without a "
                printf "configuration file! "
                printf "Exiting..."
                exit 1
        fi
}

invalid_theme_path() {

        printf "${R}[!]${N} It seems that you haven't set any themes "
        printf "path.\n${N}"
        printf "Edit ${P}'THEMES_PATH'${N} in this script to set it up and "
        printf "relaunch it!\n\n"
        
        exit 1
}

list_themes() {

        tput clear
        printf "${Y}::${N} Themes available:\n\n"

        local themes_files=("${1}"/*.toml)
        local total_themes="${#themes_files[@]}"
        local term_width=$(tput cols)
        local min_col_width=33
        local columns=$(( term_width / min_col_width - 1 ))
        (( columns < 1 )) && columns=1

        local rows=$(( (total_themes + columns - 1) / columns))

        for (( i = 0; i < rows; i++ )); do
                for (( a = 0; a < columns; a++ )); do
                        index=$(( i + a * rows ))

                        if (( index < total_themes )); then
                                theme_name=$(basename -s '.toml' ${themes_files[index]})
                                theme_number=$(( index + 1 ))

                                if (( col % 2 == 0 )); then
                                        printf "${C}[%3s]${N} - %-33s" \
                                        "${theme_number}" "${theme_name}"
                                else
                                        printf "${DC}[%3s]${N} - ${GR}%-33b${N}" \
                                        "${theme_number}" "${theme_name}"
                                fi
                        fi
                done
                printf "\n"
        done
        printf "\n"

}

theme_selection() {

        local themes_path="${1}"
        local ans_selection=0
        local themes_files=("${themes_path}"/*.toml)
        local theme_path=""
        local confirm_selection="n"


        while true; do
                list_themes "${themes_path}"
                printf "${Y}[?]${N} Type the theme ${P}ID${N} you want to "
                printf "use.\n"
                printf "(${P}[q]${N} to exit/${P}[Enter]${N} to apply/${P}"
                printf "[Ctrl + C]${N} to revert): ${Y}"

                read -r ans_selection

                printf "${N}"

                if [[ "${ans_selection}" =~ ^[qQ]$ ]]; then
                        revert_theme
                fi

                if [[ "${ans_selection}" -ge 1 && 
                "${ans_selection}" -le "${#themes_files[@]}" ]]; then
                        theme_path="${themes_files[$((ans_selection - 1))]}"
                        printf "Selected theme : ${theme_path}\n"
                        preview_theme "${theme_path}"
                fi

                if [[ -z "${ans_selection}" ]]; then
                        printf "${G}[@]${N} Applying theme.\n"
                        exit 0
                fi

                trap revert_theme SIGINT
        done

}

preview_theme() {

        local theme_path="${1}"

        if [[ -f "${ALAC_CONF_PATH}" ]]; then
                if [[ ! -f "${ALAC_CONF_PATH}.tmp.bak" ]]; then
                        cp -a "${ALAC_CONF_PATH}" "${ALAC_CONF_PATH}.tmp.bak"
                fi
                awk -v theme_path="${theme_path}" '
                        BEGIN { in_block = 0 }
                        /^\s*import = \[/ { 
                                in_block = 1 
                                print
                                print "    \x27" theme_path "\x27"
                                next
                        }
                        /^\s*]/ { 
                                in_block = 0 
                                print 
                                next
                        }
                        !in_block
                ' "${ALAC_CONF_PATH}" > "${ALAC_CONF_PATH}.tmp" && 
                mv "${ALAC_CONF_PATH}.tmp" "${ALAC_CONF_PATH}"

                printf "Preview of %s\n" "$(basename ${theme_path})"

        else
                printf "${R}[!] Alacritty configuration file could not be "
                printf "found.\n"
                exit 1
        fi
}

revert_theme() {

        if [[ -f "${ALAC_CONF_PATH}.tmp.bak" ]]; then
                mv "${ALAC_CONF_PATH}.tmp.bak" "${ALAC_CONF_PATH}"
        fi

        exit 0
}

main() {

        R="\033[91m"  # RED
        G="\033[92m"  # GREEN
        Y="\033[93m"  # YELLOW
        DC="\033[36m" # DARK CYAN 
        P="\033[95m"  # PINK
        C="\033[96m"  # CYAN
        GR="\033[37m" # GREY
        N="\033[0m"   # RESET

        # Global variables
        THEMES_PATH="${HOME}/Documents/Developement/Github/alacritty-themes/themes"
        ALAC_CONF_PATH="${HOME}/.config/alacritty/alacritty.toml"

        if [[ -z "${THEMES_PATH}" ]]; then
                invalid_theme_path
        fi
        
        if [[ ! -e "${ALAC_CONF_PATH}" ]]; then
                create_configuration "${ALAC_CONF_PATH}"
        fi

        theme_selection "${THEMES_PATH}"

        exit 0
}

main
