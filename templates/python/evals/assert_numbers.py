"""promptfoo assertion: every number in the answer must come from the test's variables.

Uses the same guardrail as the app (`app.guardrails`), so evals and production agree.
"""

from typing import Any

from app.guardrails import check_numbers


def get_assert(output: str, context: dict[str, Any]) -> dict[str, Any]:
    check = check_numbers(output, context.get("vars", {}))
    if check.ok:
        return {"pass": True, "score": 1.0, "reason": "Every number comes from the input"}
    listed = ", ".join(n.text for n in check.unsupported)
    return {"pass": False, "score": 0.0, "reason": f"Numbers not in the input: {listed}"}
