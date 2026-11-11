import pytest

from app.guardrails import (
    UnsupportedNumberError,
    check_numbers,
    enforce_numbers,
    extract_numbers,
    numbers_from,
)

DATA = {
    "fund": "World Equity",
    "aum_eur": 1_234_567.0,
    "return_ytd": 0.0812,
    "tracking_error": "1.35%",
    "holdings": [{"name": "A", "weight": 0.042}, {"name": "B", "weight": 0.031}],
}


@pytest.mark.parametrize(
    ("text", "value"),
    [
        ("1,234,567", 1_234_567),
        ("-3", -3),
        ("\u22123.5", -3.5),
        ("12.5%", 12.5),
        ("4.2M", 4_200_000),
        ("1.1 billion", 1_100_000_000),
        ("250k", 250_000),
        ("0.0812", 0.0812),
    ],
)
def test_extract_reads_english_notation(text: str, value: float) -> None:
    [number] = extract_numbers(f"Value: {text}.")
    assert number.value == pytest.approx(value)


def test_extract_ignores_digits_inside_words() -> None:
    assert extract_numbers("model gpt4o and ISIN IE00B4L5Y983") == []


def test_numbers_from_walks_nested_data_and_strings() -> None:
    assert sorted(numbers_from(DATA)) == pytest.approx(
        sorted([1_234_567.0, 0.0812, 1.35, 0.042, 0.031])
    )


def test_numbers_from_skips_booleans_and_none() -> None:
    assert numbers_from({"ok": True, "missing": None}) == []


def test_restated_and_rounded_numbers_pass() -> None:
    answer = "AUM is 1,234,567 EUR (about 1.23M), up 8.1% this year, TE 1.35%. A weighs 4.2%."
    assert check_numbers(answer, DATA).ok


def test_invented_number_fails() -> None:
    check = check_numbers("AUM is 1,500,000 EUR and TE is 1.35%.", DATA)
    assert [n.text for n in check.unsupported] == ["1,500,000"]


def test_derived_number_fails() -> None:
    # 4.2% + 3.1% = 7.3%: true, but computed by the model, so it must come from code instead.
    assert not check_numbers("A and B weigh 7.3% together.", DATA).ok


def test_wrong_rounding_fails() -> None:
    assert not check_numbers("Up 8.2% this year.", DATA).ok


def test_small_integers_and_years_are_not_checked() -> None:
    assert check_numbers("Top 3 holdings in 2026: see the 2 tables.", DATA).ok


def test_relative_tolerance() -> None:
    assert not check_numbers("AUM is 1,240,000 EUR.", DATA).ok
    assert check_numbers("AUM is 1,240,000 EUR.", DATA, rel_tol=0.01).ok


def test_enforce_blocks_by_default() -> None:
    with pytest.raises(UnsupportedNumberError, match=r"99\.9%"):
        enforce_numbers("Returned 99.9%.", DATA)


def test_enforce_flag_mode_returns_the_check() -> None:
    check = enforce_numbers("Returned 99.9%.", DATA, mode="flag")
    assert not check.ok
    assert enforce_numbers("Returned 8.12%.", DATA).ok
