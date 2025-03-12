#!/usr/bin/env bash

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: absolute path to solution folder
# $3: absolute path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/"
    exit 1
fi

slug="$1"
script_dir="$(dirname "$0")"
input_dir="${2%/}"
output_dir="${3%/}"
test_file="${input_dir}/${slug}-test.el"
test_output_file="$(mktemp)"
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

echo "${slug}: testing..."

pushd "${input_dir}" > /dev/null

# Run the tests for the provided implementation file and record all terminal
# output to a temporary file to preserve output order
script -q -c "emacs -batch -l ert -l \"${test_file}\" -f ert-run-tests-batch-and-exit" \
    "$test_output_file" &> /dev/null

popd > /dev/null

# Write the results.json file based on both the exit code of the command that
# was just executed that tested the implementation file and per-test information
tests=$("$script_dir/parse_tests.py" "$test_file" "$test_output_file")
exit_code=$?
case $exit_code in
    0) status="pass" ;;
    1) status="fail" ;;
    2) status="error" ;;
    *) echo "'parse_tests.py' script returned unknown exit code" 1>&2 && exit 1 ;;
esac

if [ $exit_code -eq 0 ]; then
    jq -n --arg status "$status" \
        --argjson tests "$tests" \
        '{version: 2, status: $status, message: null, tests: $tests}' > ${results_file}
else
    # Manually add colors to the output to help scanning the output for errors
    test_output="$(cat "$test_output_file" | sed -e '1d' -e '$d')"
    colorized_test_output=$(echo "$test_output" \
        | GREP_COLORS='01;31' grep --color=always -E -e 'FAILED.*$|$' \
        | GREP_COLORS='01;32' grep --color=always -E -e 'passed.*$|$')

    jq -n --arg status "$status" \
        --arg output "$colorized_test_output" \
        --argjson tests "$tests" \
        '{version: 2, status: $status, message: $output, tests: $tests}' > ${results_file}
fi


echo "${slug}: done"
