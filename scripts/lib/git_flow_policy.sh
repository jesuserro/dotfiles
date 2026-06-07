#!/usr/bin/env bash
# Shared parser for per-repository Git flow policy files.
# shellcheck shell=bash

GIT_FLOW_POLICY_KEYS=(
	"FLOW_MODE_TO_DEV"
	"FLOW_MODE_TO_MAIN"
	"VALIDATE_TO_DEV"
	"VALIDATE_TO_MAIN"
	"VALIDATE_CMD_TO_DEV"
	"VALIDATE_CMD_TO_MAIN"
	"MERGE_STRATEGY_TO_DEV"
	"MERGE_STRATEGY_TO_MAIN"
	"DELETE_FEATURE_BRANCH"
	"OPEN_BROWSER"
	"REMOTE_NAME"
	"BASE_DEV_BRANCH"
	"BASE_MAIN_BRANCH"
	"FEATURE_BRANCH_PREFIX"
)

git_flow_policy_error() {
	printf '%s\n' "$*" >&2
}

git_flow_policy_set_defaults() {
	FLOW_MODE_TO_DEV="local"
	FLOW_MODE_TO_MAIN="local"
	VALIDATE_TO_DEV="false"
	VALIDATE_TO_MAIN="false"
	VALIDATE_CMD_TO_DEV="make validate"
	VALIDATE_CMD_TO_MAIN="make validate-full"
	MERGE_STRATEGY_TO_DEV="merge"
	MERGE_STRATEGY_TO_MAIN="merge"
	DELETE_FEATURE_BRANCH="true"
	OPEN_BROWSER="true"
	REMOTE_NAME="origin"
	BASE_DEV_BRANCH="dev"
	BASE_MAIN_BRANCH="main"
	FEATURE_BRANCH_PREFIX="feature/"
}

git_flow_policy_is_known_key() {
	case "$1" in
	FLOW_MODE_TO_DEV | FLOW_MODE_TO_MAIN | VALIDATE_TO_DEV | VALIDATE_TO_MAIN | VALIDATE_CMD_TO_DEV | VALIDATE_CMD_TO_MAIN | MERGE_STRATEGY_TO_DEV | MERGE_STRATEGY_TO_MAIN | DELETE_FEATURE_BRANCH | OPEN_BROWSER | REMOTE_NAME | BASE_DEV_BRANCH | BASE_MAIN_BRANCH | FEATURE_BRANCH_PREFIX)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

git_flow_policy_trim_outer_quotes() {
	local value="$1"
	if [[ ${#value} -ge 2 ]]; then
		if [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]]; then
			printf '%s\n' "${value:1:${#value}-2}"
			return
		fi
		if [[ "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
			printf '%s\n' "${value:1:${#value}-2}"
			return
		fi
	fi
	printf '%s\n' "$value"
}

git_flow_policy_assign() {
	local key="$1"
	local value="$2"

	case "$key" in
	FLOW_MODE_TO_DEV) FLOW_MODE_TO_DEV="$value" ;;
	FLOW_MODE_TO_MAIN) FLOW_MODE_TO_MAIN="$value" ;;
	VALIDATE_TO_DEV) VALIDATE_TO_DEV="$value" ;;
	VALIDATE_TO_MAIN) VALIDATE_TO_MAIN="$value" ;;
	VALIDATE_CMD_TO_DEV) VALIDATE_CMD_TO_DEV="$value" ;;
	VALIDATE_CMD_TO_MAIN) VALIDATE_CMD_TO_MAIN="$value" ;;
	MERGE_STRATEGY_TO_DEV) MERGE_STRATEGY_TO_DEV="$value" ;;
	MERGE_STRATEGY_TO_MAIN) MERGE_STRATEGY_TO_MAIN="$value" ;;
	DELETE_FEATURE_BRANCH) DELETE_FEATURE_BRANCH="$value" ;;
	OPEN_BROWSER) OPEN_BROWSER="$value" ;;
	REMOTE_NAME) REMOTE_NAME="$value" ;;
	BASE_DEV_BRANCH) BASE_DEV_BRANCH="$value" ;;
	BASE_MAIN_BRANCH) BASE_MAIN_BRANCH="$value" ;;
	FEATURE_BRANCH_PREFIX) FEATURE_BRANCH_PREFIX="$value" ;;
	*)
		git_flow_policy_error "Unknown git flow policy key: ${key}"
		return 1
		;;
	esac
}

git_flow_policy_load_file() {
	local policy_file="$1"
	local line line_number key value

	if [[ ! -f "$policy_file" ]]; then
		git_flow_policy_error "Git flow policy file not found: ${policy_file}"
		return 1
	fi

	line_number=0
	while IFS= read -r line || [[ -n "$line" ]]; do
		line_number=$((line_number + 1))

		[[ "$line" =~ ^[[:space:]]*$ ]] && continue
		[[ "$line" =~ ^[[:space:]]*# ]] && continue

		if [[ "$line" != "${line#export }" ]]; then
			git_flow_policy_error "Invalid git flow policy line ${line_number}: export is not supported"
			return 1
		fi

		if [[ ! "$line" =~ ^([A-Z0-9_]+)=(.*)$ ]]; then
			git_flow_policy_error "Invalid git flow policy line ${line_number}: expected KEY=value"
			return 1
		fi

		key="${BASH_REMATCH[1]}"
		value="${BASH_REMATCH[2]}"

		if ! git_flow_policy_is_known_key "$key"; then
			git_flow_policy_error "Unknown git flow policy key: ${key}"
			return 1
		fi

		value="$(git_flow_policy_trim_outer_quotes "$value")"
		git_flow_policy_assign "$key" "$value" || return 1
	done <"$policy_file"
}

git_flow_policy_validate_enum() {
	local key="$1"
	local value="$2"
	shift 2
	local allowed
	for allowed in "$@"; do
		[[ "$value" == "$allowed" ]] && return 0
	done
	git_flow_policy_error "Invalid git flow policy value for ${key}: ${value}"
	return 1
}

git_flow_policy_validate_bool() {
	local key="$1"
	local value="$2"
	git_flow_policy_validate_enum "$key" "$value" "true" "false"
}

git_flow_policy_validate_non_empty() {
	local key="$1"
	local value="$2"
	if [[ -z "$value" ]]; then
		git_flow_policy_error "Invalid git flow policy value for ${key}: value must not be empty"
		return 1
	fi
}

git_flow_policy_validate_required_command() {
	local enabled_key="$1"
	local enabled_value="$2"
	local command_key="$3"
	local command_value="$4"

	if [[ "$enabled_value" == "true" && -z "$command_value" ]]; then
		git_flow_policy_error "Invalid git flow policy value for ${command_key}: command must not be empty when ${enabled_key}=true"
		return 1
	fi
}

git_flow_policy_validate() {
	git_flow_policy_validate_enum "FLOW_MODE_TO_DEV" "$FLOW_MODE_TO_DEV" "local" "pr" "pr_auto" "pr_immediate" || return 1
	git_flow_policy_validate_enum "FLOW_MODE_TO_MAIN" "$FLOW_MODE_TO_MAIN" "local" "pr" "pr_auto" "pr_immediate" || return 1

	git_flow_policy_validate_bool "VALIDATE_TO_DEV" "$VALIDATE_TO_DEV" || return 1
	git_flow_policy_validate_bool "VALIDATE_TO_MAIN" "$VALIDATE_TO_MAIN" || return 1
	git_flow_policy_validate_bool "DELETE_FEATURE_BRANCH" "$DELETE_FEATURE_BRANCH" || return 1
	git_flow_policy_validate_bool "OPEN_BROWSER" "$OPEN_BROWSER" || return 1

	git_flow_policy_validate_enum "MERGE_STRATEGY_TO_DEV" "$MERGE_STRATEGY_TO_DEV" "merge" "squash" "rebase" || return 1
	git_flow_policy_validate_enum "MERGE_STRATEGY_TO_MAIN" "$MERGE_STRATEGY_TO_MAIN" "merge" "squash" "rebase" || return 1

	git_flow_policy_validate_non_empty "REMOTE_NAME" "$REMOTE_NAME" || return 1
	git_flow_policy_validate_non_empty "BASE_DEV_BRANCH" "$BASE_DEV_BRANCH" || return 1
	git_flow_policy_validate_non_empty "BASE_MAIN_BRANCH" "$BASE_MAIN_BRANCH" || return 1
	git_flow_policy_validate_non_empty "FEATURE_BRANCH_PREFIX" "$FEATURE_BRANCH_PREFIX" || return 1

	git_flow_policy_validate_required_command "VALIDATE_TO_DEV" "$VALIDATE_TO_DEV" "VALIDATE_CMD_TO_DEV" "$VALIDATE_CMD_TO_DEV" || return 1
	git_flow_policy_validate_required_command "VALIDATE_TO_MAIN" "$VALIDATE_TO_MAIN" "VALIDATE_CMD_TO_MAIN" "$VALIDATE_CMD_TO_MAIN" || return 1
}

git_flow_policy_print() {
	local key
	for key in "${GIT_FLOW_POLICY_KEYS[@]}"; do
		case "$key" in
		FLOW_MODE_TO_DEV) printf '%s=%s\n' "$key" "$FLOW_MODE_TO_DEV" ;;
		FLOW_MODE_TO_MAIN) printf '%s=%s\n' "$key" "$FLOW_MODE_TO_MAIN" ;;
		VALIDATE_TO_DEV) printf '%s=%s\n' "$key" "$VALIDATE_TO_DEV" ;;
		VALIDATE_TO_MAIN) printf '%s=%s\n' "$key" "$VALIDATE_TO_MAIN" ;;
		VALIDATE_CMD_TO_DEV) printf '%s=%s\n' "$key" "$VALIDATE_CMD_TO_DEV" ;;
		VALIDATE_CMD_TO_MAIN) printf '%s=%s\n' "$key" "$VALIDATE_CMD_TO_MAIN" ;;
		MERGE_STRATEGY_TO_DEV) printf '%s=%s\n' "$key" "$MERGE_STRATEGY_TO_DEV" ;;
		MERGE_STRATEGY_TO_MAIN) printf '%s=%s\n' "$key" "$MERGE_STRATEGY_TO_MAIN" ;;
		DELETE_FEATURE_BRANCH) printf '%s=%s\n' "$key" "$DELETE_FEATURE_BRANCH" ;;
		OPEN_BROWSER) printf '%s=%s\n' "$key" "$OPEN_BROWSER" ;;
		REMOTE_NAME) printf '%s=%s\n' "$key" "$REMOTE_NAME" ;;
		BASE_DEV_BRANCH) printf '%s=%s\n' "$key" "$BASE_DEV_BRANCH" ;;
		BASE_MAIN_BRANCH) printf '%s=%s\n' "$key" "$BASE_MAIN_BRANCH" ;;
		FEATURE_BRANCH_PREFIX) printf '%s=%s\n' "$key" "$FEATURE_BRANCH_PREFIX" ;;
		esac
	done
}
