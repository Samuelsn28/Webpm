#!/bin/bash

PROPERTIES_FILE_NAME="$(dirname $(readlink -f $0))/.manage-properties"
SEPARATOR_WEBPM_BUILT_PROJECTS="----built projects----"

WEB_ENV_DIR_KEY="web-enviroment-dir"
WEB_ENV_DIR="/var/www/html"

error[1]="The passed name is invalid."
error[2]="Directory $WEB_ENV_DIR is missing."
error[3]="There's no permission to write in $WEB_ENV_DIR. Permissions: $(ls -la "$WEB_ENV_DIR")"
error[4]="The passed directory doesn't exist."
error[5]="There's no permission to write in save location"
error[6]="Error: properties file is missing."
error[7]="Error: Key can't be empty or space."
error[8]="There's no permission to write in built project location $WEB_ENV_DIR/$2"

warn[1]="Can't possible remove built project in $WEB_ENV_DIR, but the project was saved."

die() {
	echo -e "\033[1;91m(!!) ${error[$1]} \033[1;00m"
	exit $1
}

stop() {
	echo -e "\033[1;97m(^C) Program was stopped \033[1;00m"
	exit 0
}

sends_warn() {
	echo -e "\033[1;93m(!) ${warn[$1]} \033[1;00m"
}

sends_complete_message() {
	echo -e "\033[1;92m(#) $1 complete. \033[1;00m"
}

title_help() {
	echo -e " \n\033[1;12m $1 \033[1;00m"
}

text_help() {
	echo -e "	\033[0;12m$1 \033[1;00m"
}

text_strong() {
	printf "\033[1;12m$1\033[1;00m"
}

is_valid_directory() {
	[ -n "$1" ] && [ -d "$1" ]
}

already_exist_directory() {
	[ -d "$1" ]
}

has_the_operation_failed() {
	[ "$?" -ne 0 ]
}

is_valid_key() {
	[ ! -z "$1" ] && [ "$1" != " " ]
}

is_valid_builded_project_name() {
	is_valid_key "$1" && [ "$1" != "$WEB_ENV_DIR_KEY" ]
}

check_propertie_existence() {
	[ "$(grep "^$1=")" -eq 0 ]
}

get_all_built_projects() {
	echo "$(awk -v mark="$SEPARATOR_WEBPM_BUILT_PROJECTS" '$0 == mark {found=1; next} found' $PROPERTIES_FILE_NAME)"
}

get_propertie_of_key() {
	local key="$1"

	if ! is_valid_key "$key"; then
		die 7
	fi

	echo "$(grep "^$key=" "$PROPERTIES_FILE_NAME" | cut -d= -f2-)"
	return 0
}

set_propertie_of_key() {
	local key="$1"
	local new_value="$2"

	if [ ! -f "$PROPERTIES_FILE_NAME" ]; then
		die 6
	fi

	if ! is_valid_key "$key"; then
		die 7
	fi

	local old_value="$(get_propertie_of_key "$key")"
	sed -i "s|$key=$old_value|$key=$new_value|" "$PROPERTIES_FILE_NAME"
}

remove_propertie_of_key() {
	local key="$1"

	if [ ! -f "$PROPERTIES_FILE_NAME" ]; then
		die 6
	fi

	if ! is_valid_key "$key"; then
		die 7
	fi

	sed -i "/^$key=/d" "$PROPERTIES_FILE_NAME"
}

update_current_web_env_dir() {
	if [ -f "$PROPERTIES_FILE_NAME" ]; then
		WEB_ENV_DIR=$(get_propertie_of_key "$WEB_ENV_DIR_KEY")
	else
		echo "$WEB_ENV_DIR_KEY=$WEB_ENV_DIR" > "$PROPERTIES_FILE_NAME"
		echo "$SEPARATOR_WEBPM_BUILT_PROJECTS" >> "$PROPERTIES_FILE_NAME"
	fi
}

set_current_web_env_dir() {
	local current_env_dir

	current_env_dir=$(cd "$1" && pwd) || die 4

	if [ ! -z "$(get_all_built_projects)" ]; then
		read -p "All current built projects will be untracked. Continue? y/N: " answer

		if [ "$answer" != "y" ]; then
			stop
		fi
	fi

	set_propertie_of_key "$WEB_ENV_DIR_KEY" "$current_env_dir"
	WEB_ENV_DIR="$current_env_dir"

	$(sed -i "/^$SEPARATOR_WEBPM_BUILT_PROJECTS$/q" "$PROPERTIES_FILE_NAME")

	sends_complete_message "Set"
}

create_builded_project_propertie() {
	local builded_project_name="$1"
	local origin_dir="$2"

	echo "$builded_project_name=$origin_dir" >> "$PROPERTIES_FILE_NAME"
}

prepare_web_project() {
	local builded_project_name="$1"
	local origin_dir="$2"
	local builded_project_location="$WEB_ENV_DIR/$builded_project_name"

	mkdir "$builded_project_location"

	if has_the_operation_failed; then
		die 3
	fi

	cp -r "$origin_dir/." "$builded_project_location/"

	if has_the_operation_failed; then
		die 8
	fi

	create_builded_project_propertie "$builded_project_name" "$origin_dir"
}

build_project() {
	local builded_project_name="$1"
	local origin_dir="$(cd "$2"; pwd)"
	
	if ! is_valid_builded_project_name "$builded_project_name"; then
		die 1
	fi

	if ! is_valid_directory "$WEB_ENV_DIR"; then
		die 2
	fi

	prepare_web_project "$builded_project_name" "$origin_dir"
	sends_complete_message "Build"
}

show_built_projects() {
	printf "All built projects: \n\n"

	text_strong "Project"
	text_strong " | Default save dir \n"
	local built_projects=$(get_all_built_projects)

	format_output=$(printf '%s\n' "$built_projects" | sed 's|=| --> |')
	printf "$format_output \n\n"
}

save_project() {
	local builded_project_name="$1"
	local save_location_dir="$2"

	cp -r "$WEB_ENV_DIR/$builded_project_name/." "$save_location_dir/"

	if has_the_operation_failed; then
		die 5
	fi

	rm -r "$WEB_ENV_DIR/$builded_project_name/"

	if has_the_operation_failed; then
		sends_warn 1
	fi

	remove_propertie_of_key "$builded_project_name"
}

confirm_save_location_dir() {
	read -p "All in $1 will be deleted and replaced by the builded project. Continue? y/N: " answer

	if [ "$answer" != "y" ]; then
		stop
	fi
}

finish_project() {
	local builded_project_name="$1"
	local save_location_dir="$2"

	if ! is_valid_builded_project_name "$builded_project_name"; then
		die 1
	fi 

	if [ -z "$save_location_dir" ]; then
		save_location_dir="$(get_propertie_of_key "$builded_project_name")"
	else
		save_location_dir="$(cd "$save_location_dir"; pwd)"
		if already_exist_directory "$save_location_dir"; then
			confirm_save_location_dir "$save_location_dir"
		fi
	fi

	save_project "$builded_project_name" "$save_location_dir"
	sends_complete_message "Save"
}

help() {
	printf "Available Operations: \n"

	title_help "build <name> [project dir]"
	text_help "Build the project passed in <project dir> in the current web_env_dir setting <name> as build name."
	text_help "Webpm will build current directory if <project dir> isn't provided."

	title_help "finish <build name> [save dir]"
	text_help "Finish built project with name <build name> and save it in the <save dir>."
	text_help "If <save dir> is empty, Webpm will save it in the dir where it was built."

	title_help "web-environment (or we) <new dir>"
	text_help "Set web_env_dir as <new dir>."

	title_help "show"
	text_help "Show current built projects."

	title_help "help"
	text_help "Show available operations."

	printf "\n"
}


update_current_web_env_dir

if [ "$1" = "build" ]; then
	build_project "$2" "$3"
elif [ "$1" = "finish" ]; then
	finish_project "$2" "$3"
elif [ "$1" = "web-environment" -o "$1" = "we" ]; then
	set_current_web_env_dir "$2"
elif [ "$1" = "show" ]; then
	show_built_projects
elif [ "$1" = "help" ]; then
	help
else 
	echo "Command invalid. Use help to see operations."
fi



