"""Property-based tests (Hypothesis): invariants checked on hundreds of generated inputs.

Use this style for anything with rules that must always hold, such as weights summing to 1,
a tracking error never negative, or a parser that reads back what a formatter wrote.
"""

from hypothesis import given
from hypothesis import strategies as st

from app.guardrails import check_numbers, extract_numbers

amounts = st.floats(min_value=10, max_value=1e12, allow_nan=False, allow_infinity=False)


@given(amounts)
def test_formatted_amount_reads_back(value: float) -> None:
    [number] = extract_numbers(f"Total: {value:,.2f} EUR")
    assert abs(number.value - round(value, 2)) < 1e-6 * max(1.0, value)


@given(amounts, st.integers(min_value=0, max_value=4))
def test_any_rounding_of_a_source_number_is_accepted(value: float, decimals: int) -> None:
    assert check_numbers(f"It reached {value:,.{decimals}f}.", {"value": value}).ok


@given(amounts)
def test_a_number_far_from_every_source_is_rejected(value: float) -> None:
    assert not check_numbers(f"It reached {value * 3:,.2f}.", {"value": value}).ok
