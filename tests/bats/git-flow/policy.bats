#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(get_dotfiles_dir)"
	POLICY_PRINT="${DOTFILES_DIR}/scripts/git_flow_policy_print.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

expected_defaults() {
	cat <<'EOF'
FLOW_MODE_TO_DEV=local
FLOW_MODE_TO_MAIN=local
VALIDATE_TO_DEV=false
VALIDATE_TO_MAIN=false
VALIDATE_CMD_TO_DEV=make validate
VALIDATE_CMD_TO_MAIN=make validate-full
MERGE_STRATEGY_TO_DEV=merge
MERGE_STRATEGY_TO_MAIN=merge
DELETE_FEATURE_BRANCH=true
OPEN_BROWSER=true
REMOTE_NAME=origin
BASE_DEV_BRANCH=dev
BASE_MAIN_BRANCH=main
FEATURE_BRANCH_PREFIX=feature/
EOF
}

@test "policy print script exists and is executable" {
	[[ -f "$POLICY_PRINT" ]]
	[[ -x "$POLICY_PRINT" ]]
}

@test "without policy file prints stable legacy defaults" {
	cd "$TEST_TEMP_DIR"
	run bash "$POLICY_PRINT"
	[[ "$status" -eq 0 ]]
	[[ "$output" == "$(expected_defaults)" ]]
}

@test "explicit missing policy file fails clearly" {
	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/missing.env"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"Git flow policy file not found"* ]]
	[[ "$output" == *"${TEST_TEMP_DIR}/missing.env"* ]]
}

@test "valid policy overrides values and preserves unspecified defaults" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr_immediate
FLOW_MODE_TO_MAIN=pr
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="make validate"
MERGE_STRATEGY_TO_DEV=squash
OPEN_BROWSER=false
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_DEV=pr_immediate"* ]]
	[[ "$output" == *"FLOW_MODE_TO_MAIN=pr"* ]]
	[[ "$output" == *"VALIDATE_TO_DEV=false"* ]]
	[[ "$output" == *"VALIDATE_TO_MAIN=true"* ]]
	[[ "$output" == *"VALIDATE_CMD_TO_DEV=make validate"* ]]
	[[ "$output" == *"VALIDATE_CMD_TO_MAIN=make validate"* ]]
	[[ "$output" == *"MERGE_STRATEGY_TO_DEV=squash"* ]]
	[[ "$output" == *"MERGE_STRATEGY_TO_MAIN=merge"* ]]
	[[ "$output" == *"OPEN_BROWSER=false"* ]]
}

@test "invalid flow mode fails with variable and value" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
FLOW_MODE_TO_DEV=banana
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_DEV"* ]]
	[[ "$output" == *"banana"* ]]
}

@test "invalid boolean fails with variable and value" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
VALIDATE_TO_DEV=yes
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"VALIDATE_TO_DEV"* ]]
	[[ "$output" == *"yes"* ]]
}

@test "invalid merge strategy fails with variable and value" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
MERGE_STRATEGY_TO_MAIN=fast-forward
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"MERGE_STRATEGY_TO_MAIN"* ]]
	[[ "$output" == *"fast-forward"* ]]
}

@test "unknown key fails clearly" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
FOO=bar
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"Unknown git flow policy key: FOO"* ]]
}

@test "active validation with empty command fails" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV=
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"VALIDATE_CMD_TO_DEV"* ]]
	[[ "$output" == *"VALIDATE_TO_DEV=true"* ]]
}

@test "comments and blank lines are ignored" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
# Git flow policy

FLOW_MODE_TO_DEV=pr

# Browser behavior
OPEN_BROWSER=false
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_DEV=pr"* ]]
	[[ "$output" == *"OPEN_BROWSER=false"* ]]
}

@test "basic quoting removes outer quotes without expansion" {
	cat >"${TEST_TEMP_DIR}/policy.env" <<'EOF'
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="make validate-full"
VALIDATE_CMD_TO_DEV='make validate'
EOF

	run bash "$POLICY_PRINT" --policy-file "${TEST_TEMP_DIR}/policy.env"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"VALIDATE_CMD_TO_MAIN=make validate-full"* ]]
	[[ "$output" == *"VALIDATE_CMD_TO_DEV=make validate"* ]]
}
