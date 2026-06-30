## Unreleased
  - Fixed: `Power#invalid?` had an operator-precedence bug that flagged *any* fractional
    exponent as invalid instead of only negative-base fractional exponents (e.g. `2.2 ** 1.2`
    was incorrectly rejected).
  - Fixed: configuration error messages no longer route through Logstash core's internal
    `I18n` catalog (which produced text that didn't match the documented/tested error
    messages); they are now plain, predictable strings.
  - Added: `tag_on_failure` option. A runtime exception during a single calculation (e.g.
    a malformed `round` digits operand) is now caught, the event is tagged, and the rest
    of the pipeline keeps running instead of the worker crashing.
  - Fixed: field-not-found / non-numeric-field warning logs no longer eagerly serialize
    the full event via `to_hash` when warn-level logging is disabled.
  - Added: spec coverage for `abs`, `neg`, `percent_change`, and all six unit conversion
    operators (`mi_to_km`, `km_to_mi`, `m_to_ft`, `ft_to_m`, `c_to_f`, `f_to_c`), which
    previously had none.
  - Docs: documented unary (3-element) calculations, the new operators, and `tag_on_failure`,
    which were missing from `docs/index.asciidoc`.

## 1.1.3
  - Added unary (3-element) calculations alongside the original 4-element binary form.
  - Added `abs`, `neg`/`negate`, and `percent_change` operators.
  - Added unit conversion operators: `mi_to_km`, `km_to_mi`, `m_to_ft`, `ft_to_m`,
    `c_to_f`, `f_to_c`.
  - Added support for numeric literals as operands.
  - Refactored internals into `MathFunctions`, `MathCalculationElements`, and
    `EventRegisterContext`.

## 1.1.1
  - Fix to make registers threadsafe. [math filter #10](https://github.com/logstash-plugins/logstash-filter-math/issues/10)

## 1.1.0
  - Bumping to this version as this plugin was published to rubygems at v1.0
  - Fixed add backward compatible Operator reference aliases `'sub', 'mpx'` [math filter #8](https://github.com/logstash-plugins/logstash-filter-math/pull/8)

## 1.0.0
  - This plugin is now in the logstash-plugins GH org
  - Added Memory registers
  - Added More functions Power, Round, Modulo, FloatDivide
  - Added Literals
  - Added Operator reference aliases, e.g. `'*', 'times', 'multiply'` all refer to Multiply.
  - Added asciidoc documentation
  - Above features provided by [math filter #5](https://github.com/logstash-plugins/logstash-filter-math/pull/5)

## 1.0
  - Published to rubygems by Robin Clarke
