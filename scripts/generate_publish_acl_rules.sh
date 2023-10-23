#! /bin/bash
set -euo pipefail

# Declarations
topic_prefix='PONTOS_INGRESS'
topic_suffix=
username=
vessels=()
parameters=()

print_usage() {
    echo "Usage: script_name [-u username] [-t prefix] [-v vessel...] [-p parameter...]"
    echo "Options:"
    echo "  -u username        Set the username"
    echo "  -t topic prefix    Set the topic prefix to use (default: PONTOS_INGRESS)"
    echo "  -s topic suffix    Set the topic suffix to use (default: )"
    echo "  -v vessel          Specify a vessel (multiple occurrences allowed)"
    echo "  -p parameter       Specify a parameter (multiple occurrences allowed)"
    echo ""
    echo "Example:"
    echo "  script_name -u john -t prefix -s '/suffix' -v vessel1 -v vessel2 -p param1 -p param2"
}


# Process arguments
while getopts "t:s:u:v:p:" opt; do
    case $opt in
        t) topic_prefix="$OPTARG";;
        s) topic_suffix="$OPTARG";;
        u) username="$OPTARG";;
        v) vessels+=("$OPTARG");;
        p) parameters+=("$OPTARG");;
        *) print_usage; exit 1;;
    esac
done
shift $((OPTIND -1))

# Argument checks
if [ -z "${username}" ]; then
    print_usage; exit 1
fi

if [ ${#vessels[@]} -eq 0 ] || [ ${#parameters[@]} -eq 0  ]; then
    usage; exit 1
fi

# Do the actual work
for vessel in "${vessels[@]}"; do
    topics=$(printf "\"${topic_prefix}/${vessel}/%s${topic_suffix}\"\n" "${parameters[@]}" | paste -sd,)
    echo "{allow, {user, \"${username}\"}, all, [${topics}]}."
done
