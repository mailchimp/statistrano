---
title: Strategies
---

Give the strategy as the second argument to `define_deployment`. For example to use a `releases` strategy:

```ruby
define_deployment "example", :releases do
  # configuration
end
```

For more specifics about each strategy:

- [Base](/doc/strategies/base.md)
- [Releases](/doc/strategies/releases.md)
- [Branches](/doc/strategies/branches.md)