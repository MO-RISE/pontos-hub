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
        # Extract the key (by removing the  prefix)
        key="${var/"$prefix"/""}"
        # key=$(echo "$var" | sed "s/^${prefix}//")
        # and the value
        value=$(printenv "$var")

        # Update json with new field
        json=$(jq '. += {"'"$key"'":"'"$value"'"}' <<< "$json")

    done < <(compgen -v | grep "^${prefix}")

    # Return
    echo "$json"
}

# Extract variables from shell2http input
form_data_json=$(jsonify_prefixed_variables "v_")

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