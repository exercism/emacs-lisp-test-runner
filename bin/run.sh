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
input_dir="${2%/}"
output_dir="${3%/}"
test_file="${input_dir}/${slug}-test.el"
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

echo "${slug}: testing..."

pushd "${input_dir}" > /dev/null

# Run the tests for the provided implementation file and redirect stdout and
# stderr to capture it
test_output=$(emacs -batch -l ert -l "${test_file}" -f ert-run-tests-batch-and-exit 2>&1)
exit_code=$?

popd > /dev/null

# Write the results.json file based on the exit code of the command that was
# just executed that tested the implementation file
if [ $exit_code -eq 0 ]; then
    jq -n '{version: 1, status: "pass"}' > ${results_file}
else
    # Manually add colors to the output to help scanning the output for errors
    colorized_test_output=$(echo "${test_output}" \
         | GREP_COLOR='01;31' grep --color=always -E -e 'FAILED.*$|$' \
         | GREP_COLOR='01;32' grep --color=always -E -e 'passed.*$|$')

    jq -n --arg output "${colorized_test_output}" '{version: 1, status: "fail", message: $output}' > ${results_file}
fi

echo "${slug}: done"
