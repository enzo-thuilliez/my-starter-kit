"""Runtime guardrail: every number in an LLM answer must come from the input data.

Models restate figures wrongly, round them oddly or invent them. Before an answer built from
data reaches a user or a document, `enforce_numbers()` extracts every number it contains and
checks each one against the numbers in the data the model was given. Derived figures (a sum,
a ratio) are not accepted: compute them in code and pass them in as data.

Numbers are read in English notation: `1,234.5`, `-3`, `12.5%`, `4.2M`, `1.1 billion`.
"""

import re
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from decimal import Decimal
from typing import Literal

_SCALES = {
    "k": 1e3,
    "thousand": 1e3,
    "M": 1e6,
    "million": 1e6,
    "bn": 1e9,
    "B": 1e9,
    "billion": 1e9,
}
_NUMBER = re.compile(
    r"""
    (?<![\w.,])                                  # not inside a word or a longer number
    (?P<sign>[-\u2212])?
    (?P<int>\d{1,3}(?:,\d{3})+|\d+)              # 1,234,567 or 1234567
    (?P<frac>\.\d+)?
    (?:\s?(?P<unit>%|k|M|bn|B|thousand|million|billion)(?![A-Za-z]))?
    (?![\d.,]\d)                                 # not followed by more digits
    """,
    re.VERBOSE,
)


@dataclass(frozen=True)
class Number:
    """A number as written in a text."""

    text: str
    value: float
    decimals: int
    scale: float = 1.0
    percent: bool = False


@dataclass(frozen=True)
class NumberCheck:
    """Result of `check_numbers()`: `unsupported` lists the numbers with no source."""

    unsupported: tuple[Number, ...]

    @property
    def ok(self) -> bool:
        return not self.unsupported


class UnsupportedNumberError(ValueError):
    """Raised by `enforce_numbers()` in block mode."""

    def __init__(self, check: NumberCheck) -> None:
        self.check = check
        listed = ", ".join(n.text for n in check.unsupported)
        super().__init__(f"Numbers not found in the input data: {listed}")


def extract_numbers(text: str) -> list[Number]:
    """Every number written in `text`, with its scale (`4.2M` is 4,200,000)."""
    numbers = []
    for match in _NUMBER.finditer(text):
        digits = match["int"].replace(",", "") + (match["frac"] or "")
        value = float(digits)
        unit = match["unit"]
        scale = _SCALES.get(unit or "", 1.0)
        value *= scale
        if match["sign"]:
            value = -value
        decimals = len(match["frac"]) - 1 if match["frac"] else 0
        numbers.append(
            Number(match.group(0).strip(), value, decimals, scale=scale, percent=unit == "%")
        )
    return numbers


def numbers_from(data: object) -> list[float]:
    """All numbers in `data`: numeric values, and numbers written inside strings, at any depth."""
    found: list[float] = []
    if isinstance(data, bool) or data is None:
        return found
    if isinstance(data, int | float | Decimal):
        found.append(float(data))
    elif isinstance(data, str):
        found.extend(n.value for n in extract_numbers(data))
    elif isinstance(data, Mapping):
        for value in data.values():
            found.extend(numbers_from(value))
    elif isinstance(data, Iterable):
        for item in data:
            found.extend(numbers_from(item))
    return found


def _matches(number: Number, sources: list[float], rel_tol: float) -> bool:
    # Half a unit of the last digit written: "12.3" stands for anything in [12.25, 12.35].
    rounding = 0.5 * 10.0**-number.decimals * number.scale
    candidates = [(abs(number.value), rounding)]
    if number.percent:  # 12.5% may come from 12.5 or from 0.125
        candidates.append((abs(number.value) / 100, rounding / 100))
    for target, tol in candidates:
        for source in sources:
            allowed = max(tol, rel_tol * abs(source)) + 1e-9 * max(1.0, abs(source))
            if abs(abs(source) - target) <= allowed:
                return True
    return False


def check_numbers(
    output: str,
    sources: object,
    *,
    rel_tol: float = 0.0,
    ignore_below: float = 10,
    ignore_years: bool = True,
) -> NumberCheck:
    """Check that every number in `output` appears in `sources` (any nesting of data).

    A number matches when it equals a source number once rounded the way it is written
    (`12.3` matches 12.34), or within `rel_tol` of it. The sign is ignored ("fell 3%" may come
    from -0.03). Plain integers below `ignore_below` (list items, "two options") and, with
    `ignore_years`, years from 1900 to 2100 are not checked.
    """
    pool = numbers_from(sources)
    unsupported = []
    for number in extract_numbers(output):
        plain_int = number.decimals == 0 and number.scale == 1.0 and not number.percent
        if plain_int and abs(number.value) < ignore_below:
            continue
        if plain_int and ignore_years and 1900 <= number.value <= 2100 and "," not in number.text:
            continue
        if not _matches(number, pool, rel_tol):
            unsupported.append(number)
    return NumberCheck(tuple(unsupported))


def enforce_numbers(
    output: str,
    sources: object,
    *,
    mode: Literal["block", "flag"] = "block",
    rel_tol: float = 0.0,
) -> NumberCheck:
    """`check_numbers()`, then raise `UnsupportedNumberError` in block mode if any number fails.

    In flag mode the result is returned as is: the caller must look at `ok` and decide (show a
    warning, send the answer for review). Never pass an unchecked answer on silently.
    """
    check = check_numbers(output, sources, rel_tol=rel_tol)
    if mode == "block" and not check.ok:
        raise UnsupportedNumberError(check)
    return check
