#! /bin/bash
set -euo pipefail

# Define a function to create a JSON object from all available variables matching 'prefix'
jsonify_prefixed_variables() {
    # Read the prefix to use
    local prefix=$1

    #Initialize with empty json
    json={}

    # Loop over extracted variables
    while read -r var; do
        # Extract the key (by removing the prefix)
        key="${var/"$prefix"/""}"
        # and the value
        value=$(printenv "$var")

        # Update json with new field
        json=$(jq '. += {"'"$key"'":"'"$value"'"}' <<< "$json")

    done < <(compgen -v | grep "^${prefix}")

    # Return
    echo "$json"
}

# Define a function the splits a comma separated string into the substrings
split_comma_separated_string() {
    local input="$1"   # Input comma-separated string
    local IFS=","      # Internal Field Separator set to comma

    # Loop through the input string and print elements
    for item in $input; do
        echo "$item"
    done
}

# Define a function that tests if array A is a subset of array B
# Returns 0 if A is a subset of B
# Returns 1 if A is NOT a subset of B
subset_of() {
  local -n _array_A=$1
  local -n _array_B=$2
  _file_A=$(printf '%s\n' "${_array_A[@]}")
  _file_B=$(printf '%s\n' "${_array_B[@]}")

  output=$(comm -23 <(sort <<< "$_file_A") <(sort <<< "$_file_B") | head -1)
  if [[ -z $output ]]; then return 0; else return 1; fi
}

## Start processing input

# Extract variables from shell2http input
form_data_json=$(jsonify_prefixed_variables "v_")

# shellcheck disable=SC2034
mapfile -t json_keys < <(echo "$form_data_json" | jq -r 'keys[]')

# Read allowed claims from environment variable and
# verify form_data_json using allowed_claims.
# Return error if verification fails!
if [ -n "$JWT_ALLOWED_CLAIMS" ]; then
    # shellcheck disable=SC2034
    mapfile -t allowed_claims < <(split_comma_separated_string "$JWT_ALLOWED_CLAIMS")
    if ! subset_of json_keys allowed_claims; then
        printf "%s\n\n%s\n" "Status: 400" "You provided: ${json_keys[*]} which is not a subset of the allowed ones: ${allowed_claims[*]}"
        exit 1
    fi
fi

# Read required claims from environment variable and
# verify form_data_json using required_claims.
# Return error if verification fails!
if [ -n "$JWT_REQUIRED_CLAIMS" ]; then
    # shellcheck disable=SC2034
    mapfile -t required_claims < <(split_comma_separated_string "$JWT_REQUIRED_CLAIMS")
    if ! subset_of required_claims json_keys; then
        printf "%s\n\n%s\n" "Status: 400" "You provided: ${json_keys[*]} which is not a superset of the required ones: ${required_claims[*]}"
        exit 1
    fi
fi


# Extract variables from environment variables
env_json=$(jsonify_prefixed_variables "JWT_CLAIM_")

# Merged json (Note the order! Later entries overwrites earlier ones!)
merged_json=$(echo "$form_data_json $env_json" | jq -s add | jq 'to_entries | reduce .[] as $item ({}; .[$item.key] = $item.value)')

# Create token and return it
token=$(
    jwt encode \
        --iss="$JWT_ISSUER" \
        --exp="$JWT_EXPIRY" \
        --secret="$JWT_SECRET" \
        "$merged_json"
    )

echo "$token"