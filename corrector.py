import re
import sys
from pathlib import Path


def correct_source(source):
    lines = source.splitlines(keepends=True)
    corrected = []
    fixes = []

    for number, original in enumerate(lines, start=1):
        ending = "\n" if original.endswith("\n") else ""
        line = original.rstrip("\r\n")
        stripped = line.strip()

        if not stripped or stripped.startswith("//"):
            corrected.append(original)
            continue
        # Remove duplicate semicolons at the end of a statement.
        # Example: int a = 10;; -> int a = 10;
        if re.search(r";{2,}\s*$", line):
            line = re.sub(r";{2,}(\s*)$", r";\1", line)

            fixes.append(
                f"Line {number}: removed extra semicolon(s)"
            )
        # Fix reversed comparison operator => to >=.
        # Only correct when used in a simple condition.
        if re.match(r"^\s*(?:if|while)\s*\(", line):
            code_part, separator, comment = line.partition("//")

            if "=>" in code_part:
                code_part = code_part.replace("=>", ">=")
                line = code_part + (
                    separator + comment if separator else ""
                )

                fixes.append(
                    f"Line {number}: replaced invalid operator '=>' with '>='"
                )
        # 1. Missing closing brace in a simple array initializer.
        # Example: int marks[5] = {85, 90, 78, 88, 92;
        array_init = re.match(
            r"^(\s*(?:(?:int|float|char)\s+)?\w+\s*"
            r"\[\s*\d*\s*\]\s*=\s*\{[^{}]*)(;)\s*$",
            line,
        )

        if array_init:
            line = array_init.group(1) + "}" + array_init.group(2)
            fixes.append(
                f"Line {number}: inserted a possible missing '}}' "
                "in array initializer"
            )

        # 2. Missing closing bracket in a simple array declaration.
        match = re.match(
            r"^(\s*(?:int|float|char)\s+\w+\s*\[\s*\d+)\s*;\s*$",
            line,
        )

        if match:
            line = match.group(1) + "];"
            fixes.append(
                f"Line {number}: inserted missing ']' in array declaration"
            )
        # Fix a missing ] in simple array indexing.
        # Examples: marks[2 = 90; or printf("%d", marks[2);
        code_part, separator, comment = line.partition("//")

        if code_part.count("[") == code_part.count("]") + 1:
            match = re.search(
                r"\b[A-Za-z_]\w*\[\s*(?:\d+|[A-Za-z_]\w*)"
                r"(?=\s*(?:=|;|\)|,))",
                code_part,
            )

            if match:
                position = match.end()
                code_part = (
                    code_part[:position] + "]" + code_part[position:]
                )
                line = code_part + (
                    separator + comment if separator else ""
                )

                fixes.append(
                    f"Line {number}: inserted missing ']' in array indexing"
                )
        # 3. Extra closing parenthesis immediately before a block.
        if re.search(r"\)\)\s*\{", line):
            line = re.sub(r"\)\)(\s*\{)", r")\1", line, count=1)
            fixes.append(
                f"Line {number}: removed an extra closing parenthesis"
            )
        # Remove one extra ) from simple control conditions.
        if re.match(r"^\s*(?:if|while|for)\s*\(", line):
            code_part, separator, comment = line.partition("//")

            if (
                code_part.count(")") == code_part.count("(") + 1
                and code_part.rstrip().endswith(")")
            ):
                code_part = code_part.rstrip()[:-1]

                line = code_part + (
                    separator + comment if separator else ""
                )

                fixes.append(
                    f"Line {number}: removed extra ')' in condition"
                )
        # 4. Missing closing parenthesis before an opening block.
        header = re.match(
            r"^(\s*(?:(?:int|float|char|void)\s+\w+|if|while|for)"
            r"\s*\(.*?)(\s*\{)\s*$",
            line,
        )

        if header:
            prefix, opening_brace = header.groups()

            if prefix.count("(") > prefix.count(")"):
                line = prefix + ")" + opening_brace
                fixes.append(
                    f"Line {number}: inserted a possible missing ')'"
                )

        # Fix missing ) in simple if/while conditions.
        if re.match(r"^\s*(?:if|while|for)\s*\(", line):
            code_part, separator, comment = line.partition("//")

            if code_part.count("(") == code_part.count(")") + 1:
                if not code_part.rstrip().endswith(";"):
                    if "{" in code_part:
                        position = code_part.index("{")
                    else:
                        position = len(code_part.rstrip())
                    code_part = (
                        code_part[:position].rstrip()
                        + ")"
                        + code_part[position:]
                    )

                    line = code_part + (
                        separator + comment if separator else ""
                    )

                    fixes.append(
                        f"Line {number}: inserted missing ')' in condition"
                    )
               # 5. Repair a simple malformed if-else block.
        if re.match(r"^\s*else\s*$", line):
            previous = next(
                (item.strip() for item in reversed(corrected) if item.strip()),
                ""
            )

            # Only handle a simple else with one statement and
            # an existing closing brace immediately afterward.
            next_lines = lines[number:]
            nonempty = [
                (i, item.strip())
                for i, item in enumerate(next_lines)
                if item.strip()
            ]

            if (
                previous.endswith(";")
                and len(nonempty) >= 2
                and re.match(r"^\s*(?:printf|scanf)\s*\(.*\)\s*;\s*$",
                             nonempty[0][1])
                and nonempty[1][1] == "}"
            ):
                indentation = re.match(r"^\s*", line).group()
                line = indentation + "} else {"

                fixes.append(
                    f"Line {number}: repaired simple if-else braces"
                )    
        # Fix missing comma after format string in printf/scanf.
        match = re.match(
            r'^(\s*(?:printf|scanf)\s*\(\s*"[^"]*")'
            r'(\s+)([A-Za-z_]\w*(?:\[\d+\])?\s*\))',
            line,
        )

        if match:
            line = (
                line[:match.start()]
                + match.group(1)
                + ", "
                + match.group(3)
                + line[match.end():]
            )

            fixes.append(
                f"Line {number}: inserted missing comma in function call"
            )   
        # Fix missing closing parenthesis in printf/scanf calls.
        if re.match(r"^\s*(?:printf|scanf)\s*\(", line):
            code_part, separator, comment = line.partition("//")

            if code_part.count("(") > code_part.count(")"):
                semicolon = code_part.rstrip().endswith(";")
                body = code_part.rstrip()

                if semicolon:
                    body = body[:-1].rstrip()

                code_part = body + ")" + (";" if semicolon else "")
                line = code_part + (separator + comment if separator else "")

                fixes.append(
                    f"Line {number}: inserted a possible missing ')' in function call"
                )

        # Fix missing semicolon after printf/scanf.
        if (
            re.match(r"^\s*(?:printf|scanf)\s*\(", line)
            and line.rstrip().endswith(")")
        ):
            line = line.rstrip() + ";"
            fixes.append(
                f"Line {number}: inserted missing semicolon after function call"
            )
        # Fix missing semicolons after array assignments
        # and simple function calls.
        code = line.strip()

        array_assignment = re.match(
            r"^[A-Za-z_]\w*\s*\[[^\[\]]+\]\s*=\s*.+$",
            code,
        )

        function_call = (
           re.match(r"^[A-Za-z_]\w*\s*\(.*\)$", code)
           if not re.match(
               r"^(?:if|while|for|switch)\s*\(",
               code
           )
           else None
        )

        if (
            (array_assignment or function_call)
            and not code.endswith((";", "{", "}"))
            and "//" not in line
        ):
            line = line.rstrip() + ";"
            fixes.append(
                f"Line {number}: inserted missing semicolon"
            )
        # 6. Missing semicolons on supported simple statements.
        candidate = (
            re.match(r"^\s*(?:int|float|char)\s+\w+\s*=", line)
            or re.match(r"^\s*\w+\s*=\s*[^=].*", line)
            or re.match(r"^\s*return(?:\s+.+)?$", line)
            or re.match(r"^\s*\w+\s*(?:\+\+|--)\s*$", line)
        )

        if (
            candidate
            and not re.match(r"^\s*(?:if|while|for)\s*\(", line)
            and not line.strip().endswith(";")
            and not line.strip().endswith("{")
            and not line.strip().endswith("}")
        ):
            line += ";"
            fixes.append(
                f"Line {number}: inserted a possible missing semicolon"
            )

        corrected.append(line + ending)
    # Fix missing closing braces at the end of the program.
    result = "".join(corrected)

    opening = result.count("{")
    closing = result.count("}")

    if opening > closing:
        missing = opening - closing

        result = result.rstrip() + "\n" + ("}\n" * missing)

        fixes.append(
            f"Inserted {missing} missing closing brace(s) at end of file"
        )

    return result, fixes
    return "".join(corrected), fixes


def main():
    if len(sys.argv) != 2:
        print("Usage: python corrector.py <source_file>")
        raise SystemExit(1)

    source_path = Path(sys.argv[1])

    if not source_path.is_file():
        print(f"Error: source file not found: {source_path}")
        raise SystemExit(1)

    source = source_path.read_text(encoding="utf-8")
    repaired, fixes = correct_source(source)

    output_path = source_path.with_name(
        f"{source_path.stem}_corrected{source_path.suffix}"
    )

    output_path.write_text(repaired, encoding="utf-8")

    print("\n========== SYNTAXGUARD CORRECTOR ==========")

    if fixes:
        print(f"Proposed corrections: {len(fixes)}")
        for fix in fixes:
            print("- " + fix)
    else:
        print("No supported corrections found.")

    print(f"\nCorrected copy saved to: {output_path}")
    print("Review and validate all corrections before accepting them.")
    print("===========================================")


if __name__ == "__main__":
    main()