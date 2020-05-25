# Changelog
## 0.7.0 - 25/05/2020
 * Require Elixir ~> 1.7
 * Drop support for ecto 2.x, add support for ecto ~> 3.3

## 0.6.1
 * Bugfix release

## 0.6.0
 * Add compatability with ecto ~> 2.1, many thanks for @galina and @s33m4nn for their contribution;
 * Fix some bugs.
 * Update dependencies.

## 0.5.0
 * All keys in query object convert to strings, you can use both String and atom in any keys.

## 0.4.0
 * Add ability to use atom keys in query object, thanks for @dotsent.

## 0.3.0
 * Fix predicate extraction
 * Add interpolation mark for eq, lt, gt, queries builder.

## 0.2.0
 * Fix condition combinator
 * Add error `{:error, :value_is_empty}` for empty condition values

## 0.1.0
 * Initial release
