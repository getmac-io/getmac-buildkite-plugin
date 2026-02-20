#!/bin/bash
set -euo pipefail

# Plugin configuration (read from BUILDKITE_PLUGIN_GETMAC_* env vars)
GETMAC_IMAGE="${BUILDKITE_PLUGIN_GETMAC_IMAGE:-macos-sequoia}"
GETMAC_MACHINE_TYPE="${BUILDKITE_PLUGIN_GETMAC_MACHINE_TYPE:-mac-m4-c4-m8}"
GETMAC_REGION="${BUILDKITE_PLUGIN_GETMAC_REGION:-eu-central-ltu-1}"
GETMAC_PROJECT_ID="${BUILDKITE_PLUGIN_GETMAC_PROJECT_ID:-}"
GETMAC_SSH_PRIVATE_KEY_PATH="${BUILDKITE_PLUGIN_GETMAC_SSH_PRIVATE_KEY_PATH:-${HOME}/.ssh/id_rsa}"
GETMAC_API_URL="${BUILDKITE_PLUGIN_GETMAC_API_URL:-https://api.getmac.io/v1}"
GETMAC_DEBUG="${BUILDKITE_PLUGIN_GETMAC_DEBUG:-false}"

# VM name derived from Buildkite build and step IDs
GETMAC_VM_NAME="buildkite-${BUILDKITE_BUILD_ID:-unknown}-${BUILDKITE_STEP_ID:-unknown}"
# Truncate to 63 characters for safety
GETMAC_VM_NAME="${GETMAC_VM_NAME:0:63}"

getmac_log() {
  echo "~~~ :getmac: $*"
}

getmac_debug() {
  if [[ "${GETMAC_DEBUG}" == "true" ]]; then
    echo "    [debug] $*"
  fi
}

getmac_api() {
  local method="$1"
  local endpoint="$2"
  shift 2

  local url="${GETMAC_API_URL}${endpoint}"

  getmac_debug "${method} ${url}"

  local tmpfile
  tmpfile=$(mktemp)
  trap "rm -f '${tmpfile}'" RETURN

  local http_code
  http_code=$(curl -s -o "${tmpfile}" -w "%{http_code}" \
    -X "${method}" \
    -H "Authorization: Bearer ${GETMAC_CLOUD_API_KEY}" \
    -H "Content-Type: application/json" \
    "${@}" \
    "${url}")

  local exit_code=$?

  if [[ ${exit_code} -ne 0 ]]; then
    echo "Error: curl request failed with exit code ${exit_code}" >&2
    return 1
  fi

  local response
  response=$(cat "${tmpfile}")

  if [[ "${http_code}" -ge 400 ]]; then
    echo "Error: API returned HTTP ${http_code}" >&2
    echo "${response}" >&2
    return 1
  fi

  getmac_debug "Response (HTTP ${http_code}): ${response}"
  echo "${response}"
}

create_vm() {
  local body
  body=$(cat <<EOF
{
  "name": "${GETMAC_VM_NAME}",
  "image": "${GETMAC_IMAGE}",
  "type": "${GETMAC_MACHINE_TYPE}",
  "region": "${GETMAC_REGION}"
}
EOF
)

  getmac_debug "Create VM body: ${body}"

  getmac_api POST "/instances?project_id=${GETMAC_PROJECT_ID}" -d "${body}"
}

get_vm_by_name() {
  local response
  response=$(getmac_api GET "/instances?project_id=${GETMAC_PROJECT_ID}")

  echo "${response}" | jq -r ".instances[] | select(.name == \"${GETMAC_VM_NAME}\")"
}

delete_vm() {
  local vm_id="$1"
  getmac_api DELETE "/instances/${vm_id}?project_id=${GETMAC_PROJECT_ID}"
}
