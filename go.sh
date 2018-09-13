#!/usr/bin/env bash

CONFIG_FILE="${HOME}/.go_config"

function abspath {
    if [[ -d "$1" ]]; then
        pushd "$1" >/dev/null
        pwd
        popd >/dev/null
    elif [[ -e $1 ]]; then
        pushd "$(dirname "$1")" >/dev/null
        echo "$(pwd)/$(basename "$1")"
        popd >/dev/null
    else
        echo "$1" does not exist! >&2
        return 127
    fi
}
function find_alias {
	cat "$CONFIG_FILE" | grep -E "^${1}:"
}
function cmd_add {
	if [[ -f "$CONFIG_FILE" && $(find_alias "$1") ]]; then
		cmd_del "$1"
	fi
	echo "$1:$2" >> $CONFIG_FILE
}
function cmd_del {
	TMP_FILE=$(mktemp -t tempXXXXXX)
	mv "$CONFIG_FILE" "$TMP_FILE"
	cat "$TMP_FILE" | egrep --invert-match "^$1:" > "$CONFIG_FILE"
	if [[ -f "$TMP_FILE" ]]; then
		rm "$TMP_FILE"
	fi
}
function usage {
	if [[ "$1" ]]; then
		echo "ERROR: $1"
		echo
	fi
	echo "Usage: go folder-alias"
	echo "       go --command [arguments]"
	echo ""
	echo "Changes directory to a folder, mapped in '${CONFIG_FILE}'; structure:"
	echo "---8<--------------------------"
	echo "alias1:~/path/to/folder-alias-1"
	echo "alias2:/path/to/folder-alias-2"
	echo "..."
	echo "--------------------------8<---"
	echo "Commands:"
	echo "  -l or --list       Lists all defined aliases, sorted"
	echo "  -a or --add x y    Add/replace alias x for folder y to the list. y is optional (pwd is used when omitted) "
	echo "  -d or --del x      Remove alias x from the list"
	echo "  -h, -? or --help   Show this text"
	echo
}

# First find out what to do
if [[ $# -lt 1 ]]; then
	CMD=list
else
	if [[ $1 =~ ^[-] ]]; then
		case $1 in
			(-l | -list | --list)      CMD=list; shift;;
			(-a | -add | --add)        CMD=add; shift;;
			(-d | -del | --del)        CMD=del; shift;;
			(-h | -? | -help | --help) CMD=usage;CMD_ARG="";;
			(*)                        CMD=usage;CMD_ARG="unknown option '$1'";;
		esac
	else
		CMD=goto
	fi
fi

if [[ $CMD == usage ]]; then
	usage "$CMD_ARG"
elif [[ $CMD == list ]]; then
    if [[ -f "$CONFIG_FILE" ]]; then
		echo -e "alias\tfolder"
		echo -e "=====\t=================="
		cat "$CONFIG_FILE" | awk '{sub(":","\t",$0); print;}' | sort
	else
		echo "No config stored yet!"
	fi

elif [[ $CMD == add ]]; then
	if [[ $# -lt 1 ]]; then
		>&2 echo "Usage: go add alias [path-to-alias]"
	else
		if [[ $1 == *:* ]]; then
			>&2 echo "Alias '$1' can't contain a colon (:)"
		else
			ALIAS=$1
			if [[ $# -lt 2 ]]; then
				GOTO_FOLDER=$(pwd)
			else
				GOTO_FOLDER=$(abspath $2)
			fi
			if [[ ! -d "$GOTO_FOLDER" ]]; then
				>&2 echo "Folder '$GOTO_FOLDER' does not exist"
			else
				cmd_add "$ALIAS" "$GOTO_FOLDER"
			fi
		fi
	fi
elif [[ $CMD == del ]]; then
	if [[ $# -lt 1 ]]; then
		>&2 echo "Usage: go del alias"
	else
		ALIAS=$1
		if [[ -z $(find_alias "$ALIAS") ]]; then
			>&2 echo "Alias '$ALIAS' is not found in config"
		else
			cmd_del "$ALIAS"
		fi
	fi
elif [[ $CMD == goto ]]; then
	FOLDER_ALIAS=$1

	GOTO_FOLDER=$(find_alias "$FOLDER_ALIAS")
	GOTO_FOLDER=${GOTO_FOLDER:((${#FOLDER_ALIAS}+1))} #remove everything left before the colon (inclusive)
	if [[ "${GOTO_FOLDER:0:1}" == "~" ]]; then
		GOTO_FOLDER=${HOME}/${GOTO_FOLDER:1}
	fi
	if [[ -z "$GOTO_FOLDER" ]]; then
		>&2 echo "Can't find '$FOLDER_ALIAS' in '${CONFIG_FILE}'"
		if [[ $FOLDER_ALIAS =~ ^list|add|del|help$ ]]; then
			>&2 echo "Tip: to use the '$FOLDER_ALIAS' as a command, put a dash before the command. "
		fi
	else
		cd "$GOTO_FOLDER"
	fi
else
	>&2 echo "Internal error, command '$CMD' is unknown."
fi
