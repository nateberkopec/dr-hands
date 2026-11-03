import argparse
import json
from pathlib import Path
import sys


def reject_constant(_value):
    raise ValueError("non-JSON constant")


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate object key")
        result[key] = value
    return result


def main():
    parser = argparse.ArgumentParser(
        description="Validate report structure locally; never render or fetch report content."
    )
    parser.add_argument("report", help="UTF-8 JSON file, at most 1 MiB")
    args = parser.parse_args()

    try:
        from jsonschema import Draft202012Validator
    except ModuleNotFoundError:
        print("Install the dependencies in requirements-lint.txt before linting.", file=sys.stderr)
        return 2

    try:
        with open(args.report, "rb") as source:
            raw = source.read(1024 * 1024 + 1)
    except OSError:
        print("Cannot read the report file.", file=sys.stderr)
        return 2

    if len(raw) > 1024 * 1024:
        print("Report exceeds the 1 MiB byte limit.", file=sys.stderr)
        return 1

    try:
        report = json.loads(
            raw.decode("utf-8"),
            object_pairs_hook=unique_object,
            parse_constant=reject_constant,
        )
    except (ValueError, RecursionError):
        print("Report must be bounded UTF-8 JSON with unique keys and valid JSON values.", file=sys.stderr)
        return 1

    schema_path = Path(__file__).resolve().parent.parent / "schemas" / "report.schema.json"
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    error = next(Draft202012Validator(schema).iter_errors(report), None)
    if error is not None:
        location = json.dumps(list(error.absolute_path), ensure_ascii=True)
        print(f"Report violates {error.validator} at {location}.", file=sys.stderr)
        return 1

    print("Report structure is valid; contents remain hostile.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
