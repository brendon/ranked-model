## [Unreleased]

## [0.5.0] - 2026-10-19

- Require Ruby 3.3+ and Rails 7.2+.
- Avoid permanently checking out a database connection when ranking. Thanks @joeljunstrom!
- Fix `rebalance_ranks` rounding that could push rank values past the maximum integer column value. Thanks @RNDcpp!

## [0.4.11] - 2024-11-20

- Add `funding_uri` to gemspec.

## [0.4.10] - 2024-08-09

- Publish ActiveSupport notifications on rebalancing. Thanks @tjvc!

## [0.4.9] - 2023-08-22

- Require Rails 5.2+.
- Update the `_position` attribute to its integer value after saving with an inferred position (e.g. `:last`), so saving again doesn't move the record. Thanks @CodingAnarchy!
- Document the possible N+1 when reading `_rank` across many records. Thanks @mrcasals!

## [0.4.8] - 2022-02-08

- Fix an unbounded query when setting a position of `:last`. Thanks @vincedevendra!
- Test against Rails 6.1. Thanks @aried3r!

## [0.4.7] - 2021-01-17

- Quote the column name in `_rank` queries, fixing SQL errors with reserved column names like `order`. Thanks @ursm!
- Test against Ruby 3.0. Thanks @aried3r!
- Document the `unless` option. Thanks @aried3r!

## [0.4.6] - 2020-03-17

- Support unique indexes on the ranked column when rebalancing. Thanks @janklimo!

## [0.4.5] - 2020-01-22

- Fix a `NoMethodError` when changing a `with_same` attribute and triggering a rebalance at the same time. Thanks @frysch!
- Don't fail when checking the column default before the table exists. Thanks @walf443!
- Use an `exists?` query when checking whether a rank is already taken.
- Test against Rails 6.0. Thanks @walf443!

## [0.4.4] - 2019-03-23

- Add a `<ranker>_rank` method (e.g. `row_order_rank`) that returns a record's position within the ordered list. Thanks @pragyadaga!
- Skip the column default check when there's no database connection.

## [0.4.3] - 2019-02-13

- Raise `RankedModel::NonNilColumnDefault` if the ranked column has a default value in the database.
- Use `reorder` rather than `order` so a `default_scope` ordering doesn't interfere with ranking.
- Only look for the record in the current order during rebalancing if it's persisted with a rank.

## [0.4.2] - 2018-12-10

- Require Rails 4.1+.
- Rails 5.x compatibility.
- Fix ranking when the final two ranks are consecutive and a record is moved to second to last.
- Quote the column name when rearranging ranks. Thanks @mkalygin!

## [0.4.1] - 2018-07-12

- Extend the rank range to the full signed 4-byte integer range. Thanks @bnauta!
- Fix memoization of `RankedModel::Ranker::Mapper#finder`.
- Name the missing attribute in the error raised when one of several `with_same` attributes doesn't exist. Thanks @vinbarnes!
