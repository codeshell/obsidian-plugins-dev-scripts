strip_trailing_newlines() {
	local s="$1"
	while [ -n "$s" ] && [ "${s: -1}" = $'\n' ]; do
		s="${s%$'\n'}"
	done
	printf '%s' "$s"
}

format_table_bash() {
	local input
	input="$(strip_trailing_newlines "$1")"
	local -a rows
	while IFS= read -r line; do rows+=("$line"); done <<< "$input"
	local -a widths
	local -a proc_rows
	local delim=$'\x1F'
	local r i f

	for ((r=0; r<${#rows[@]}; r++)); do
		IFS='|' read -ra fields <<< "${rows[r]}"
		local joined=""
		local start_index=0
		if [[ "${rows[r]}" =~ ^[[:space:]]*\| ]]; then
			start_index=1
		fi
		local j=0
		for ((i=start_index; i<${#fields[@]}; i++)); do
			f="${fields[i]}"
			f="${f#${f%%[![:space:]]*}}"
			f="${f%${f##*[![:space:]]}}"
			local len=${#f}
			if [ -z "${widths[j]}" ] || [ "$len" -gt "${widths[j]}" ]; then
				widths[j]=$len
			fi
			if [ $j -eq 0 ]; then
				joined="$f"
			else
				joined+="$delim$f"
			fi
			j=$((j+1))
		done
		proc_rows[r]="$joined"
	done

	for ((r=0; r<${#proc_rows[@]}; r++)); do
		IFS="$delim" read -ra fields <<< "${proc_rows[r]}"
		printf "|"
		for ((i=0; i<${#fields[@]}; i++)); do
			printf " %-${widths[i]}s |" "${fields[i]}"
		done
		printf "\n"
	done
}
# Allow being executed directly with a quoted multi-line argument.
if [ "$#" -ge 1 ]; then
	format_table_bash "$1"
else
	# Read stdin if no positional argument provided
	input=""
	while IFS= read -r line; do
		input+="$line"$'\n'
	done
	format_table_bash "$(strip_trailing_newlines "$input")"
fi
