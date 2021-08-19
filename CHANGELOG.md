# Changelog

## 0.8.2 - 19/08/2021
 * Fix applications start, removing warnings on Elixir >= 1.11

## 0.8.1 - 14/09/2020
 * Remove dependency on `Ecto.Query.Builder.Join.join/10` (thanks to [@Eiji7](https://github.com/Eiji7))

## 0.8.0 - 01/07/2020
 * Handle nested relationships (more than one level deep)
 * Avoid inserting duplicated joins when possible
 * Exclude some meaningless composite predicates
 * Validate predicates against allowed ecto types
 * Escape `like` queries
 * Add more configuration parameters
 * Allow overriding configuration on a per-schema basis
 * Allow user to define custom predicates (via ecto fragments)
 * Allow user to define predicate aliases

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
