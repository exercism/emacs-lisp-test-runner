#!/usr/bin/env python3

import json
import re
import sys
from enum import Enum


class ExitCode(Enum):
    PASS = 0
    FAIL = 1
    ERROR = 2


class Status(Enum):
    PASS = "pass"
    FAIL = "fail"
    ERROR = "error"


TEST_FUNCTION = "ert-deftest"
TEST_FAILED_FUNCTION = "ert-test-failed"


def parse_test_functions(s: str):
    """
    Retrieve test function names and code from regions like
        '(ert-deftest name-is-persistent
            "Test that robot name is persistent."
            (should (equal (robot-name *robbie*)
                        (robot-name *robbie*))))'
    in the test file
    """
    function_matches = re.finditer(
        fr"(?P<semicolons>;+)?\s*\({TEST_FUNCTION}\s+(?P<name>[\w-]+)\s+\(\)\s*(?P<docstring>\".*\")?\s*(?P<code>(?:\n.+)+)\)",
        s,
    )
    names = []
    code_pieces = []
    for m in function_matches:
        if m["semicolons"]:
            continue
        names.append(m["name"])
        code_pieces.append(m["code"].strip())
    return names, code_pieces


def parse_test_statuses(s: str):
    """
    Retrieve test statuses from lines like
        'passed  3/4  name-is-persistent (0.000049 sec)'
    in the test output
    """
    status_matches = re.finditer(
        r"(?P<status>passed|FAILED)\s+(?P<number>\d+)\/\d+\s+(?P<name>[\w-]+)\s*(?:\(\d+\.\d+\ssec\))?",
        s,
    )
    return {
        m["name"]: (
            Status.PASS if m["status"].strip() == "passed" else Status.FAIL
        )
        for m in status_matches
    }


def parse_test_message(name: str, s: str):
    """
    Retrieve test messages from regions like
        'Test name-can-be-reset condition:
            (wrong-type-argument hash-table-p nil)
            FAILED  2/4  name-can-be-reset'
    in the test output
    """
    condition_matches = re.finditer(
        fr"Test\s{name}\scondition:\s+(?P<condition>\((?P<function>.+)(?:\n.+)+)FAILED\s+(?P<number>\d+)/\d+\s+{name}",
        s,
    )
    try:
        cond_match = next(condition_matches)
    except StopIteration:
        return None, None
    message = cond_match["condition"].strip()
    # status is 'fail' if test condition starts with the test failed function
    # otherwise there is an error
    status = (
        Status.FAIL
        if cond_match["function"] == TEST_FAILED_FUNCTION
        else Status.ERROR
    )
    return message, status


def parse_test_output(name: str, num: int, s: str):
    """
    Retrieve test outputs from regions like
        'Running 4 tests (2022-01-04 17:06:51+0200, selector ‘t’)
        "1DG190"
            passed  1/4  different-robots-have-different-names (0.000075 sec)'
    ,
        '   passed  1/4  different-robots-have-different-names (0.000075 sec)
        "1XW454"
            passed  2/4  name-can-be-reset (0.000047 sec)'
    and
        '   passed  3/4  name-is-persistent (0.000049 sec)
        "1DG190"
        Test name-matches-expected-pattern backtrace:'
    in the test output
    """
    status_line_regexp = fr"(?:passed|FAILED)\s+{num - 1}\/\d+\s+(?:[\w-]+)\s*(?:\(\d+\.\d+\ssec\))?"
    output_regexp = fr"(?P<output>(?:\n.*)+)\s*(?:passed\s+{num}|Test\s{name}\sbacktrace)"
    output_matches = re.finditer(
        (r"\)" if num == 1 else status_line_regexp) + output_regexp, s
    )
    try:
        output_match = next(output_matches)
    except StopIteration:
        return None, None
    output = output_match["output"].strip()
    message = None
    # Output is limited to 500 chars
    if len(output) > 500:
        message = "Output was truncated. Please limit to 500 chars"
        output = output[:500]
    return output, message


def run(test_file_path: str, test_output_file_path: str):
    exit_code = ExitCode.PASS
    with open(test_file_path, encoding="utf-8") as f:
        test_file_content = f.read()
    with open(test_output_file_path, encoding="utf-8") as f:
        test_output_file_content = f.read()
    names, code_pieces = parse_test_functions(test_file_content)
    name_to_number = {name: i + 1 for i, name in enumerate(sorted(names))}
    name_to_status = parse_test_statuses(test_output_file_content)
    status_to_exit_code = {Status(ec.name.lower()): ec for ec in ExitCode}
    tests = []
    for name, code in zip(names, code_pieces):
        test = {}
        number = name_to_number[name]
        test["name"] = name
        test["test_code"] = code.strip()
        # get status from status line or assume it is syntax error if there is no one
        status = name_to_status.get(name, Status.ERROR)
        message = None
        condition_message, message_status = parse_test_message(
            name, test_output_file_content
        )
        if condition_message:
            message, status = condition_message, message_status
        output, output_message = parse_test_output(
            name, int(number), test_output_file_content
        )
        if output_message and status != Status.PASS:
            if message:
                message += "\n" + output_message
            else:
                message = output_message
        exit_code = max(
            exit_code, status_to_exit_code[status], key=lambda x: x.value
        )
        test["status"] = status.value
        test["message"] = message
        if output:
            test["output"] = output
        tests.append(test)
    print(json.dumps(tests))
    return exit_code


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("./parse-tests.py <test-file> <test-output>", file=sys.stderr)
        sys.exit(ExitCode.ERROR.value)
    else:
        exit_code = run(*sys.argv[1:])
        sys.exit(exit_code.value)
