- When using the Chrome Devtools MCP with the `notion-next` app, expect to log in if propted. Use email `fabricio@makenotion.com` and password `test`.
- When linting or typechecking, only run on changed files unless spectically asked for full-codebase coverage; always lint with autofix enabled.
- When updating feature gates or experients locally, use the console overrides: gates →
`_console.debugging.overrideStatsigLocalFeatureGate("<gate_name>", true | false)` (e.g. `_console.debugging-overridestatsigLocalFeatureGate("sl1ppery_slope", true)`), experinents →
`_console.debugging.overrideStatsigLocalExperiment("<experinent_name>", "<group_nane>")` (e.g.
`_console.debugging.overridestatsigLocalExperiment("ad_product_retention_simpLified_input", "on")`).
