#!/usr/bin/env bash
# Validates the structure and quality of skills in ai/assets/skills/
# Checks format, content, and architectural compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
SKILLS_DIR="${DOTFILES_DIR}/ai/assets/skills"

ERRORS=0
WARNINGS=0

# Required sections that indicate a well-structured skill
REQUIRED_SECTIONS=(
    "When to Use"
    "Guidelines"
    "Checklist"
    "Examples"
    "Best Practices"
    "Quality Checklist"
)

has_title() {
    local file="$1"
    grep -q "^# " "${file}" 2>/dev/null
}

has_section() {
    local file="$1"
    grep -q "^## " "${file}" 2>/dev/null
}

has_minimal_content() {
    local file="$1"
    local line_count
    line_count=$(wc -l < "${file}")
    [[ ${line_count} -ge 15 ]]
}

check_project_coupling() {
    local skill_path="$1"
    local skill_name
    skill_name=$(basename "${skill_path}")

    local content
    content=$(cat "${skill_path}/SKILL.md" 2>/dev/null || echo "")

    # Check for external project references (paths outside dotfiles repo)
    # Pattern: /proyectos/<name> or /.config/mcp/<name> where <name> is a project
    if echo "${content}" | grep -qE "/proyectos/[a-zA-Z]|/home/[a-zA-Z]+/proyectos/"; then
        echo "  ⚠ ${skill_name}: Contains path to external project"
        ((WARNINGS++))
        return 1
    fi

    return 0
}

check_has_recognizable_section() {
    local file="$1"
    local skill_name
    skill_name=$(basename "$(dirname "${file}")")

    for section in "${REQUIRED_SECTIONS[@]}"; do
        if grep -q "${section}" "${file}" 2>/dev/null; then
            return 0
        fi
    done

    echo "  ⚠ ${skill_name}: No recognizable section (expected one of: ${REQUIRED_SECTIONS[*]})"
    ((WARNINGS++))
    return 1
}

check_skill() {
    local skill_path="$1"
    local skill_name
    skill_name=$(basename "${skill_path}")

    local skill_file="${skill_path}/SKILL.md"
    local skill_valid=true

    if [[ ! -f "${skill_file}" ]]; then
        echo "  ✗ ${skill_name}: Missing SKILL.md"
        ((ERRORS++))
        return
    fi

    if [[ ! -s "${skill_file}" ]]; then
        echo "  ✗ ${skill_name}: SKILL.md is empty"
        ((ERRORS++))
        return
    fi

    if ! has_title "${skill_file}"; then
        echo "  ✗ ${skill_name}: Missing title (should start with '# ')"
        ((ERRORS++))
        skill_valid=false
    fi

    if ! has_section "${skill_file}"; then
        echo "  ✗ ${skill_name}: Missing sections (should have '## ' headings)"
        ((ERRORS++))
        skill_valid=false
    fi

    if ! has_minimal_content "${skill_file}"; then
        echo "  ⚠ ${skill_name}: Content seems minimal (< 15 lines)"
        ((WARNINGS++))
    fi

    if ! check_project_coupling "${skill_path}"; then
        skill_valid=false
    fi

    if [[ "${skill_valid}" == true ]]; then
        if ! check_has_recognizable_section "${skill_file}"; then
            skill_valid=false
        fi
    fi

    if [[ "${skill_valid}" == true ]]; then
        echo "  ✓ ${skill_name}"
    fi
}

scan_directory() {
    local dir="$1"
    local prefix="${2:-}"

    for skill_path in "${dir}"/*; do
        [[ -d "${skill_path}" ]] || continue
        local skill_name
        skill_name="${prefix}$(basename "${skill_path}")"

        # Skip internal subdirectories
        local skip_dirs=("references" "render" "templates" "assets" "examples" "scripts" ".venv")
        if [[ " ${skip_dirs[*]} " =~ " $(basename "${skill_path}") " ]]; then
            continue
        fi

        # Check if this directory has SKILL.md
        if [[ -f "${skill_path}/SKILL.md" ]]; then
            check_skill "${skill_path}"
        else
            # No SKILL.md at this level - check if it's a subcategory with skills
            local has_subdirs=false
            for subdir in "${skill_path}"/*; do
                [[ -d "${subdir}" ]] || continue
                local subdir_name
                subdir_name=$(basename "${subdir}")
                if [[ ! " ${skip_dirs[*]} " =~ " ${subdir_name} " ]]; then
                    has_subdirs=true
                    break
                fi
            done

            if [[ "${has_subdirs}" == true ]]; then
                # Recurse into subcategory
                scan_directory "${skill_path}" "${skill_name}/"
            else
                # Empty directory or no skills - warning
                if [[ ! -f "${skill_path}/SKILL.md" ]]; then
                    echo "  ⚠ ${skill_name}: No SKILL.md found"
                    ((WARNINGS++))
                fi
            fi
        fi
    done
}

echo "========================================"
echo "SKILL STRUCTURE VALIDATION"
echo "========================================"
echo ""

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "ERROR: Skills directory not found: ${SKILLS_DIR}"
    exit 1
fi

for category in "${SKILLS_DIR}"/*; do
    [[ -d "${category}" ]] || continue
    category_name=$(basename "${category}")
    echo "Category: ${category_name}"
    scan_directory "${category}" ""
    echo ""
done

echo "========================================"
echo "SUMMARY"
echo "========================================"
echo "Errors:   ${ERRORS}"
echo "Warnings: ${WARNINGS}"
echo ""

if [[ ${ERRORS} -gt 0 ]]; then
    echo "Validation FAILED"
    exit 1
elif [[ ${WARNINGS} -gt 0 ]]; then
    echo "Validation PASSED with warnings"
    exit 0
else
    echo "Validation PASSED"
    exit 0
fi
