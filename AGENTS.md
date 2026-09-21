# Pinpoint Workspace Rules

- `Settings.get(key)` always returns the fallback from `defaultSettings[key]`. Cast directly to the non-nullable type (`as int`, `as bool`, `as String`) without redundant `??` null-coalescing or nullable casts (`as int?`).
