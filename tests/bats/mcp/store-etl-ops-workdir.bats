#!/usr/bin/env bats
# store_etl_ops: configurable workdir contract.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SERVER="${DOTFILES_DIR}/ai/runtime/mcp/servers/store_etl_ops/server.py"
}

@test "store_etl_ops server.py passes py_compile" {
	run python3 -m py_compile "${SERVER}"
	[[ "${status}" -eq 0 ]]
}

@test "store_etl_ops workdir resolution unit tests pass" {
	run python3 -m unittest discover -s "${DOTFILES_DIR}/tests/python" -p 'test_store_etl_ops_workdir.py' -v
	[[ "${status}" -eq 0 ]]
}

@test "store_etl_ops server documents STORE_ETL_WORKDIR env var" {
	grep -q 'STORE_ETL_WORKDIR' "${SERVER}"
	grep -q 'DEFAULT_STORE_ETL_WORKDIR' "${SERVER}"
}
