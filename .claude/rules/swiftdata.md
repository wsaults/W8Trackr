# SwiftData Rules

## CloudKit Sync Compatibility

SwiftData models that sync with CloudKit have specific requirements to ensure proper synchronization.

### Attribute Constraints
- **Never use `@Attribute(.unique)`** in CloudKit-synced models
- CloudKit doesn't support unique constraints; they will cause sync failures

### Property Requirements
- All properties must have default values OR be optional
- Non-optional properties without defaults will fail during CloudKit sync

```swift
// Good
@Model
class Item {
    var name: String = ""
    var count: Int = 0
    var notes: String?
}

// Bad - will fail CloudKit sync
@Model
class Item {
    var name: String  // No default, not optional
    @Attribute(.unique) var id: String  // Unique constraint
}
```

### Relationship Requirements
- **All relationships must be optional**
- Required relationships will cause CloudKit sync issues

```swift
// Good
@Model
class Task {
    var title: String = ""
    var category: Category?  // Optional relationship
    var tags: [Tag]?  // Optional to-many relationship
}

// Bad - required relationship
@Model
class Task {
    var title: String = ""
    var category: Category  // Will fail CloudKit sync
}
```

## Summary Checklist
- [ ] No `@Attribute(.unique)` on any property
- [ ] All properties have defaults or are optional
- [ ] All relationships are optional
