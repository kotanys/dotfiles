---
name: gnu-date
description: >
    Use when writing scripts that need to parse user-provided dates in text
    format and are supposed to be running in an environment with GNU date
    available with no limitation on external dependencies.
---

GNU date makes for a powerful date parsing mechanism. Not only it can parse
strings like '08-11-2026', but also human-readables like 'tomorrow' or '2
weeks ago'

Use only when:
1. Know that the machine the script will be running on has GNU utilities.
2. Have no requirement to minimize external dependencies.

Invoke GNU date with the language's execvp(3) equivalent. E.g. for python: `subprocess.run`.
Give three arguments:
1. output format that can be parsed into the language's date type, starting with `+`.
   E.g. in Python `+%Y-%m-%d` can be then parsed with
   ```python
   import datetime
   datetime.datetime.strptime(returned_date, "%Y-%m-%d").date()
   ```
2. `-d`
3. input string, unprocessed. 

Full example (Python):
```python
date = subprocess.run(
    ["date", "-d", expression, "+%Y-%m-%d"],
    capture_output=True,
    text=True,
    check=False,
)
if date.returncode:
    sys.exit(f'cannot parse date "{expression}": {date.stderr.strip()}')
return datetime.datetime.strptime(date.stdout.strip(), "%Y-%m-%d").date()
```

Make sure to handle errors (non-zero return code).
