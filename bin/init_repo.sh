#!/bin/bash

nc="\033[0m"
red="\033[0;31m"
green="\033[0;32m"

printf "===========================================\n"
printf "              INITIALIZATION               \n"
printf "                  SCRIPT                   \n"
printf "===========================================\n"
printf "\n"

root_path="$(dirname "$0")/.."

AVAILABLE_VERSIONS=$(cd "${root_path}/templates" && find * -maxdepth 1 -type d | xargs )
printf "Available Python versions: %s\n" "${AVAILABLE_VERSIONS}"
printf "Select your version: "
read -r PYTHON_VERSION

if [ ! -d "${root_path}/templates/${PYTHON_VERSION}" ];
then
  echo "Python Version not supported"
  exit 0
fi

mkdir -p "${root_path}/requirements"
mkdir -p "${root_path}/.github/workflows"

# template_file_path:destination_file_path. File paths are relative to the project root
templates=(
    "templates/setup.cfg.tmpl:setup.cfg"
    "templates/${PYTHON_VERSION}/requirements.in:requirements/requirements.in"
    "templates/${PYTHON_VERSION}/requirements_ci.in:requirements/requirements_ci.in"
    "templates/continous-delivery.yml.tmpl:.github/workflows/continous-delivery.yml"
    "templates/continous-integration.yml.tmpl:.github/workflows/continous-integration.yml"
    "templates/Dockerfile.tmpl:Dockerfile"
    "templates/Makefile.tmpl:Makefile"
    "templates/MANIFEST.in.tmpl:MANIFEST.in"
    "templates/.gitattributes.tmpl:.gitattributes"
)

# placeholder in format placeholder:description
placeholders=(
    "PROJECT_NAME:Project name"
    "SRC:Source folder name"
    "PROJECT_DESCRIPTION:Project description"
)

user_values=()

for placeholder in "${placeholders[@]}" ; do
    placeholder_name="${placeholder%%:*}"
    description="${placeholder##*:}"
    printf "%s: " "${description}"
    read -r value
    user_values+=("${value}")
done
printf "Remove templates (Y/n)? "
read -r remove_templates
placeholders+=("GITHUB_REPO:Github repository" "PYTHON_VERSION:Python Version")
user_values+=("$(git remote get-url origin)" "${PYTHON_VERSION}")

for template in "${templates[@]}" ; do
    source_path="${root_path}/${template%%:*}"
    dest_path="${root_path}/${template##*:}"

    if [ -f "${source_path}" ] ;
    then
        result=$(cat "${source_path}")
        for idx in "${!user_values[@]}" ; do
            placeholder=${placeholders[idx]}
            placeholder_name="${placeholder%%:*}"
            val=${user_values[idx]}
            result="${result//"{{${placeholder_name}}}"/${val}}"
            if [ "${placeholder_name}" = "SRC" ] && [ "${val}" != 'src' ]; then
              mv "${root_path}/src" "${root_path}/${val}"
            fi
        done
        echo "${result}" > "${dest_path}"
        printf "${green}Processed and created ${nc}%s\n" "${dest_path}"
        if [ "${remove_templates}" = "Y" ] || [ "${remove_templates}" = "y" ]; then
          rm "${source_path}"
        fi
    else
        printf "${red}File not found ${nc}%s\n" "${source_path}"
    fi
done
