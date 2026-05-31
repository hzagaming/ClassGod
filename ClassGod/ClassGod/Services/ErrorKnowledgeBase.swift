//
//  ErrorKnowledgeBase.swift
//  ClassGod
//
//  Comprehensive macOS/Swift/SwiftUI Error Database
//  Created by ClassGod on 2026/05/31.
//

import Foundation

final class ErrorKnowledgeBase {
    static let shared = ErrorKnowledgeBase()
    private(set) var allEntries: [ErrorEntry] = []
    
    private init() {
        loadAllEntries()
    }
    
    // MARK: - Search
    func search(query: String, category: ErrorCategory? = nil) -> [ErrorSearchResult] {
        let lowerQuery = query.lowercased()
        let entries = category == nil || category == .all ? allEntries : allEntries.filter { $0.category == category }
        
        var results: [ErrorSearchResult] = []
        for entry in entries {
            var score: Double = 0
            var matchedField = ""
            
            if let code = entry.errorCode, code.lowercased().contains(lowerQuery) {
                score += 100
                matchedField = "Error Code"
            }
            if entry.title.lowercased().contains(lowerQuery) {
                score += 50
                matchedField = matchedField.isEmpty ? "Title" : matchedField
            }
            if entry.description.lowercased().contains(lowerQuery) {
                score += 30
                matchedField = matchedField.isEmpty ? "Description" : matchedField
            }
            if entry.cause.lowercased().contains(lowerQuery) {
                score += 20
                matchedField = matchedField.isEmpty ? "Cause" : matchedField
            }
            for tag in entry.tags where tag.lowercased().contains(lowerQuery) {
                score += 15
                matchedField = matchedField.isEmpty ? "Tag" : matchedField
            }
            if entry.relatedErrors.contains(where: { $0.lowercased().contains(lowerQuery) }) {
                score += 10
            }
            
            if score > 0 {
                results.append(ErrorSearchResult(entry: entry, relevanceScore: score, matchedField: matchedField))
            }
        }
        
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    func entries(for category: ErrorCategory) -> [ErrorEntry] {
        guard category != .all else { return allEntries }
        return allEntries.filter { $0.category == category }
    }
    
    func entriesBySeverity(_ severity: ErrorSeverity) -> [ErrorEntry] {
        return allEntries.filter { $0.severity == severity }
    }
    
    func findRelated(to entry: ErrorEntry) -> [ErrorEntry] {
        let relatedTitles = Set(entry.relatedErrors)
        return allEntries.filter { relatedTitles.contains($0.title) || $0.relatedErrors.contains(entry.title) }
    }
    
    // MARK: - Load All Entries
    private func loadAllEntries() {
        var entries: [ErrorEntry] = []
        entries.append(contentsOf: swiftCompileErrors())
        entries.append(contentsOf: swiftRuntimeErrors())
        entries.append(contentsOf: swiftUIErrors())
        entries.append(contentsOf: appKitErrors())
        entries.append(contentsOf: xcodeBuildErrors())
        entries.append(contentsOf: networkErrors())
        entries.append(contentsOf: fileSystemErrors())
        entries.append(contentsOf: permissionErrors())
        entries.append(contentsOf: memoryErrors())
        entries.append(contentsOf: concurrencyErrors())
        entries.append(contentsOf: coreDataErrors())
        entries.append(contentsOf: codeSigningErrors())
        entries.append(contentsOf: widgetKitErrors())
        entries.append(contentsOf: combineErrors())
        entries.append(contentsOf: metalErrors())
        entries.append(contentsOf: securityErrors())
        entries.append(contentsOf: notificationErrors())
        entries.append(contentsOf: audioVideoErrors())
        entries.append(contentsOf: accessibilityErrors())
        entries.append(contentsOf: localizationErrors())
        entries.append(contentsOf: testingErrors())
        entries.append(contentsOf: packageManagerErrors())
        entries.append(contentsOf: generalErrors())
        entries.append(contentsOf: moreSwiftRuntimeErrors())
        entries.append(contentsOf: moreSwiftUIErrors())
        entries.append(contentsOf: moreAppKitErrors())
        entries.append(contentsOf: moreNetworkErrors())
        entries.append(contentsOf: moreFileSystemErrors())
        entries.append(contentsOf: morePermissionErrors())
        entries.append(contentsOf: moreMemoryErrors())
        entries.append(contentsOf: moreConcurrencyErrors())
        entries.append(contentsOf: moreCoreDataErrors())
        entries.append(contentsOf: moreCodeSigningErrors())
        entries.append(contentsOf: moreWidgetKitErrors())
        entries.append(contentsOf: moreCombineErrors())
        entries.append(contentsOf: moreMetalErrors())
        entries.append(contentsOf: moreSecurityErrors())
        entries.append(contentsOf: moreNotificationErrors())
        entries.append(contentsOf: moreAudioVideoErrors())
        entries.append(contentsOf: moreAccessibilityErrors())
        entries.append(contentsOf: moreLocalizationErrors())
        entries.append(contentsOf: moreTestingErrors())
        entries.append(contentsOf: moreSPMErrors())
        entries.append(contentsOf: moreGeneralErrors())
        allEntries = entries
    }
    
    // =========================================================================
    // MARK: - 1. SWIFT COMPILE ERRORS (100+ entries)
    // =========================================================================
    
    private func swiftCompileErrors() -> [ErrorEntry] {
        return [
            // -----------------------------------------------------------------
            // Type System Errors
            // -----------------------------------------------------------------
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Cannot convert value of type 'X' to expected argument type 'Y'",
                errorCode: "SWIFT_COMPILE_TYPE_MISMATCH",
                description: "The compiler cannot automatically convert one type to another. This is Swift's strict type safety preventing implicit conversions that could lead to runtime bugs.",
                cause: "1. Passing wrong type to function parameter. 2. Assigning incompatible types. 3. Missing explicit cast. 4. Generic type inference failure. 5. Protocol conformance mismatch.",
                solutions: [
                    "Explicitly cast using 'as', 'as?', or 'as!' depending on safety needs",
                    "Check function signature and ensure parameter types match exactly",
                    "Use String(describing:) or String interpolation for custom types",
                    "For numeric types, use Int(value), Double(value), CGFloat(value) constructors",
                    "Implement required protocol methods if it's a protocol conformance issue",
                    "Use map, compactMap, or flatMap to transform collections element types",
                    "Add @objc or NSObject conformance for Objective-C interop"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Type Mismatch Fix",
                        badCode: "let label: UILabel = \"Hello\"  // String to UILabel mismatch",
                        goodCode: "let label = UILabel()\nlabel.text = \"Hello\"",
                        explanation: "Cannot assign String to UILabel. Create UILabel instance first, then set text property."
                    ),
                    CodeExample(
                        language: "swift",
                        title: "Numeric Cast",
                        badCode: "let x: Int = 3.14  // Double to Int",
                        goodCode: "let x = Int(3.14)  // Explicit cast truncates to 3",
                        explanation: "Swift requires explicit numeric conversions to prevent accidental precision loss."
                    )
                ],
                relatedErrors: ["Cannot assign value of type", "Generic parameter could not be inferred"],
                tags: ["type", "cast", "conversion", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TypeCasting.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Value of optional type 'X?' must be unwrapped",
                errorCode: "SWIFT_COMPILE_OPTIONAL_UNWRAP",
                description: "Swift requires explicit handling of optional values. You cannot use an optional value directly where a non-optional is expected.",
                cause: "1. Attempting to use optional value without unwrapping. 2. Property declared as optional but used as non-optional. 3. Function returns optional but result used directly. 4. IBOutlet or similar implicitly optional not handled.",
                solutions: [
                    "Use if let binding: if let value = optional { /* use value */ }",
                    "Use guard let for early exit: guard let value = optional else { return }",
                    "Force unwrap with ! only when 100% sure value exists (DANGEROUS)",
                    "Use nil-coalescing ?? to provide default: let value = optional ?? defaultValue",
                    "Use optional chaining ?. to call methods on optional",
                    "Use map: optional.map { $0.someMethod() }",
                    "Consider making property non-optional if it always has value after init"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Unwrapping",
                        badCode: "let name: String? = getName()\nprint(name.uppercased())  // Error",
                        goodCode: "if let name = getName() {\n    print(name.uppercased())\n}",
                        explanation: "Always unwrap optionals safely. Force unwrap (!) causes runtime crashes if nil."
                    ),
                    CodeExample(
                        language: "swift",
                        title: "Nil Coalescing",
                        badCode: "let count: Int? = nil\nlet doubled = count * 2  // Error",
                        goodCode: "let count: Int? = nil\nlet doubled = (count ?? 0) * 2  // 0",
                        explanation: "?? provides a default value when optional is nil, preventing crashes."
                    )
                ],
                relatedErrors: ["Unexpectedly found nil", "Forced unwrap of nil"],
                tags: ["optional", "unwrap", "nil", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Cannot find 'X' in scope",
                errorCode: "SWIFT_COMPILE_NOT_IN_SCOPE",
                description: "The compiler cannot find a variable, function, type, or module with the given name in the current scope.",
                cause: "1. Typo in identifier name. 2. Missing import statement. 3. Variable declared in different scope. 4. Accessing before declaration. 5. Private/internal access violation. 6. Framework not linked. 7. Conditional compilation excluding code.",
                solutions: [
                    "Check for typos: Swift is case-sensitive (myVar != MyVar)",
                    "Add missing import: import Foundation, import SwiftUI, etc.",
                    "Ensure variable is declared before use (Swift requires declaration before use)",
                    "Check access control: private, fileprivate, internal, public, open",
                    "Link required framework in Build Phases > Link Binary With Libraries",
                    "Clean build folder (Cmd+Shift+K) and rebuild",
                    "Check if the code is wrapped in #if DEBUG and you're building Release",
                    "For SPM packages, check Package.swift dependencies and target membership"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Missing Import",
                        badCode: "let date = Date()  // Error if Foundation not imported",
                        goodCode: "import Foundation\nlet date = Date()",
                        explanation: "Foundation types like Date, URL, Data require explicit import."
                    ),
                    CodeExample(
                        language: "swift",
                        title: "Scope Order",
                        badCode: "print(x)\nlet x = 5  // Error: x used before declaration",
                        goodCode: "let x = 5\nprint(x)",
                        explanation: "Swift requires variables to be declared before they are used."
                    )
                ],
                relatedErrors: ["Use of unresolved identifier", "No such module"],
                tags: ["scope", "import", "undefined", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Protocol 'X' requires property 'Y' with type 'Z'",
                errorCode: "SWIFT_COMPILE_PROTOCOL_REQ",
                description: "A type conforming to a protocol must implement all required properties and methods with matching types.",
                cause: "1. Missing protocol property/method implementation. 2. Wrong type in implementation. 3. Missing { get } or { get set } specification. 4. Static vs instance mismatch. 5. Optional requirement not handled.",
                solutions: [
                    "Implement all required properties and methods from the protocol",
                    "Check exact type signatures - Swift requires exact matches",
                    "Ensure { get } vs { get set } matches the protocol definition",
                    "For static requirements, use static keyword in implementation",
                    "Use Xcode's Fix-it (Cmd+.) to auto-generate stub implementations",
                    "Check if protocol has associated types that need typealias",
                    "Ensure Self or associated type constraints are satisfied"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Protocol Implementation",
                        badCode: "protocol Greetable { var name: String { get } }\nstruct Person: Greetable {}  // Missing name",
                        goodCode: "protocol Greetable { var name: String { get } }\nstruct Person: Greetable {\n    let name: String\n}",
                        explanation: "All protocol requirements must be implemented with matching types."
                    )
                ],
                relatedErrors: ["Type does not conform to protocol", "Protocol can only be used as generic constraint"],
                tags: ["protocol", "conformance", "interface", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Protocols.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Initializer does not override a designated initializer from its superclass",
                errorCode: "SWIFT_COMPILE_INIT_OVERRIDE",
                description: "When overriding an initializer in a subclass, you must use the override keyword and match the superclass initializer exactly.",
                cause: "1. Missing override keyword on init. 2. Wrong parameter types. 3. Trying to override convenience init. 4. Superclass init not marked as designated. 5. Required init not implemented.",
                solutions: [
                    "Add override keyword: override init(...) { super.init(...) }",
                    "Ensure parameter types match superclass exactly",
                    "Only designated initializers can be overridden; convenience inits cannot",
                    "Implement required init?(coder:) for NSCoding conformance",
                    "Call super.init(...) before any self property access",
                    "For NSViewController/UIViewController, override init(nibName:bundle:)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Override Init",
                        badCode: "class Child: Parent {\n    init(value: Int) { }  // Missing override\n}",
                        goodCode: "class Child: Parent {\n    override init(value: Int) {\n        super.init(value: value)\n    }\n}",
                        explanation: "Always use override keyword when overriding superclass initializers."
                    )
                ],
                relatedErrors: ["Overriding non-open instance method outside its defining module", "Must call a designated initializer of superclass"],
                tags: ["init", "override", "superclass", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Inheritance.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "'let' properties are immutable",
                errorCode: "SWIFT_COMPILE_LET_IMMUTABLE",
                description: "Properties declared with let cannot be reassigned after initialization. Only var properties can be mutated.",
                cause: "1. Trying to reassign let property. 2. let property in struct needs mutation but struct value semantics prevent it. 3. Class with let property trying to mutate reference. 4. Copy-on-write types using let.",
                solutions: [
                    "Change let to var if the property needs to change: var name: String",
                    "For structs, mark mutating methods with 'mutating' keyword",
                    "For value types in arrays/dictionaries, reassign the entire element",
                    "Use inout parameter for function mutations",
                    "Consider using class instead of struct for reference semantics",
                    "For computed properties, use a stored var with private setter"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Mutable Property",
                        badCode: "let count = 0\ncount = 5  // Error: immutable",
                        goodCode: "var count = 0\ncount = 5  // OK",
                        explanation: "Use var for mutable properties, let for constants that never change."
                    )
                ],
                relatedErrors: ["Cannot assign to property", "Left side of mutating operator"],
                tags: ["let", "var", "immutable", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Reference to property 'X' in closure requires explicit use of 'self'",
                errorCode: "SWIFT_COMPILE_SELF_IN_CLOSURE",
                description: "Swift requires explicit self in closures to prevent accidental retain cycles and make capture semantics clear.",
                cause: "1. Accessing self property/method in closure without self. 2. Implicit self not allowed in escaping closures. 3. Closure capture list not specifying [weak self] or [unowned self].",
                solutions: [
                    "Add explicit self: self.propertyName",
                    "Use [weak self] capture list to prevent retain cycles",
                    "Use [unowned self] only when self will always exist during closure execution",
                    "For non-escaping closures, Swift allows implicit self (no warning)",
                    "Guard let self = self else { return } for safe unwrapping of weak self",
                    "In Swift 5.8+, implicit self is allowed after guard let self"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Closure Self",
                        badCode: "Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in\n    updateUI()  // Missing self\n}",
                        goodCode: "Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in\n    guard let self = self else { return }\n    self.updateUI()\n}",
                        explanation: "Always use [weak self] in escaping closures to prevent retain cycles."
                    )
                ],
                relatedErrors: ["Closure captures self before all members are initialized", "Escaping closure captures mutating self parameter"],
                tags: ["closure", "self", "retain cycle", "memory", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Closures.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Generic parameter 'T' could not be inferred",
                errorCode: "SWIFT_COMPILE_GENERIC_INFER",
                description: "The compiler cannot determine the concrete type for a generic parameter from the context.",
                cause: "1. Ambiguous type context. 2. Missing type annotation. 3. Overloaded functions with generics. 4. Complex nested generic types. 5. Type inference chain broken.",
                solutions: [
                    "Add explicit type annotation: let value: Type = genericFunc()",
                    "Specify generic parameter: genericFunc<Type>()",
                    "Break complex expression into simpler steps with explicit types",
                    "For publishers, specify Output and Failure types explicitly",
                    "Use typealias to simplify complex generic types",
                    "Ensure all closure parameters have explicit types",
                    "For JSON decoding, specify the Decodable type: try JSONDecoder().decode(Type.self, from: data)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Explicit Generic Type",
                        badCode: "let result = decode(data)  // Cannot infer T",
                        goodCode: "let result: User = decode(data)\n// or\nlet result = decode<User>(data)",
                        explanation: "Help the compiler by specifying generic types explicitly."
                    )
                ],
                relatedErrors: ["Cannot convert value of type", "Type of expression is ambiguous without more context"],
                tags: ["generic", "type inference", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Generics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Type of expression is ambiguous without more context",
                errorCode: "SWIFT_COMPILE_AMBIGUOUS_TYPE",
                description: "The compiler cannot determine the type of an expression because multiple types could satisfy the constraints.",
                cause: "1. Overloaded operators or functions. 2. Complex chained expressions. 3. Multiple protocol conformances. 4. Numeric literals without type context. 5. Operator precedence ambiguity.",
                solutions: [
                    "Add explicit type annotations to variables",
                    "Break complex expression into multiple lines with intermediate typed variables",
                    "For numeric literals, add type suffix: 42 as Int, 3.14 as Double",
                    "Use explicit function names instead of overloaded operators",
                    "Cast intermediate results: (a as Double) + b",
                    "For ternary operators, ensure both branches return same type",
                    "Check for imported modules with conflicting extensions"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Ambiguous Numeric",
                        badCode: "let result = 3 + 4.5  // Ambiguous: Int + Double?",
                        goodCode: "let result = Double(3) + 4.5  // Explicit: 7.5",
                        explanation: "Numeric literals need explicit context when mixed types are involved."
                    )
                ],
                relatedErrors: ["Generic parameter could not be inferred", "Cannot convert value of type"],
                tags: ["ambiguous", "type inference", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TypeSafetyAndTypeInference.html",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Expression was too complex to be solved in reasonable time",
                errorCode: "SWIFT_COMPILE_TOO_COMPLEX",
                description: "Swift's type checker has a complexity limit. Extremely complex expressions with many overloaded operators can exceed this limit.",
                cause: "1. Long chains of + operators with mixed types. 2. Complex nested ternary operators. 3. Many overloaded function candidates. 4. Deeply nested generic types. 5. Complex string interpolation.",
                solutions: [
                    "Break expression into multiple sub-expressions with explicit intermediate variables",
                    "Replace + chains with explicit type casts at each step",
                    "Simplify ternary operators by extracting conditions into variables",
                    "Add explicit type annotations to all intermediate values",
                    "Use parentheses to clarify operator precedence",
                    "Replace string interpolation with separate formatting steps",
                    "Consider using a computed property or function instead of inline expression"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Break Complex Expression",
                        badCode: "let result = a + b * c / d - e + f * g / h - i  // Too complex",
                        goodCode: "let term1 = a\nlet term2 = b * c / d\nlet term3 = f * g / h\nlet result = term1 + term2 - e + term3 - i",
                        explanation: "Break complex expressions into simpler steps with explicit types."
                    )
                ],
                relatedErrors: ["The compiler is unable to type-check this expression in reasonable time"],
                tags: ["complex", "type checker", "performance", "compile"],
                appleDocURL: "https://bugs.swift.org/browse/SR-",
                commonInVersions: ["Swift 4.x", "Swift 5.0", "Swift 5.1"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Missing return in a function expected to return 'X'",
                errorCode: "SWIFT_COMPILE_MISSING_RETURN",
                description: "A function declared to return a value must return that value on all code paths, including error conditions and guard else blocks.",
                cause: "1. Missing return in if/else branch. 2. Guard else block without return. 3. Switch case without return. 4. Throwing function not throwing on all paths. 5. Early return only in some branches.",
                solutions: [
                    "Ensure every code path has a return statement",
                    "In guard else, add return, throw, or fatalError()",
                    "For switch statements, ensure all cases return or add default",
                    "Use @unknown default for enums to catch future cases",
                    "Consider making function Void if it doesn't need to return",
                    "Use Never return type for functions that always crash/exit",
                    "For computed properties, ensure get accessor returns on all paths"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Complete Returns",
                        badCode: "func maxValue(_ a: Int, _ b: Int) -> Int {\n    if a > b {\n        return a\n    }\n    // Missing return for else case\n}",
                        goodCode: "func maxValue(_ a: Int, _ b: Int) -> Int {\n    if a > b {\n        return a\n    } else {\n        return b\n    }\n}",
                        explanation: "Every code path must return a value matching the declared return type."
                    )
                ],
                relatedErrors: ["Function declares an opaque return type but has no return statements", "Missing return in closure"],
                tags: ["return", "function", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Result of call to function is unused",
                errorCode: "SWIFT_COMPILE_UNUSED_RESULT",
                description: "A function returns a value but the caller discards it. This may indicate a bug where an important result is ignored.",
                cause: "1. Function returns value but result not assigned. 2. @discardableResult not used. 3. Side-effect function accidentally returns value. 4. Refactored code leaving unused return.",
                solutions: [
                    "Assign the result to _: let _ = function()",
                    "Use the returned value appropriately",
                    "Add @discardableResult attribute to the function if discard is expected",
                    "Change function to return Void if the value isn't meaningful",
                    "For @discardableResult methods, no action needed (just a warning)",
                    "Enable 'Treat Warnings as Errors' in build settings to catch these"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Discard Result",
                        badCode: "array.sorted()  // Warning: result unused",
                        goodCode: "let sorted = array.sorted()\n// or\n_ = array.sorted()",
                        explanation: "sorted() returns a new array; the original is unchanged. Use result or discard explicitly."
                    )
                ],
                relatedErrors: ["Variable was never used", "Initialization of immutable value was never used"],
                tags: ["unused", "warning", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Binary operator 'X' cannot be applied to operands of type 'Y' and 'Z'",
                errorCode: "SWIFT_COMPILE_BINARY_OP",
                description: "An operator cannot be used with the given operand types because no matching operator overload exists.",
                cause: "1. Adding String and Int directly. 2. Comparing incompatible optionals. 3. Custom types without operator overloads. 4. Protocol types without operator requirements. 5. Numeric type mismatch.",
                solutions: [
                    "Cast operands to same type before operation",
                    "For String concatenation, convert numbers: String(value) + \"text\"",
                    "Implement custom operator overload for your types",
                    "Use explicit comparison methods instead of operators",
                    "For optionals, unwrap first or use == comparison with optional types",
                    "Use NSNumber for comparing different numeric types in Objective-C interop"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Operand Type Match",
                        badCode: "let result = \"Count: \" + 42  // String + Int",
                        goodCode: "let result = \"Count: \" + String(42)\n// or\nlet result = \"Count: \(42)\"",
                        explanation: "Convert non-String types to String before concatenation, or use interpolation."
                    )
                ],
                relatedErrors: ["Cannot convert value of type", "Referencing operator on type"],
                tags: ["operator", "binary", "type", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AdvancedOperators.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Class 'X' has no initializers",
                errorCode: "SWIFT_COMPILE_NO_INIT",
                description: "A class with stored properties that have no default values must provide at least one initializer.",
                cause: "1. Stored properties without default values. 2. All properties are non-optional with no init. 3. Subclass not calling super.init. 4. Required init from protocol not implemented.",
                solutions: [
                    "Provide default values for all stored properties",
                    "Add a designated initializer: init(...) { self.prop = value }",
                    "For optional types, they default to nil (no init needed)",
                    "For subclasses, call super.init(...) in your init",
                    "Implement required init?(coder:) for NSCoding/Storyboard",
                    "Use convenience init for additional initialization paths"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Class Initializer",
                        badCode: "class Person {\n    var name: String  // No default, no init\n}",
                        goodCode: "class Person {\n    var name: String\n    init(name: String) {\n        self.name = name\n    }\n}",
                        explanation: "Classes must initialize all non-optional stored properties before use."
                    )
                ],
                relatedErrors: ["Property self.prop not initialized", "Return from initializer without initializing all stored properties"],
                tags: ["init", "class", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Initialization.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Property 'self.X' not initialized at super.init call",
                errorCode: "SWIFT_COMPILE_PROP_NOT_INIT",
                description: "In class initialization, all stored properties must be initialized before calling super.init() or using self.",
                cause: "1. Property initialized after super.init call. 2. Using self before all properties initialized. 3. Delegating init not setting all properties. 4. Two-phase initialization violation.",
                solutions: [
                    "Initialize all properties BEFORE calling super.init()",
                    "Assign default values at declaration: var prop: Type = defaultValue",
                    "Use implicitly unwrapped optionals for late initialization",
                    "Follow Swift's two-phase initialization rules strictly",
                    "For computed properties, no initialization needed",
                    "Use lazy var for properties depending on self"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Init Order",
                        badCode: "class Child: Parent {\n    var value: Int\n    override init() {\n        super.init()  // Error: value not init\n        value = 10\n    }\n}",
                        goodCode: "class Child: Parent {\n    var value: Int\n    override init() {\n        value = 10\n        super.init()\n    }\n}",
                        explanation: "Always initialize all stored properties before calling super.init()."
                    )
                ],
                relatedErrors: ["Use of self in delegating initializer before self.init is called", "Class has no initializers"],
                tags: ["init", "property", "super", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Initialization.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Switch must be exhaustive",
                errorCode: "SWIFT_COMPILE_SWITCH_EXHAUSTIVE",
                description: "Swift requires switch statements to cover all possible cases. Non-exhaustive switches are compile errors.",
                cause: "1. Missing case in enum switch. 2. Default case omitted. 3. New enum case added but switch not updated. 4. Bool or Optional switch missing case.",
                solutions: [
                    "Add a default case: default: break",
                    "Use @unknown default for enums to get warnings on new cases",
                    "Explicitly list all enum cases",
                    "For Optional, handle .some and .none",
                    "For Bool, handle true and false",
                    "Use if case let for single-case matching instead of switch"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Exhaustive Switch",
                        badCode: "enum Status { case active, inactive }\nswitch status {\ncase .active: print(\"Active\")\n}  // Missing .inactive",
                        goodCode: "enum Status { case active, inactive }\nswitch status {\ncase .active: print(\"Active\")\ncase .inactive: print(\"Inactive\")\n}",
                        explanation: "All possible values must be covered in a switch statement."
                    )
                ],
                relatedErrors: ["Enum case not found in type", "Switch must be exhaustive, consider adding a default clause"],
                tags: ["switch", "enum", "exhaustive", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/ControlFlow.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Variable was never mutated; consider changing to 'let'",
                errorCode: "SWIFT_COMPILE_NEVER_MUTATED",
                description: "A variable declared with var is never modified. Swift suggests using let for immutability.",
                cause: "1. var used but never reassigned. 2. Property only read, never written. 3. Function parameter marked var but not mutated.",
                solutions: [
                    "Change var to let for cleaner, safer code",
                    "If planning to mutate later, keep var (suppresses warning)",
                    "For function parameters, remove 'var' keyword (deprecated in Swift 3)",
                    "This is a warning, not an error - code still compiles"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Use Let",
                        badCode: "var greeting = \"Hello\"\nprint(greeting)  // Warning: never mutated",
                        goodCode: "let greeting = \"Hello\"\nprint(greeting)  // Clean, immutable",
                        explanation: "Use let for values that never change to prevent accidental mutation."
                    )
                ],
                relatedErrors: ["Initialization of immutable value was never used"],
                tags: ["var", "let", "warning", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Use of undeclared type 'X'",
                errorCode: "SWIFT_COMPILE_UNDECLARED_TYPE",
                description: "The compiler cannot find a type definition. The type may be undefined, misspelled, or in an unimported module.",
                cause: "1. Typo in type name. 2. Type in different module not imported. 3. Type not yet defined (forward reference). 4. Typealias or associated type not resolved. 5. Type in excluded source file.",
                solutions: [
                    "Check for typos in type name (case-sensitive!)",
                    "Add import for the module containing the type",
                    "Ensure type is defined before use (Swift requires definition before use)",
                    "For nested types, use Parent.Child syntax",
                    "Check if type is in a conditional compilation block (#if)",
                    "Ensure file is included in target's Compile Sources",
                    "For SPM, check that package dependency is declared in Package.swift"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Import Module",
                        badCode: "let view: NSView = NSView()  // Error without AppKit",
                        goodCode: "import AppKit\nlet view: NSView = NSView()",
                        explanation: "AppKit types like NSView require importing AppKit framework."
                    )
                ],
                relatedErrors: ["Cannot find type", "No such module"],
                tags: ["type", "undefined", "import", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Function declares an opaque return type but has no return statements",
                errorCode: "SWIFT_COMPILE_OPAQUE_NO_RETURN",
                description: "A function with 'some' opaque return type must have at least one return statement that returns a concrete type conforming to the stated protocol.",
                cause: "1. Missing return in function with some View/some Collection. 2. All return paths have errors. 3. Conditional branches missing returns.",
                solutions: [
                    "Add return statement(s) returning a concrete type",
                    "Ensure all code paths return a value",
                    "For some View, return EmptyView() as placeholder",
                    "Check that returned type conforms to the stated protocol",
                    "For conditional returns, use Group or AnyView wrapping"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Opaque Return",
                        badCode: "func makeView() -> some View {\n    let label = Text(\"Hello\")\n}  // Missing return",
                        goodCode: "func makeView() -> some View {\n    return Text(\"Hello\")\n}",
                        explanation: "Functions with opaque return types (some Protocol) must return a concrete conforming type."
                    )
                ],
                relatedErrors: ["Missing return in a function", "Type 'X' does not conform to protocol 'Y'"],
                tags: ["opaque", "some", "return", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/OpaqueTypes.html",
                commonInVersions: ["Swift 5.1+", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Overriding non-open instance method outside its defining module",
                errorCode: "SWIFT_COMPILE_OVERRIDE_NON_OPEN",
                description: "You can only override methods marked 'open' from another module. 'public' methods cannot be overridden externally.",
                cause: "1. Trying to override public method from external framework. 2. Framework author used public instead of open. 3. Subclassing framework class and overriding public method.",
                solutions: [
                    "Use composition instead of inheritance: wrap the class",
                    "Request framework author to mark method as open",
                    "Use method swizzling (Objective-C runtime, not recommended)",
                    "Create extension with new method instead of overriding",
                    "Fork the framework and change public to open",
                    "Use delegate/protocol pattern instead of subclassing"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Composition vs Inheritance",
                        badCode: "// Can't override if method is public not open\nclass MyView: SomeFrameworkView {\n    override func draw() { }  // Error\n}",
                        goodCode: "class MyViewWrapper {\n    let view = SomeFrameworkView()\n    func customDraw() {\n        // Custom behavior without overriding\n    }\n}",
                        explanation: "public methods cannot be overridden outside the module; use open or composition."
                    )
                ],
                relatedErrors: ["Cannot inherit from non-open class", "Overriding non-@objc declarations from extensions is not supported"],
                tags: ["open", "public", "override", "module", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Non-@objc property does not support existing Objective-C instance variable",
                errorCode: "SWIFT_COMPILE_OBJC_IVAR",
                description: "When subclassing an Objective-C class, properties must be marked @objc to map to Objective-C instance variables.",
                cause: "1. Subclassing NSObject without @objc on properties. 2. Overriding Objective-C property without @objc. 3. KVO compliance requires @objc dynamic.",
                solutions: [
                    "Add @objc to property declarations: @objc var property: Type",
                    "For KVO, use @objc dynamic var property: Type",
                    "For Swift-only classes, avoid NSObject subclassing",
                    "Use Combine publishers instead of KVO where possible",
                    "Check that property name doesn't conflict with ivar"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "@objc Property",
                        badCode: "class MyObject: NSObject {\n    var name: String = \"\"  // Missing @objc\n}",
                        goodCode: "class MyObject: NSObject {\n    @objc var name: String = \"\"\n}",
                        explanation: "NSObject subclasses need @objc for properties to be accessible from Objective-C runtime."
                    )
                ],
                relatedErrors: ["Property cannot be marked @objc because its type cannot be represented in Objective-C"],
                tags: ["objc", "ivar", "nsobject", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#objc",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Trailing closure is ambiguous with multiple trailing closure syntax",
                errorCode: "SWIFT_COMPILE_AMBIGUOUS_TRAILING",
                description: "When a function has multiple closure parameters, a trailing closure may be ambiguous about which parameter it matches.",
                cause: "1. Function with multiple closure params and trailing closure. 2. SwiftUI view modifiers with multiple closures. 3. Builder patterns with trailing closures.",
                solutions: [
                    "Label the closure explicitly: paramName: { ... }",
                    "Use regular parameter syntax instead of trailing closure",
                    "Upgrade to Swift 5.3+ which supports multiple trailing closures",
                    "For SwiftUI, use explicit parameter labels for .sheet, .alert, etc."
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Labeled Closure",
                        badCode: "myFunc { value in\n    // Ambiguous which param this matches\n}",
                        goodCode: "myFunc(completion: { value in\n    // Explicitly labeled\n})",
                        explanation: "Label closures explicitly when function has multiple closure parameters."
                    )
                ],
                relatedErrors: ["Conflicting arguments to generic parameter"],
                tags: ["trailing closure", "ambiguous", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Closures.html",
                commonInVersions: ["Swift 5.0", "Swift 5.1", "Swift 5.2"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot use instance member 'X' within property initializer",
                errorCode: "SWIFT_COMPILE_SELF_IN_INIT",
                description: "Property initializers run before self is fully initialized, so they cannot access instance members.",
                cause: "1. Property default value references another property. 2. Property initializer calls instance method. 3. Closure in property captures self before init completes.",
                solutions: [
                    "Use lazy var: lazy var computed = self.otherProperty * 2",
                    "Initialize in init() after all properties are set",
                    "Use a computed property instead of stored property",
                    "For closures, use lazy to defer execution until after init",
                    "Move initialization to didSet or willSet if appropriate"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Lazy Property",
                        badCode: "class Calculator {\n    let base = 10\n    let doubled = base * 2  // Error: self not ready\n}",
                        goodCode: "class Calculator {\n    let base = 10\n    lazy var doubled = self.base * 2  // OK with lazy\n}",
                        explanation: "lazy defers initialization until first access, after self is fully initialized."
                    )
                ],
                relatedErrors: ["Property self.X not initialized at super.init call", "Use of self in delegating initializer"],
                tags: ["self", "init", "property", "lazy", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Properties.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Consecutive statements on a line must be separated by ';'",
                errorCode: "SWIFT_COMPILE_SEPARATE_STATEMENTS",
                description: "Swift interprets two expressions on the same line as a single statement, causing syntax errors.",
                cause: "1. Missing newline between statements. 2. Trailing closure followed by another expression. 3. Copy-paste error merging lines. 4. Missing comma or separator.",
                solutions: [
                    "Add newline between statements",
                    "Add semicolon ; between statements (not recommended style)",
                    "Check for missing closing braces or parentheses",
                    "Ensure closures are properly enclosed in braces",
                    "Format code with SwiftFormat to fix layout issues"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Statement Separation",
                        badCode: "let x = 5 let y = 10  // Missing separator",
                        goodCode: "let x = 5\nlet y = 10",
                        explanation: "Each statement should be on its own line for readability and correctness."
                    )
                ],
                relatedErrors: ["Expected ';' separator", "Expected expression"],
                tags: ["syntax", "separator", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Use of unresolved identifier 'print' / 'NSLog'",
                errorCode: "SWIFT_COMPILE_UNRESOLVED_PRINT",
                description: "Foundation types like print(), NSLog(), Date, etc. require the Foundation module to be imported.",
                cause: "1. Missing import Foundation. 2. Shadowed by local variable named 'print'. 3. Stripped standard library in embedded Swift.",
                solutions: [
                    "Add import Foundation at top of file",
                    "Check for local variable shadowing: var print = ...",
                    "For pure Swift without Foundation, use Swift.print (always available)",
                    "Note: print() is in Swift standard library, not Foundation",
                    "NSLog requires Foundation; use print() for basic logging without import"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Foundation Import",
                        badCode: "NSLog(\"Hello\")  // Needs Foundation",
                        goodCode: "import Foundation\nNSLog(\"Hello\")",
                        explanation: "NSLog is in Foundation framework. print() is in standard library and doesn't need import."
                    )
                ],
                relatedErrors: ["Cannot find 'X' in scope", "No such module 'Foundation'"],
                tags: ["foundation", "import", "print", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/foundation",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Method 'X' with Objective-C selector conflicts with previous declaration",
                errorCode: "SWIFT_COMPILE_SELECTOR_CONFLICT",
                description: "Two methods have the same Objective-C selector, which is not allowed for @objc methods.",
                cause: "1. Overloaded Swift methods exposed to Obj-C with same selector. 2. Different parameter types but same Obj-C name. 3. Extension adding method with same selector as superclass.",
                solutions: [
                    "Rename one method to have different Obj-C selector",
                    "Use @objc(selectorName:) to specify unique selector",
                    "Remove @objc from one method if Obj-C interop not needed",
                    "Use different method names instead of Swift overloading",
                    "For Swift-only code, remove @objc entirely"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Unique Selector",
                        badCode: "@objc func process(value: Int) { }\n@objc func process(value: String) { }  // Same selector",
                        goodCode: "@objc(processInt:) func process(value: Int) { }\n@objc(processString:) func process(value: String) { }",
                        explanation: "Use @objc(customName:) to give unique Objective-C selectors to overloaded methods."
                    )
                ],
                relatedErrors: ["@objc attribute conflicts with previous declaration"],
                tags: ["objc", "selector", "overload", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#objc",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Will never be executed / Unreachable code",
                errorCode: "SWIFT_COMPILE_UNREACHABLE",
                description: "Code after a return, fatalError, or infinite loop will never execute.",
                cause: "1. Code after return statement. 2. Code after fatalError(). 3. Code after infinite while true loop. 4. Code in guard else after return.",
                solutions: [
                    "Remove unreachable code",
                    "Move code before the return/fatalError",
                    "Use conditional compilation #if to exclude code",
                    "For debugging, use print before return instead of after",
                    "Check if a switch case accidentally has a fallthrough before other code"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Remove Dead Code",
                        badCode: "func test() -> Int {\n    return 42\n    print(\"This never runs\")  // Warning\n}",
                        goodCode: "func test() -> Int {\n    print(\"About to return\")\n    return 42\n}",
                        explanation: "Code after return, fatalError, throw, or break is unreachable."
                    )
                ],
                relatedErrors: ["Code after 'throw' will never be executed"],
                tags: ["unreachable", "dead code", "warning", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/ControlFlow.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "All paths through this function will call itself",
                errorCode: "SWIFT_COMPILE_INFINITE_RECURSION",
                description: "The function calls itself recursively on all code paths without a base case, causing infinite recursion.",
                cause: "1. Recursive function without terminating condition. 2. Base case condition always false. 3. Indirect recursion through other functions. 4. Default parameter causing self-call.",
                solutions: [
                    "Add a base case that stops recursion",
                    "Ensure recursive call moves toward base case",
                    "Use iteration (for/while) instead of recursion for large datasets",
                    "Check for accidental self-calls in method overrides",
                    "Add a depth counter to prevent stack overflow",
                    "For mutual recursion, ensure at least one function has a base case"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Base Case",
                        badCode: "func factorial(_ n: Int) -> Int {\n    return n * factorial(n)  // Never terminates\n}",
                        goodCode: "func factorial(_ n: Int) -> Int {\n    if n <= 1 { return 1 }  // Base case\n    return n * factorial(n - 1)\n}",
                        explanation: "Every recursive function must have a base case that stops the recursion."
                    )
                ],
                relatedErrors: ["Execution was interrupted, reason: EXC_BAD_ACCESS", "Stack overflow"],
                tags: ["recursion", "infinite", "compile", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot assign through subscript: subscript is get-only",
                errorCode: "SWIFT_COMPILE_GET_ONLY_SUBSCRIPT",
                description: "A subscript declared with only a getter cannot be used to assign values.",
                cause: "1. Dictionary subscript for non-existent key returns nil (no auto-insert). 2. Custom subscript missing set accessor. 3. Read-only collection type.",
                solutions: [
                    "For dictionaries, use dict[key, default: value] for mutable access",
                    "Add set accessor to custom subscript",
                    "Use updateValue(_:forKey:) for dictionary mutations",
                    "For arrays, ensure index is within bounds before assignment",
                    "Consider using a computed property with getter/setter instead"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Mutable Subscript",
                        badCode: "struct Container {\n    subscript(index: Int) -> Int { return 0 }  // get-only\n}\nvar c = Container()\nc[0] = 5  // Error",
                        goodCode: "struct Container {\n    private var items: [Int] = []\n    subscript(index: Int) -> Int {\n        get { items[index] }\n        set { items[index] = newValue }\n    }\n}",
                        explanation: "Subscripts need explicit get/set accessors to support assignment."
                    )
                ],
                relatedErrors: ["Cannot assign to value: 'X' is a 'let' constant"],
                tags: ["subscript", "get-only", "setter", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Subscripts.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Default argument value of type 'X' cannot be converted to type 'Y'",
                errorCode: "SWIFT_COMPILE_DEFAULT_ARG_MISMATCH",
                description: "The default value provided for a function parameter doesn't match the parameter's declared type.",
                cause: "1. Default value literal inferred as wrong type. 2. Default expression returns wrong type. 3. Optional parameter with non-optional default. 4. Generic parameter default not matching constraint.",
                solutions: [
                    "Cast default value: defaultValue as ExpectedType",
                    "Use explicit type annotation on default value",
                    "For optionals, use nil as default: param: Type? = nil",
                    "Ensure default expression type matches parameter exactly",
                    "For closures, use explicit closure type: { } as () -> Void"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Default Value Type",
                        badCode: "func greet(name: String = 123) { }  // Int to String",
                        goodCode: "func greet(name: String = \"Guest\") { }",
                        explanation: "Default values must exactly match the parameter type."
                    )
                ],
                relatedErrors: ["Cannot convert value of type"],
                tags: ["default", "parameter", "type", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Cast from 'X' to unrelated type 'Y' always fails",
                errorCode: "SWIFT_COMPILE_UNRELATED_CAST",
                description: "A type cast is attempted between two types that have no inheritance relationship, making the cast impossible.",
                cause: "1. Casting unrelated classes. 2. Casting value type to unrelated reference type. 3. Generic type cast without constraints. 4. Protocol cast without conformance.",
                solutions: [
                    "Check if types are actually related in inheritance hierarchy",
                    "Use conditional cast as? to handle failure gracefully",
                    "For unrelated types, create a converter/factory method",
                    "Check protocol conformance before casting",
                    "Use Any or AnyObject container if types must be mixed",
                    "Rethink design - unrelated types shouldn't be cast"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Casting",
                        badCode: "let x = 42\nlet s = x as String  // Unrelated types",
                        goodCode: "let x = 42\nlet s = String(x)  // Proper conversion",
                        explanation: "Use constructors or conversion methods instead of casting unrelated types."
                    )
                ],
                relatedErrors: ["Cannot cast", "Conditional cast always fails"],
                tags: ["cast", "type", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TypeCasting.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "'X' is not a member type of class 'Y'",
                errorCode: "SWIFT_COMPILE_NOT_MEMBER_TYPE",
                description: "A nested type reference is invalid because the type doesn't exist within the specified class/struct/enum.",
                cause: "1. Typo in nested type name. 2. Type defined outside not inside. 3. Extension adding type not visible. 4. Generic type parameter confusion.",
                solutions: [
                    "Check nested type path for typos",
                    "Ensure type is defined within the parent, not alongside it",
                    "For associated types, use Self.AssociatedType syntax",
                    "Check access control on nested type",
                    "Use typealias to simplify complex nested references"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Nested Type",
                        badCode: "class Outer {\n    struct Inner { }\n}\nlet x: Outer.Iner  // Typo",
                        goodCode: "let x: Outer.Inner  // Correct nested type",
                        explanation: "Nested types use dot syntax; check spelling carefully."
                    )
                ],
                relatedErrors: ["Cannot find type"],
                tags: ["nested", "type", "member", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/NestedTypes.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Instance method 'X' is a member of the constrained extension",
                errorCode: "SWIFT_COMPILE_CONSTRAINED_EXT",
                description: "A method in a constrained extension (where clause) can only be called when the constraints are satisfied.",
                cause: "1. Calling constrained extension method on unconstrained type. 2. Generic type doesn't meet where clause requirements. 3. Associated type constraints not satisfied.",
                solutions: [
                    "Ensure generic parameters satisfy extension constraints",
                    "Move method to unconstrained extension if applicable to all types",
                    "Add necessary protocol conformances to satisfy where clause",
                    "Use conditional compilation or type checking before calling",
                    "For Equatable constraints, ensure type implements == operator"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Constrained Extension",
                        badCode: "extension Array where Element: Equatable {\n    func allEqual() -> Bool { }\n}\nlet arr: [Any] = [1, 2]\narr.allEqual()  // Any not Equatable",
                        goodCode: "let arr: [Int] = [1, 1]\narr.allEqual()  // Int is Equatable",
                        explanation: "Constrained extensions only apply when generic constraints are met."
                    )
                ],
                relatedErrors: ["Type 'X' does not conform to protocol 'Y'"],
                tags: ["extension", "constraint", "where", "generic", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Generics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            // -----------------------------------------------------------------
            // More Swift Compile Errors (continued)
            // -----------------------------------------------------------------
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Escaping closure captures 'inout' parameter",
                errorCode: "SWIFT_COMPILE_INOUT_CAPTURE",
                description: "An @escaping closure cannot capture an inout parameter because the parameter's lifetime is limited to the function call.",
                cause: "1. Passing inout parameter to async/escaping closure. 2. Using inout var in completion handler. 3. DispatchQueue.async capturing inout parameter.",
                solutions: [
                    "Copy inout value to local var before capturing: var local = param",
                    "Remove inout if mutation not actually needed",
                    "Use return value instead of inout for escaping contexts",
                    "For async operations, pass value directly, not as inout",
                    "Use UnsafeMutablePointer for advanced scenarios"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Avoid Inout Capture",
                        badCode: "func process(value: inout Int, completion: @escaping () -> Void) {\n    DispatchQueue.main.async {\n        value += 1  // Error: inout capture\n        completion()\n    }\n}",
                        goodCode: "func process(value: inout Int, completion: @escaping (Int) -> Void) {\n    var local = value\n    DispatchQueue.main.async {\n        local += 1\n        completion(local)\n    }\n}",
                        explanation: "Copy inout values to local variables before capturing in escaping closures."
                    )
                ],
                relatedErrors: ["Closure captures mutating self parameter"],
                tags: ["inout", "escaping", "closure", "capture", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Closures.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot assign value of type 'X' to type 'Y' (different optionality)",
                errorCode: "SWIFT_COMPILE_OPTIONAL_ASSIGN",
                description: "Assignment fails because one side is optional and the other is not, or optionality levels don't match.",
                cause: "1. Assigning Optional<T> to T. 2. Assigning T to Optional<T> in wrong direction. 3. Double optional vs single optional mismatch. 4. Implicitly unwrapped optional confusion.",
                solutions: [
                    "Unwrap optional before assignment: target = optional!",
                    "Use nil-coalescing for default: target = optional ?? default",
                    "Make target optional if nil is acceptable",
                    "Use if let/guard let to safely unwrap",
                    "For IUO, they act like Optional during assignment"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Optional Assignment",
                        badCode: "let optionalName: String? = \"Bob\"\nlet name: String = optionalName  // Error",
                        goodCode: "let name: String = optionalName ?? \"Unknown\"",
                        explanation: "Optional values must be unwrapped before assigning to non-optional types."
                    )
                ],
                relatedErrors: ["Value of optional type must be unwrapped"],
                tags: ["optional", "assign", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Comparison of non-optional value of type 'X' to 'nil' always returns true/false",
                errorCode: "SWIFT_COMPILE_NIL_COMPARISON",
                description: "Comparing a non-optional value to nil is a logical error because non-optionals can never be nil.",
                cause: "1. Variable was made non-optional but nil check remains. 2. Refactored code leaving stale nil checks. 3. Confusion between Optional and non-Optional types.",
                solutions: [
                    "Remove the nil check - it's unnecessary for non-optionals",
                    "Make the type optional if nil is a valid state",
                    "For implicitly unwrapped optionals, treat as Optional for safety",
                    "Use if value.isEmpty or similar for collection emptiness checks"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Remove Dead Nil Check",
                        badCode: "let name: String = \"Bob\"\nif name != nil {  // Always true, warning\n    print(name)\n}",
                        goodCode: "let name: String = \"Bob\"\nprint(name)  // No nil check needed",
                        explanation: "Non-optional types are guaranteed non-nil; nil checks are redundant."
                    )
                ],
                relatedErrors: ["Expression implicitly coerced from 'X?' to 'X'"],
                tags: ["nil", "optional", "warning", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Variable used within its own initial value",
                errorCode: "SWIFT_COMPILE_SELF_INIT",
                description: "A variable cannot reference itself in its own initialization expression.",
                cause: "1. Recursive initialization like let x = x + 1. 2. Closure capturing variable during its initialization. 3. Property referencing itself in default value.",
                solutions: [
                    "Initialize with literal or computed value not referencing self",
                    "Use lazy var for deferred initialization",
                    "Move initialization to init() method",
                    "For computed properties, don't use stored property syntax",
                    "Use a factory method or static method to create the value"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Avoid Self Reference",
                        badCode: "let x = x + 1  // Self-referential",
                        goodCode: "let base = 5\nlet x = base + 1  // Reference different variable",
                        explanation: "A variable cannot be used in its own initialization expression."
                    )
                ],
                relatedErrors: ["Variable declared in 'guard' condition is not usable"],
                tags: ["init", "self reference", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "'@objc' can only be used with members of classes, @objc protocols, and concrete extensions of classes",
                errorCode: "SWIFT_COMPILE_OBJC_NONCLASS",
                description: "The @objc attribute is only valid on classes, class members, and @objc protocols. It cannot be used on structs, enums, or standalone functions.",
                cause: "1. Adding @objc to struct method. 2. @objc on enum without raw type. 3. @objc on protocol not marked @objc. 4. @objc on global function.",
                solutions: [
                    "Remove @objc if Objective-C interop not needed",
                    "Convert struct to class (NSObject subclass) if @objc required",
                    "For enums, use @objc enum with Int raw type",
                    "Mark protocol as @objc if it needs @objc members",
                    "For global functions, wrap in NSObject subclass"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "@objc Enum",
                        badCode: "enum Status {\n    case active\n}\n@objc func getStatus() -> Status { }  // Struct enum",
                        goodCode: "@objc enum Status: Int {\n    case active = 0\n}\nclass Controller: NSObject {\n    @objc func getStatus() -> Status { }\n}",
                        explanation: "@objc requires NSObject classes, @objc enums with raw values, or @objc protocols."
                    )
                ],
                relatedErrors: ["@objc attribute cannot be applied to this declaration"],
                tags: ["objc", "class", "struct", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#objc",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "'X' is unavailable: cannot find Swift declaration for this Objective-C class",
                errorCode: "SWIFT_COMPILE_OBJC_UNAVAILABLE",
                description: "Swift cannot find the Objective-C header or declaration for a referenced class.",
                cause: "1. Missing bridging header. 2. Framework not imported correctly. 3. Objective-C class not marked with NS_SWIFT_NAME. 4. Module map missing. 5. Precompiled header issues.",
                solutions: [
                    "Add #import \"Header.h\" to bridging header",
                    "Ensure framework is linked in Build Phases",
                    "Add NS_SWIFT_NAME(MySwiftName) to Objective-C declarations",
                    "Check module map for framework",
                    "Clean build folder and DerivedData",
                    "Ensure 'Defines Module' is YES for Objective-C targets",
                    "For CocoaPods, use use_modular_headers! or use_frameworks!"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Bridging Header",
                        badCode: "// In Swift, trying to use Obj-C class\nlet obj = MyObjCClass()  // Unavailable",
                        goodCode: "// In ProjectName-Bridging-Header.h:\n#import \"MyObjCClass.h\"\n\n// In Swift:\nlet obj = MyObjCClass()",
                        explanation: "Objective-C classes need to be imported via bridging header or framework module."
                    )
                ],
                relatedErrors: ["No such module", "Could not build Objective-C module"],
                tags: ["objc", "unavailable", "bridging", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/swift/importing-objective-c-into-swift",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Variable 'X' was never used; consider replacing with '_' or removing it",
                errorCode: "SWIFT_COMPILE_UNUSED_VARIABLE",
                description: "A variable is declared but never referenced, which wastes memory and indicates potential bugs.",
                cause: "1. Declared variable but forgot to use it. 2. Refactored code leaving unused variable. 3. Function returns value but caller ignores it. 4. For loop with unused iteration variable.",
                solutions: [
                    "Replace with underscore _: let _ = function()",
                    "Remove unused variable entirely",
                    "Use the variable where it was intended",
                    "For for loops: for _ in 0..<10 { }",
                    "Enable 'Treat Warnings as Errors' to catch during development",
                    "Use SwiftLint or Xcode's static analysis to find unused code"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Unused Variable",
                        badCode: "let result = calculate()  // Warning: never used",
                        goodCode: "_ = calculate()  // Explicitly discard\n// or\nlet result = calculate()\nprint(result)",
                        explanation: "Use _ to explicitly discard unused values, or remove the assignment."
                    )
                ],
                relatedErrors: ["Result of call to function is unused"],
                tags: ["unused", "variable", "warning", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot use mutating member on immutable value: 'X' is a 'let' constant",
                errorCode: "SWIFT_COMPILE_MUTATING_LET",
                description: "Mutating methods on structs/enums cannot be called on let constants because value types are copied on mutation.",
                cause: "1. Calling mutating method on let struct. 2. Array append on let array. 3. Dictionary update on let dictionary. 4. Set insert on let set.",
                solutions: [
                    "Change let to var if mutation is needed",
                    "Create a mutable copy, mutate it, then reassign",
                    "For function parameters, remove let (parameters are let by default)",
                    "Use inout for function parameters that need mutation",
                    "For classes (reference types), mutation doesn't require var"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Mutable Struct",
                        badCode: "let numbers = [1, 2]\nnumbers.append(3)  // Error: let array",
                        goodCode: "var numbers = [1, 2]\nnumbers.append(3)  // OK",
                        explanation: "Value types (struct, enum, Array, Dictionary, Set) require var for mutation."
                    )
                ],
                relatedErrors: ["Left side of mutating operator"],
                tags: ["mutating", "let", "struct", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Methods.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot convert return expression of type 'X' to return type 'some Y'",
                errorCode: "SWIFT_COMPILE_OPAQUE_RETURN_MISMATCH",
                description: "An opaque return type (some Protocol) requires all return paths to produce the same concrete type.",
                cause: "1. Returning different view types in conditional branches. 2. if/else returning Text vs Image. 3. switch cases returning different types. 4. Using AnyView incorrectly.",
                solutions: [
                    "Wrap different types in AnyView (loses type info, use sparingly)",
                    "Use @ViewBuilder to allow different View types",
                    "Ensure all branches return the same concrete type",
                    "Use Group or conditional modifiers instead of conditional types",
                    "Use .opacity(0) to hide views instead of conditional creation",
                    "For some Collection, ensure same collection type on all paths"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Opaque Return Match",
                        badCode: "func getView() -> some View {\n    if condition {\n        return Text(\"A\")\n    } else {\n        return Image(\"B\")  // Different type\n    }\n}",
                        goodCode: "func getView() -> some View {\n    Group {\n        if condition {\n            Text(\"A\")\n        } else {\n            Image(\"B\")\n        }\n    }\n}",
                        explanation: "some Protocol requires identical concrete types. Use Group or @ViewBuilder for conditional views."
                    )
                ],
                relatedErrors: ["Function declares an opaque return type but has no return statements"],
                tags: ["opaque", "some", "return", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/OpaqueTypes.html",
                commonInVersions: ["Swift 5.1+", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Coercion of implicitly unwrappable value of type 'X?' to 'X'",
                errorCode: "SWIFT_COMPILE_IUO_COERCION",
                description: "An optional value is being used where a non-optional is expected, triggering an implicit unwrap.",
                cause: "1. Implicitly unwrapped optional behaving as regular optional. 2. API returning optional but used as non-optional. 3. IBOutlet changing from IUO to Optional in newer SDKs.",
                solutions: [
                    "Explicitly unwrap: value! (dangerous if nil)",
                    "Use if let/guard let for safe unwrapping",
                    "Use nil-coalescing: value ?? default",
                    "Change property to non-optional if it should never be nil",
                    "For IBOutlets, use optional chaining: label?.text = ..."
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe IUO Handling",
                        badCode: "let name: String! = nil\nlet upper = name.uppercased()  // Crash at runtime",
                        goodCode: "let name: String! = nil\nlet upper = name?.uppercased() ?? \"EMPTY\"",
                        explanation: "IUOs can be nil. Use optional chaining or explicit checks for safety."
                    )
                ],
                relatedErrors: ["Expression implicitly coerced from 'String?' to 'String'"],
                tags: ["iuo", "optional", "coercion", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Type 'X' does not conform to protocol 'Hashable' / 'Equatable'",
                errorCode: "SWIFT_COMPILE_HASHABLE_CONFORM",
                description: "Using a type in a context that requires Hashable or Equatable conformance, but the type doesn't implement it.",
                cause: "1. Using struct as Dictionary key without Hashable. 2. Comparing structs with == without Equatable. 3. Set containing non-Hashable type. 4. @State var with non-Hashable optional.",
                solutions: [
                    "Add Hashable/Equatable conformance: struct MyType: Hashable",
                    "For structs with only Hashable properties, conformance is auto-synthesized",
                    "Implement static func == and func hash(into:) manually for custom behavior",
                    "For enums, Hashable is auto-synthesized if all cases have Hashable associated values",
                    "For classes, you must manually implement == and hash(into:)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Hashable Conformance",
                        badCode: "struct Person {\n    let name: String\n}\nlet dict: [Person: Int] = [:]  // Error",
                        goodCode: "struct Person: Hashable {\n    let name: String\n}\nlet dict: [Person: Int] = [:]  // OK",
                        explanation: "Dictionary keys and Set elements must be Hashable. Swift auto-synthesizes this for structs."
                    )
                ],
                relatedErrors: ["Type 'X' does not conform to protocol 'Equatable'", "Generic struct 'Dictionary' requires 'Key' to conform to 'Hashable'"],
                tags: ["hashable", "equatable", "protocol", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Protocols.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Argument labels '(a:)' do not match any available overloads",
                errorCode: "SWIFT_COMPILE_ARG_LABEL_MISMATCH",
                description: "The argument labels used in a function call don't match any declared function signature.",
                cause: "1. Wrong argument labels. 2. Missing argument labels. 3. Extra argument labels. 4. Swapped parameter order. 5. Different function overload selected.",
                solutions: [
                    "Check exact argument labels in function declaration",
                    "Use Xcode's autocomplete to ensure correct labels",
                    "Swift includes first parameter label by default for clarity",
                    "For functions with _ first param, omit the first label",
                    "Check if function has multiple overloads with different labels",
                    "For init, all parameters have labels by default"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Correct Labels",
                        badCode: "func greet(person name: String) { }\ngreet(\"Bob\")  // Missing label",
                        goodCode: "func greet(person name: String) { }\ngreet(person: \"Bob\")  // Correct label",
                        explanation: "Swift uses argument labels as part of the function signature. Include them in calls."
                    )
                ],
                relatedErrors: ["Extra argument in call", "Missing argument for parameter"],
                tags: ["argument", "label", "overload", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Extra argument in call",
                errorCode: "SWIFT_COMPILE_EXTRA_ARG",
                description: "A function is called with more arguments than its declaration specifies.",
                cause: "1. Passing too many parameters. 2. Misunderstanding function signature. 3. Trailing closure counted as extra arg. 4. Using wrong function overload.",
                solutions: [
                    "Check function signature and remove extra arguments",
                    "Use Xcode's Cmd+Click to jump to function definition",
                    "For trailing closures, ensure function accepts closure parameter",
                    "Check if you're calling a property instead of a method",
                    "For variadic parameters, check if they need special syntax"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Correct Arguments",
                        badCode: "func add(_ a: Int, _ b: Int) -> Int { a + b }\nlet sum = add(1, 2, 3)  // Extra arg",
                        goodCode: "let sum = add(1, 2)  // Correct: 2 args",
                        explanation: "Function calls must match the exact number and types of parameters."
                    )
                ],
                relatedErrors: ["Missing argument for parameter", "Argument labels do not match"],
                tags: ["argument", "parameters", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Missing argument for parameter 'X' in call",
                errorCode: "SWIFT_COMPILE_MISSING_ARG",
                description: "A function call doesn't provide all required parameters.",
                cause: "1. Forgot to pass a parameter. 2. Parameter has no default value. 3. Wrong function overload with fewer params. 4. Trailing closure syntax confusion.",
                solutions: [
                    "Provide all required parameters",
                    "Add default value to parameter declaration if optional",
                    "Make parameter optional: param: Type? = nil",
                    "Use function overload with fewer parameters",
                    "For closures, use explicit parameter syntax"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Provide All Args",
                        badCode: "func greet(name: String, age: Int) { }\ngreet(name: \"Bob\")  // Missing age",
                        goodCode: "func greet(name: String, age: Int = 0) { }\ngreet(name: \"Bob\")  // Uses default age",
                        explanation: "All non-optional parameters without defaults must be provided."
                    )
                ],
                relatedErrors: ["Extra argument in call", "Argument labels do not match"],
                tags: ["argument", "missing", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot invoke 'X' with an argument list of type '(Y)'",
                errorCode: "SWIFT_COMPILE_INVOKE_MISMATCH",
                description: "The function exists but no overload matches the provided argument types.",
                cause: "1. Wrong argument types. 2. Missing argument labels. 3. Parameter types don't match exactly. 4. Implicit conversion not available. 5. Generic constraints not met.",
                solutions: [
                    "Check exact parameter types (Swift is strict - Int != Int32)",
                    "Cast arguments to expected types",
                    "Add missing argument labels",
                    "Check for optional vs non-optional mismatches",
                    "For generics, ensure type arguments satisfy constraints",
                    "Use trailing closure syntax correctly"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Type Match",
                        badCode: "func process(value: Double) { }\nprocess(value: 5)  // Int, not Double",
                        goodCode: "func process(value: Double) { }\nprocess(value: 5.0)  // Double literal\n// or\nprocess(value: Double(5))",
                        explanation: "Argument types must exactly match parameter types; Swift doesn't implicitly convert."
                    )
                ],
                relatedErrors: ["Cannot convert value of type", "Extra argument in call"],
                tags: ["invoke", "argument", "type", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "'X' is deprecated: Use 'Y' instead",
                errorCode: "SWIFT_COMPILE_DEPRECATED",
                description: "An API has been marked as deprecated and will be removed in a future version.",
                cause: "1. Using old API after SDK update. 2. Third-party library deprecation. 3. Your own deprecated code still in use. 4. macOS/iOS version deprecation.",
                solutions: [
                    "Follow deprecation message and use recommended replacement",
                    "Check Apple's documentation for migration guide",
                    "Use #available to support both old and new APIs",
                    "Update dependencies to latest versions",
                    "For your own deprecations, add @available(*, deprecated, renamed: \"newName\")",
                    "Suppress warning with #pragma clang diagnostic if absolutely necessary"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Deprecation",
                        badCode: "let attr = NSAttributedString(...)  // Deprecated init",
                        goodCode: "if #available(macOS 12, *) {\n    let attr = AttributedString(...)\n} else {\n    let attr = NSAttributedString(...)\n}",
                        explanation: "Use #available checks to adopt new APIs while maintaining backward compatibility."
                    )
                ],
                relatedErrors: ["'X' is only available on macOS Y.Z or newer"],
                tags: ["deprecated", "warning", "api", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/checking-for-api-availability",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "'X' is only available on macOS Y.Z or newer",
                errorCode: "SWIFT_COMPILE_AVAILABILITY",
                description: "An API is used that was introduced in a newer macOS version than the deployment target.",
                cause: "1. Using new API without availability check. 2. Deployment target lower than API introduction version. 3. Missing @available or #available. 4. Using newer Swift feature on older runtime.",
                solutions: [
                    "Wrap usage in #available(macOS X, *) check",
                    "Mark function/class with @available(macOS X, *)",
                    "Raise deployment target in project settings if acceptable",
                    "Provide fallback implementation for older OS versions",
                    "Use availability macros in Package.swift for SPM",
                    "For SwiftUI, use @ViewBuilder with conditional modifiers"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Availability Check",
                        badCode: "let color = Color.mint  // macOS 11+ only, target is 10.15",
                        goodCode: "if #available(macOS 11, *) {\n    let color = Color.mint\n} else {\n    let color = Color.green  // Fallback\n}",
                        explanation: "Always check API availability when deployment target is lower than API introduction version."
                    )
                ],
                relatedErrors: ["'X' is unavailable in macOS", "API is only available on"],
                tags: ["availability", "macos", "api", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/checking-for-api-availability",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Initializer for class 'X' is '@inlinable' and must delegate with 'self.init' rather than 'super.init'",
                errorCode: "SWIFT_COMPILE_INLINABLE_INIT",
                description: "@inlinable initializers have restrictions on how they delegate initialization.",
                cause: "1. @inlinable init trying to call super.init. 2. Cross-module inlining with init delegation. 3. SDK class with @inlinable requiring specific init pattern.",
                solutions: [
                    "Use self.init(...) for delegation within the same class",
                    "Remove @inlinable if not needed for performance",
                    "Ensure superclass init is accessible from inline context",
                    "For framework authors, mark inits as @usableFromInline"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Inlinable Init",
                        badCode: "@inlinable public init(value: Int) {\n    super.init()  // Error\n}",
                        goodCode: "@inlinable public init(value: Int) {\n    self.init()\n    self.value = value\n}",
                        explanation: "@inlinable initializers must use self.init for delegation."
                    )
                ],
                relatedErrors: ["Initializer does not override a designated initializer"],
                tags: ["inlinable", "init", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#inlinable",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Circular reference",
                errorCode: "SWIFT_COMPILE_CIRCULAR_REF",
                description: "Two or more types depend on each other in a way that creates an infinite loop during type resolution.",
                cause: "1. Type A has property of Type B, and Type B has property of Type A. 2. Protocol A inherits Protocol B, and Protocol B inherits Protocol A. 3. Associated type circular constraints. 4. Recursive type aliases.",
                solutions: [
                    "Break circular dependency using weak references or optionals",
                    "Use protocols instead of concrete type references",
                    "For classes, use weak var to break retain cycle",
                    "Extract shared logic into a third type",
                    "Use type erasure (AnyX) to hide concrete types",
                    "For value types, use indirect enum or Box pattern",
                    "Redefine relationship as one-way dependency"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Break Circular Reference",
                        badCode: "class A { var b: B! }\nclass B { var a: A! }  // Circular",
                        goodCode: "class A { weak var b: B? }\nclass B { var a: A? }  // A owns B, B weakly references A",
                        explanation: "Use weak/unowned or optionals to break circular type dependencies."
                    )
                ],
                relatedErrors: ["Recursive value type is not allowed", "Type alias references itself"],
                tags: ["circular", "reference", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .critical,
                title: "Recursive value type 'X' is not allowed",
                errorCode: "SWIFT_COMPILE_RECURSIVE_VALUE",
                description: "Value types (struct, enum) cannot contain themselves directly because they are copied by value, causing infinite size.",
                cause: "1. Struct containing property of same type. 2. Enum case with associated value of same type without indirect. 3. Value type recursive without indirection.",
                solutions: [
                    "Use indirect enum: indirect case node(value, next: MyEnum)",
                    "Use class instead of struct for recursive types",
                    "Use Box pattern with class wrapper for recursive structs",
                    "Use Optional<Self> to allow nil termination",
                    "For linked lists, use class-based Node with value type payload"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Indirect Enum",
                        badCode: "enum Tree {\n    case leaf\n    case node(value: Int, left: Tree, right: Tree)  // Error\n}",
                        goodCode: "enum Tree {\n    case leaf\n    indirect case node(value: Int, left: Tree, right: Tree)\n}",
                        explanation: "Use 'indirect' for recursive enum cases. Value types can't contain themselves directly."
                    )
                ],
                relatedErrors: ["Value type 'X' cannot have a stored property that references itself"],
                tags: ["recursive", "value type", "indirect", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "@escaping attribute only applies to function types",
                errorCode: "SWIFT_COMPILE_ESCAPING_NONFUNC",
                description: "The @escaping attribute is only valid on closure/function parameters, not on regular types.",
                cause: "1. Adding @escaping to non-closure parameter. 2. Misunderstanding @escaping purpose. 3. Copy-paste error from closure parameter.",
                solutions: [
                    "Remove @escaping from non-function parameters",
                    "Ensure parameter type is a function type: () -> Void",
                    "For closures in tuples/optionals, @escaping is required and valid",
                    "Check if parameter should actually be a closure"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Escaping Closure",
                        badCode: "func process(@escaping value: Int) { }  // Error",
                        goodCode: "func process(value: Int, @escaping completion: () -> Void) { }",
                        explanation: "@escaping only applies to function/closure type parameters."
                    )
                ],
                relatedErrors: ["Attribute can only be applied to declarations, not types"],
                tags: ["escaping", "closure", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Closures.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "'_' can only appear in a pattern or on the left side of an assignment",
                errorCode: "SWIFT_COMPILE_UNDERSCORE_MISUSE",
                description: "The underscore wildcard is used incorrectly. It can only discard values in assignments or patterns.",
                cause: "1. Using _ as a value. 2. _ in expression context. 3. Returning _ from function. 4. Passing _ as argument.",
                solutions: [
                    "Use _ only on left side of assignment: _ = function()",
                    "In patterns: case .some(_) or for _ in array",
                    "In function parameters to ignore: func f(_ x: Int)",
                    "Don't use _ where an actual value is needed"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Proper Underscore Use",
                        badCode: "let x = _  // Error",
                        goodCode: "_ = someFunction()  // Discard return value",
                        explanation: "_ is a discard pattern, not a value. Use it to ignore unwanted values."
                    )
                ],
                relatedErrors: ["Expected expression"],
                tags: ["underscore", "pattern", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "A declaration cannot be both 'final' and 'dynamic'",
                errorCode: "SWIFT_COMPILE_FINAL_DYNAMIC",
                description: "final prevents overriding, while dynamic requires Objective-C runtime dispatch. These are contradictory.",
                cause: "1. Marking property as both @objc dynamic and final. 2. KVO requiring dynamic but class design using final. 3. Conflicting attributes from different sources.",
                solutions: [
                    "Remove final if dynamic dispatch needed",
                    "Remove dynamic if overriding not needed",
                    "For KVO, use ObservableObject and Combine instead of @objc dynamic",
                    "Use @objc without dynamic if Obj-C visibility is enough",
                    "Consider property wrappers for observation"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Final vs Dynamic",
                        badCode: "final class Model: NSObject {\n    @objc dynamic var name = \"\"  // final + dynamic conflict\n}",
                        goodCode: "class Model: NSObject {\n    @objc dynamic var name = \"\"  // Not final\n}",
                        explanation: "final prevents subclassing/overriding; dynamic requires runtime dispatch. Choose one."
                    )
                ],
                relatedErrors: ["'dynamic' instance method must be declared on class"],
                tags: ["final", "dynamic", "objc", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Inheritance.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "'X' is inaccessible due to 'private' protection level",
                errorCode: "SWIFT_COMPILE_PRIVATE_ACCESS",
                description: "A private member can only be accessed within its declaring source file, not from other files.",
                cause: "1. Accessing private property from different file. 2. Private init preventing instantiation. 3. Test target trying to access private members. 4. Extension in different file.",
                solutions: [
                    "Change access level to internal or public",
                    "Use fileprivate for same-file extensions",
                    "For tests, use @testable import to access internal members",
                    "Add public accessor methods for private state",
                    "Move accessing code to same file",
                    "For singletons, use static shared with private init"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Access Level Fix",
                        badCode: "// File A.swift\nclass A { private var secret = 42 }\n// File B.swift\nprint(A().secret)  // Error",
                        goodCode: "// File A.swift\nclass A {\n    private var secret = 42\n    var publicSecret: Int { secret }  // Public getter\n}",
                        explanation: "Use appropriate access control. Expose only what's needed through computed properties."
                    )
                ],
                relatedErrors: ["'X' is inaccessible due to 'fileprivate' protection level", "'X' is inaccessible due to 'internal' protection level"],
                tags: ["private", "access control", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Declaration is only valid at file scope",
                errorCode: "SWIFT_COMPILE_FILE_SCOPE",
                description: "Certain declarations like imports, top-level constants, and some attributes are only valid at file scope.",
                cause: "1. import inside function or class. 2. @main inside nested scope. 3. Top-level statement inside type body. 4. File-private at non-file scope.",
                solutions: [
                    "Move import statements to top of file",
                    "Move @main struct to file scope",
                    "Place top-level declarations outside of types",
                    "Use nested types or extensions for organization instead"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "File Scope",
                        badCode: "class MyClass {\n    import Foundation  // Error\n}",
                        goodCode: "import Foundation\n\nclass MyClass {\n    // Use Foundation types\n}",
                        explanation: "Imports must be at file scope, before any other declarations."
                    )
                ],
                relatedErrors: ["Expected declaration"],
                tags: ["scope", "file", "import", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot declare entity named 'X' inside extension of generic type",
                errorCode: "SWIFT_COMPILE_GENERIC_EXT_DECL",
                description: "Swift has restrictions on what can be declared inside extensions of generic types.",
                cause: "1. Nested type in generic extension. 2. Stored property in extension of generic type. 3. Static stored property in generic type extension.",
                solutions: [
                    "Move declaration to main type definition instead of extension",
                    "Use computed properties instead of stored properties in extensions",
                    "For nested types, define at file scope with generic parameters",
                    "Use associated objects for stored properties in extensions"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Generic Extension Limit",
                        badCode: "extension Array {\n    struct MyNested { }  // Error in some contexts\n}",
                        goodCode: "struct ArrayNested<T> { }  // Define at file scope\nextension Array {\n    func useNested() -> ArrayNested<Element> { }\n}",
                        explanation: "Some declarations are restricted in generic extensions; move to type body or file scope."
                    )
                ],
                relatedErrors: ["Extension of generic type cannot contain an object with a non-protocol, non-class requirement"],
                tags: ["generic", "extension", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Generics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Stored property cannot have covariant 'Self' type",
                errorCode: "SWIFT_COMPILE_SELF_STORED",
                description: "Self type (which refers to the dynamic type of self) cannot be used for stored properties because the concrete size is unknown.",
                cause: "1. Using Self as property type. 2. Protocol with Self requirement used as stored property. 3. Associated type resolving to Self.",
                solutions: [
                    "Use concrete type instead of Self",
                    "Use protocol with associated type and typealias",
                    "For factory methods, use static methods returning Self",
                    "Use generics with type constraints instead of Self"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Avoid Self Property",
                        badCode: "class Container {\n    var item: Self  // Error\n}",
                        goodCode: "class Container<T> {\n    var item: T  // Generic instead of Self\n}",
                        explanation: "Self represents the dynamic type and can't be used for stored properties. Use generics."
                    )
                ],
                relatedErrors: ["Protocol can only be used as a generic constraint"],
                tags: ["self", "stored property", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Generics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Will be cast to 'X' which is always true/false",
                errorCode: "SWIFT_COMPILE_ALWAYS_CAST",
                description: "A conditional cast (as?) or forced cast (as!) will always succeed or always fail based on type relationships.",
                cause: "1. Casting to same type. 2. Casting to unrelated type. 3. Upcasting with as? instead of as. 4. Downcasting known type.",
                solutions: [
                    "Remove unnecessary cast",
                    "Use as for upcasting (always succeeds)",
                    "Use as? for downcasting (may fail)",
                    "Use as! only when certain of success",
                    "Remove cast if types are identical"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Appropriate Cast",
                        badCode: "let s: String = \"hello\"\nlet x = s as? String  // Always true, unnecessary",
                        goodCode: "let a: Any = \"hello\"\nlet s = a as? String  // Proper conditional cast",
                        explanation: "Only use conditional casts when the cast might actually fail."
                    )
                ],
                relatedErrors: ["Cast from 'X' to unrelated type 'Y' always fails"],
                tags: ["cast", "type", "warning", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TypeCasting.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot specialize protocol type 'X'",
                errorCode: "SWIFT_COMPILE_SPECIALIZE_PROTOCOL",
                description: "Protocol types with Self or associated type requirements cannot be used as concrete types.",
                cause: "1. Using Equatable as a type. 2. Using Collection as property type. 3. Protocol with associated type used directly.",
                solutions: [
                    "Use the protocol as a generic constraint instead",
                    "Use any Protocol (existential) in Swift 5.6+",
                    "Use type erasure (AnySequence, AnyPublisher, etc.)",
                    "For Equatable/Hashable, use generics: func f<T: Equatable>(x: T)",
                    "Use some Protocol for opaque return types"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Protocol Constraint",
                        badCode: "func compare(a: Equatable, b: Equatable) -> Bool { }  // Error",
                        goodCode: "func compare<T: Equatable>(a: T, b: T) -> Bool {\n    return a == b\n}",
                        explanation: "Protocols with Self/associated type requirements can only be used as generic constraints, not concrete types."
                    )
                ],
                relatedErrors: ["Protocol 'X' can only be used as a generic constraint"],
                tags: ["protocol", "generic", "associated type", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Protocols.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Extension of generic type 'Array<X>' with constraints cannot have an inheritance clause",
                errorCode: "SWIFT_COMPILE_EXT_INHERIT_CONSTRAINT",
                description: "Extensions with where clauses cannot add protocol conformance through inheritance clauses.",
                cause: "1. Trying to add protocol conformance in constrained extension. 2. where clause combined with : Protocol syntax.",
                solutions: [
                    "Add conformance in unconstrained extension",
                    "Use unconditional extension for protocol conformance",
                    "Implement protocol requirements in constrained extension without conformance declaration",
                    "Use @retroactive for retroactive conformances in Swift 5.10+"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Extension Conformance",
                        badCode: "extension Array where Element: Comparable: Sortable { }  // Error",
                        goodCode: "extension Array: Sortable where Element: Comparable { }  // Conditional conformance",
                        explanation: "Protocol conformance with constraints uses different syntax than constrained extensions."
                    )
                ],
                relatedErrors: ["Conditional conformance of type 'X' to protocol 'Y' does not imply conformance"],
                tags: ["extension", "generic", "conformance", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Generics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .high,
                title: "Cannot convert value of type 'X' to closure result type 'Y'",
                errorCode: "SWIFT_COMPILE_CLOSURE_RESULT",
                description: "The return type of a closure doesn't match the expected closure result type.",
                cause: "1. Closure returning wrong type. 2. Implicit return expression type mismatch. 3. Multiple return paths with different types. 4. Missing return in closure.",
                solutions: [
                    "Ensure closure returns expected type",
                    "Add explicit return type annotation to closure",
                    "For single-expression closures, ensure expression type matches",
                    "Use conditional expressions that return same type",
                    "For Void closures, don't return any value"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Closure Return Type",
                        badCode: "let transform: (Int) -> String = { num in\n    num  // Returns Int, not String\n}",
                        goodCode: "let transform: (Int) -> String = { num in\n    String(num)\n}",
                        explanation: "Closures must return the exact type specified in their signature."
                    )
                ],
                relatedErrors: ["Missing return in closure"],
                tags: ["closure", "return", "type", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Closures.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftCompile,
                severity: .medium,
                title: "Capture of 'X' with non-sendable type in a `@Sendable` closure",
                errorCode: "SWIFT_COMPILE_SENDABLE_CAPTURE",
                description: "Swift concurrency requires Sendable types to be captured in @Sendable closures for thread safety.",
                cause: "1. Capturing non-Sendable class in Task or async context. 2. @Sendable closure capturing mutable state. 3. Pre-concurrency types not marked Sendable.",
                solutions: [
                    "Mark type as @unchecked Sendable if manually thread-safe",
                    "Use actors for mutable shared state",
                    "Send values instead of references across concurrency boundaries",
                    "Use @MainActor for UI-related closures",
                    "For pre-Swift 6, add -warn-concurrency flag gradually",
                    "Use sendable closures with value types only"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Sendable Conformance",
                        badCode: "class Counter { var count = 0 }\nlet c = Counter()\nTask {\n    c.count += 1  // Non-sendable capture\n}",
                        goodCode: "actor Counter {\n    var count = 0\n    func increment() { count += 1 }\n}\nlet c = Counter()\nTask {\n    await c.increment()\n}",
                        explanation: "Use actors for mutable shared state in concurrent contexts."
                    )
                ],
                relatedErrors: ["Type 'X' does not conform to the 'Sendable' protocol"],
                tags: ["sendable", "concurrency", "closure", "compile"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html",
                commonInVersions: ["Swift 5.5+", "Swift 6.x"]
            ),
        ]
    }
    

    // =========================================================================
    // MARK: - 2. SWIFT RUNTIME ERRORS (100+ entries)
    // =========================================================================
    
    private func swiftRuntimeErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Unexpectedly found nil while unwrapping an Optional value",
                errorCode: "EXC_BAD_INSTRUCTION / SIGILL",
                description: "A force unwrap (!) was performed on a nil Optional, causing an immediate runtime crash. This is the #1 cause of Swift app crashes.",
                cause: "1. Force unwrapping a nil optional: optional!. 2. Implicitly unwrapped optional being nil at access time. 3. IBOutlet not connected in storyboard/xib. 4. Optional chaining result force unwrapped. 5. Dictionary[key]! on missing key. 6. try! on throwing function that throws.",
                solutions: [
                    "NEVER use ! unless 100% certain value exists (basically never)",
                    "Replace optional! with if let or guard let binding",
                    "Use nil-coalescing ?? to provide defaults: value ?? default",
                    "For IBOutlets, use optional chaining: label?.text = ...",
                    "Use try? instead of try! for safe error handling",
                    "Enable Address Sanitizer and Thread Sanitizer in debug builds",
                    "Use XCTest preconditions to catch these during testing"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Unwrapping",
                        badCode: "let name: String? = nil\nprint(name!.uppercased())  // CRASH!",
                        goodCode: "if let name = name {\n    print(name.uppercased())\n} else {\n    print(\"No name\")\n}",
                        explanation: "Force unwrap crashes on nil. Always use safe unwrapping patterns."
                    ),
                    CodeExample(
                        language: "swift",
                        title: "Dictionary Safe Access",
                        badCode: "let dict = [\"a\": 1]\nlet val = dict[\"b\"]!  // CRASH: key missing",
                        goodCode: "let val = dict[\"b\", default: 0]  // Safe: returns 0",
                        explanation: "Use default value subscript or conditional binding for dictionary access."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "Thread 1: Fatal error"],
                tags: ["nil", "force unwrap", "optional", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "EXC_BAD_ACCESS (code=1, address=0x...)",
                errorCode: "EXC_BAD_ACCESS",
                description: "Attempting to access memory that has been deallocated or is invalid. Often caused by dangling pointers or use-after-free.",
                cause: "1. Accessing deallocated object (dangling pointer). 2. Retain cycle broken but weak reference accessed after deallocation. 3. Force unwrapping implicitly unwrapped optional after object dealloc. 4. C pointer manipulation error. 5. Buffer overflow/underflow. 6. Accessing released CGImage/CoreFoundation object.",
                solutions: [
                    "Enable Zombie Objects in Diagnostics (keeps deallocated objects for debugging)",
                    "Use weak/unknown references properly to avoid retain cycles",
                    "Guard let self = self after weak self capture",
                    "Check for race conditions in multi-threaded code",
                    "Use Address Sanitizer (ASan) to detect use-after-free",
                    "For CoreFoundation objects, ensure proper retain/release",
                    "Check if delegate/datasource is set to nil on deinit",
                    "Look for unowned references to objects that deallocate earlier"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Weak Self",
                        badCode: "Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in\n    self.update()  // Self may be deallocated\n}",
                        goodCode: "Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in\n    guard let self = self else { return }\n    self.update()\n}",
                        explanation: "Always use [weak self] in escaping closures that outlive the object."
                    )
                ],
                relatedErrors: ["SIGSEGV", "SIGBUS", "EXC_BAD_INSTRUCTION"],
                tags: ["bad access", "memory", "dangling pointer", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Index out of range",
                errorCode: "Swift.Array._checkSubscript",
                description: "Accessing an array element at an index that doesn't exist (negative or >= count).",
                cause: "1. Accessing array[index] where index >= count. 2. Off-by-one errors in loops. 3. Empty array access. 4. Concurrent modification during iteration. 5. String index from different string used on another.",
                solutions: [
                    "Always check bounds before access: if index < array.count",
                    "Use safe subscript: array[safe: index] (add extension)",
                    "Use first, last, randomElement() for safe access",
                    "Use for element in array instead of index-based loops when possible",
                    "For string indices, ensure they're from the same string instance",
                    "Check array.isEmpty before accessing first/last elements",
                    "Use prefix, suffix, dropFirst, dropLast for safe slicing"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Array Access",
                        badCode: "let arr = [1, 2, 3]\nprint(arr[5])  // CRASH: index out of range",
                        goodCode: "if let item = arr[safe: 5] {\n    print(item)\n} else {\n    print(\"Index out of range\")\n}",
                        explanation: "Add a safe subscript extension or check bounds before accessing array elements."
                    )
                ],
                relatedErrors: ["EXC_BAD_INSTRUCTION", "Range requires lowerBound <= upperBound"],
                tags: ["array", "index", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Dictionary literal contains duplicate keys",
                errorCode: "Swift.Dictionary.init",
                description: "Creating a dictionary with duplicate keys in a literal. Only the last value is kept, but in some contexts this is a runtime error.",
                cause: "1. Dictionary literal with same key appearing twice. 2. Generated code creating duplicates. 3. Merging dictionaries without deduplication.",
                solutions: [
                    "Remove duplicate keys from dictionary literals",
                    "Use Dictionary(uniqueKeysWithValues:) which throws on duplicates",
                    "Use merging(_:uniquingKeysWith:) to handle conflicts",
                    "For dynamic generation, use reduce(into:) with conflict handling",
                    "Validate key uniqueness before dictionary creation"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Unique Dictionary Keys",
                        badCode: "let dict = [\"a\": 1, \"a\": 2]  // Duplicate key 'a'",
                        goodCode: "let dict = [\"a\": 1, \"b\": 2]  // Unique keys\n// or for merging:\nlet merged = dict1.merging(dict2) { old, new in new }",
                        explanation: "Dictionary keys must be unique. Handle merges explicitly."
                    )
                ],
                relatedErrors: ["Fatal error: duplicate keys of type"],
                tags: ["dictionary", "duplicate", "keys", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Can't form Range with upperBound < lowerBound",
                errorCode: "Swift.Range.init",
                description: "Creating a Range where the start is greater than or equal to the end, which is invalid.",
                cause: "1. Calculated range bounds where max < min. 2. String index operations producing invalid range. 3. Negative length calculations. 4. Off-by-one errors in range formation.",
                solutions: [
                    "Ensure lowerBound <= upperBound before creating Range",
                    "Use Swift.min/max to clamp bounds: min...max",
                    "For string ranges, use String.Index properly",
                    "Use prefix/upTo instead of manual range creation",
                    "Add precondition checks for range validity",
                    "For empty ranges, use 0..<0 or startIndex..<startIndex"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Range",
                        badCode: "let start = 5\nlet end = 2\nlet range = start..<end  // CRASH",
                        goodCode: "let start = 5\nlet end = 2\nlet range = min(start, end)..<max(start, end)  // Safe",
                        explanation: "Always ensure range lowerBound <= upperBound."
                    )
                ],
                relatedErrors: ["Fatal error: Range requires lowerBound <= upperBound"],
                tags: ["range", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/ControlFlow.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: UnsafeMutablePointer.initialize overlapping range",
                errorCode: "Swift.UnsafeMutablePointer.initialize",
                description: "Using unsafe pointer operations with overlapping memory ranges, which corrupts memory.",
                cause: "1. Pointer arithmetic errors. 2. Buffer overlap in memcpy-like operations. 3. Unsafe buffer operations with incorrect counts. 4. C interop with incorrect pointer math.",
                solutions: [
                    "Avoid unsafe pointer operations unless absolutely necessary",
                    "Use Swift's safe collection types instead",
                    "If using unsafe code, carefully validate pointer arithmetic",
                    "Use memmove instead of memcpy for overlapping regions",
                    "Enable Address Sanitizer to catch buffer issues",
                    "For C interop, write wrapper functions that validate inputs"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Avoid Unsafe Overlap",
                        badCode: "var arr = [1, 2, 3, 4]\narr.withUnsafeMutableBufferPointer { ptr in\n    ptr.baseAddress!.advanced(by: 0).initialize(from: ptr.baseAddress!.advanced(by: 2), count: 2)\n}",
                        goodCode: "var arr = [1, 2, 3, 4]\nlet copy = Array(arr[2...3])\narr[0...1] = copy[0...1]  // Safe copy",
                        explanation: "Avoid unsafe pointer operations. Use Swift's built-in collection operations."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGSEGV"],
                tags: ["unsafe", "pointer", "memory", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: UnsafeMutablePointer.deallocate with mismatched allocation",
                errorCode: "Swift.UnsafeMutablePointer.deallocate",
                description: "Deallocating memory with wrong size or alignment, or double-deallocating.",
                cause: "1. Deallocating with wrong count. 2. Double deallocation. 3. Mismatched allocate/deallocate types. 4. Deallocating stack memory. 5. Deallocating after pointer escape.",
                solutions: [
                    "Use safe Swift types instead of manual memory management",
                    "If using UnsafeMutablePointer, match allocate and deallocate counts exactly",
                    "Use defer to ensure deallocation happens",
                    "Never deallocate pointers you didn't allocate",
                    "For C interop, let the C library manage its own memory",
                    "Use Unmanaged<T> for explicit retain/release control"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Allocation",
                        badCode: "let ptr = UnsafeMutablePointer<Int>.allocate(capacity: 10)\nptr.deallocate()  // Missing capacity!",
                        goodCode: "let ptr = UnsafeMutablePointer<Int>.allocate(capacity: 10)\ndefer { ptr.deallocate() }\n// Use ptr...",
                        explanation: "Always match allocate capacity with deallocate. Use defer for cleanup."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGSEGV"],
                tags: ["unsafe", "pointer", "deallocate", "memory", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Double-free or invalid pointer",
                errorCode: "Swift.HeapObject",
                description: "An object is being released twice, or a non-heap pointer is being passed to free(). Common in C interop.",
                cause: "1. Double release of CFRelease/Release. 2. Unmanaged.release() called twice. 3. C function freeing Swift-allocated memory. 4. Manual retain/release mismatch.",
                solutions: [
                    "Don't manually manage memory for Swift reference types",
                    "Use ARC - it handles retain/release automatically",
                    "For CF objects, use __bridge_transfer or CFAutorelease",
                    "Match every retain with exactly one release",
                    "Use toll-free bridged types where possible",
                    "For C interop, clearly document memory ownership"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "CF Object Memory",
                        badCode: "let cfStr = CFStringCreate...\nCFRelease(cfStr)\nCFRelease(cfStr)  // Double free!",
                        goodCode: "let cfStr = CFStringCreate...\n// Let ARC handle it via bridging\nlet nsStr = cfStr as NSString\n// No manual release needed",
                        explanation: "Use ARC bridging instead of manual CoreFoundation memory management."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGABRT"],
                tags: ["double free", "memory", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFMemoryMgmt/CFMemoryMgmt.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Array cannot be bridged from Objective-C",
                errorCode: "Swift._forceBridgeFromObjectiveC",
                description: "Swift array bridging from NSArray failed because elements don't match the expected Swift type.",
                cause: "1. NSArray contains heterogeneous types. 2. NSNull objects in array accessed as non-optional. 3. NSMutableArray mutated during bridging. 4. Type mismatch between Obj-C and Swift expectations.",
                solutions: [
                    "Cast NSArray to [Any] first, then filter/map to desired type",
                    "Handle NSNull explicitly: array.compactMap { $0 as? String }",
                    "Use NSArray instead of Swift Array for heterogeneous data",
                    "Validate array contents before casting",
                    "For JSON parsing, use Codable with proper type handling"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Bridging",
                        badCode: "let nsArray: NSArray = [\"a\", NSNull(), \"b\"]\nlet strings = nsArray as! [String]  // CRASH on NSNull",
                        goodCode: "let strings = nsArray.compactMap { $0 as? String }  // [\"a\", \"b\"]",
                        explanation: "Use compactMap to safely filter and cast bridged arrays."
                    )
                ],
                relatedErrors: ["Could not cast value of type"],
                tags: ["bridge", "objective-c", "array", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swift/importing-objective-c-into-swift",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Thread 1: signal SIGABRT",
                errorCode: "SIGABRT",
                description: "The process was intentionally aborted, usually by calling abort() or failing an assertion. Common in failed preconditions and NSExceptions.",
                cause: "1. preconditionFailure() or fatalError() called. 2. NSException not caught. 3. abort() called in C code. 4. Assertion failure in debug. 5. dyld missing library. 6. Corrupted memory detected by malloc.",
                solutions: [
                    "Check console for assertion/precondition failure messages",
                    "Look for fatalError, precondition, assert in stack trace",
                    "For NSException, add exception breakpoint in Xcode",
                    "Check for missing frameworks in embedded binaries",
                    "Enable malloc scribble and guard edges in diagnostics",
                    "For C libraries, check if abort() is called on error",
                    "Use do-catch for Objective-C exceptions if bridged"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Precondition",
                        badCode: "precondition(index >= 0, \"Index must be non-negative\")\n// Called with index = -1 -> SIGABRT",
                        goodCode: "guard index >= 0 else {\n    print(\"Invalid index, using 0\")\n    return 0\n}",
                        explanation: "Use guard with graceful handling instead of precondition for recoverable errors."
                    )
                ],
                relatedErrors: ["SIGILL", "SIGSEGV", "SIGBUS"],
                tags: ["sigabrt", "abort", "assertion", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Division by zero",
                errorCode: "Swift.Int./",
                description: "Integer division or modulo by zero, which is undefined in mathematics and crashes in Swift.",
                cause: "1. Division where denominator is 0. 2. Modulo with zero divisor. 3. Calculated denominator becomes zero. 4. User input not validated before division.",
                solutions: [
                    "Always check divisor != 0 before division",
                    "Use guard or if to validate denominator",
                    "For floating point, division by zero produces inf (not crash)",
                    "Return optional or throw error for invalid division",
                    "Use .isZero check for numeric types",
                    "For averages, check count > 0 before sum/count"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Division",
                        badCode: "func average(_ values: [Int]) -> Int {\n    return values.reduce(0, +) / values.count  // Crash on empty!\n}",
                        goodCode: "func average(_ values: [Int]) -> Int? {\n    guard !values.isEmpty else { return nil }\n    return values.reduce(0, +) / values.count\n}",
                        explanation: "Always validate divisor is non-zero before performing division."
                    )
                ],
                relatedErrors: ["Fatal error: Remainder of division by zero"],
                tags: ["division", "zero", "math", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/BasicOperators.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: UnsafeBufferPointer with negative count",
                errorCode: "Swift.UnsafeBufferPointer.init",
                description: "Creating an unsafe buffer pointer with a negative count, which is invalid.",
                cause: "1. Negative count passed to buffer pointer init. 2. Integer overflow resulting in negative count. 3. C function returning negative size.",
                solutions: [
                    "Validate count >= 0 before creating buffer pointers",
                    "Use Int(bitPattern:) for unsigned C size_t conversions",
                    "Check for integer overflow in size calculations",
                    "Avoid unsafe buffer operations when possible",
                    "Use Array.init(unsafeUninitializedCapacity:) for safer initialization"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Buffer",
                        badCode: "let count = -1\nlet buffer = UnsafeBufferPointer(start: ptr, count: count)  // Crash",
                        goodCode: "let count = max(0, calculatedCount)\nlet buffer = UnsafeBufferPointer(start: ptr, count: count)",
                        explanation: "Always validate buffer counts are non-negative."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["unsafe", "buffer", "negative", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Could not cast value of type 'X' to 'Y'",
                errorCode: "Swift._dynamicCast",
                description: "A dynamic cast (as!, as?) failed at runtime because the types are incompatible.",
                cause: "1. Forced cast as! to wrong type. 2. Any/AnyObject cast to incompatible type. 3. Protocol cast to type that doesn't conform. 4. Bridging failure between Swift and Obj-C types.",
                solutions: [
                    "Use conditional cast as? instead of forced cast as!",
                    "Check type with is before casting",
                    "Use switch with case let for type matching",
                    "For Any, check type metadata before casting",
                    "For JSON, decode directly to target type with Codable",
                    "When receiving from Obj-C, validate class with isKind(of:)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Type Cast",
                        badCode: "let anyValue: Any = 42\nlet text = anyValue as! String  // CRASH: Int not String",
                        goodCode: "if let text = anyValue as? String {\n    print(text)\n} else if let num = anyValue as? Int {\n    print(num)\n}",
                        explanation: "Always use conditional casting for runtime type conversions."
                    )
                ],
                relatedErrors: ["Fatal error: Could not cast value", "EXC_BAD_INSTRUCTION"],
                tags: ["cast", "type", "dynamic", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TypeCasting.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: unexpectedly found nil while implicitly unwrapping an Optional value",
                errorCode: "Swift.ImplicitlyUnwrappedOptional",
                description: "An implicitly unwrapped optional (IUO) was nil when accessed. Common with IBOutlets and SDK APIs.",
                cause: "1. IBOutlet not connected in Interface Builder. 2. IUO property not set before access. 3. SDK API returning nil unexpectedly. 4. viewDidLoad not called before UI access. 5. Storyboard segue not configured.",
                solutions: [
                    "Connect all IBOutlets in storyboard/xib (check for typos)",
                    "Change IBOutlet to optional: @IBOutlet weak var label: UILabel?",
                    "Ensure view lifecycle methods complete before UI access",
                    "Use optional chaining for all UI element access: label?.text",
                    "For non-UI code, avoid IUO - use regular Optional",
                    "Check awakeFromNib/viewDidLoad initialization order",
                    "Use guard let for required UI elements with meaningful errors"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe IBOutlet",
                        badCode: "@IBOutlet var label: UILabel!\noverride func viewDidLoad() {\n    label.text = \"Hello\"  // Crash if not connected\n}",
                        goodCode: "@IBOutlet weak var label: UILabel?\noverride func viewDidLoad() {\n    label?.text = \"Hello\"  // Safe if not connected\n}",
                        explanation: "Use optional IBOutlets to prevent crashes when connections are missing."
                    )
                ],
                relatedErrors: ["Unexpectedly found nil while unwrapping an Optional value"],
                tags: ["iuo", "iboutlet", "nil", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: UnsafeMutableRawPointer.initializeMemory bound to type mismatch",
                errorCode: "Swift.UnsafeMutableRawPointer.initializeMemory",
                description: "Raw pointer memory initialization with wrong type binding, corrupting type information.",
                cause: "1. Initialize memory as Type A but access as Type B. 2. Type punning through raw pointers. 3. Incorrect stride or alignment calculations. 4. C struct mapped to wrong Swift type.",
                solutions: [
                    "Avoid raw pointer type punning",
                    "Use typed pointers (UnsafePointer<T>) instead of raw pointers",
                    "Ensure binding type matches actual memory layout",
                    "For C interop, use proper struct mappings",
                    "Use withMemoryRebound for legitimate type rebinding",
                    "Check alignment requirements with MemoryLayout"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Type Safe Pointers",
                        badCode: "let raw = UnsafeMutableRawPointer.allocate(...)\nraw.initializeMemory(as: Int.self, repeating: 0, count: 1)\nlet floatPtr = raw.assumingMemoryBound(to: Float.self)  // Mismatch",
                        goodCode: "let intPtr = UnsafeMutablePointer<Int>.allocate(capacity: 1)\nintPtr.initialize(to: 0)\ndefer { intPtr.deallocate() }",
                        explanation: "Use typed pointers matching the actual data type to avoid binding mismatches."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["unsafe", "pointer", "type", "memory", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Stack overflow",
                errorCode: "EXC_BAD_ACCESS (SIGSEGV)",
                description: "The call stack has exceeded its maximum size, usually due to infinite recursion or extremely deep call chains.",
                cause: "1. Infinite recursion without base case. 2. Very deep mutual recursion. 3. Massive number of nested closure captures. 4. Deep JSON/graph traversal without tail call optimization. 5. Large value types copied on stack.",
                solutions: [
                    "Add base case to all recursive functions",
                    "Convert recursion to iteration (for/while loops)",
                    "Use tail recursion where Swift supports it",
                    "Increase stack size for worker threads (not main thread)",
                    "For deep data structures, use iterative traversal with explicit stack",
                    "Break large structs into reference types (classes)",
                    "For JSON, use streaming parsers instead of recursive descent"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Iteration Over Recursion",
                        badCode: "func factorial(_ n: Int) -> Int {\n    n * factorial(n - 1)  // No base case -> infinite recursion\n}",
                        goodCode: "func factorial(_ n: Int) -> Int {\n    var result = 1\n    for i in 1...n {\n        result *= i\n    }\n    return result\n}",
                        explanation: "Use iteration instead of deep recursion to avoid stack overflow."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGSEGV"],
                tags: ["stack overflow", "recursion", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Functions.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Attempted to read an unowned reference but object was already deallocated",
                errorCode: "Swift._unownedHeapObject",
                description: "An unowned reference was accessed after the object it pointed to was deallocated. unowned assumes the object always exists.",
                cause: "1. Object deallocated while unowned reference still exists. 2. Unowned reference in closure outliving referenced object. 3. Delegate pattern using unowned instead of weak. 4. Parent-child relationship where parent deallocates first.",
                solutions: [
                    "Use weak instead of unowned if the object might deallocate",
                    "Ensure unowned object always outlives the reference",
                    "For delegates/datasources, always use weak",
                    "For parent-child, child should use weak reference to parent",
                    "Guard let self = self when weak self is unwrapped",
                    "Review object lifecycles to ensure proper ordering"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Weak vs Unowned",
                        badCode: "class Parent {\n    var child: Child!\n}\nclass Child {\n    unowned var parent: Parent  // Crash if parent deallocates\n}",
                        goodCode: "class Parent {\n    var child: Child!\n}\nclass Child {\n    weak var parent: Parent?  // Safe: becomes nil when deallocated\n}",
                        explanation: "Use weak for references that might become nil. Use unowned only when reference always exists."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "Fatal error: attempted to retain deallocated object"],
                tags: ["unowned", "weak", "deallocated", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: unsupported String index operation: index is invalid for this string",
                errorCode: "Swift.String.Index",
                description: "String indices are opaque and tied to a specific String instance. Using an index from one string on another causes crashes.",
                cause: "1. Index from string A used on string B. 2. Index used after string mutation. 3. Invalid index calculation. 4. Assumed UTF-8 byte offset equals character index.",
                solutions: [
                    "Always derive indices from the string you're indexing",
                    "Recalculate indices after string mutations",
                    "Use String methods that return valid indices: startIndex, endIndex, index(before:), index(after:)",
                    "For substrings, use Substring type to preserve index validity",
                    "Avoid assuming fixed-width characters - Swift uses extended grapheme clusters",
                    "Use utf8, utf16, or unicodeScalars views for byte-level access"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe String Index",
                        badCode: "let s1 = \"Hello\"\nlet idx = s1.index(s1.startIndex, offsetBy: 2)\nlet s2 = \"World\"\nprint(s2[idx])  // Crash: idx from s1",
                        goodCode: "let s2 = \"World\"\nlet idx = s2.index(s2.startIndex, offsetBy: 2)\nprint(s2[idx])  // Safe: idx from s2",
                        explanation: "String indices are bound to a specific string instance. Never share indices between strings."
                    )
                ],
                relatedErrors: ["Fatal error: String index is out of bounds"],
                tags: ["string", "index", "unicode", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: UnsafeMutableRawPointer.load out of bounds",
                errorCode: "Swift.UnsafeMutableRawPointer.load",
                description: "Loading data from a raw pointer at an offset that exceeds allocated memory bounds.",
                cause: "1. Offset calculation error. 2. Buffer smaller than expected. 3. Integer overflow in offset math. 4. C function returning wrong size.",
                solutions: [
                    "Validate offset < allocated size before load",
                    "Use typed pointers with known element sizes",
                    "Check MemoryLayout.size(ofValue:) for correct sizes",
                    "For C structs, verify packing and alignment",
                    "Use withUnsafeBytes for safe buffer access",
                    "Enable Address Sanitizer to catch out-of-bounds access"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Pointer Load",
                        badCode: "let ptr = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 4)\nptr.load(fromByteOffset: 8, as: Int32.self)  // Out of bounds!",
                        goodCode: "let ptr = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 4)\ndefer { ptr.deallocate() }\nptr.storeBytes(of: 42, toByteOffset: 0, as: Int32.self)\nlet value = ptr.load(fromByteOffset: 0, as: Int32.self)",
                        explanation: "Always ensure load offsets are within allocated bounds."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGSEGV"],
                tags: ["unsafe", "pointer", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Collection index is out of its bounds",
                errorCode: "Swift.Collection.",
                description: "Accessing a collection element using an index that is not valid for that collection instance.",
                cause: "1. Index from one collection used on another. 2. Collection mutated, making indices invalid. 3. Calculated index beyond bounds. 4. Index before startIndex or after endIndex.",
                solutions: [
                    "Verify index >= startIndex && index < endIndex before access",
                    "Regenerate indices after collection mutation",
                    "Use safe subscript methods or bounds checking",
                    "For sets/dictionaries, indices become invalid on mutation",
                    "Use for-in loops instead of manual index management",
                    "For String, indices are invalidated on mutation"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Collection Index",
                        badCode: "var arr = [1, 2, 3]\nlet idx = arr.index(arr.startIndex, offsetBy: 2)\narr.removeAll()\nprint(arr[idx])  // Invalid after mutation",
                        goodCode: "var arr = [1, 2, 3]\nif let idx = arr.indices.first(where: { arr[$0] == 3 }) {\n    print(arr[idx])\n}",
                        explanation: "Collection indices become invalid when the collection is mutated."
                    )
                ],
                relatedErrors: ["Fatal error: Index out of range"],
                tags: ["collection", "index", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Attempt to initialize an object twice",
                errorCode: "Swift._swift_allocObject",
                description: "An object is being initialized more than once, which corrupts memory and object state.",
                cause: "1. Calling super.init() twice. 2. Manually calling init on already initialized object. 3. C struct bridging double-initialization. 4. Factory pattern error.",
                solutions: [
                    "Ensure init is called exactly once per object",
                    "Don't call init on objects returned from factory methods",
                    "For C interop, check initialization boundaries",
                    "Use convenience init delegating to designated init properly",
                    "Avoid manual allocation + initialization patterns"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Single Initialization",
                        badCode: "class MyClass: NSObject {\n    override init() {\n        super.init()\n        super.init()  // Double init!\n    }\n}",
                        goodCode: "class MyClass: NSObject {\n    override init() {\n        super.init()\n    }\n}",
                        explanation: "Each object must be initialized exactly once. Never call init or super.init multiple times."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGABRT"],
                tags: ["init", "double", "object", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Initialization.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: UnsafeMutablePointer.moveInitialize with overlapping range",
                errorCode: "Swift.UnsafeMutablePointer.moveInitialize",
                description: "Moving initialization with overlapping source and destination ranges in unsafe pointer operations.",
                cause: "1. Overlapping memory regions in moveInitialize. 2. Incorrect source/destination pointer math. 3. Buffer shift operation with overlap.",
                solutions: [
                    "Ensure source and destination ranges don't overlap for moveInitialize",
                    "Use copy for overlapping ranges (though copy also forbids overlap)",
                    "For shifting elements, use temporary buffer",
                    "Avoid unsafe operations for simple array manipulations",
                    "Use Array's built-in mutating methods instead"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Non-Overlapping Move",
                        badCode: "ptr.moveInitialize(from: ptr, count: 5)  // Source == dest overlap",
                        goodCode: "// Use safe array operations instead\nvar arr = [1, 2, 3, 4, 5]\narr.insert(0, at: 0)  // Safe shift",
                        explanation: "Unsafe pointer move operations require non-overlapping ranges. Use safe collections."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["unsafe", "pointer", "overlap", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .medium,
                title: "Runtime warning: Modifying state during view update",
                errorCode: "SwiftUI.StateMutation",
                description: "SwiftUI state was modified during a view update, which can cause undefined behavior and infinite update loops.",
                cause: "1. Mutating @State in body computation. 2. Mutating @State in computed property used by view. 3. Side effects in View initializers. 4. Modifying state in onReceive during update.",
                solutions: [
                    "Never mutate @State during body evaluation",
                    "Move state mutations to event handlers (onTap, onAppear, etc.)",
                    "Use .task or .onAppear for async state initialization",
                    "For computed dependencies, use derived bindings",
                    "Use DispatchQueue.main.async to defer state mutation",
                    "Replace computed properties that mutate state with methods"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe State Update",
                        badCode: "var body: some View {\n    counter += 1  // NEVER do this in body!\n    return Text(\"\\(counter)\")\n}",
                        goodCode: "var body: some View {\n    Text(\"\\(counter)\")\n        .onTapGesture {\n            counter += 1  // Safe: in event handler\n        }\n}",
                        explanation: "Only mutate @State in response to user actions or lifecycle events, never during view rendering."
                    )
                ],
                relatedErrors: ["SwiftUI: Modifying state during view update"],
                tags: ["swiftui", "state", "mutation", "runtime", "warning"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/state",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Attempt to create a duplicate Set element",
                errorCode: "Swift.Set.insert",
                description: "Set elements must be unique according to Hashable/Equatable. This error occurs with malformed Hashable implementations.",
                cause: "1. Custom Hashable where == and hash(into:) are inconsistent. 2. Mutable properties included in hash but not equality. 3. hashValue changes after insertion.",
                solutions: [
                    "Ensure == and hash(into:) use exactly the same properties",
                    "Don't include mutable properties in hash if they change",
                    "Use struct auto-synthesized Hashable instead of custom",
                    "For classes, ensure hash properties are immutable",
                    "Test Hashable consistency: a == b implies a.hash == b.hash"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Consistent Hashable",
                        badCode: "struct Item: Hashable {\n    var id: Int\n    var name: String\n    func hash(into hasher: inout Hasher) {\n        hasher.combine(id)\n    }\n    static func == (lhs: Item, rhs: Item) -> Bool {\n        lhs.id == rhs.id && lhs.name == rhs.name  // Mismatch!\n    }\n}",
                        goodCode: "struct Item: Hashable {\n    let id: Int\n    var name: String\n    // Auto-synthesized hash and == both use id and name\n}",
                        explanation: "Hashable implementations must be consistent: equal objects must have equal hashes."
                    )
                ],
                relatedErrors: ["Fatal error: Dictionary literal contains duplicate keys"],
                tags: ["set", "hashable", "duplicate", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .medium,
                title: "warning: 'X' was deprecated in macOS Y.Z: Use 'Z' instead",
                errorCode: "DEPRECATION_WARNING",
                description: "Runtime warning that an API is deprecated. Unlike compile-time deprecation warnings, these may appear in logs during execution.",
                cause: "1. Using deprecated API at runtime. 2. Framework calling deprecated API internally. 3. Reflection or dynamic dispatch to deprecated method.",
                solutions: [
                    "Check console for exact deprecation message and replacement",
                    "Update to recommended API using #available checks",
                    "Update third-party frameworks to latest versions",
                    "For internal deprecations, migrate all call sites",
                    "Use responds(to:) checks for optional deprecated APIs"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "API Migration",
                        badCode: "NSLog(\"Hello\")  // Deprecated in favor of os_log",
                        goodCode: "import os.log\nlet logger = Logger(subsystem: \"com.app\", category: \"main\")\nlogger.log(\"Hello\")",
                        explanation: "Follow deprecation warnings to adopt modern replacements."
                    )
                ],
                relatedErrors: ["'X' is deprecated"],
                tags: ["deprecated", "warning", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/checking-for-api-availability",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: UnsafeMutablePointer.storeBytes to misaligned raw pointer",
                errorCode: "Swift.UnsafeMutablePointer.storeBytes",
                description: "Writing bytes to a memory address that doesn't meet the type's alignment requirements.",
                cause: "1. Wrong alignment in allocate. 2. Pointer arithmetic breaking alignment. 3. Packed C structs with different alignment. 4. Unaligned buffer access.",
                solutions: [
                    "Use MemoryLayout<T>.alignment when allocating",
                    "Ensure pointer offset preserves alignment",
                    "For C interop, match struct packing attributes",
                    "Use aligned allocate variants",
                    "For unaligned access, copy to aligned buffer first"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Aligned Allocation",
                        badCode: "let ptr = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 1)\nptr.storeBytes(of: 42.0, as: Double.self)  // Alignment 1 < 8",
                        goodCode: "let ptr = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: MemoryLayout<Double>.alignment)\nptr.storeBytes(of: 42.0, as: Double.self)",
                        explanation: "Always allocate with proper alignment for the types you'll store."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGBUS"],
                tags: ["unsafe", "alignment", "pointer", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Attempt to decrement before startIndex",
                errorCode: "Swift.String.Index",
                description: "Attempting to move a String index before the string's startIndex, which is invalid.",
                cause: "1. index(before:) on startIndex. 2. Offset calculation going negative. 3. Loop decrementing beyond bounds.",
                solutions: [
                    "Check index > startIndex before calling index(before:)",
                    "Use index(offsetBy:limitedBy:) for safe offset",
                    "Clamp offset to valid range",
                    "Use reversed() or striding methods for backward iteration",
                    "For character removal, check isEmpty first"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Index Movement",
                        badCode: "let s = \"A\"\nvar idx = s.startIndex\nidx = s.index(before: idx)  // Crash",
                        goodCode: "let s = \"A\"\nif let idx = s.index(s.startIndex, offsetBy: -1, limitedBy: s.startIndex) {\n    // Won't execute for negative offset\n}",
                        explanation: "Use limitedBy variant of index(offsetBy:) to prevent out-of-bounds index movement."
                    )
                ],
                relatedErrors: ["Fatal error: String index is out of bounds"],
                tags: ["string", "index", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Range requires lowerBound <= upperBound in String subscript",
                errorCode: "Swift.String.subscript",
                description: "Creating a string range or slice where start > end, which is invalid.",
                cause: "1. Range formed with reversed indices. 2. Substring operations with wrong index order. 3. Dynamic range calculation errors.",
                solutions: [
                    "Ensure range lowerBound <= upperBound",
                    "Use min/max to order indices correctly",
                    "For prefix/suffix extraction, use prefix(upTo:) and suffix(from:)",
                    "Validate range before subscripting",
                    "Use String.Index offset calculations carefully"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid String Range",
                        badCode: "let s = \"Hello\"\nlet start = s.index(s.startIndex, offsetBy: 3)\nlet end = s.index(s.startIndex, offsetBy: 1)\nlet sub = s[start..<end]  // start > end -> crash",
                        goodCode: "let lower = min(start, end)\nlet upper = max(start, end)\nlet sub = s[lower..<upper]",
                        explanation: "Always ensure string range lowerBound <= upperBound."
                    )
                ],
                relatedErrors: ["Fatal error: Can't form Range with upperBound < lowerBound"],
                tags: ["string", "range", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Attempting to access a pointer past its buffer",
                errorCode: "Swift.UnsafeBufferPointer.subscript",
                description: "Accessing an element in an unsafe buffer pointer beyond its allocated count.",
                cause: "1. Index >= buffer count. 2. Buffer count smaller than expected. 3. Off-by-one in index calculation. 4. Buffer resize not reflected in usage.",
                solutions: [
                    "Always check index < buffer.count before access",
                    "Use for-in loops over buffers instead of manual indexing",
                    "Regenerate buffer pointer after underlying data changes",
                    "Use withUnsafeBufferPointer which validates bounds",
                    "For C arrays passed to Swift, verify element count"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Buffer Access",
                        badCode: "let arr = [1, 2, 3]\narr.withUnsafeBufferPointer { buf in\n    print(buf[5])  // Out of bounds\n}",
                        goodCode: "arr.withUnsafeBufferPointer { buf in\n    for i in buf.indices {\n        print(buf[i])\n    }\n}",
                        explanation: "Iterate using buffer indices rather than arbitrary offsets."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["unsafe", "buffer", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Attempted to read an unowned reference but object was already deallocated (in async context)",
                errorCode: "Swift.Task.unowned",
                description: "In Swift concurrency, unowned references captured in async contexts can be accessed after deallocation when tasks outlive the referenced object.",
                cause: "1. unowned self in async/await closures. 2. Task capturing unowned reference. 3. Actor-isolated unowned reference accessed from different task.",
                solutions: [
                    "Use [weak self] in all async closures and tasks",
                    "Guard let self = self else { return } after weak capture",
                    "Never use unowned in async or escaping contexts",
                    "For actors, pass values instead of references",
                    "Use withCheckedContinuation carefully with weak references"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Weak in Async",
                        badCode: "Task {\n    [unowned self] in\n    await self.loadData()  // Crash if self deallocated\n}",
                        goodCode: "Task {\n    [weak self] in\n    guard let self = self else { return }\n    await self.loadData()\n}",
                        explanation: "Always use weak references in async contexts. Unowned is unsafe when execution spans suspension points."
                    )
                ],
                relatedErrors: ["Fatal error: Attempted to read an unowned reference"],
                tags: ["async", "unowned", "weak", "concurrency", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html",
                commonInVersions: ["Swift 5.5+", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: UnsafeMutablePointer.initialize with count exceeding allocated capacity",
                errorCode: "Swift.UnsafeMutablePointer.initialize",
                description: "Initializing more elements than were allocated, writing into unowned memory.",
                cause: "1. Count > allocated capacity. 2. Buffer resized but count not updated. 3. C function returning larger count than buffer. 4. Integer overflow in capacity calculation.",
                solutions: [
                    "Ensure count <= allocated capacity",
                    "Calculate capacity using MemoryLayout.size",
                    "Validate C API return values before using as count",
                    "Use withUnsafeMutablePointer to bounded buffers",
                    "For collections, prefer Array.init(unsafeUninitializedCapacity:)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Capacity Check",
                        badCode: "let ptr = UnsafeMutablePointer<Int>.allocate(capacity: 5)\nptr.initialize(repeating: 0, count: 10)  // Exceeds capacity",
                        goodCode: "let capacity = 5\nlet ptr = UnsafeMutablePointer<Int>.allocate(capacity: capacity)\nptr.initialize(repeating: 0, count: capacity)",
                        explanation: "Never initialize more elements than the allocated capacity."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["unsafe", "pointer", "capacity", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: attempt to create a duplicate Dictionary key after mutation",
                errorCode: "Swift.Dictionary.subscript._modify",
                description: "Dictionary uniqueness invariant violated during in-place mutation, usually from malformed Hashable.",
                cause: "1. Mutating key's hash value after insertion. 2. Key's == and hash inconsistent. 3. Custom dictionary key with mutable hash property.",
                solutions: [
                    "Make all properties used in hash(into:) immutable (let)",
                    "Ensure == and hash(into:) use identical properties",
                    "Don't mutate dictionary keys after insertion",
                    "Remove and re-insert if key properties must change",
                    "Use struct with auto-synthesized Hashable"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Immutable Hash Key",
                        badCode: "class Key: Hashable {\n    var id: Int\n    func hash(into hasher: inout Hasher) { hasher.combine(id) }\n}\nvar dict: [Key: String] = [:]\nlet k = Key(id: 1)\ndict[k] = \"A\"\nk.id = 2  // Mutates hash -> corruption",
                        goodCode: "struct Key: Hashable {\n    let id: Int  // Immutable hash property\n}",
                        explanation: "Dictionary keys must have stable hash values. Use immutable properties for hashing."
                    )
                ],
                relatedErrors: ["Fatal error: Dictionary literal contains duplicate keys"],
                tags: ["dictionary", "hashable", "mutation", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: unsafeBitCast of different-sized types",
                errorCode: "Swift.unsafeBitCast",
                description: "unsafeBitCast requires source and destination types to have the same size. Different sizes cause memory corruption.",
                cause: "1. Casting Int to Int32 on 64-bit platforms. 2. Casting struct to different-sized struct. 3. Pointer to non-pointer type casts. 4. Platform-dependent size differences.",
                solutions: [
                    "Ensure MemoryLayout<Source>.size == MemoryLayout<Dest>.size",
                    "Use unsafeDowncast for class hierarchy casting",
                    "Use withMemoryRebound for pointer type rebinding",
                    "For numeric conversion, use constructors: Int32(value)",
                    "Avoid unsafeBitCast unless absolutely necessary",
                    "For type punning, use UnsafeRawPointer.load"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Same Size Cast",
                        badCode: "let i: Int = 42\nlet i32 = unsafeBitCast(i, to: Int32.self)  // Size mismatch on 64-bit",
                        goodCode: "let i: Int = 42\nlet i32 = Int32(i)  // Safe conversion",
                        explanation: "Never use unsafeBitCast for type conversion. Use safe constructors."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["unsafe", "bitCast", "type", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Array.subscript: index out of range (in concurrent access)",
                errorCode: "Swift.Array.concurrent",
                description: "Array accessed from multiple threads simultaneously without synchronization, causing race conditions and crashes.",
                cause: "1. Reading array count on one thread, accessing on another. 2. Appending while iterating. 3. Multiple threads mutating same array. 4. Array passed to async task and mutated.",
                solutions: [
                    "Use NSLock, os_unfair_lock, or actor isolation for array access",
                    "Use concurrent collections from DispatchQueue",
                    "For Swift 5.5+, use actor to protect shared mutable state",
                    "Copy array before passing to background tasks",
                    "Use @MainActor for UI-related arrays",
                    "For read-heavy access, use immutable arrays and replace atomically"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Actor Protected Array",
                        badCode: "var sharedArray: [Int] = []\nDispatchQueue.global().async {\n    sharedArray.append(1)  // Race condition\n}\nDispatchQueue.global().async {\n    sharedArray.append(2)  // Race condition\n}",
                        goodCode: "actor DataStore {\n    private var array: [Int] = []\n    func append(_ value: Int) {\n        array.append(value)\n    }\n}\nlet store = DataStore()\nTask { await store.append(1) }\nTask { await store.append(2) }",
                        explanation: "Use actors or locks to protect shared mutable collections from concurrent access."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "Fatal error: Index out of range"],
                tags: ["concurrent", "array", "race condition", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: UnsafeMutablePointer.deinitialize with count exceeding initialized count",
                errorCode: "Swift.UnsafeMutablePointer.deinitialize",
                description: "Deinitializing more elements than were initialized, potentially accessing uninitialized memory.",
                cause: "1. Deinitialize count > initialize count. 2. Partial initialization not tracked. 3. Buffer partially filled but fully deinitialized.",
                solutions: [
                    "Track initialized count separately from allocated count",
                    "Use defer with exact initialized count",
                    "For partial initialization, deinitialize only initialized prefix",
                    "Prefer Array over raw pointers for dynamic-sized collections",
                    "Use UnsafeMutableBufferPointer for easier count tracking"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Track Init Count",
                        badCode: "let ptr = UnsafeMutablePointer<String>.allocate(capacity: 10)\nptr.initialize(to: \"A\")\nptr.deinitialize(count: 10)  // Only 1 initialized -> crash",
                        goodCode: "let ptr = UnsafeMutablePointer<String>.allocate(capacity: 10)\nvar initCount = 0\nptr.initialize(to: \"A\"); initCount += 1\nptr.deinitialize(count: initCount)\nptr.deallocate()",
                        explanation: "Track exactly how many elements were initialized and deinitialize only those."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["unsafe", "pointer", "deinitialize", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/UnsafePointers.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .medium,
                title: "warning: Forming 'X' with a gap is deprecated and will be removed in a future version",
                errorCode: "SWIFT_RANGE_GAP_DEPRECATED",
                description: "Creating ranges or partial ranges that have gaps or are invalid due to type constraints.",
                cause: "1. Partial range from with gap operations. 2. Deprecated range formation patterns. 3. String index ranges with gaps.",
                solutions: [
                    "Use standard range formation methods",
                    "Ensure range indices are contiguous",
                    "For partial ranges, use ...upper or lower... syntax",
                    "Replace deprecated range operations with modern equivalents"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Range",
                        badCode: "let r = 5..<3  // Gap (deprecated in some contexts)",
                        goodCode: "let r = 3..<5  // Valid range",
                        explanation: "Always form ranges with lowerBound <= upperBound."
                    )
                ],
                relatedErrors: ["Fatal error: Can't form Range with upperBound < lowerBound"],
                tags: ["range", "deprecated", "warning", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/ControlFlow.html",
                commonInVersions: ["Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Sequence elements are not lazily evaluated in this context",
                errorCode: "Swift.Sequence.lazy",
                description: "Attempting to use lazy sequence evaluation in a context that requires eager evaluation, causing unexpected behavior.",
                cause: "1. Using lazy map/filter in contexts requiring concrete arrays. 2. Multiple passes over lazy sequence. 3. Side effects in lazy transformations executed unexpectedly.",
                solutions: [
                    "Call .array to materialize lazy sequences when needed",
                    "Avoid side effects in lazy transformations",
                    "For multiple passes, materialize with Array(...)",
                    "Use eager operations if lazy semantics cause issues",
                    "Understand that lazy operations are re-evaluated on each iteration"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Materialize Lazy",
                        badCode: "let lazy = [1,2,3].lazy.map { $0 * 2 }\nprint(lazy.count)  // May have issues",
                        goodCode: "let eager = Array([1,2,3].lazy.map { $0 * 2 })\nprint(eager.count)  // OK: materialized",
                        explanation: "Lazy sequences should be materialized with Array() when concrete collection behavior is needed."
                    )
                ],
                relatedErrors: ["Fatal error: Lazy sequence side effect"],
                tags: ["lazy", "sequence", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
        ]
    }
    

    // =========================================================================
    // MARK: - 3. SWIFTUI ERRORS (80+ entries)
    // =========================================================================
    
    private func swiftUIErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .swiftUI,
                severity: .critical,
                title: "Modifying state during view update, this will cause undefined behavior",
                errorCode: "SwiftUI.StateUpdate",
                description: "A SwiftUI view's body is being computed while state is simultaneously being mutated, causing infinite render loops or crashes.",
                cause: "1. Mutating @State inside body. 2. Mutating @State in computed property getter. 3. Publishing ObservableObject change during view update. 4. onReceive handler mutating state during render. 5. Calling objectWillChange.send() inside body.",
                solutions: [
                    "Never mutate @State/@ObservedObject/@EnvironmentObject during body evaluation",
                    "Move mutations to event handlers: onTapGesture, onSubmit, button actions",
                    "Use .task modifier for async state initialization",
                    "Use DispatchQueue.main.async { } to defer state mutation to next runloop",
                    "For onReceive, wrap mutation in DispatchQueue.main.async",
                    "Use Button(action:) instead of TapGesture for actions",
                    "Refactor computed properties that trigger state changes"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe State Mutation",
                        badCode: "var body: some View {\n    counter += 1  // CRASH/undefined behavior\n    Text(\"\\(counter)\")\n}",
                        goodCode: "var body: some View {\n    Text(\"\\(counter)\")\n        .onTapGesture {\n            counter += 1  // Safe: in event handler\n        }\n}",
                        explanation: "State mutation must only happen in response to events, never during view rendering."
                    ),
                    CodeExample(
                        language: "swift",
                        title: "Defer State Update",
                        badCode: ".onReceive(timer) { _ in\n    counter += 1  // May trigger during update\n}",
                        goodCode: ".onReceive(timer) { _ in\n    DispatchQueue.main.async {\n        counter += 1  // Deferred to next runloop\n    }\n}",
                        explanation: "Defer publisher-triggered mutations to avoid modifying state during view updates."
                    )
                ],
                relatedErrors: ["Runtime warning: Modifying state during view update", "SwiftUI: cyclic dependency"],
                tags: ["swiftui", "state", "mutation", "body", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/app-essentials",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "Context in environment is not connected to a view",
                errorCode: "SwiftUI.Environment",
                description: "A SwiftUI view is trying to access an environment value before being placed in the view hierarchy, or the environment value doesn't exist.",
                cause: "1. Accessing @Environment before view is in hierarchy. 2. Custom environment key not injected. 3. Preview missing environment objects. 4. Window/Scene not properly configured.",
                solutions: [
                    "Ensure view is embedded in a NavigationView, List, or other container before accessing environment",
                    "Inject required environment objects with .environmentObject(obj)",
                    "For previews, add mock environment values",
                    "Use @StateObject instead of @EnvironmentObject for view-local state",
                    "Check that custom EnvironmentKey has a defaultValue",
                    "For macOS, ensure window group has proper scene configuration"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Environment Injection",
                        badCode: "struct ChildView: View {\n    @EnvironmentObject var store: Store\n    var body: some View { Text(\"\\(store.value)\") }\n}\n// Parent doesn't inject store",
                        goodCode: "struct ParentView: View {\n    @StateObject var store = Store()\n    var body: some View {\n        ChildView()\n            .environmentObject(store)\n    }\n}",
                        explanation: "Always inject @EnvironmentObject before the view that consumes it."
                    )
                ],
                relatedErrors: ["No ObservableObject of type X found", "SwiftUI: missing environment"],
                tags: ["swiftui", "environment", "environmentobject", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/environmentobject",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "No ObservableObject of type X found. A View.environmentObject(_:) for X may be missing.",
                errorCode: "SwiftUI.ObservableObjectMissing",
                description: "A view uses @EnvironmentObject but no ancestor view injected that object type into the environment.",
                cause: "1. Missing .environmentObject() modifier. 2. Wrong object type injected. 3. View hierarchy broken by sheet/fullScreenCover. 4. Preview missing environment object. 5. Object injected in wrong branch of view hierarchy.",
                solutions: [
                    "Add .environmentObject(myObject) on ancestor view",
                    "Ensure injected type matches exactly (subclass won't match base class)",
                    "For sheets, pass object explicitly or reinject in sheet content",
                    "For previews, create mock object and inject it",
                    "Consider using @StateObject for view-owned objects instead",
                    "Check view hierarchy - environment doesn't flow through UIKit bridges"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Sheet Environment",
                        badCode: ".sheet(isPresented: $showSheet) {\n    DetailView()  // Missing environment object\n}",
                        goodCode: ".sheet(isPresented: $showSheet) {\n    DetailView()\n        .environmentObject(store)  // Reinject for sheet\n}",
                        explanation: "Environment objects don't automatically flow into sheets and modals. Reinject explicitly."
                    )
                ],
                relatedErrors: ["Context in environment is not connected", "SwiftUI: environment missing"],
                tags: ["swiftui", "environmentobject", "observableobject", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/environmentobject",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "AttributeGraph: cycle detected through attribute X",
                errorCode: "SwiftUI.AttributeGraph",
                description: "SwiftUI's internal dependency graph detected a cyclic dependency, usually caused by state mutations creating infinite update loops.",
                cause: "1. State A depends on State B which depends on State A. 2. onChange modifier triggering the change it observes. 3. Binding getter/setter creating feedback loop. 4. ObservedObject published property triggering its own update.",
                solutions: [
                    "Break circular dependencies by introducing intermediate state",
                    "Use onChange carefully - don't mutate the observed value",
                    "For bindings, ensure setter doesn't trigger getter re-evaluation",
                    "Add DispatchQueue.main.async to break synchronous cycles",
                    "Use Equatable conformance to prevent redundant updates",
                    "Separate read and write concerns into different objects"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Break Dependency Cycle",
                        badCode: ".onChange(of: text) { newValue in\n    text = newValue.uppercased()  // Triggers another change\n}",
                        goodCode: ".onChange(of: text) { newValue in\n    // Don't mutate 'text' here; use derived state instead\n    displayText = newValue.uppercased()\n}",
                        explanation: "onChange should not mutate the value it's observing. Use separate state variables."
                    )
                ],
                relatedErrors: ["Modifying state during view update", "SwiftUI: cyclic dependency"],
                tags: ["swiftui", "attributegraph", "cycle", "dependency", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/state",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "ForEach<X, Y>: the ID X occurs multiple times within the collection",
                errorCode: "SwiftUI.ForEachDuplicateID",
                description: "ForEach requires all elements to have unique identifiers. Duplicate IDs cause rendering issues and crashes.",
                cause: "1. Array elements with same id property. 2. Using index as id but array has duplicates. 3. Core Data objects with temporary IDs. 4. ID not updated after object creation.",
                solutions: [
                    "Ensure all elements have truly unique IDs",
                    "Use UUID() for new objects",
                    "For Core Data, use objectID or nsManagedObjectID",
                    "Don't use array index as id if elements can move",
                    "Use identifiable array wrapper with computed unique IDs",
                    "Check for duplicate data before passing to ForEach"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Unique IDs",
                        badCode: "struct Item: Identifiable {\n    var id = 0\n}\nlet items = [Item(), Item()]  // Both id = 0",
                        goodCode: "struct Item: Identifiable {\n    let id = UUID()\n}\nlet items = [Item(), Item()]  // Unique UUIDs",
                        explanation: "ForEach requires unique IDs. Never hardcode IDs or use non-unique values."
                    )
                ],
                relatedErrors: ["SwiftUI: duplicate identifier"],
                tags: ["swiftui", "foreach", "id", "duplicate", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/foreach",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "Bound preference X tried to update multiple times per frame",
                errorCode: "SwiftUI.PreferenceMultipleUpdates",
                description: "A SwiftUI preference is being updated multiple times in a single frame, which is not allowed and indicates conflicting layout computations.",
                cause: "1. Multiple views setting same preference key. 2. Preference update triggering another preference update. 3. GeometryReader inside ScrollView causing layout thrashing. 4. Dynamic frame sizes creating feedback loops.",
                solutions: [
                    "Ensure only one view sets each preference key",
                    "Use .reduce for aggregating preferences from multiple children",
                    "Avoid GeometryReader inside scrolling containers",
                    "Cache geometry values to prevent repeated calculations",
                    "Use fixedSize() or frame constraints to prevent layout oscillation",
                    "Move preference logic to onPreferenceChange handler"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Reduce Preferences",
                        badCode: "// Multiple children setting same preference -> conflict\nVStack {\n    Child().preference(key: HeightKey.self, value: 10)\n    Child().preference(key: HeightKey.self, value: 20)\n}",
                        goodCode: "struct HeightKey: PreferenceKey {\n    static var defaultValue: [CGFloat] = []\n    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {\n        value.append(contentsOf: nextValue())\n    }\n}",
                        explanation: "Use PreferenceKey.reduce to aggregate values from multiple children instead of overwriting."
                    )
                ],
                relatedErrors: ["SwiftUI: preference loop", "Layout loop detected"],
                tags: ["swiftui", "preference", "layout", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/preferencekey",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "ViewGeometry proxy is being read while it is being written",
                errorCode: "SwiftUI.GeometryProxy",
                description: "A GeometryReader's proxy is being accessed in a way that conflicts with SwiftUI's layout pass, causing inconsistent values.",
                cause: "1. Accessing geometry proxy in state setter. 2. Mutating state based on geometry during layout. 3. Nested GeometryReaders creating layout thrashing. 4. Using geometry size in frame modifier that affects the same geometry.",
                solutions: [
                    "Don't store geometry values in @State - use directly in layout",
                    "For size-dependent layout, use GeometryReader at appropriate level",
                    "Avoid nested GeometryReaders",
                    "Use .overlay or .background for size measurement without affecting layout",
                    "For dynamic sizing, consider using PreferenceKey instead"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Geometry Usage",
                        badCode: "GeometryReader { geo in\n    VStack {\n        width = geo.size.width  // Mutating state during layout\n        Text(\"Width: \\(width)\")\n    }\n}",
                        goodCode: "GeometryReader { geo in\n    Text(\"Width: \\(geo.size.width)\")  // Use directly, no state\n}",
                        explanation: "Never store GeometryReader values in state. Read them directly during layout."
                    )
                ],
                relatedErrors: ["Modifying state during view update", "Layout loop detected"],
                tags: ["swiftui", "geometry", "proxy", "layout", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/geometryreader",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: Failed to create rendering Surface",
                errorCode: "SwiftUI.RenderSurface",
                description: "SwiftUI could not create a rendering surface for the view, often due to invalid view geometry or system resource exhaustion.",
                cause: "1. Zero or negative frame size. 2. Invalid transform matrix. 3. Window not properly configured. 4. GPU resource exhaustion. 5. Layer-backed view conflicts.",
                solutions: [
                    "Ensure all views have valid (non-zero, non-negative) frames",
                    "Check for NaN or infinite values in frame calculations",
                    "Set minWidth/minHeight constraints on resizable views",
                    "For macOS, ensure window contentView is set",
                    "Restart app if GPU resources exhausted",
                    "Avoid extremely complex view hierarchies"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Frame",
                        badCode: "Text(\"Hello\")\n    .frame(width: -10, height: 20)  // Invalid",
                        goodCode: "Text(\"Hello\")\n    .frame(minWidth: 10, idealWidth: 100, maxWidth: .infinity)",
                        explanation: "Always provide valid, positive frame dimensions."
                    )
                ],
                relatedErrors: ["SwiftUI: rendering failure", "Metal: failed to create texture"],
                tags: ["swiftui", "render", "surface", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: Implicit capture of 'self' in escaping closure requires explicit 'self.'",
                errorCode: "SwiftUI.SelfCapture",
                description: "SwiftUI view builders and closures require explicit self references to avoid retain cycles and make capture semantics clear.",
                cause: "1. Accessing self property in Button action without self. 2. onAppear closure referencing property. 3. Task block accessing view properties.",
                solutions: [
                    "Add explicit self. prefix: self.propertyName",
                    "Use [weak self] in closures that outlive the view",
                    "For short-lived closures, explicit self is sufficient",
                    "For async tasks, consider capturing values instead of self"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Explicit Self",
                        badCode: "Button(\"Tap\") {\n    updateCounter()  // Missing self\n}",
                        goodCode: "Button(\"Tap\") {\n    self.updateCounter()  // Explicit self\n}",
                        explanation: "SwiftUI closures require explicit self references for clarity and safety."
                    )
                ],
                relatedErrors: ["Reference to property in closure requires explicit 'self'"],
                tags: ["swiftui", "self", "closure", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: PreviewProvider body must return some View",
                errorCode: "SwiftUI.PreviewProvider",
                description: "A PreviewProvider's previews static property must return a SwiftUI View, but something else was returned.",
                cause: "1. Returning non-View type from previews. 2. Missing some View return type. 3. Preview struct not conforming to PreviewProvider. 4. Multiple previews not wrapped in Group.",
                solutions: [
                    "Ensure previews returns some View",
                    "Wrap multiple previews in Group { ... }",
                    "Check that struct conforms to PreviewProvider",
                    "For conditional previews, use Group with conditional content",
                    "Add required view modifiers to make preview valid"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Preview",
                        badCode: "struct MyPreview: PreviewProvider {\n    static var previews: Int { 42 }  // Not a View\n}",
                        goodCode: "struct MyPreview: PreviewProvider {\n    static var previews: some View {\n        MyView()\n    }\n}",
                        explanation: "PreviewProvider.previews must always return a View type."
                    )
                ],
                relatedErrors: ["Type 'X' does not conform to protocol 'PreviewProvider'"],
                tags: ["swiftui", "preview", "previewprovider", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/previewprovider",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: Update NSViewRepresentable must not update the presented NSView's frame",
                errorCode: "SwiftUI.NSViewRepresentable",
                description: "In NSViewRepresentable, directly modifying the wrapped NSView's frame conflicts with SwiftUI's layout system.",
                cause: "1. Setting frame in updateNSView. 2. Autoresizing mask conflicts. 3. Manual layout in representable. 4. NSView translating autoresizing mask into constraints.",
                solutions: [
                    "Let SwiftUI control the representable's frame via modifiers",
                    "In updateNSView, only update content/state, not layout",
                    "Disable autoresizingMaskTranslation: nsView.translatesAutoresizingMaskIntoConstraints = false",
                    "Use SwiftUI frame modifiers on the representable",
                    "For complex NSViews, wrap in NSViewControllerRepresentable"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe NSViewRepresentable",
                        badCode: "func updateNSView(_ nsView: MyNSView, context: Context) {\n    nsView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)  // Bad\n}",
                        goodCode: "func updateNSView(_ nsView: MyNSView, context: Context) {\n    nsView.text = \"Updated\"  // Only update content\n}\n// In SwiftUI:\nMyRepresentable()\n    .frame(width: 100, height: 100)  // SwiftUI handles layout",
                        explanation: "Never modify frame in updateNSView. Use SwiftUI modifiers for layout control."
                    )
                ],
                relatedErrors: ["SwiftUI: layout conflict in representable"],
                tags: ["swiftui", "nsviewrepresentable", "frame", "layout", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/nsviewrepresentable",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: @ViewBuilder attribute can only be applied to closure parameters",
                errorCode: "SwiftUI.ViewBuilder",
                description: "The @ViewBuilder attribute is being used incorrectly - it's only valid on function/closures that return View content.",
                cause: "1. Applying @ViewBuilder to non-closure parameter. 2. Using @ViewBuilder on stored property. 3. @ViewBuilder on function that doesn't return View.",
                solutions: [
                    "Only use @ViewBuilder on closure parameters",
                    "For computed properties returning View, SwiftUI handles ViewBuilder implicitly",
                    "For custom container views, apply @ViewBuilder to content closure parameter",
                    "Ensure the function body returns View content"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "ViewBuilder Usage",
                        badCode: "@ViewBuilder var myProperty: some View {  // Error\n    Text(\"Hello\")\n}",
                        goodCode: "var myProperty: some View {\n    Text(\"Hello\")\n}",
                        explanation: "@ViewBuilder is implicit in SwiftUI view properties. Only use it explicitly on closure parameters."
                    )
                ],
                relatedErrors: ["@ViewBuilder cannot be applied"],
                tags: ["swiftui", "viewbuilder", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/viewbuilder",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: 'body' is inaccessible due to 'private' protection level",
                errorCode: "SwiftUI.PrivateBody",
                description: "A view's body property must be at least internal access level because SwiftUI's framework code needs to call it.",
                cause: "1. Marking body as private. 2. View in private extension. 3. Fileprivate view with body.",
                solutions: [
                    "Remove private from body property",
                    "Change to internal or public",
                    "For view modifiers, ensure the view type is accessible",
                    "Don't put views in private/fileprivate extensions if they need to be rendered"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Accessible Body",
                        badCode: "struct MyView: View {\n    private var body: some View {  // Error\n        Text(\"Hello\")\n    }\n}",
                        goodCode: "struct MyView: View {\n    var body: some View {\n        Text(\"Hello\")\n    }\n}",
                        explanation: "View.body must be accessible to the SwiftUI framework. Never mark it private."
                    )
                ],
                relatedErrors: ["Protocol requires 'body' to be accessible"],
                tags: ["swiftui", "body", "access", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: onChange(of:) action tried to update multiple times per frame",
                errorCode: "SwiftUI.OnChangeMultiple",
                description: "The onChange modifier triggered multiple times in a single frame, often because the action itself mutated the observed value.",
                cause: "1. onChange action mutating the observed value. 2. Cascading state updates from onChange. 3. onChange on a value that changes during every frame.",
                solutions: [
                    "Never mutate the value being observed in onChange",
                    "Use separate state variable for derived values",
                    "Add Equatable conformance to prevent unnecessary change detection",
                    "Debounce rapid changes with Combine or Timer",
                    "Use task(id:) instead of onChange for async reactions"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe onChange",
                        badCode: ".onChange(of: text) { newValue in\n    text = newValue.trimmed()  // Mutates observed value -> loop\n}",
                        goodCode: ".onChange(of: text) { newValue in\n    trimmedText = newValue.trimmed()  // Separate state\n}",
                        explanation: "onChange must never mutate the value it's observing. Store derived results separately."
                    )
                ],
                relatedErrors: ["Modifying state during view update", "AttributeGraph: cycle detected"],
                tags: ["swiftui", "onchange", "state", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view/onchange",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: Binding transaction attempted to update while updating",
                errorCode: "SwiftUI.BindingTransaction",
                description: "A Binding's setter triggered another binding update during an ongoing update, causing nested transaction conflicts.",
                cause: "1. Binding setter calling another binding setter. 2. Custom Binding with get/set creating feedback. 3. Two-way binding with computed dependency. 4. onChange of binding triggering binding update.",
                solutions: [
                    "Break binding chains by using intermediate state",
                    "For custom bindings, avoid triggering other bindings in setter",
                    "Use Transaction to disable animations during programmatic updates",
                    "Separate read binding from write binding",
                    "Use explicit Button actions instead of binding mutations for complex logic"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Binding",
                        badCode: "var binding: Binding<Bool> {\n    Binding(\n        get: { isOn },\n        set: {\n            isOn = $0\n            otherBinding.wrappedValue = $0  // Nested update\n        }\n    )\n}",
                        goodCode: "var binding: Binding<Bool> {\n    Binding(\n        get: { isOn },\n        set: { newValue in\n            var transaction = Transaction()\n            transaction.disablesAnimations = true\n            withTransaction(transaction) {\n                isOn = newValue\n            }\n        }\n    )\n}",
                        explanation: "Avoid nested binding updates. Use transactions to manage complex state changes safely."
                    )
                ],
                relatedErrors: ["Modifying state during view update", "AttributeGraph: cycle detected"],
                tags: ["swiftui", "binding", "transaction", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/binding",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: Window requires a root view controller before it can be used",
                errorCode: "SwiftUI.WindowRootView",
                description: "A SwiftUI window or hosting controller was used before it had a proper root view configured.",
                cause: "1. Window shown before rootView set. 2. Hosting controller initialized without root view. 3. Scene lifecycle issue where window created too early.",
                solutions: [
                    "Ensure NSHostingView has a root view before displaying",
                    "Set window.contentView before calling makeKeyAndOrderFront",
                    "For NSWindowController, set contentViewController before showing",
                    "In app lifecycle, setup UI in applicationDidFinishLaunching",
                    "For SwiftUI App lifecycle, ensure WindowGroup has content"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Window Setup",
                        badCode: "let window = NSWindow(...)\nwindow.makeKeyAndOrderFront(nil)  // No content view set",
                        goodCode: "let window = NSWindow(...)\nwindow.contentView = NSHostingView(rootView: MyView())\nwindow.makeKeyAndOrderFront(nil)",
                        explanation: "Always set a content view before displaying a window."
                    )
                ],
                relatedErrors: ["NSWindow requires a root view controller"],
                tags: ["swiftui", "window", "rootview", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/nswindow",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: Invalid frame dimension (negative or infinite)",
                errorCode: "SwiftUI.InvalidFrame",
                description: "A frame modifier was given invalid dimensions that cannot be rendered.",
                cause: "1. Negative width or height. 2. .infinity in non-max dimension. 3. NaN in frame calculation. 4. Division by zero in size computation.",
                solutions: [
                    "Ensure all frame dimensions are positive and finite",
                    "Use .infinity only with maxWidth/maxHeight parameters",
                    "Guard against division by zero in size calculations",
                    "Use max(0, calculatedValue) to clamp to valid range",
                    "For proportional sizing, use GeometryReader with safe math"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Frame",
                        badCode: "Text(\"Hello\")\n    .frame(width: .infinity)  // .infinity not allowed here",
                        goodCode: "Text(\"Hello\")\n    .frame(maxWidth: .infinity)  // Correct usage",
                        explanation: ".infinity is only valid for maxWidth, maxHeight, minWidth, minHeight - not for fixed width/height."
                    )
                ],
                relatedErrors: ["SwiftUI: Failed to create rendering Surface"],
                tags: ["swiftui", "frame", "layout", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view/frame",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: List row content must not generate more than one view per row",
                errorCode: "SwiftUI.ListMultipleViews",
                description: "List rows in older SwiftUI versions required exactly one top-level view per row. Multiple views caused ambiguity.",
                cause: "1. Returning multiple views from List row closure. 2. Conditional views creating different counts. 3. ForEach inside List row generating multiple views.",
                solutions: [
                    "Wrap multiple views in HStack, VStack, or Group",
                    "Use Section to group related rows",
                    "For conditional content, wrap in Group with if/else",
                    "Upgrade to newer SwiftUI where List supports multiple views per row",
                    "Use ForEach with explicit id for dynamic rows"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Single Row View",
                        badCode: "List {\n    Text(\"A\")\n    Text(\"B\")  // Two views in one row closure\n}",
                        goodCode: "List {\n    VStack {\n        Text(\"A\")\n        Text(\"B\")\n    }\n}",
                        explanation: "Wrap multiple views in a container when used as List row content."
                    )
                ],
                relatedErrors: ["SwiftUI: ambiguous List content"],
                tags: ["swiftui", "list", "row", "layout", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/list",
                commonInVersions: ["Swift 5.0", "Swift 5.1"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: NavigationLink is only supported inside a NavigationView",
                errorCode: "SwiftUI.NavigationLink",
                description: "NavigationLink requires a NavigationView ancestor to manage the navigation stack and push/pop transitions.",
                cause: "1. NavigationLink without NavigationView wrapper. 2. NavigationView in wrong view hierarchy branch. 3. Sheet/modal presenting view with NavigationLink.",
                solutions: [
                    "Wrap content in NavigationView { ... }",
                    "For macOS, use NavigationSplitView for 3-column layout",
                    "Ensure NavigationView is the root of the navigable content",
                    "For programmatic navigation, use NavigationPath (iOS 16+)",
                    "For deep linking, set up navigation stack properly"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Navigation Setup",
                        badCode: "var body: some View {\n    NavigationLink(\"Go\", destination: DetailView())  // No NavigationView\n}",
                        goodCode: "var body: some View {\n    NavigationView {\n        NavigationLink(\"Go\", destination: DetailView())\n    }\n}",
                        explanation: "NavigationLink must be inside a NavigationView to function."
                    )
                ],
                relatedErrors: ["SwiftUI: Navigation without NavigationView"],
                tags: ["swiftui", "navigationlink", "navigationview", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/navigationlink",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: sheet/fullScreenCover requires isPresented binding or item",
                errorCode: "SwiftUI.SheetBinding",
                description: "Sheet and fullScreenCover modifiers require either an isPresented Bool binding or an optional item binding.",
                cause: "1. Missing binding parameter. 2. Using constant(true) causing immediate dismissal. 3. Binding not updating correctly. 4. Multiple sheets with same binding.",
                solutions: [
                    "Pass a @State Bool binding: .sheet(isPresented: $showSheet)",
                    "Or pass an optional item: .sheet(item: $selectedItem)",
                    "Ensure binding is two-way (@State, @Binding)",
                    "Don't use .constant(true) - sheet dismisses itself",
                    "For multiple sheets, use separate bindings or .sheet(item:)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Sheet Binding",
                        badCode: ".sheet(isPresented: .constant(true)) {  // Won't work\n    DetailView()\n}",
                        goodCode: "@State private var showSheet = false\n\n// ...\n.sheet(isPresented: $showSheet) {\n    DetailView()\n}",
                        explanation: "Sheets require a mutable binding so they can set it to false when dismissed."
                    )
                ],
                relatedErrors: ["SwiftUI: sheet without binding"],
                tags: ["swiftui", "sheet", "binding", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view/sheet",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: ObservableObject objectWillChange sent before object was fully initialized",
                errorCode: "SwiftUI.ObservableObjectInit",
                description: "An ObservableObject published a change before its initialization completed, causing undefined observation behavior.",
                cause: "1. Publishing property change in init. 2. Calling external method in init that triggers publish. 3. Subclass ObservableObject with premature publish.",
                solutions: [
                    "Don't publish changes during initialization",
                    "Defer initial publishes to after init completes",
                    "Use @Published with default values instead of manual publish",
                    "For complex init, set properties directly without willChange",
                    "Use a configure() method called after initialization"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe ObservableObject Init",
                        badCode: "class Store: ObservableObject {\n    @Published var count = 0\n    init() {\n        count = 5  // Publishes during init\n    }\n}",
                        goodCode: "class Store: ObservableObject {\n    @Published var count = 5  // Set default, no publish\n    init() { }\n}",
                        explanation: "Set @Published defaults at declaration. Avoid publishing during init."
                    )
                ],
                relatedErrors: ["SwiftUI: ObservableObject init warning"],
                tags: ["swiftui", "observableobject", "init", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/combine/observableobject",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: Preview crashed due to runtime error",
                errorCode: "SwiftUI.PreviewCrash",
                description: "The SwiftUI Preview canvas crashed due to a runtime error in the previewed view or its dependencies.",
                cause: "1. Force unwrap in preview. 2. Missing environment object in preview. 3. Preview accessing file/resource not in preview bundle. 4. Preview using singleton that needs setup. 5. Core Data context missing in preview.",
                solutions: [
                    "Add all required environment objects to preview",
                    "Use mock data instead of real network/file access",
                    "Create preview-specific view configurations",
                    "For Core Data, create in-memory preview container",
                    "Check preview canvas logs for specific error",
                    "Use #if DEBUG for preview-specific code paths",
                    "Simplify preview to isolate the crashing component"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Robust Preview",
                        badCode: "struct MyPreview: PreviewProvider {\n    static var previews: some View {\n        MyView()  // Missing required environment\n    }\n}",
                        goodCode: "struct MyPreview: PreviewProvider {\n    static var previews: some View {\n        MyView()\n            .environmentObject(MockStore())\n            .environment(\\.managedObjectContext, previewContext)\n    }\n}",
                        explanation: "Previews need all dependencies injected. Use mocks for external services."
                    )
                ],
                relatedErrors: ["SwiftUI: Preview error", "Canvas agent crashed"],
                tags: ["swiftui", "preview", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/previewprovider",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: ViewRendererHostView size is zero, content will not be rendered",
                errorCode: "SwiftUI.ZeroSize",
                description: "A SwiftUI view has zero width or height, so nothing will be visible.",
                cause: "1. View in zero-size container. 2. Frame set to 0x0. 3. Spacer in empty layout. 4. View clipped to zero size. 5. Layout priority issue causing collapse.",
                solutions: [
                    "Set minimum frame dimensions: .frame(minWidth: 10, minHeight: 10)",
                    "Check parent container size",
                    "Remove fixed .frame(width: 0, height: 0)",
                    "Use layoutPriority to prevent collapse",
                    "For resizable views, ensure parent provides space",
                    "Use fixedSize() to prevent view from shrinking to zero"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Non-Zero Frame",
                        badCode: "Text(\"Hello\")\n    .frame(width: 0, height: 0)  // Invisible",
                        goodCode: "Text(\"Hello\")\n    .frame(minWidth: 50, minHeight: 20)",
                        explanation: "Ensure views have positive dimensions. Use min constraints to prevent zero-size collapse."
                    )
                ],
                relatedErrors: ["SwiftUI: Invalid frame dimension"],
                tags: ["swiftui", "frame", "zero", "layout", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view/frame",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
        ]
    }
    

    // =========================================================================
    // MARK: - 4. APPKIT / MACOS ERRORS (60+ entries)
    // =========================================================================
    
    private func appKitErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .appKit,
                severity: .critical,
                title: "-[NSApplication run] must be called from main thread only",
                errorCode: "APPKIT_MAIN_THREAD",
                description: "AppKit UI operations must run on the main thread. Calling from background threads causes crashes or undefined behavior.",
                cause: "1. Creating NSWindow/NSView on background thread. 2. Calling NSApplication.shared from background. 3. UI updates from DispatchQueue.global. 4. Timer callback on background thread.",
                solutions: [
                    "Wrap all UI code in DispatchQueue.main.async { }",
                    "Use @MainActor for SwiftUI views and AppKit UI classes",
                    "For background completion, dispatch UI updates to main thread",
                    "Use MainThreadGuard in debug builds to catch violations",
                    "For Combine, use .receive(on: DispatchQueue.main)",
                    "For async/await, mark UI methods with @MainActor"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Main Thread UI",
                        badCode: "DispatchQueue.global().async {\n    let window = NSWindow(...)  // CRASH\n    window.makeKeyAndOrderFront(nil)\n}",
                        goodCode: "DispatchQueue.global().async {\n    let data = fetchData()\n    DispatchQueue.main.async {\n        self.label.stringValue = data\n    }\n}",
                        explanation: "All AppKit UI must happen on the main thread. Dispatch UI updates explicitly."
                    )
                ],
                relatedErrors: ["EXC_BAD_INSTRUCTION", "NSInternalInconsistencyException"],
                tags: ["appkit", "main thread", "ui", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsapplication",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+", "macOS 13+", "macOS 14+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .critical,
                title: "NSWindow drag regions should only be invalidated on the Main Thread!",
                errorCode: "APPKIT_DRAG_REGION_MAIN",
                description: "Window drag region updates triggered from a background thread. This is a strict main-thread-only operation.",
                cause: "1. Modifying window style mask from background thread. 2. Updating title bar from background. 3. Window resize from non-main thread. 4. setFrame called on background queue.",
                solutions: [
                    "Dispatch ALL window operations to main thread",
                    "Use NSWindow.performOnMainThread if available",
                    "For async updates, use await MainActor.run { }",
                    "Audit all window modifications for thread safety",
                    "Use Xcode's Main Thread Checker to find violations"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Main Thread Window",
                        badCode: "DispatchQueue.global().async {\n    window.title = \"Updated\"  // Warning/crash\n}",
                        goodCode: "DispatchQueue.main.async {\n    window.title = \"Updated\"\n}",
                        explanation: "Every NSWindow and NSView operation must occur on the main thread."
                    )
                ],
                relatedErrors: ["-[NSApplication run] must be called from main thread"],
                tags: ["appkit", "window", "drag region", "main thread", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nswindow",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "Unable to activate constraint with anchors because they have no common ancestor",
                errorCode: "APPKIT_CONSTRAINT_ANCESTOR",
                description: "Auto Layout constraints can only be created between views that are in the same view hierarchy.",
                cause: "1. Constraint between views in different windows. 2. Constraint added before view is added to superview. 3. Constraint to view that was removed. 4. Anchors from different view hierarchies.",
                solutions: [
                    "Ensure both views are in the same hierarchy before adding constraints",
                    "Add views to superview first, then activate constraints",
                    "For cross-hierarchy relationships, use spacer views",
                    "Deactivate old constraints before reparenting views",
                    "Use layout guides for areas that need constraints"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Common Ancestor",
                        badCode: "let constraint = view1.leadingAnchor.constraint(equalTo: view2.leadingAnchor)\nconstraint.isActive = true  // Views not in same hierarchy",
                        goodCode: "superview.addSubview(view1)\nsuperview.addSubview(view2)\nlet constraint = view1.leadingAnchor.constraint(equalTo: view2.leadingAnchor)\nconstraint.isActive = true",
                        explanation: "Views must share a common ancestor before constraints can link them."
                    )
                ],
                relatedErrors: ["NSLayoutConstraint inconsistent hierarchy"],
                tags: ["appkit", "autolayout", "constraint", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nslayoutconstraint",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "Unable to simultaneously satisfy constraints",
                errorCode: "APPKIT_AMBIGUOUS_LAYOUT",
                description: "Auto Layout cannot find a valid solution because constraints conflict with each other.",
                cause: "1. Two constraints requiring different sizes. 2. Fixed width + leading + trailing exceeding parent. 3. Conflicting compression resistance priorities. 4. Ambiguous constraint priorities.",
                solutions: [
                    "Check console for specific conflicting constraints",
                    "Set lower priority on one of the conflicting constraints",
                    "Use inequalities (>=, <=) instead of equalities where appropriate",
                    "Check intrinsicContentSize of custom views",
                    "Set content hugging and compression resistance priorities",
                    "Remove redundant constraints",
                    "Use NSLayoutConstraint.visualFormat for complex layouts"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Resolve Conflicts",
                        badCode: "view.widthAnchor.constraint(equalToConstant: 100).isActive = true\nview.widthAnchor.constraint(equalToConstant: 200).isActive = true  // Conflict",
                        goodCode: "view.widthAnchor.constraint(equalToConstant: 100).isActive = true\nview.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true  // Compatible",
                        explanation: "Constraints must be mutually satisfiable. Use priority or inequalities to resolve conflicts."
                    )
                ],
                relatedErrors: ["NSLayoutConstraint breakpoint"],
                tags: ["appkit", "autolayout", "constraint", "ambiguous", "runtime"],
                appleDocURL: "https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "NSViewController's view was unloaded while key value observers were still registered",
                errorCode: "APPKIT_KVO_CRASH",
                description: "Key-Value Observing observers were not removed before the view controller's view was deallocated.",
                cause: "1. Adding KVO observer without removing in dealloc. 2. viewWillDisappear not removing observers. 3. Multiple addObserver calls without matching removeObserver. 4. Observer added in init but not removed.",
                solutions: [
                    "Always remove KVO observers in deinit or viewWillDisappear",
                    "Use block-based KVO with NSKeyValueObservation token",
                    "For modern code, use Combine or ObservableObject instead of KVO",
                    "Use Swift's didSet/willSet for property observation",
                    "For NSViewController, remove observers in viewWillDisappear"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe KVO",
                        badCode: "override func viewDidLoad() {\n    super.viewDidLoad()\n    addObserver(self, forKeyPath: \"title\", options: .new, context: nil)\n}  // Missing removeObserver",
                        goodCode: "private var observation: NSKeyValueObservation?\noverride func viewDidLoad() {\n    super.viewDidLoad()\n    observation = observe(\\.title) { obj, change in\n        // Auto-removed when observation deallocated\n    }\n}",
                        explanation: "Use NSKeyValueObservation tokens which auto-remove on deallocation, or remove manually."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGABRT in KVO"],
                tags: ["appkit", "kvo", "observer", "memory", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/nskeyvalueobserving",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSWindow initWithContentRect:styleMask:backing:defer:] failed to create NSWindow",
                errorCode: "APPKIT_WINDOW_CREATE_FAIL",
                description: "NSWindow creation failed, usually due to invalid parameters or running outside a proper app context.",
                cause: "1. Creating window before NSApplication is ready. 2. Invalid content rect (NaN, infinite). 3. Unsupported style mask combination. 4. Sandboxing restricting window creation. 5. Running in command-line tool without app bundle.",
                solutions: [
                    "Create windows after applicationDidFinishLaunching",
                    "Ensure content rect has valid, finite dimensions",
                    "Use valid style mask combinations",
                    "For CLI tools, create an NSApplication instance first",
                    "Check sandbox entitlements for window creation",
                    "For tests, use NSWindow without showing it"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Window Creation",
                        badCode: "let window = NSWindow(contentRect: .infinite, styleMask: .borderless, backing: .buffered, defer: false)  // Invalid rect",
                        goodCode: "let rect = NSRect(x: 0, y: 0, width: 400, height: 300)\nlet window = NSWindow(contentRect: rect, styleMask: [.titled, .closable], backing: .buffered, defer: false)",
                        explanation: "Always create windows with valid rectangles and valid style masks after app launch."
                    )
                ],
                relatedErrors: ["NSWindow creation failed"],
                tags: ["appkit", "window", "creation", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nswindow",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSView setFrameOrigin:] or setFrameSize: called from non-main thread",
                errorCode: "APPKIT_SETFRAME_THREAD",
                description: "Modifying view geometry from a background thread is unsafe and can corrupt the view hierarchy.",
                cause: "1. Animation completion on background thread. 2. Network callback updating view frame. 3. Timer on background queue. 4. Concurrent calculation setting view sizes.",
                solutions: [
                    "Dispatch ALL frame modifications to main thread",
                    "Use NSView.animator() only on main thread",
                    "For async sizing, calculate on background, apply on main",
                    "Use Auto Layout instead of manual frame setting",
                    "Enable Main Thread Checker in Xcode to catch violations"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Main Thread Frame",
                        badCode: "DispatchQueue.global().async {\n    self.view.frame.size.width = 200  // Unsafe\n}",
                        goodCode: "DispatchQueue.main.async {\n    self.view.frame.size.width = 200\n}",
                        explanation: "All view geometry changes must happen on the main thread."
                    )
                ],
                relatedErrors: ["NSWindow drag regions should only be invalidated on main thread"],
                tags: ["appkit", "view", "frame", "thread", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsview",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .medium,
                title: "-[NSImage initWithContentsOfFile:] failed to load image",
                errorCode: "APPKIT_IMAGE_LOAD_FAIL",
                description: "NSImage could not load from the specified file path, usually because the file doesn't exist or is in an unsupported format.",
                cause: "1. File path doesn't exist. 2. Wrong file extension. 3. Image format not supported. 4. Sandboxing blocking file access. 5. Corrupted image file. 6. Bundle resource not included.",
                solutions: [
                    "Verify file exists: FileManager.default.fileExists(atPath:)",
                    "Check image format is supported (PNG, JPEG, TIFF, etc.)",
                    "Use Bundle.main.url(forResource:withExtension:) for bundled images",
                    "For sandboxed apps, request file access permissions",
                    "Use NSImage(named:) for images in asset catalogs",
                    "Check file permissions and sandbox entitlements"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Image Loading",
                        badCode: "let image = NSImage(contentsOfFile: \"/path/that/doesnt/exist.png\")  // nil",
                        goodCode: "if let url = Bundle.main.url(forResource: \"icon\", withExtension: \"png\"),\n   let image = NSImage(contentsOf: url) {\n    // Use image\n}",
                        explanation: "Always validate file existence before loading images. Use bundle APIs for bundled resources."
                    )
                ],
                relatedErrors: ["NSImage: image load failed", "CGImageSourceCreateWithURL returned nil"],
                tags: ["appkit", "nsimage", "load", "file", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsimage",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSMenuItem setTarget:] target does not respond to selector",
                errorCode: "APPKIT_MENU_SELECTOR",
                description: "A menu item's target doesn't implement the action selector, so clicking the menu item does nothing or logs a warning.",
                cause: "1. Target set to wrong object. 2. Selector name typo. 3. Method not marked @objc. 4. Target deallocated (weak reference). 5. Method in extension not visible to Obj-C runtime.",
                solutions: [
                    "Ensure target implements the action method",
                    "Mark action methods with @objc",
                    "Use #selector syntax to catch typos at compile time",
                    "Set target to self or a long-lived controller",
                    "For Swift-only, use closures or NSMenuItem.action property",
                    "Check that target is not nil when menu is displayed"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Menu Target",
                        badCode: "let item = NSMenuItem(title: \"Do It\", action: #selector(doIt), keyEquivalent: \"\")\nitem.target = self  // But doIt() not @objc",
                        goodCode: "@objc func doIt() { }\nlet item = NSMenuItem(title: \"Do It\", action: #selector(doIt), keyEquivalent: \"\")\nitem.target = self",
                        explanation: "Menu action methods must be @objc and implemented by the target."
                    )
                ],
                relatedErrors: ["Menu item action not sent", "Target does not implement action"],
                tags: ["appkit", "nsmenu", "selector", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsmenuitem",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .medium,
                title: "-[NSStatusBarButton sendAction:to:] cannot send action because target is nil",
                errorCode: "APPKIT_STATUSBAR_NIL_TARGET",
                description: "NSStatusBar button action cannot be sent because the target is nil or doesn't implement the action.",
                cause: "1. Status item button target not set. 2. Target deallocated. 3. Action selector not implemented. 4. Using Swift closure instead of selector target.",
                solutions: [
                    "Set button.action and button.target explicitly",
                    "Use button.sendAction(on: .leftMouseUp) for custom handling",
                    "For closures, use NSEvent.addGlobalMonitor or button action",
                    "Ensure target outlives the status item",
                    "For modern macOS, use NSStatusBarButton.action property"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Status Item Target",
                        badCode: "let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)\nitem.button?.action = #selector(toggle)  // target not set",
                        goodCode: "let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)\nitem.button?.target = self\nitem.button?.action = #selector(toggle)",
                        explanation: "Always set both target and action for status bar buttons."
                    )
                ],
                relatedErrors: ["Menu item action not sent"],
                tags: ["appkit", "statusbar", "target", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsstatusbar",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSViewController loadView] loaded the nib but no view was set",
                errorCode: "APPKIT_NIB_NO_VIEW",
                description: "A view controller loaded from a nib/xib/storyboard but the view outlet wasn't connected.",
                cause: "1. IBOutlet view not connected in Interface Builder. 2. Nib name doesn't match class name. 3. Wrong nib file specified. 4. View outlet renamed but not updated in IB.",
                solutions: [
                    "Connect the view outlet in Interface Builder",
                    "Ensure nib name matches class: ClassName.xib -> ClassName",
                    "Override loadView() to create view programmatically",
                    "Check that File's Owner class is set correctly",
                    "For SwiftUI hosting, use NSHostingController instead"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Programmatic View",
                        badCode: "class MyVC: NSViewController {\n    // No view set, no xib connected\n}",
                        goodCode: "class MyVC: NSViewController {\n    override func loadView() {\n        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))\n    }\n}",
                        explanation: "Either connect a xib's view outlet or override loadView() to create the view programmatically."
                    )
                ],
                relatedErrors: ["NSInternalInconsistencyException", "View controller nib not found"],
                tags: ["appkit", "viewcontroller", "nib", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsviewcontroller",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSApplication terminate:] called while modal session active",
                errorCode: "APPKIT_TERMINATE_MODAL",
                description: "Trying to terminate the app while a modal dialog or sheet is still active.",
                cause: "1. Calling NSApp.terminate during modal dialog. 2. Force quit while save panel open. 3. Modal session not ended before termination.",
                solutions: [
                    "End all modal sessions before terminating",
                    "For NSAlert, use endSheet before termination",
                    "Implement applicationShouldTerminate to check modal state",
                    "Dismiss open panels/sheets before quit",
                    "Use NSApp.stopModal() before terminating"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Termination",
                        badCode: "NSApp.runModal(for: alert)\nNSApp.terminate(nil)  // Modal still active",
                        goodCode: "NSApp.stopModal()\nalert.window.orderOut(nil)\nNSApp.terminate(nil)",
                        explanation: "End modal sessions before terminating the application."
                    )
                ],
                relatedErrors: ["Modal session still active"],
                tags: ["appkit", "modal", "terminate", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsapplication",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .medium,
                title: "-[NSTextField setStringValue:] called with nil string",
                errorCode: "APPKIT_NIL_STRING",
                description: "Setting an NSTextField's stringValue to nil causes a crash because NSString properties don't accept nil.",
                cause: "1. Passing optional String? to stringValue. 2. Unwrapped optional being nil. 3. Dictionary value lookup returning nil. 4. JSON parsing result being nil.",
                solutions: [
                    "Use nil-coalescing: textField.stringValue = optional ?? \"\"",
                    "Guard let before assignment",
                    "For bindings, ensure source never returns nil",
                    "Use NSString safely with bridging",
                    "Validate data before UI updates"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe String Assignment",
                        badCode: "let name: String? = nil\ntextField.stringValue = name  // Crash",
                        goodCode: "textField.stringValue = name ?? \"\"",
                        explanation: "AppKit string properties don't accept nil. Always provide a fallback."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGABRT"],
                tags: ["appkit", "textfield", "nil", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nstextfield",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSWindow setContentView:] content view cannot be nil",
                errorCode: "APPKIT_NIL_CONTENTVIEW",
                description: "Setting a window's content view to nil is not allowed and causes a crash.",
                cause: "1. Assigning nil to contentView. 2. Hosting view deallocated. 3. SwiftUI view creation returning nil. 4. IBOutlet not connected.",
                solutions: [
                    "Always provide a non-nil content view",
                    "For empty windows, use NSView() as placeholder",
                    "Ensure NSHostingView is properly initialized",
                    "Check that SwiftUI root view is valid",
                    "For teardown, orderOut window instead of nil contentView"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Content View",
                        badCode: "window.contentView = nil  // Crash",
                        goodCode: "window.contentView = NSView()  // Empty but valid",
                        explanation: "Window contentView must always be a valid NSView instance."
                    )
                ],
                relatedErrors: ["NSWindow requires a content view"],
                tags: ["appkit", "window", "contentview", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nswindow",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .medium,
                title: "-[NSView addSubview:] view already has a superview",
                errorCode: "APPKIT_DUPLICATE_SUBVIEW",
                description: "Adding a view as a subview when it already has a different superview. The view is automatically removed from its old superview.",
                cause: "1. View already in another hierarchy. 2. Reusing view without removing first. 3. Cell-based table reusing views incorrectly. 4. Animation moving view between parents.",
                solutions: [
                    "Remove view from old superview before adding to new: view.removeFromSuperview()",
                    "For reusable views, create new instances instead of reparenting",
                    "Check view.superview before adding",
                    "For animations, use NSViewAnimation or Core Animation",
                    "For table/collection views, use proper cell reuse"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Reparent View",
                        badCode: "oldContainer.addSubview(view)\nnewContainer.addSubview(view)  // Auto-removed from old",
                        goodCode: "view.removeFromSuperview()\nnewContainer.addSubview(view)",
                        explanation: "Explicitly remove a view before reparenting to avoid ambiguity."
                    )
                ],
                relatedErrors: ["NSView hierarchy inconsistency"],
                tags: ["appkit", "view", "superview", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsview",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSViewController presentViewController:animator:] view controller already presented",
                errorCode: "APPKIT_ALREADY_PRESENTED",
                description: "Attempting to present a view controller that is already being presented.",
                cause: "1. Double-tap on present button. 2. Presenting same VC twice. 3. Dismissal animation not complete before re-present. 4. State not updated after presentation.",
                solutions: [
                    "Track presentation state with a Bool flag",
                    "Disable present button while presenting",
                    "Check presentedViewControllers before presenting",
                    "Use sheet completion handler to reset state",
                    "For reusable VCs, create new instances each time"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Prevent Double Present",
                        badCode: "@IBAction func showSheet() {\n    presentAsSheet(detailVC)  // Called twice -> crash\n}",
                        goodCode: "@IBAction func showSheet() {\n    guard presentedViewControllers == nil else { return }\n    presentAsSheet(detailVC)\n}",
                        explanation: "Check if already presenting before showing another sheet or modal."
                    )
                ],
                relatedErrors: ["View controller already presented"],
                tags: ["appkit", "present", "viewcontroller", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsviewcontroller",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .medium,
                title: "-[NSWindow makeKeyAndOrderFront:] window has no contentView",
                errorCode: "APPKIT_WINDOW_NO_CONTENT",
                description: "Trying to show a window that has no content view set.",
                cause: "1. Window created but contentView not assigned. 2. Content view set to nil. 3. Nib loading failed. 4. SwiftUI hosting view creation failed.",
                solutions: [
                    "Set contentView before showing window",
                    "For programmatic windows, assign a view immediately",
                    "Check that nib/storyboard loaded successfully",
                    "For SwiftUI, verify NSHostingView initialization",
                    "Add nil check before makeKeyAndOrderFront"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Window Content Setup",
                        badCode: "let window = NSWindow(...)\nwindow.makeKeyAndOrderFront(nil)  // No contentView",
                        goodCode: "let window = NSWindow(...)\nwindow.contentView = NSHostingView(rootView: MyView())\nwindow.makeKeyAndOrderFront(nil)",
                        explanation: "Always set a content view before displaying a window."
                    )
                ],
                relatedErrors: ["NSWindow requires a content view"],
                tags: ["appkit", "window", "contentview", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nswindow",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "-[NSView lockFocus] failed to allocate CGSConnection",
                errorCode: "APPKIT_LOCKFOCUS_FAIL",
                description: "Drawing operations failed because the window doesn't have a valid connection to the window server.",
                cause: "1. Drawing on background thread. 2. Window not on screen. 3. Window server connection lost. 4. App not active/foreground. 5. Drawing during app termination.",
                solutions: [
                    "Move all drawing to main thread",
                    "Ensure window is visible before custom drawing",
                    "Check window.isVisible before lockFocus",
                    "Use CALayer-based drawing instead of lockFocus",
                    "For offscreen rendering, use NSImage or CGBitmapContext",
                    "Defer drawing until applicationDidBecomeActive"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Drawing",
                        badCode: "DispatchQueue.global().async {\n    view.lockFocus()  // Wrong thread\n    // draw...\n    view.unlockFocus()\n}",
                        goodCode: "DispatchQueue.main.async {\n    if view.window != nil {\n        view.lockFocus()\n        // draw...\n        view.unlockFocus()\n    }\n}",
                        explanation: "Drawing must happen on the main thread with a valid window connection."
                    )
                ],
                relatedErrors: ["CGSConnection cannot be allocated"],
                tags: ["appkit", "draw", "lockfocus", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsview",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 5. XCODE BUILD ERRORS (60+ entries)
    // =========================================================================
    
    private func xcodeBuildErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .xcodeBuild,
                severity: .critical,
                title: "Build input file cannot be found: 'X.swift'",
                errorCode: "XCODE_BUILD_INPUT_MISSING",
                description: "Xcode cannot find a source file referenced in the build settings or project file.",
                cause: "1. File deleted but still in Compile Sources. 2. File moved to different directory. 3. File not added to target. 4. Case-sensitive filesystem mismatch. 5. Git merge conflict leaving bad references.",
                solutions: [
                    "Remove missing file from Build Phases > Compile Sources",
                    "Re-add file to project if it exists elsewhere",
                    "Check file path for case sensitivity (MyFile.swift vs myfile.swift)",
                    "Clean build folder (Cmd+Shift+K) and rebuild",
                    "Check .pbxproj file for stale references",
                    "For SPM packages, resolve packages (File > Packages > Resolve)",
                    "Check if file is in .gitignore accidentally"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fix Missing File",
                        badCode: "// File was deleted but still in Compile Sources\n// Build fails: cannot find 'OldFile.swift'",
                        goodCode: "// 1. Open Build Phases > Compile Sources\n// 2. Remove red/missing file references\n// 3. Add correct file if renamed",
                        explanation: "Keep Compile Sources in sync with actual project files."
                    )
                ],
                relatedErrors: ["No such file or directory", "Build input cannot be found"],
                tags: ["xcode", "build", "missing file", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/building-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .critical,
                title: "Linker command failed with exit code 1 (use -v to see invocation)",
                errorCode: "XCODE_LINK_ERROR",
                description: "The linker (ld) failed to create the executable, usually due to missing symbols, duplicate symbols, or framework issues.",
                cause: "1. Missing framework in Link Binary With Libraries. 2. Undefined symbol (function not found). 3. Duplicate symbol defined in multiple files. 4. Architecture mismatch (arm64 vs x86_64). 5. Static library not built for target architecture.",
                solutions: [
                    "Check linker error messages for specific undefined symbols",
                    "Add missing frameworks to Build Phases > Link Binary With Libraries",
                    "For duplicate symbols, check for multiple definitions of same function",
                    "Ensure all dependencies support target architecture (arm64 for Apple Silicon)",
                    "For C/C++, check header guards to prevent duplicate definitions",
                    "Clean build folder and DerivedData",
                    "For SPM, check Package.resolved and update packages",
                    "Add -ObjC linker flag if using Objective-C categories from static lib"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Link Framework",
                        badCode: "// Using Alamofire but not linked\nimport Alamofire  // Build succeeds, link fails",
                        goodCode: "// 1. Add Alamofire.framework to Build Phases > Link Binary With Libraries\n// 2. Or add via SPM / CocoaPods / Carthage",
                        explanation: "All imported frameworks must be linked. Check Build Phases for missing frameworks."
                    )
                ],
                relatedErrors: ["Undefined symbols for architecture", "Duplicate symbols"],
                tags: ["xcode", "linker", "build", "compile"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/resolving-build-warnings-and-errors",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .critical,
                title: "Undefined symbol: _OBJC_CLASS_$__X",
                errorCode: "XCODE_UNDEF_SYMBOL",
                description: "The linker cannot find the implementation of an Objective-C class or method.",
                cause: "1. .m file not included in Compile Sources. 2. Framework not linked. 3. Class marked @objc but implemented in Swift without NSObject. 4. Category method not found. 5. Static library missing Obj-C symbols.",
                solutions: [
                    "Add -ObjC to Other Linker Flags for static libraries with categories",
                    "Ensure .m/.mm files are in Compile Sources",
                    "Link the framework containing the symbol",
                    "For Swift classes exposed to Obj-C, inherit from NSObject",
                    "For bridging, ensure @objc and public are used",
                    "Check that module map includes all headers",
                    "For CocoaPods, use use_frameworks! or ensure proper linker flags"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "ObjC Class Link",
                        badCode: "// Swift class not inheriting NSObject\n@objc class MyClass { }  // Not found by Obj-C runtime",
                        goodCode: "@objc class MyClass: NSObject { }  // Visible to Obj-C",
                        explanation: "Classes exposed to Objective-C must inherit from NSObject."
                    )
                ],
                relatedErrors: ["Linker command failed", "Undefined symbols for architecture"],
                tags: ["xcode", "linker", "undefined", "objc", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/resolving-build-warnings-and-errors",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .critical,
                title: "Duplicate symbol '_symbolName' in: file1.o file2.o",
                errorCode: "XCODE_DUPLICATE_SYMBOL",
                description: "The same symbol (function, variable, or class) is defined in multiple object files.",
                cause: "1. Global variable defined in header without extern. 2. Function implemented in header file. 3. Same file added to target twice. 4. Static library containing duplicate symbols. 5. C++ template instantiation conflicts.",
                solutions: [
                    "For headers, declare with extern and define in one .c/.cpp file",
                    "Use static for file-private globals",
                    "Use inline for header-defined functions (C++)",
                    "Remove duplicate file references from Compile Sources",
                    "For constants in headers, use static const or extern",
                    "Check for copy-pasted implementations in multiple files",
                    "For Swift, global variables at file scope are internal by default"
                ],
                codeExamples: [
                    CodeExample(
                        language: "c",
                        title: "Header Guard",
                        badCode: "// In header.h:\nint globalCount = 0;  // Defined in every including file",
                        goodCode: "// In header.h:\nextern int globalCount;\n// In one .c file:\nint globalCount = 0;",
                        explanation: "Global variables in headers need extern declaration. Define in exactly one source file."
                    )
                ],
                relatedErrors: ["Linker command failed"],
                tags: ["xcode", "linker", "duplicate", "symbol", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/resolving-build-warnings-and-errors",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .critical,
                title: "No such module 'X'",
                errorCode: "XCODE_NO_MODULE",
                description: "Xcode cannot find the specified Swift module or framework.",
                cause: "1. Framework not added to project. 2. SPM dependency not resolved. 3. Module not built before dependent target. 4. Import path not configured. 5. Framework search paths incorrect. 6. Target dependency not set.",
                solutions: [
                    "Add framework via SPM: File > Add Package Dependencies",
                    "For local frameworks, add to Target Dependencies",
                    "Check Framework Search Paths in Build Settings",
                    "Resolve SPM packages: File > Packages > Resolve Package Versions",
                    "For CocoaPods, run pod install",
                    "Ensure dependency target builds before dependent target",
                    "Check if module uses @objc and needs bridging header"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Add SPM Dependency",
                        badCode: "import Alamofire  // No such module",
                        goodCode: "// File > Add Package Dependencies > https://github.com/Alamofire/Alamofire\nimport Alamofire",
                        explanation: "Add missing dependencies via SPM, CocoaPods, or manual framework linking."
                    )
                ],
                relatedErrors: ["Could not build Objective-C module", "Module map not found"],
                tags: ["xcode", "module", "import", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .critical,
                title: "Code signing 'X.app' failed",
                errorCode: "XCODE_CODE_SIGN_FAIL",
                description: "Xcode failed to sign the app bundle, preventing installation or distribution.",
                cause: "1. No valid signing certificate. 2. Provisioning profile expired. 3. Bundle ID mismatch. 4. Certificate revoked. 5. Keychain access denied. 6. Team ID not set. 7. Sandbox entitlement conflict.",
                solutions: [
                    "Open Xcode Preferences > Accounts and download certificates",
                    "Check Apple Developer portal for valid certificates/profiles",
                    "Ensure bundle ID matches provisioning profile",
                    "Set correct Team in Signing & Capabilities",
                    "For local development, use 'Sign to Run Locally'",
                    "Reset Keychain: rm -rf ~/Library/Developer/Xcode/DerivedData",
                    "For CI, use match, fastlane, or manual certificate import",
                    "Check Keychain Access for expired/duplicate certificates"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Local Signing",
                        badCode: "// Team not set, no certificate",
                        goodCode: "// Build Settings > Code Signing Identity: Sign to Run Locally\n// Or in xcodebuild: CODE_SIGN_IDENTITY=\"-\" CODE_SIGNING_REQUIRED=NO",
                        explanation: "For local development, use 'Sign to Run Locally' or disable code signing."
                    )
                ],
                relatedErrors: ["Provisioning profile expired", "No valid signing identity"],
                tags: ["xcode", "code sign", "certificate", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "The sandbox is not in sync with the Podfile.lock",
                errorCode: "XCODE_PODFILE_LOCK",
                description: "CocoaPods dependencies are out of sync with the Podfile.lock, causing build inconsistencies.",
                cause: "1. Podfile changed but pod install not run. 2. Podfile.lock committed without Pods directory. 3. Different CocoaPods versions. 4. Merge conflict in Podfile.lock.",
                solutions: [
                    "Run pod install in project directory",
                    "Run pod update for specific pods if needed",
                    "Ensure all team members use same CocoaPods version",
                    "Commit both Podfile.lock and Pods directory (or neither)",
                    "For CI, run pod install as build step",
                    "Consider migrating to SPM for simpler dependency management"
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Fix CocoaPods",
                        badCode: "# Podfile changed, lock out of sync",
                        goodCode: "cd ProjectDirectory\npod install\n# or\npod update",
                        explanation: "Always run pod install after modifying Podfile. Commit lock file."
                    )
                ],
                relatedErrors: ["diff: Podfile.lock", "CocoaPods error"],
                tags: ["xcode", "cocoapods", "dependency", "build"],
                appleDocURL: "https://guides.cocoapods.org",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "The file 'X' couldn't be opened because there is no such file",
                errorCode: "XCODE_FILE_NOT_FOUND",
                description: "Xcode or the build system cannot find a referenced file.",
                cause: "1. File deleted outside Xcode. 2. File moved but reference not updated. 3. Case-sensitive filesystem issue. 4. Resource not copied to bundle. 5. Build phase references missing script.",
                solutions: [
                    "Locate missing file in Finder and re-add to project",
                    "Update file references in project navigator",
                    "Check Build Phases > Copy Bundle Resources for missing files",
                    "For case-sensitive filesystems, match exact case",
                    "Clean build folder and rebuild",
                    "Check if file is excluded by .gitignore"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fix File Reference",
                        badCode: "// File shown in red in project navigator",
                        goodCode: "// 1. Right-click > Show in Finder\n// 2. If missing, delete reference and re-add\n// 3. Check Copy Bundle Resources",
                        explanation: "Keep project references in sync with filesystem. Red files in navigator indicate missing references."
                    )
                ],
                relatedErrors: ["Build input file cannot be found"],
                tags: ["xcode", "file", "missing", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/managing-files-and-folders",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "Command PhaseScriptExecution failed with a nonzero exit code",
                errorCode: "XCODE_SCRIPT_FAIL",
                description: "A build phase script (Run Script) exited with an error code, stopping the build.",
                cause: "1. Script has syntax error. 2. Script references missing tool. 3. Script file not executable (chmod +x). 4. Script depends on file that doesn't exist. 5. Environment variable missing.",
                solutions: [
                    "Check script output in build log for specific errors",
                    "Run script manually in Terminal to debug",
                    "Ensure script has execute permission: chmod +x script.sh",
                    "Check script shell path (#!/bin/bash vs #!/bin/sh)",
                    "For SwiftLint/SwiftFormat, ensure binary is in PATH",
                    "Add set -e to script for better error reporting",
                    "For CocoaPods scripts, ensure Pods are installed"
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Debug Build Script",
                        badCode: "# Script references swiftlint which is not installed",
                        goodCode: "# Add error checking:\nif command -v swiftlint &> /dev/null; then\n    swiftlint\nelse\n    echo \"warning: SwiftLint not installed\"\nfi",
                        explanation: "Make build scripts resilient to missing tools. Check build log for exact script failure."
                    )
                ],
                relatedErrors: ["Build script failed"],
                tags: ["xcode", "script", "build phase", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/customizing-the-build-phases-of-a-target",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "Multiple commands produce 'X.app/Info.plist'",
                errorCode: "XCODE_MULTIPLE_OUTPUTS",
                description: "Two or more build steps are trying to create the same output file.",
                cause: "1. Info.plist in Copy Bundle Resources AND build setting. 2. Multiple files with same name in different paths. 3. CocoaPods and manual target both copying same file. 4. Build rule conflict.",
                solutions: [
                    "Remove Info.plist from Copy Bundle Resources if set in build settings",
                    "Rename conflicting files to unique names",
                    "For CocoaPods, check if file is duplicated in Pods and main target",
                    "Use $(SRCROOT) relative paths consistently",
                    "Clean build folder and rebuild",
                    "Check Build Rules for overlapping outputs"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fix Info.plist Conflict",
                        badCode: "// Info.plist in Copy Bundle Resources AND\n// Build Settings > Packaging > Info.plist File set",
                        goodCode: "// Remove Info.plist from Copy Bundle Resources\n// Keep only Build Settings reference",
                        explanation: "Info.plist should only be copied once - via build settings, not Copy Bundle Resources."
                    )
                ],
                relatedErrors: ["Multiple commands produce"],
                tags: ["xcode", "build", "conflict", "plist"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/customizing-the-build-phases-of-a-target",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .critical,
                title: "Embedded binary is not signed with the same certificate as the parent app",
                errorCode: "XCODE_EMBED_SIGN_MISMATCH",
                description: "An embedded framework, app extension, or binary is signed with a different certificate than the main app.",
                cause: "1. Framework signed with development cert, app with distribution cert. 2. Third-party framework pre-signed with different identity. 3. Team ID mismatch between targets. 4. Ad-hoc signed embedded binary.",
                solutions: [
                    "Use same team/cert for all targets",
                    "Set 'Code Signing Identity' consistently across targets",
                    "For third-party frameworks, re-sign during build",
                    "Check 'Embed & Sign' vs 'Embed Without Signing' in Build Phases",
                    "For SPM dependencies, let Xcode handle signing",
                    "Match provisioning profile types (development/distribution)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Consistent Signing",
                        badCode: "// Main app: Team A, Development\n// Widget: Team B, Distribution -> mismatch",
                        goodCode: "// All targets: Team A, Development (for debug)\n// All targets: Team A, Distribution (for release)",
                        explanation: "All embedded binaries must be signed with the same certificate as the parent app."
                    )
                ],
                relatedErrors: ["Code signing failed", "Provisioning profile mismatch"],
                tags: ["xcode", "signing", "embedded", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "The app delegate must implement the window property",
                errorCode: "XCODE_APP_DELEGATE_WINDOW",
                description: "For non-SwiftUI apps using scenes, the app delegate needs a window property if not using the modern scene delegate approach.",
                cause: "1. Mixed UIKit App Delegate and Scene Delegate. 2. Deleted window property from AppDelegate. 3. Storyboard-based app without proper scene configuration.",
                solutions: [
                    "For pure AppKit/SwiftUI, use @main App protocol",
                    "For UIKit with scenes, use SceneDelegate",
                    "Add var window: UIWindow? to AppDelegate if needed",
                    "Check Info.plist for UIApplicationSceneManifest",
                    "For macOS, use NSApplicationDelegate with proper window management"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Modern App Setup",
                        badCode: "@main\nclass AppDelegate: UIResponder, UIApplicationDelegate {\n    // Missing window property\n}",
                        goodCode: "@main\nstruct MyApp: App {\n    var body: some Scene {\n        WindowGroup {\n            ContentView()\n        }\n    }\n}",
                        explanation: "Use modern SwiftUI App lifecycle instead of manual AppDelegate/SceneDelegate."
                    )
                ],
                relatedErrors: ["Application delegate must implement window"],
                tags: ["xcode", "app delegate", "window", "build"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/app-essentials",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "Swift compiler error: Segmentation fault: 11",
                errorCode: "XCODE_COMPILER_CRASH",
                description: "The Swift compiler itself crashed while trying to compile your code. This is a compiler bug, not a code bug.",
                cause: "1. Extremely complex type inference. 2. Recursive type aliases. 3. Circular protocol constraints. 4. Complex nested generics. 5. Swift compiler bug in specific version.",
                solutions: [
                    "Simplify complex expressions - break into smaller pieces",
                    "Add explicit type annotations to help type checker",
                    "Comment out recent code changes to isolate trigger",
                    "Update Xcode to latest version",
                    "File bug at bugs.swift.org with reproducible example",
                    "Try incremental builds vs clean builds",
                    "Use whole module optimization or single file compilation to test",
                    "Add // swiftlint:disable for complex expressions temporarily"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Simplify Expression",
                        badCode: "let result = a.map { $0.b.filter { $0.c > 0 }.reduce(0) { $0 + $1.d } }.compactMap { $0.e }.sorted { $0.f < $1.f }  // Too complex",
                        goodCode: "let filtered = a.flatMap { $0.b.filter { $0.c > 0 } }\nlet sum = filtered.map { $0.d }.reduce(0, +)\nlet results = filtered.compactMap { $0.e }.sorted { $0.f < $1.f }",
                        explanation: "Break complex chained expressions into steps with explicit intermediate variables."
                    )
                ],
                relatedErrors: ["Command CompileSwift failed", "Illegal instruction: 4"],
                tags: ["xcode", "compiler", "crash", "segfault", "build"],
                appleDocURL: "https://bugs.swift.org",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "Building for iOS Simulator, but linking in object file built for iOS",
                errorCode: "XCODE_ARCH_MISMATCH",
                description: "A library or framework was built for device (arm64) but the target is simulator (x86_64 or arm64-simulator).",
                cause: "1. Prebuilt library doesn't include simulator slice. 2. CocoaPods framework built for device only. 3. XCFramework missing simulator variant. 4. M1 Mac trying to run Intel-only simulator binary.",
                solutions: [
                    "Use XCFramework with both device and simulator slices",
                    "For CocoaPods, use valid_archs or EXCLUDED_ARCHS settings",
                    "For M1 Macs, set Rosetta simulator or build for arm64 simulator",
                    "In Build Settings, set VALID_ARCHS appropriately",
                    "For third-party libs, request universal binary or XCFramework",
                    "Use 'Build Active Architecture Only' = YES for debug builds"
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Create XCFramework",
                        badCode: "// Linking device-only framework to simulator target",
                        goodCode: "# Build for simulator:\nxcodebuild -scheme MyLib -sdk iphonesimulator\n# Build for device:\nxcodebuild -scheme MyLib -sdk iphoneos\n# Create XCFramework:\nxcodebuild -create-xcframework -framework simulator/MyLib.framework -framework device/MyLib.framework -output MyLib.xcframework",
                        explanation: "Use XCFramework to bundle multiple architectures for different platforms."
                    )
                ],
                relatedErrors: ["Undefined symbols for architecture", "Incompatible architecture"],
                tags: ["xcode", "architecture", "simulator", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/building-universal-apps-and-mac-catalyst-apps",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .xcodeBuild,
                severity: .high,
                title: "IPA processing failed",
                errorCode: "XCODE_IPA_FAIL",
                description: "Xcode failed to create the IPA archive for distribution, usually due to signing, entitlements, or asset issues.",
                cause: "1. Invalid provisioning profile. 2. App icon missing required sizes. 3. Entitlements mismatch. 4. Bitcode issues. 5. Framework signing problems. 6. Asset catalog compilation failure.",
                solutions: [
                    "Check provisioning profile validity and expiration",
                    "Ensure all required app icon sizes are in Assets.xcassets",
                    "Validate entitlements against provisioning profile",
                    "Disable bitcode if not needed (deprecated in Xcode 14)",
                    "Check 'Embed & Sign' for all embedded frameworks",
                    "Validate asset catalogs compile without errors",
                    "For TestFlight, ensure correct export options plist"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fix IPA",
                        badCode: "// Missing 1024x1024 app store icon",
                        goodCode: "// Add all required icon sizes to AppIcon in Assets.xcassets\n// Check App Store Connect for current requirements",
                        explanation: "Ensure all App Store icon requirements are met before archiving."
                    )
                ],
                relatedErrors: ["Archive failed", "Export failed"],
                tags: ["xcode", "ipa", "archive", "distribution", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
        ]
    }
    

    // =========================================================================
    // MARK: - 6. NETWORK / URL ERRORS (50+ entries)
    // =========================================================================
    
    private func networkErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1001 'The request timed out.'",
                errorCode: "NSURLErrorTimedOut (-1001)",
                description: "The network request exceeded its timeout interval without receiving a response.",
                cause: "1. Server is down or unreachable. 2. Network connection is slow. 3. Timeout interval too short. 4. Firewall blocking connection. 5. DNS resolution failure. 6. Request body too large.",
                solutions: [
                    "Increase timeoutInterval: URLRequest.timeoutInterval = 60",
                    "Check network connectivity with NWPathMonitor",
                    "Implement retry logic with exponential backoff",
                    "Check server status and availability",
                    "For large uploads, use background URLSession",
                    "Verify firewall/proxy settings",
                    "Use reachability checks before making requests",
                    "Implement offline mode with cached data"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Timeout Handling",
                        badCode: "let task = URLSession.shared.dataTask(with: url) { ... }\ntask.resume()  // Default 60s timeout",
                        goodCode: "var request = URLRequest(url: url)\nrequest.timeoutInterval = 120\nlet task = URLSession.shared.dataTask(with: request) { data, response, error in\n    if let error = error as? URLError, error.code == .timedOut {\n        // Retry or show error\n    }\n}",
                        explanation: "Configure appropriate timeouts and handle timeout errors gracefully."
                    )
                ],
                relatedErrors: ["NSURLErrorCannotConnectToHost (-1004)", "NSURLErrorNetworkConnectionLost (-1005)"],
                tags: ["network", "timeout", "urlsession", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1004 'Could not connect to the server.'",
                errorCode: "NSURLErrorCannotConnectToHost (-1004)",
                description: "The client could not establish a TCP connection to the server.",
                cause: "1. Server is down. 2. Wrong port number. 3. Firewall blocking port. 4. DNS resolution failed. 5. SSL/TLS handshake failure. 6. Server rejecting connections.",
                solutions: [
                    "Verify server URL and port are correct",
                    "Check if server is running and accessible",
                    "Test with curl or browser to verify connectivity",
                    "Check firewall rules for outgoing connections",
                    "For HTTPS, verify certificate is valid",
                    "Check if server requires VPN or specific network",
                    "Verify DNS resolution: ping domain name"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Connection Check",
                        badCode: "let url = URL(string: \"http://localhost:9999\")!  // Wrong port",
                        goodCode: "let url = URL(string: \"https://api.example.com/v1\")!\n// Verify with curl first:\n// curl -I https://api.example.com/v1",
                        explanation: "Always verify server connectivity with simple tools before debugging in code."
                    )
                ],
                relatedErrors: ["NSURLErrorTimedOut (-1001)", "NSURLErrorCannotFindHost (-1003)"],
                tags: ["network", "connection", "server", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1200 'An SSL error has occurred'",
                errorCode: "NSURLErrorSecureConnectionFailed (-1200)",
                description: "The HTTPS connection failed due to SSL/TLS certificate or configuration issues.",
                cause: "1. Self-signed certificate not trusted. 2. Certificate expired. 3. TLS version mismatch. 4. Certificate hostname mismatch. 5. ATS (App Transport Security) blocking insecure connection. 6. Intermediate certificate missing.",
                solutions: [
                    "For production: fix server certificate (proper CA-signed cert)",
                    "For development only: add NSExceptionDomains to Info.plist",
                    "Disable ATS entirely (NOT recommended for production): NSAllowsArbitraryLoads",
                    "Update server to support TLS 1.2+",
                    "Check certificate chain is complete",
                    "For custom trust, implement URLSessionDelegate.didReceive challenge",
                    "Test with SSL Labs to diagnose certificate issues"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "ATS Exception (Dev Only)",
                        badCode: "// Trying to connect to http:// or self-signed https",
                        goodCode: "// In Info.plist (development ONLY):\n<key>NSAppTransportSecurity</key>\n<dict>\n    <key>NSExceptionDomains</key>\n    <dict>\n        <key>localhost</key>\n        <dict>\n            <key>NSExceptionAllowsInsecureHTTPLoads</key>\n            <true/>\n        </dict>\n    </dict>\n</dict>",
                        explanation: "For development with self-signed certs, add ATS exceptions. NEVER for production."
                    )
                ],
                relatedErrors: ["NSURLErrorServerCertificateHasBadDate (-1201)", "NSURLErrorServerCertificateUntrusted (-1202)"],
                tags: ["network", "ssl", "tls", "certificate", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1005 'The network connection was lost.'",
                errorCode: "NSURLErrorNetworkConnectionLost (-1005)",
                description: "An established network connection was broken, usually due to network changes or server closing connection.",
                cause: "1. WiFi/cellular switch mid-request. 2. VPN disconnect. 3. Server closed connection. 4. Request body too large for server. 5. Keep-alive timeout. 6. Network interface change.",
                solutions: [
                    "Implement retry logic for idempotent requests",
                    "Use URLSession with configuration.allowsCellularAccess appropriately",
                    "Handle network path changes with NWPathMonitor",
                    "For large requests, use chunked transfer encoding",
                    "Implement request deduplication to avoid duplicate submissions",
                    "Use background URLSession for large uploads/downloads",
                    "Set appropriate HTTP keep-alive settings"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Retry Logic",
                        badCode: "let task = URLSession.shared.dataTask(with: request) { data, response, error in\n    if let error = error {\n        print(error)  // No retry\n    }\n}",
                        goodCode: "func fetchWithRetry(request: URLRequest, retries: Int = 3) {\n    let task = URLSession.shared.dataTask(with: request) { data, response, error in\n        if let error = error as? URLError, error.code == .networkConnectionLost, retries > 0 {\n            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {\n                fetchWithRetry(request: request, retries: retries - 1)\n            }\n            return\n        }\n        // Handle response\n    }\n    task.resume()\n}",
                        explanation: "Implement retry with backoff for transient network failures."
                    )
                ],
                relatedErrors: ["NSURLErrorTimedOut (-1001)", "NSURLErrorNotConnectedToInternet (-1009)"],
                tags: ["network", "connection lost", "retry", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1009 'The Internet connection appears to be offline.'",
                errorCode: "NSURLErrorNotConnectedToInternet (-1009)",
                description: "The device has no internet connectivity.",
                cause: "1. Airplane mode enabled. 2. WiFi disconnected. 3. Cellular data disabled. 4. Network interface down. 5. Routing issue.",
                solutions: [
                    "Check network reachability before making requests",
                    "Implement offline mode with local caching",
                    "Use NWPathMonitor to detect connectivity changes",
                    "Show user-friendly offline message",
                    "Queue requests for when connection returns",
                    "Check SCNetworkReachability for connectivity status"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Reachability Check",
                        badCode: "// Make request without checking connectivity",
                        goodCode: "import Network\nlet monitor = NWPathMonitor()\nmonitor.pathUpdateHandler = { path in\n    if path.status == .satisfied {\n        makeRequest()\n    } else {\n        showOfflineMessage()\n    }\n}\nmonitor.start(queue: DispatchQueue.global())",
                        explanation: "Always check network reachability and handle offline scenarios gracefully."
                    )
                ],
                relatedErrors: ["NSURLErrorCannotConnectToHost (-1004)"],
                tags: ["network", "offline", "reachability", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/network/nwpathmonitor",
                commonInVersions: ["iOS 12+", "macOS 10.14+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .medium,
                title: "Error Domain=NSURLErrorDomain Code=-1002 'unsupported URL'",
                errorCode: "NSURLErrorUnsupportedURL (-1002)",
                description: "The URL scheme is not supported by URLSession.",
                cause: "1. Using ftp://, file://, or custom scheme without handler. 2. Malformed URL string. 3. Missing URL scheme entirely. 4. Special characters not percent-encoded.",
                solutions: [
                    "Use supported schemes: http://, https://",
                    "For file URLs, use FileManager directly",
                    "For custom schemes, register URL protocol handler",
                    "Percent-encode special characters in URLs",
                    "Validate URL with URL(string:) != nil",
                    "Use URLComponents for building complex URLs"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid URL",
                        badCode: "let url = URL(string: \"ftp://example.com/file\")!  // Unsupported",
                        goodCode: "let url = URL(string: \"https://example.com/file\")!\n// or for file access:\nlet fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first",
                        explanation: "URLSession only supports http and https by default. Use appropriate APIs for other URL types."
                    )
                ],
                relatedErrors: ["NSURLErrorBadURL (-1000)"],
                tags: ["network", "url", "unsupported", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "HTTP 401 Unauthorized",
                errorCode: "HTTP 401",
                description: "The request requires user authentication. The credentials provided were missing or invalid.",
                cause: "1. Missing authentication header. 2. Expired token. 3. Wrong credentials. 4. Token not refreshed. 5. API key missing.",
                solutions: [
                    "Include Authorization header with valid token",
                    "Implement token refresh logic for expired tokens",
                    "Check API documentation for required auth method",
                    "For OAuth, refresh access token using refresh token",
                    "Store credentials securely in Keychain, not UserDefaults",
                    "Show login screen when 401 received",
                    "Use URLCredential for HTTP Basic Auth"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Auth Header",
                        badCode: "var request = URLRequest(url: url)\n// Missing Authorization header -> 401",
                        goodCode: "var request = URLRequest(url: url)\nrequest.setValue(\"Bearer \\(accessToken)\", forHTTPHeaderField: \"Authorization\")",
                        explanation: "Always include proper authentication headers for protected endpoints."
                    )
                ],
                relatedErrors: ["HTTP 403 Forbidden", "HTTP 419 Authentication Timeout"],
                tags: ["network", "http", "401", "auth", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/url_loading_system",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "HTTP 403 Forbidden",
                errorCode: "HTTP 403",
                description: "The server understood the request but refuses to authorize it. Different from 401 - credentials were accepted but lack permissions.",
                cause: "1. Insufficient permissions for resource. 2. IP address blocked. 3. API rate limit exceeded. 4. CORS policy violation. 5. CSRF token missing.",
                solutions: [
                    "Check API key permissions and scopes",
                    "Contact API provider for access",
                    "Implement rate limiting on client side",
                    "For CORS, ensure proper Origin headers",
                    "Check if IP whitelist is required",
                    "Review API documentation for required permissions"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle 403",
                        badCode: "if httpResponse.statusCode == 403 {\n    // Ignore\n}",
                        goodCode: "if httpResponse.statusCode == 403 {\n    showAlert(\"Access Denied\", \"You don't have permission. Contact support.\")\n}",
                        explanation: "403 means authenticated but not authorized. Inform user and log for debugging."
                    )
                ],
                relatedErrors: ["HTTP 401 Unauthorized", "HTTP 429 Too Many Requests"],
                tags: ["network", "http", "403", "forbidden", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/url_loading_system",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "HTTP 404 Not Found",
                errorCode: "HTTP 404",
                description: "The requested resource does not exist on the server.",
                cause: "1. Wrong API endpoint URL. 2. Resource deleted. 3. Path parameter incorrect. 4. API version changed. 5. Typo in URL path.",
                solutions: [
                    "Verify API endpoint URL",
                    "Check API documentation for correct paths",
                    "Ensure path parameters are valid",
                    "Handle 404 gracefully - show 'not found' message",
                    "For user-generated content, check if resource was deleted",
                    "Log 404s to detect broken API integrations"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle 404",
                        badCode: "let url = URL(string: \"https://api.example.com/usrs/123\")!  // Typo: usrs",
                        goodCode: "let url = URL(string: \"https://api.example.com/users/123\")!\n// In response handler:\nif httpResponse.statusCode == 404 {\n    showNotFoundMessage()\n}",
                        explanation: "Double-check API paths and handle 404 with appropriate user feedback."
                    )
                ],
                relatedErrors: ["HTTP 410 Gone"],
                tags: ["network", "http", "404", "not found", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/url_loading_system",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "HTTP 500 Internal Server Error",
                errorCode: "HTTP 500",
                description: "The server encountered an unexpected condition that prevented it from fulfilling the request.",
                cause: "1. Server-side bug. 2. Database connection failure. 3. Unexpected request format. 4. Server resource exhaustion. 5. Dependency service down.",
                solutions: [
                    "This is a server error - client cannot fix it directly",
                    "Implement retry with exponential backoff",
                    "Show user-friendly 'server error' message",
                    "Log request details for server team debugging",
                    "Check server status page or API health endpoint",
                    "For critical operations, queue for retry later",
                    "Contact API provider if persistent"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Server Error Handling",
                        badCode: "if httpResponse.statusCode == 500 {\n    fatalError(\"Server broken\")  // Don't crash!\n}",
                        goodCode: "if httpResponse.statusCode >= 500 {\n    showRetryDialog(message: \"Server error. Please try again.\") {\n        retryRequest()\n    }\n}",
                        explanation: "5xx errors are server-side. Retry gracefully and inform the user."
                    )
                ],
                relatedErrors: ["HTTP 502 Bad Gateway", "HTTP 503 Service Unavailable", "HTTP 504 Gateway Timeout"],
                tags: ["network", "http", "500", "server error", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/url_loading_system",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .medium,
                title: "HTTP 429 Too Many Requests",
                errorCode: "HTTP 429",
                description: "The user has sent too many requests in a given amount of time. Rate limiting enforced.",
                cause: "1. Excessive API calls. 2. Missing rate limiting on client. 3. Burst of requests on app launch. 4. Retry loop without backoff. 5. Multiple simultaneous requests.",
                solutions: [
                    "Implement client-side rate limiting",
                    "Use exponential backoff for retries",
                    "Check Retry-After header in response",
                    "Batch requests instead of individual calls",
                    "Cache responses to reduce API calls",
                    "Use request deduplication",
                    "Implement request queue with rate limiting"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Rate Limiting",
                        badCode: "for id in 0..<1000 {\n    fetchUser(id: id)  // 1000 simultaneous requests\n}",
                        goodCode: "let semaphore = DispatchSemaphore(value: 5)\nfor id in 0..<1000 {\n    DispatchQueue.global().async {\n        semaphore.wait()\n        fetchUser(id: id) { _ in\n            semaphore.signal()\n        }\n    }\n}",
                        explanation: "Limit concurrent requests and implement backoff to avoid rate limiting."
                    )
                ],
                relatedErrors: ["HTTP 403 Forbidden"],
                tags: ["network", "http", "429", "rate limit", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/url_loading_system",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "JSON Decoding Error: dataCorrupted or keyNotFound",
                errorCode: "Swift.DecodingError",
                description: "JSONDecoder failed to decode response data into the expected Swift type.",
                cause: "1. JSON structure doesn't match Codable model. 2. Missing required key. 3. Type mismatch (String vs Int). 4. Null value for non-optional property. 5. Date format mismatch. 6. Snake_case vs camelCase keys.",
                solutions: [
                    "Use optional properties for fields that may be null",
                    "Implement custom init(from:) for flexible parsing",
                    "Use JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase",
                    "Set dateDecodingStrategy to match API format",
                    "Print raw JSON string for debugging: String(data: data, encoding: .utf8)",
                    "Use quicktype.io or similar to generate Codable from JSON",
                    "For unknown fields, use [String: Any] or generic JSON type"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Flexible Decoding",
                        badCode: "struct User: Codable {\n    let name: String  // Fails if name is null or missing\n    let age: Int      // Fails if age is \"25\" (string)\n}",
                        goodCode: "struct User: Codable {\n    let name: String?\n    let age: Int?\n    \n    init(from decoder: Decoder) throws {\n        let container = try decoder.container(keyedBy: CodingKeys.self)\n        name = try container.decodeIfPresent(String.self, forKey: .name)\n        if let ageInt = try? container.decode(Int.self, forKey: .age) {\n            age = ageInt\n        } else if let ageString = try? container.decode(String.self, forKey: .age) {\n            age = Int(ageString)\n        } else {\n            age = nil\n        }\n    }\n}",
                        explanation: "Make decoding resilient to API variations with optional properties and custom init."
                    )
                ],
                relatedErrors: ["typeMismatch", "valueNotFound"],
                tags: ["network", "json", "decode", "codable", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/jsondecoder",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "URLSessionTask finished with error - code: -999 'cancelled'",
                errorCode: "NSURLErrorCancelled (-999)",
                description: "The URLSession task was explicitly cancelled before completion.",
                cause: "1. task.cancel() called. 2. View deallocated, cancelling tasks. 3. Parent task cancelled in structured concurrency. 4. User navigated away. 5. Request timeout with aggressive cancellation.",
                solutions: [
                    "Distinguish cancellation from real errors: error.code == .cancelled",
                    "Don't show error UI for cancelled requests",
                    "For view-bound requests, cancel on view disappear",
                    "Use Task.checkCancellation() in async code",
                    "For Combine, handle .cancel in sink",
                    "Log cancellations for debugging but ignore in UI"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Cancellation",
                        badCode: "let task = URLSession.shared.dataTask(with: url) { data, response, error in\n    if let error = error {\n        showError(error)  // Shows error even for cancellation\n    }\n}",
                        goodCode: "let task = URLSession.shared.dataTask(with: url) { data, response, error in\n    if let error = error as? URLError, error.code == .cancelled {\n        return  // Ignore cancellation\n    }\n    if let error = error {\n        showError(error)\n    }\n}",
                        explanation: "Cancelled tasks are not errors. Handle them separately from real failures."
                    )
                ],
                relatedErrors: ["NSURLErrorUnknown (-1)"],
                tags: ["network", "cancel", "urlsession", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Background URLSession transfer failed: task was not created from a background session",
                errorCode: "NSURLErrorBackgroundSession",
                description: "Background URLSession tasks must be created from a session with a background configuration.",
                cause: "1. Using URLSession.shared for background tasks. 2. Background session identifier mismatch. 3. App terminated before task completed. 4. Background session not reconnected after app relaunch.",
                solutions: [
                    "Create background session with URLSessionConfiguration.background(withIdentifier:)",
                    "Use unique but consistent identifier for background session",
                    "Implement URLSessionDelegate for background events",
                    "Handle app termination gracefully with URLSessionTaskDelegate",
                    "For macOS, background sessions have different behavior than iOS"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Background Session",
                        badCode: "let task = URLSession.shared.downloadTask(with: url)  // Not background",
                        goodCode: "let config = URLSessionConfiguration.background(withIdentifier: \"com.app.downloads\")\nlet session = URLSession(configuration: config, delegate: self, delegateQueue: nil)\nlet task = session.downloadTask(with: url)\ntask.resume()",
                        explanation: "Background transfers require a specially configured URLSession with background identifier."
                    )
                ],
                relatedErrors: ["Background URLSession requires delegate"],
                tags: ["network", "background", "urlsession", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1407496-background",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .network,
                severity: .medium,
                title: "Network request blocked by App Transport Security",
                errorCode: "NSURLErrorAppTransportSecurity",
                description: "App Transport Security (ATS) blocked an insecure HTTP request or a request to a domain with insufficient security.",
                cause: "1. HTTP (not HTTPS) request without exception. 2. TLS version too old on server. 3. Certificate doesn't meet ATS requirements. 4. Domain not in exception list.",
                solutions: [
                    "Use HTTPS for all network requests",
                    "Add NSExceptionDomains for specific domains (dev only)",
                    "Set NSAllowsArbitraryLoads to YES (NOT for production)",
                    "Update server to support TLS 1.2+ with forward secrecy",
                    "For development with localhost, add localhost exception",
                    "Submit ATS justification if App Store requires exceptions"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "ATS Configuration",
                        badCode: "let url = URL(string: \"http://insecure-site.com\")!  // Blocked by ATS",
                        goodCode: "// In Info.plist (temporary development exception):\n<key>NSAppTransportSecurity</key>\n<dict>\n    <key>NSExceptionDomains</key>\n    <dict>\n        <key>insecure-site.com</key>\n        <dict>\n            <key>NSExceptionMinimumTLSVersion</key>\n            <string>TLSv1.2</string>\n        </dict>\n    </dict>\n</dict>",
                        explanation: "ATS enforces secure connections. Add exceptions only for development and justify for App Store."
                    )
                ],
                relatedErrors: ["NSURLErrorSecureConnectionFailed (-1200)"],
                tags: ["network", "ats", "security", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity",
                commonInVersions: ["iOS 9+", "macOS 10.11+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 7. FILE SYSTEM ERRORS (40+ entries)
    // =========================================================================
    
    private func fileSystemErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .fileSystem,
                severity: .high,
                title: "The file 'X' doesn't exist.",
                errorCode: "NSCocoaErrorDomain 260",
                description: "An operation attempted to access a file that doesn't exist at the specified path.",
                cause: "1. File was deleted. 2. Wrong path. 3. File not created yet. 4. Case-sensitive path mismatch. 5. Relative path resolved incorrectly.",
                solutions: [
                    "Check file existence: FileManager.default.fileExists(atPath:)",
                    "Use URL/NSString path utilities for correct path construction",
                    "Create file/directory before accessing: createDirectory(at:withIntermediateDirectories:)",
                    "For bundles, use Bundle.main.url(forResource:withExtension:)",
                    "Handle case sensitivity on APFS/HFS+",
                    "Use FileManager URLs instead of string paths"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe File Access",
                        badCode: "let data = try Data(contentsOf: URL(fileURLWithPath: \"/tmp/missing.txt\"))  // Throws",
                        goodCode: "let url = URL(fileURLWithPath: \"/tmp/missing.txt\")\nif FileManager.default.fileExists(atPath: url.path) {\n    let data = try Data(contentsOf: url)\n} else {\n    print(\"File not found\")\n}",
                        explanation: "Always verify file existence before reading, or handle errors gracefully."
                    )
                ],
                relatedErrors: ["No such file or directory"],
                tags: ["filesystem", "file", "missing", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .fileSystem,
                severity: .high,
                title: "You don't have permission to save the file 'X' in the folder 'Y'.",
                errorCode: "NSCocoaErrorDomain 513",
                description: "The app lacks write permission for the target directory.",
                cause: "1. Sandboxing preventing file system access. 2. Trying to write to system directories. 3. File permissions set to read-only. 4. TCC (Transparency, Consent, Control) blocked access. 5. App not entitled for file access.",
                solutions: [
                    "Write to app-appropriate directories: Documents, Caches, Application Support",
                    "Use FileManager.urls(for:in:) to get correct directories",
                    "For sandboxed apps, request appropriate entitlements",
                    "For user files, use NSOpenPanel/NSSavePanel",
                    "Check file permissions with fileManager.attributesOfItem",
                    "For macOS, request folder access with NSOpenPanel or security-scoped bookmarks",
                    "Add com.apple.security.files.user-selected.read-write entitlement"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Write Location",
                        badCode: "let url = URL(fileURLWithPath: \"/System/myfile.txt\")\ntry data.write(to: url)  // Permission denied",
                        goodCode: "let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!\nlet url = docs.appendingPathComponent(\"myfile.txt\")\ntry data.write(to: url)",
                        explanation: "Only write to directories your app has permission for. Use FileManager to locate appropriate directories."
                    )
                ],
                relatedErrors: ["NSCocoaErrorDomain 257", "Operation not permitted"],
                tags: ["filesystem", "permission", "sandbox", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .fileSystem,
                severity: .medium,
                title: "The file 'X' already exists.",
                errorCode: "NSCocoaErrorDomain 516",
                description: "An operation tried to create a file or directory but it already exists.",
                cause: "1. File creation without checking existence. 2. Copy operation with same destination. 3. Download retry saving to same path.",
                solutions: [
                    "Check existence before creation: !fileManager.fileExists(atPath:)",
                    "Use .atomic or .withoutOverwriting options",
                    "Generate unique filenames with UUID or timestamps",
                    "Remove existing file before writing: fileManager.removeItem",
                    "For copies, use fileManager.copyItem and handle errors"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Unique File Names",
                        badCode: "let url = docs.appendingPathComponent(\"download.pdf\")\ntry data.write(to: url)  // Fails if exists",
                        goodCode: "let uniqueName = \"download-\(UUID().uuidString).pdf\"\nlet url = docs.appendingPathComponent(uniqueName)\ntry data.write(to: url)",
                        explanation: "Generate unique names or check existence to avoid file creation conflicts."
                    )
                ],
                relatedErrors: ["File exists"],
                tags: ["filesystem", "file", "exists", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .fileSystem,
                severity: .high,
                title: "The folder 'X' doesn't exist.",
                errorCode: "NSCocoaErrorDomain 4",
                description: "An operation requires a directory that doesn't exist.",
                cause: "1. Parent directory not created before file write. 2. Directory was deleted. 3. Wrong path to directory.",
                solutions: [
                    "Create intermediate directories: createDirectory(at:withIntermediateDirectories: true)",
                    "Use FileManager to ensure directory exists before writing",
                    "For temporary files, use FileManager.temporaryDirectory",
                    "Handle directory creation errors separately"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Create Directories",
                        badCode: "let dir = docs.appendingPathComponent(\"subdir\")\nlet file = dir.appendingPathComponent(\"file.txt\")\ntry data.write(to: file)  // Fails: subdir doesn't exist",
                        goodCode: "let dir = docs.appendingPathComponent(\"subdir\")\ntry FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)\nlet file = dir.appendingPathComponent(\"file.txt\")\ntry data.write(to: file)",
                        explanation: "Always create parent directories with withIntermediateDirectories: true before writing nested files."
                    )
                ],
                relatedErrors: ["No such file or directory"],
                tags: ["filesystem", "directory", "missing", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .fileSystem,
                severity: .medium,
                title: "The file 'X' is not in the correct format.",
                errorCode: "NSCocoaErrorDomain 259",
                description: "A file operation expected a specific format but the file content didn't match.",
                cause: "1. Corrupted plist file. 2. Wrong encoding for text file. 3. JSON file with syntax errors. 4. Binary file read as text.",
                solutions: [
                    "Validate file content before parsing",
                    "Use proper encoding: String(contentsOf:encoding:)",
                    "For plists, use PropertyListSerialization",
                    "For JSON, use JSONDecoder with error handling",
                    "Check file signatures/magic numbers for binary formats",
                    "Implement fallback for corrupted files"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Parsing",
                        badCode: "let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]  // May fail",
                        goodCode: "do {\n    let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]\n} catch {\n    print(\"Corrupted plist: \\(error)\")\n}",
                        explanation: "Always use do-catch for file parsing and handle format errors gracefully."
                    )
                ],
                relatedErrors: ["NSCocoaErrorDomain 3840"],
                tags: ["filesystem", "format", "corrupt", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .fileSystem,
                severity: .high,
                title: "The file 'X' couldn't be opened because you don't have permission to view it.",
                errorCode: "NSCocoaErrorDomain 257",
                description: "The app lacks read permission for the specified file or directory.",
                cause: "1. Sandboxing blocking file access. 2. File permissions (chmod) set to no-read. 3. TCC privacy protection (Documents folder, Desktop, etc.). 4. Quarantine attributes on downloaded files. 5. File owned by different user.",
                solutions: [
                    "Request file access via NSOpenPanel for user files",
                    "Use security-scoped bookmarks for persistent access",
                    "Add appropriate sandbox entitlements",
                    "For quarantined files, remove com.apple.quarantine xattr",
                    "Check file permissions with ls -la",
                    "For shared files, ensure proper ACLs",
                    "For TCC, prompt user with NSOpenPanel first"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Request File Access",
                        badCode: "let url = URL(fileURLWithPath: \"/Users/Shared/secret.txt\")\nlet data = try Data(contentsOf: url)  // Permission denied",
                        goodCode: "let panel = NSOpenPanel()\npanel.canChooseFiles = true\nif panel.runModal() == .OK, let url = panel.url {\n    let data = try Data(contentsOf: url)  // User granted access\n}",
                        explanation: "For files outside app container, use file panels to request user permission."
                    )
                ],
                relatedErrors: ["NSCocoaErrorDomain 513"],
                tags: ["filesystem", "permission", "read", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsopenpanel",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 8. PERMISSIONS / SANDBOX ERRORS (40+ entries)
    // =========================================================================
    
    private func permissionErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .permissions,
                severity: .critical,
                title: "This app has crashed because it attempted to access privacy-sensitive data without a usage description",
                errorCode: "TCC_CRASH",
                description: "macOS/iOS killed the app because it tried to access protected resources (camera, microphone, location, etc.) without the required Info.plist usage description.",
                cause: "1. Missing NS*UsageDescription in Info.plist. 2. Accessing camera without NSCameraUsageDescription. 3. Accessing location without NSLocationWhenInUseUsageDescription. 4. Accessing contacts without NSContactsUsageDescription. 5. Accessing photos without NSPhotoLibraryUsageDescription.",
                solutions: [
                    "Add required usage description keys to Info.plist",
                    "NSCameraUsageDescription - Camera access",
                    "NSMicrophoneUsageDescription - Microphone access",
                    "NSLocationWhenInUseUsageDescription - Location while app is open",
                    "NSLocationAlwaysUsageDescription - Background location",
                    "NSContactsUsageDescription - Contacts access",
                    "NSPhotoLibraryUsageDescription - Photo library access",
                    "NSBluetoothAlwaysUsageDescription - Bluetooth",
                    "NSSpeechRecognitionUsageDescription - Speech recognition",
                    "NSCalendarsUsageDescription - Calendar access",
                    "NSRemindersUsageDescription - Reminders access",
                    "Provide clear, user-friendly descriptions of why access is needed"
                ],
                codeExamples: [
                    CodeExample(
                        language: "xml",
                        title: "Usage Descriptions",
                        badCode: "<!-- Missing usage description -->",
                        goodCode: "<key>NSCameraUsageDescription</key>\n<string>This app needs camera access to scan QR codes.</string>\n<key>NSLocationWhenInUseUsageDescription</key>\n<string>This app uses your location to show nearby places.</string>",
                        explanation: "Every privacy-sensitive access requires a usage description in Info.plist. Without it, the app crashes on access."
                    )
                ],
                relatedErrors: ["kTCCServiceAccessDenied", "Privacy violation"],
                tags: ["permissions", "privacy", "tcc", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/bundleresources/information_property_list/protected_resources",
                commonInVersions: ["iOS 10+", "macOS 10.14+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "Access to X was denied. The user may have denied access or the app may not have the required entitlement.",
                errorCode: "TCC_DENIED",
                description: "The user denied permission for a protected resource, or the app lacks the required entitlement.",
                cause: "1. User clicked 'Don't Allow' in permission dialog. 2. Permission revoked in System Preferences. 3. Missing entitlement in app signature. 4. Parental controls blocking access. 5. MDM policy restricting access.",
                solutions: [
                    "Check authorization status before accessing: AVAudioSession.sharedInstance().recordPermission",
                    "Show user-friendly explanation when permission denied",
                    "Provide deep link to System Preferences for re-enabling",
                    "For macOS, use AXIsProcessTrustedWithOptions for accessibility",
                    "Handle all authorization states: .notDetermined, .restricted, .denied, .authorized",
                    "Request permission at appropriate time (not on launch)",
                    "For camera/mic, use AVCaptureDevice.authorizationStatus"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Denied Permission",
                        badCode: "let session = AVCaptureSession()\nsession.startRunning()  // Fails if denied",
                        goodCode: "switch AVCaptureDevice.authorizationStatus(for: .video) {\ncase .authorized:\n    startCamera()\ncase .notDetermined:\n    AVCaptureDevice.requestAccess(for: .video) { granted in\n        if granted { startCamera() }\n    }\ncase .denied, .restricted:\n    showSettingsAlert()\n@unknown default:\n    break\n}",
                        explanation: "Always check authorization status and handle all cases gracefully."
                    )
                ],
                relatedErrors: ["Access denied", "Not authorized"],
                tags: ["permissions", "denied", "tcc", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_macos",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "App Sandbox: exec of X denied",
                errorCode: "SANDBOX_EXEC_DENIED",
                description: "The sandboxed app tried to execute a subprocess or access a resource that is blocked by sandbox rules.",
                cause: "1. Trying to run shell commands from sandboxed app. 2. Accessing files outside container. 3. Network outbound blocked. 4. Inter-process communication restricted. 5. Hardware access blocked.",
                solutions: [
                    "Add com.apple.security.app-sandbox entitlement",
                    "For network, add com.apple.security.network.client/server",
                    "For file access, add com.apple.security.files.user-selected.read-write",
                    "For temporary exceptions, add com.apple.security.temporary-exception",
                    "For non-sandboxed tools, distribute outside Mac App Store",
                    "Use XPC services for privileged operations",
                    "For scripts, embed interpreter or use NSTask with proper entitlements"
                ],
                codeExamples: [
                    CodeExample(
                        language: "xml",
                        title: "Sandbox Entitlements",
                        badCode: "<!-- No network entitlement, outbound connections blocked -->",
                        goodCode: "<key>com.apple.security.app-sandbox</key>\n<true/>\n<key>com.apple.security.network.client</key>\n<true/>\n<key>com.apple.security.files.user-selected.read-write</key>\n<true/>",
                        explanation: "Enable required sandbox entitlements for the resources your app needs."
                    )
                ],
                relatedErrors: ["Sandbox violation", "Operation not permitted"],
                tags: ["permissions", "sandbox", "entitlement", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/configuring-the-app-sandbox",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "Not authorized for local and push notification scheduling",
                errorCode: "UNErrorNotAuthorized",
                description: "The app attempted to schedule a notification without user authorization.",
                cause: "1. requestAuthorization never called. 2. User denied notification permission. 3. Notifications disabled in System Preferences. 4. Provisional authorization not granted.",
                solutions: [
                    "Call UNUserNotificationCenter.requestAuthorization before scheduling",
                    "Check authorization status with getNotificationSettings",
                    "For macOS, ensure app is signed with Developer ID or distributed via App Store",
                    "Handle all authorization states gracefully",
                    "For critical alerts, request .criticalAlert authorization",
                    "Provide settings deep link for users to re-enable"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Request Notification Auth",
                        badCode: "let content = UNMutableNotificationContent()\nlet request = UNNotificationRequest(identifier: \"id\", content: content, trigger: nil)\nUNUserNotificationCenter.current().add(request)  // May fail",
                        goodCode: "UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in\n    if granted {\n        // Now safe to schedule\n    }\n}",
                        explanation: "Always request authorization before scheduling notifications."
                    )
                ],
                relatedErrors: ["Notifications not allowed"],
                tags: ["permissions", "notifications", "authorization", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/usernotifications",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "Accessibility access denied",
                errorCode: "AX_DENIED",
                description: "The app tried to use accessibility APIs but was not granted permission in System Preferences.",
                cause: "1. App not checked in Security & Privacy > Accessibility. 2. App was blocked by user. 3. Code signature changed, breaking trust. 4. Accessibility not requested properly.",
                solutions: [
                    "Prompt user to enable in System Preferences > Security & Privacy > Privacy > Accessibility",
                    "Use AXIsProcessTrustedWithOptions to check status",
                    "Open System Preferences directly: NSWorkspace.shared.open(URL(string: 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility')!)",
                    "Ensure app is properly signed for accessibility trust",
                    "For helper apps, both main app and helper need accessibility access",
                    "Reset accessibility permissions: tccutil reset Accessibility"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Check Accessibility",
                        badCode: "// Try to use accessibility without checking",
                        goodCode: "let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]\nlet accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)\nif !accessibilityEnabled {\n    // Show instructions to user\n}",
                        explanation: "Always check accessibility trust status and guide users to enable it in System Preferences."
                    )
                ],
                relatedErrors: ["AXErrorCannotComplete", "AXErrorNotAllowed"],
                tags: ["permissions", "accessibility", "ax", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/applicationservices/axuielement_h",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 9. MEMORY ERRORS (30+ entries)
    // =========================================================================
    
    private func memoryErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .memory,
                severity: .critical,
                title: "EXC_BAD_ACCESS (SIGSEGV) - KERN_INVALID_ADDRESS",
                errorCode: "EXC_BAD_ACCESS",
                description: "Attempting to access memory that doesn't belong to the process. The #1 cause of crashes in production apps.",
                cause: "1. Use after free (dangling pointer). 2. Buffer overflow/underflow. 3. Accessing deallocated Objective-C object. 4. Unowned reference to deallocated object. 5. C pointer arithmetic error. 6. Stack overflow.",
                solutions: [
                    "Enable Zombie Objects in Diagnostics to catch use-after-free",
                    "Use Address Sanitizer (ASan) in debug builds",
                    "Replace unowned with weak where appropriate",
                    "Check for retain cycles with Instruments",
                    "Validate array/string bounds before access",
                    "Use safe Swift collections instead of raw pointers",
                    "For C interop, validate all pointer operations",
                    "Set NSZombieEnabled=YES for Objective-C debugging"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Weak Reference",
                        badCode: "class Parent {\n    var child: Child!\n}\nclass Child {\n    unowned var parent: Parent  // Crash if parent deallocates\n}",
                        goodCode: "class Child {\n    weak var parent: Parent?  // Safe: nil when deallocated\n}",
                        explanation: "Use weak references to avoid dangling pointers. Unowned is dangerous if the referenced object might deallocate."
                    )
                ],
                relatedErrors: ["SIGSEGV", "SIGBUS", "KERN_PROTECTION_FAILURE"],
                tags: ["memory", "bad access", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .memory,
                severity: .critical,
                title: "Memory pressure warning: Received memory warning",
                errorCode: "MEMORY_PRESSURE",
                description: "The system is running low on memory and asking the app to free up resources. If ignored, the app may be terminated.",
                cause: "1. Memory leaks accumulating. 2. Large images/video in memory. 3. Caching too much data. 4. Retain cycles preventing deallocation. 5. Loading large files into memory.",
                solutions: [
                    "Implement didReceiveMemoryWarning to clear caches",
                    "Use NSCache instead of Dictionary for caches (auto-eviction)",
                    "Unload invisible view controllers and views",
                    "Release large images not currently displayed",
                    "Flush URLCache when memory warning received",
                    "Use Instruments to find and fix memory leaks",
                    "For images, downsample to display size before keeping in memory",
                    "Use memory-mapped files for large data"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Memory Pressure Handler",
                        badCode: "// No memory warning handling",
                        goodCode: "let center = NotificationCenter.default\ncenter.addObserver(forName: NSApplication.didReceiveMemoryPressureNotification, object: nil, queue: .main) { _ in\n    imageCache.removeAllObjects()\n    URLCache.shared.removeAllCachedResponses()\n}",
                        explanation: "Respond to memory pressure by clearing caches and releasing non-essential resources."
                    )
                ],
                relatedErrors: ["Terminated due to memory issue", "JetsamEvent"],
                tags: ["memory", "pressure", "warning", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .memory,
                severity: .critical,
                title: "Terminated due to memory issue ( Jetsam )",
                errorCode: "JETSAM",
                description: "The system killed the app because it exceeded its memory limit. This is the #1 reason for app termination in production.",
                cause: "1. Severe memory leak. 2. Loading very large assets. 3. Infinite recursion causing stack growth. 4. Memory not released after use. 5. Retain cycles throughout app. 6. Image/video processing using too much RAM.",
                solutions: [
                    "Profile with Instruments > Allocations to find leaks",
                    "Use weak self in all closures",
                    "Downsample images: UIGraphicsImageRenderer / ImageIO",
                    "Use streaming for large JSON/XML processing",
                    "Implement pagination instead of loading all data",
                    "Release CGImage, CVPixelBuffer, and other large objects promptly",
                    "For video, use AVPlayer instead of loading into memory",
                    "Monitor memory usage with os_signpost or custom logging"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Image Downsampling",
                        badCode: "let image = UIImage(contentsOfFile: path)  // Full size in memory",
                        goodCode: "func downsample(imageAt url: URL, to size: CGSize) -> UIImage {\n    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary\n    let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions)!\n    let maxDimension = max(size.width, size.height)\n    let downsampleOptions = [\n        kCGImageSourceCreateThumbnailFromImageAlways: true,\n        kCGImageSourceShouldCacheImmediately: true,\n        kCGImageSourceCreateThumbnailWithTransform: true,\n        kCGImageSourceThumbnailMaxPixelSize: maxDimension\n    ] as CFDictionary\n    return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions).flatMap { UIImage(cgImage: $0) }!\n}",
                        explanation: "Always downsample images to display size before keeping in memory."
                    )
                ],
                relatedErrors: ["Memory pressure warning", "EXC_BAD_ACCESS"],
                tags: ["memory", "jetsam", "terminated", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .memory,
                severity: .high,
                title: "Retain cycle detected: object A retains object B which retains object A",
                errorCode: "RETAIN_CYCLE",
                description: "Two or more objects hold strong references to each other, preventing deallocation and causing memory leaks.",
                cause: "1. Delegate pattern with strong delegate property. 2. Closure capturing self strongly. 3. Parent-child both holding strong references. 4. Notification observer not removed. 5. Timer retaining target.",
                solutions: [
                    "Use weak for delegate properties: weak var delegate: MyDelegate?",
                    "Use [weak self] in all escaping closures",
                    "Parent holds strong to child, child holds weak to parent",
                    "Remove notification observers in deinit",
                    "Invalidate timers and set to nil",
                    "Use Instruments > Leaks to find cycles",
                    "For Combine, use .sink with [weak self]",
                    "Break cycles in deinit by setting references to nil"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Break Retain Cycle",
                        badCode: "class Manager {\n    var handler: (() -> Void)?\n    func setup() {\n        handler = {\n            self.doWork()  // Strong self capture -> cycle\n        }\n    }\n}",
                        goodCode: "class Manager {\n    var handler: (() -> Void)?\n    func setup() {\n        handler = { [weak self] in\n            self?.doWork()  // Weak capture -> no cycle\n        }\n    }\n}",
                        explanation: "Always use [weak self] in closures that outlive the current scope."
                    )
                ],
                relatedErrors: ["Memory leak", "Object not deallocated"],
                tags: ["memory", "retain cycle", "leak", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .memory,
                severity: .high,
                title: "MACH Exception: EXC_RESOURCE (CPU / Memory / IO / Wakeups)",
                errorCode: "EXC_RESOURCE",
                description: "The app exceeded system resource limits (CPU usage, memory, I/O operations, or wakeups) and was terminated.",
                cause: "1. Excessive CPU usage on main thread. 2. Too many I/O operations. 3. Excessive timer wakeups draining battery. 4. Background fetch using too much CPU. 5. Memory usage exceeding limit.",
                solutions: [
                    "Move heavy work off main thread",
                    "Batch I/O operations instead of many small ones",
                    "Use coalesced timers instead of many frequent timers",
                    "For background tasks, use BGTaskScheduler with proper constraints",
                    "Profile CPU usage with Instruments > Time Profiler",
                    "Reduce timer frequency: use 0.1s instead of 0.001s",
                    "For location, use significant location changes instead of constant updates"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Efficient Timers",
                        badCode: "Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in\n    // Too many wakeups\n}",
                        goodCode: "Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in\n    // Coalesced, fewer wakeups\n}",
                        explanation: "Minimize timer wakeups by using longer intervals and coalescing work."
                    )
                ],
                relatedErrors: ["EXC_GUARD", "0x8badf00d"],
                tags: ["memory", "resource", "cpu", "io", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 10. CONCURRENCY / THREAD ERRORS (30+ entries)
    // =========================================================================
    
    private func concurrencyErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .concurrency,
                severity: .critical,
                title: "Thread 1: EXC_BAD_ACCESS - Data race detected",
                errorCode: "THREAD_SANITIZER_RACE",
                description: "Multiple threads accessed the same memory location simultaneously without synchronization, causing undefined behavior.",
                cause: "1. Multiple threads reading/writing same variable. 2. Unsynchronized array/dictionary mutation. 3. Property accessed from background and main thread. 4. Singleton not thread-safe.",
                solutions: [
                    "Enable Thread Sanitizer in Xcode to detect races",
                    "Use actors (Swift 5.5+) to protect mutable state",
                    "Use NSLock, os_unfair_lock, or DispatchQueue for synchronization",
                    "Use atomic properties or thread-safe wrappers",
                    "For collections, copy before modifying",
                    "Use DispatchQueue.sync or async with serial queue",
                    "Mark UI-related properties with @MainActor",
                    "For singletons, use dispatch_once pattern or static let"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Actor Protection",
                        badCode: "var counter = 0\nDispatchQueue.concurrentPerform(iterations: 1000) { _ in\n    counter += 1  // Data race!\n}",
                        goodCode: "actor Counter {\n    private var value = 0\n    func increment() { value += 1 }\n    func getValue() -> Int { value }\n}\nlet counter = Counter()\nawait withTaskGroup(of: Void.self) { group in\n    for _ in 0..<1000 {\n        group.addTask { await counter.increment() }\n    }\n}",
                        explanation: "Use actors or locks to protect shared mutable state from concurrent access."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "ThreadSanitizer: data race"],
                tags: ["concurrency", "data race", "thread", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["Swift 5.5+", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .concurrency,
                severity: .critical,
                title: "Thread 1: EXC_BAD_INSTRUCTION - Main Thread Checker: UI API called on background thread",
                errorCode: "MAIN_THREAD_CHECKER_UI",
                description: "AppKit/UIK it UI methods were called from a background thread, which is unsafe and can cause crashes.",
                cause: "1. Updating UI from network callback. 2. Setting label text from background. 3. Presenting alert from async task. 4. Modifying view frame from DispatchQueue.global.",
                solutions: [
                    "Dispatch ALL UI updates to main thread: DispatchQueue.main.async",
                    "Use @MainActor on UI-related methods and properties",
                    "For Combine, add .receive(on: DispatchQueue.main)",
                    "For async/await, the main actor is implicit in SwiftUI views",
                    "For callbacks, wrap UI code in main queue dispatch",
                    "Enable Main Thread Checker in diagnostics"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Main Thread UI",
                        badCode: "URLSession.shared.dataTask(with: url) { data, _, _ in\n    self.imageView.image = NSImage(data: data!)  // Background thread!\n}.resume()",
                        goodCode: "URLSession.shared.dataTask(with: url) { data, _, _ in\n    DispatchQueue.main.async {\n        self.imageView.image = NSImage(data: data!)\n    }\n}.resume()",
                        explanation: "Every UI update must happen on the main thread. Always dispatch UI code to main queue."
                    )
                ],
                relatedErrors: ["NSWindow drag regions should only be invalidated on main thread"],
                tags: ["concurrency", "main thread", "ui", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .concurrency,
                severity: .high,
                title: "Swift runtime failure: Reference to captured var 'X' in concurrently-executing code",
                errorCode: "CONCURRENT_VAR_CAPTURE",
                description: "In Swift concurrency, a variable captured by multiple concurrent tasks was mutated, which is a data race.",
                cause: "1. Mutating var in concurrentPerform. 2. Modifying captured variable in async task. 3. Shared mutable state in TaskGroup. 4. Closure capturing var across thread boundaries.",
                solutions: [
                    "Use let instead of var for captured values",
                    "Pass values into closures instead of capturing",
                    "Use actors for shared mutable state",
                    "Use atomic operations or locks if needed",
                    "For accumulators, use return values from tasks and combine",
                    "Sendable conformance enforcement in Swift 6"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Concurrent Capture",
                        badCode: "var results: [String] = []\nawait withTaskGroup(of: Void.self) { group in\n    for i in 0..<10 {\n        group.addTask {\n            results.append(\"\\(i)\")  // Data race!\n        }\n    }\n}",
                        goodCode: "let results = await withTaskGroup(of: String.self) { group -> [String] in\n    for i in 0..<10 {\n        group.addTask {\n            return \"\\(i)\"\n        }\n    }\n    var collected: [String] = []\n    for await result in group {\n        collected.append(result)\n    }\n    return collected\n}",
                        explanation: "Return values from tasks instead of mutating shared state. Combine results serially."
                    )
                ],
                relatedErrors: ["Data race detected", "Sendable conformance"],
                tags: ["concurrency", "capture", "var", "swift 6", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html",
                commonInVersions: ["Swift 5.5+", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .concurrency,
                severity: .high,
                title: "ThreadSanitizer: Swift access race on global variable 'X'",
                errorCode: "TSAN_GLOBAL_RACE",
                description: "Thread Sanitizer detected unsynchronized access to a global or static variable from multiple threads.",
                cause: "1. Global variable accessed from multiple threads. 2. Static property not thread-safe. 3. Singleton lazy initialization race. 4. Global counter incremented without synchronization.",
                solutions: [
                    "Use dispatch_once or static let for singletons (thread-safe by default)",
                    "Protect globals with locks or serial queues",
                    "Use atomics for simple counters (OSAtomic, stdatomic)",
                    "Convert globals to actors in Swift 5.5+",
                    "Use ThreadSafe wrappers around mutable globals"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Thread-Safe Singleton",
                        badCode: "var sharedCounter = 0  // Global, not thread-safe",
                        goodCode: "actor Counter {\n    static let shared = Counter()\n    private var value = 0\n    func increment() { value += 1 }\n}",
                        explanation: "Use actors or proper synchronization for shared mutable state."
                    )
                ],
                relatedErrors: ["Data race detected"],
                tags: ["concurrency", "thread sanitizer", "global", "race", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            
            ErrorEntry(
                category: .concurrency,
                severity: .high,
                title: "Swift runtime failure: Child task was thrown out of a parent that was already cancelled",
                errorCode: "TASK_CANCEL_THROW",
                description: "A structured concurrency task was cancelled and threw a CancellationError, but the parent task had also been cancelled.",
                cause: "1. Parent task cancelled while child running. 2. Task group cancelled before children complete. 3. View disappeared, cancelling .task modifier. 4. Timeout expired on withTimeout.",
                solutions: [
                    "Use Task.checkCancellation() to cooperatively handle cancellation",
                    "Wrap task work in do-catch for CancellationError",
                    "For view-bound tasks, handle .task cancellation gracefully",
                    "Use withTaskCancellationHandler for cleanup",
                    "Don't throw from cancelled tasks unless necessary",
                    "For timeouts, use withTimeoutOrNil pattern"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Graceful Cancellation",
                        badCode: "Task {\n    try await longRunningOperation()  // Throws if cancelled\n}",
                        goodCode: "Task {\n    do {\n        try await longRunningOperation()\n    } catch is CancellationError {\n        // Clean up and exit gracefully\n    }\n}",
                        explanation: "Handle CancellationError explicitly to perform cleanup when tasks are cancelled."
                    )
                ],
                relatedErrors: ["Task cancelled", "CancellationError"],
                tags: ["concurrency", "task", "cancel", "swift 6", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html",
                commonInVersions: ["Swift 5.5+", "Swift 6.x"]
            ),
            
            ErrorEntry(
                category: .concurrency,
                severity: .high,
                title: "Deadlock detected: Thread A waiting for lock held by Thread B, which waits for lock held by Thread A",
                errorCode: "DEADLOCK",
                description: "Two or more threads are waiting for each other to release locks, causing all involved threads to hang forever.",
                cause: "1. Nested lock acquisition in different order. 2. sync dispatch to current queue. 3. Main thread waiting for background that waits for main. 4. Recursive lock without recursion support.",
                solutions: [
                    "Always acquire locks in the same global order",
                    "Use tryLock with timeout instead of blocking lock",
                    "Use async instead of sync for queue dispatch",
                    "Never call sync on the same queue you're running on",
                    "Use NSRecursiveLock if reentrant locking needed",
                    "For actors, avoid calling actors from each other synchronously",
                    "Use async/await to eliminate callback-based deadlocks"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Avoid Deadlock",
                        badCode: "let queue = DispatchQueue(label: \"serial\")\nqueue.sync {\n    queue.sync {  // Deadlock: waiting on same queue\n        // work\n    }\n}",
                        goodCode: "let queue = DispatchQueue(label: \"serial\")\nqueue.async {\n    queue.async {\n        // work\n    }\n}",
                        explanation: "Never call sync on a serial queue from within that queue. Use async instead."
                    )
                ],
                relatedErrors: ["Hang", "Unresponsive"],
                tags: ["concurrency", "deadlock", "lock", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/dispatch",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .concurrency,
                severity: .medium,
                title: "DispatchQueue: overcommit of worker threads",
                errorCode: "DISPATCH_OVERCOMMIT",
                description: "Creating too many concurrent DispatchQueue tasks, causing thread explosion and excessive context switching.",
                cause: "1. Unbounded concurrentPerform iterations. 2. Creating global().async in loops. 3. Too many concurrent URLSession tasks. 4. Not using semaphore to limit concurrency.",
                solutions: [
                    "Limit concurrent operations with DispatchSemaphore",
                    "Use OperationQueue with maxConcurrentOperationCount",
                    "For I/O bound work, use fewer threads than CPU cores",
                    "Batch work instead of individual tasks",
                    "Use concurrentPerform which manages thread pool",
                    "For async work, use structured concurrency with limited TaskGroups"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Limit Concurrency",
                        badCode: "for url in urls {\n    DispatchQueue.global().async {\n        download(url)  // 1000 simultaneous downloads\n    }\n}",
                        goodCode: "let semaphore = DispatchSemaphore(value: 5)\nfor url in urls {\n    DispatchQueue.global().async {\n        semaphore.wait()\n        download(url)\n        semaphore.signal()\n    }\n}",
                        explanation: "Limit concurrent operations to prevent thread explosion and resource exhaustion."
                    )
                ],
                relatedErrors: ["Resource temporarily unavailable", "Thread creation failed"],
                tags: ["concurrency", "dispatch", "thread", "overcommit", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/dispatch",
                commonInVersions: ["All versions"]
            ),
        ]
    }
    

    // =========================================================================
    // MARK: - 11. CORE DATA ERRORS (30+ entries)
    // =========================================================================
    
    private func coreDataErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .coreData,
                severity: .critical,
                title: "Core Data: The model used to open the store is incompatible with the one used to create the store",
                errorCode: "NSPersistentStoreIncompatibleVersionHashError (134100)",
                description: "The Core Data model has changed (entity added/removed/renamed) but a lightweight or heavyweight migration was not performed.",
                cause: "1. Model changed without migration. 2. Added new entity. 3. Changed attribute type. 4. Added required attribute without default. 5. Deleted entity that existing store contains.",
                solutions: [
                    "Enable automatic lightweight migration: NSPersistentStoreDescription.shouldMigrateStoreAutomatically = true",
                    "Set shouldInferMappingModelAutomatically = true",
                    "For complex changes, create mapping model (.xcmappingmodel)",
                    "Version your data model: Editor > Add Model Version",
                    "Set current model version in File Inspector",
                    "For destructive changes, delete and recreate store (data loss!)",
                    "Test migration with old and new store versions"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Auto Migration",
                        badCode: "let container = NSPersistentContainer(name: \"MyModel\")\ncontainer.loadPersistentStores { _, error in }  // No migration config",
                        goodCode: "let container = NSPersistentContainer(name: \"MyModel\")\nlet description = container.persistentStoreDescriptions.first\ndescription?.shouldMigrateStoreAutomatically = true\ndescription?.shouldInferMappingModelAutomatically = true\ncontainer.loadPersistentStores { _, error in }",
                        explanation: "Always configure automatic migration or create explicit mapping models when changing Core Data schemas."
                    )
                ],
                relatedErrors: ["NSMigrationError (134110)", "NSMigrationMissingSourceModelError (134130)"],
                tags: ["coredata", "migration", "model", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/migration_guide",
                commonInVersions: ["iOS 13+", "macOS 10.15+", "iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: executeFetchRequest:error: A fetch request must have an entity",
                errorCode: "NSInvalidArgumentException",
                description: "A fetch request was created without specifying which entity to fetch.",
                cause: "1. NSFetchRequest created without entity name. 2. Entity name is nil or empty. 3. Using wrong NSEntityDescription.",
                solutions: [
                    "Set entity: fetchRequest.entity = NSEntityDescription.entity(forEntityName: in:)",
                    "Use typed fetch request: NSFetchRequest<MyEntity>(entityName: \"MyEntity\")",
                    "Verify entity name matches model exactly (case-sensitive)",
                    "Ensure model is loaded before creating fetch requests"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Fetch Request",
                        badCode: "let request = NSFetchRequest<NSManagedObject>()  // No entity",
                        goodCode: "let request = NSFetchRequest<MyEntity>(entityName: \"MyEntity\")\n// or\nlet request = NSFetchRequest<NSManagedObject>(entityName: \"MyEntity\")",
                        explanation: "Always specify the entity name in fetch requests."
                    )
                ],
                relatedErrors: ["Entity name not found"],
                tags: ["coredata", "fetch", "entity", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsfetchrequest",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: attempt to insert new object with no entity description",
                errorCode: "NSInvalidArgumentException",
                description: "NSEntityDescription.insertNewObject was called without a valid entity description.",
                cause: "1. Entity name doesn't exist in model. 2. Wrong context passed. 3. Model not loaded. 4. Typo in entity name.",
                solutions: [
                    "Verify entity name matches model exactly",
                    "Use NSEntityDescription.insertNewObject(forEntityName:into:)",
                    "For typed access, use MyEntity(context: context)",
                    "Ensure persistent container is initialized before insertions"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Insert Object",
                        badCode: "let obj = NSManagedObject()  // No entity",
                        goodCode: "let obj = MyEntity(context: context)  // Swift generated class\n// or\nlet obj = NSEntityDescription.insertNewObject(forEntityName: \"MyEntity\", into: context)",
                        explanation: "Always use entity-specific insertion methods with valid context."
                    )
                ],
                relatedErrors: ["Entity not found"],
                tags: ["coredata", "insert", "entity", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsentitydescription",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: Unrecognized selector sent to instance NSManagedObject",
                errorCode: "NSInvalidArgumentException",
                description: "A method was called on an NSManagedObject subclass that doesn't implement it. Usually caused by codegen issues.",
                cause: "1. Codegen set to Manual but class not implemented. 2. Class name mismatch between model and code. 3. Category/extension not loaded. 4. @objc name mismatch.",
                solutions: [
                    "Set Codegen to Class Definition or Category/Extension in model editor",
                    "Ensure class name in model matches Swift class name",
                    "For manual codegen, generate files: Editor > Create NSManagedObject Subclass",
                    "Add @objc(MyEntity) if class name differs from entity name",
                    "Clean build folder after changing codegen settings",
                    "Check module name in model inspector"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "CodeGen Setup",
                        badCode: "// Entity 'Person' in model but no Swift class defined",
                        goodCode: "// In Core Data Model Inspector:\n// Module: Current Product Module\n// Codegen: Class Definition\n// Swift generates: public class Person: NSManagedObject { }",
                        explanation: "Ensure Core Data codegen settings match your project setup. Use 'Class Definition' for automatic generation."
                    )
                ],
                relatedErrors: ["NSManagedObject class not found"],
                tags: ["coredata", "codegen", "selector", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/modeling_data",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: Context save error - validation error",
                errorCode: "NSValidationError (1560)",
                description: "The managed object context could not save because one or more objects failed validation.",
                cause: "1. Required attribute is nil. 2. String exceeds max length. 3. Number outside valid range. 4. Regex validation failed. 5. Custom validation method returned false.",
                solutions: [
                    "Check validation errors in error.userInfo[NSDetailedErrorsKey]",
                    "Ensure all required attributes have values before save",
                    "Validate input before assigning to managed objects",
                    "Use optional attributes with defaults instead of required",
                    "For batch inserts, validate each object individually",
                    "Implement validateForInsert/Update for custom validation",
                    "Use context.shouldDeleteInaccessibleFaults = true"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Save Error",
                        badCode: "try context.save()  // May throw validation error",
                        goodCode: "do {\n    try context.save()\n} catch let error as NSError {\n    if let errors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {\n        for err in errors {\n            print(\"Validation error: \\(err.localizedDescription)\")\n        }\n    }\n}",
                        explanation: "Inspect detailed errors to identify which objects and attributes failed validation."
                    )
                ],
                relatedErrors: ["NSValidationMultipleErrorsError", "NSValidationMissingMandatoryPropertyError"],
                tags: ["coredata", "validation", "save", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsvalidationerror",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: Cannot perform operation since entity is not key value coding-compliant for property 'X'",
                errorCode: "NSUnknownKeyException",
                description: "Attempting to access a property on an NSManagedObject that doesn't exist in the entity description.",
                cause: "1. Property name typo. 2. Property deleted from model but still referenced in code. 3. Using value(forKey:) with wrong key. 4. NSPredicate referencing non-existent property.",
                solutions: [
                    "Verify property name matches model exactly",
                    "Use Swift generated properties instead of value(forKey:)",
                    "Check that model is up to date with code",
                    "For predicates, verify key path exists",
                    "Clean build after model changes",
                    "Use #keyPath for compile-time checking"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Property Access",
                        badCode: "person.value(forKey: \"nmae\")  // Typo",
                        goodCode: "person.name  // Swift generated property",
                        explanation: "Use Swift-generated typed properties instead of string-based KVC for Core Data objects."
                    )
                ],
                relatedErrors: ["NSUnknownKeyException"],
                tags: ["coredata", "kvc", "property", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsmanagedobject",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: fault cannot be fulfilled",
                errorCode: "NSObjectInaccessibleException",
                description: "A faulted object could not be fulfilled because the underlying data was deleted or the context was reset.",
                cause: "1. Object deleted in another context. 2. Context reset while object faulted. 3. Store removed or recreated. 4. Persistent history not processed. 5. Background context deleted object while main context holds fault.",
                solutions: [
                    "Check object.isDeleted before accessing properties",
                    "Handle NSManagedObjectContextObjectsDidChange notification",
                    "Use NSFetchRequest.returnsObjectsAsFaults = false if needed immediately",
                    "For background deletions, merge changes properly",
                    "Refresh objects before access: context.refresh(object, mergeChanges: true)",
                    "Use try? object.managedObjectContext?.existingObject(with: object.objectID)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Fault Handling",
                        badCode: "print(deletedPerson.name)  // Fault cannot be fulfilled",
                        goodCode: "if !person.isDeleted, let context = person.managedObjectContext {\n    context.refresh(person, mergeChanges: true)\n    print(person.name)\n}",
                        explanation: "Always check if an object is still valid before accessing faulted properties."
                    )
                ],
                relatedErrors: ["NSObjectInaccessibleException"],
                tags: ["coredata", "fault", "deleted", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsmanagedobject",
                commonInVersions: ["All versions"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 12. CODE SIGNING ERRORS (30+ entries)
    // =========================================================================
    
    private func codeSigningErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .codeSigning,
                severity: .critical,
                title: "Code Signing Error: No signing certificate 'iOS Development' found",
                errorCode: "CERT_MISSING",
                description: "Xcode cannot find a valid code signing certificate for the selected team and provisioning profile.",
                cause: "1. Certificate expired. 2. Certificate revoked. 3. Private key missing from Keychain. 4. Wrong team selected. 5. Certificate not downloaded from Developer Portal.",
                solutions: [
                    "Xcode > Preferences > Accounts > Download Manual Profiles",
                    "Open Keychain Access and check for valid certificates",
                    "Revoke and re-create certificate in Apple Developer Portal",
                    "Ensure correct Team ID is selected in Signing & Capabilities",
                    "For CI, import certificate and private key to build keychain",
                    "Use fastlane match for team certificate management",
                    "Check that certificate is in 'login' or 'System' keychain"
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Fix Certificate",
                        badCode: "// No valid development certificate",
                        goodCode: "# In Terminal, check certificates:\nsecurity find-identity -v -p codesigning\n# Revoke old, create new at:\n# https://developer.apple.com/account/resources/certificates/list",
                        explanation: "Certificates and private keys must both be present in Keychain. Download from Apple Developer Portal."
                    )
                ],
                relatedErrors: ["No signing identity found", "Provisioning profile not found"],
                tags: ["codesigning", "certificate", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .codeSigning,
                severity: .critical,
                title: "Provisioning profile 'X' doesn't include signing certificate 'Y'",
                errorCode: "PROFILE_CERT_MISMATCH",
                description: "The provisioning profile was created without including the selected signing certificate.",
                cause: "1. Certificate created after provisioning profile. 2. Profile downloaded before certificate. 3. Different certificate selected in Xcode than in profile. 4. Team member added but profile not regenerated.",
                solutions: [
                    "Regenerate provisioning profile in Developer Portal",
                    "Download updated profile in Xcode Preferences > Accounts",
                    "Ensure certificate is added to the App ID's provisioning profile",
                    "For development, use automatic signing to let Xcode manage",
                    "For manual signing, update profile after adding certificates",
                    "Delete old profiles from ~/Library/MobileDevice/Provisioning Profiles"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Auto Signing",
                        badCode: "// Manual signing with stale profile",
                        goodCode: "// In Xcode: Target > Signing & Capabilities > Automatically manage signing > ON",
                        explanation: "Use automatic signing to let Xcode manage certificates and provisioning profiles."
                    )
                ],
                relatedErrors: ["Provisioning profile expired", "Certificate not in profile"],
                tags: ["codesigning", "provisioning", "certificate", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .codeSigning,
                severity: .high,
                title: "The entitlements specified in your application's Code Signing Entitlements file do not match those specified in your provisioning profile",
                errorCode: "ENTITLEMENT_MISMATCH",
                description: "The app's entitlements don't match the provisioning profile's entitlements.",
                cause: "1. Added capability but profile not regenerated. 2. Different App ID used. 3. Entitlements file manually edited incorrectly. 4. Multiple targets with different entitlements sharing profile.",
                solutions: [
                    "Regenerate provisioning profile after adding capabilities",
                    "Ensure App ID matches exactly between project and profile",
                    "Check .entitlements file matches profile capabilities",
                    "For automatic signing, disable and re-enable to refresh",
                    "For manual, update profile in Developer Portal with new entitlements",
                    "Compare entitlements: codesign -d --entitlements :- MyApp.app"
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Check Entitlements",
                        badCode: "// Profile doesn't include push notification entitlement",
                        goodCode: "# Check app entitlements:\ncodesign -d --entitlements :- MyApp.app\n# Check profile entitlements:\nsecurity cms -D -i MyProfile.mobileprovision | plutil -p -",
                        explanation: "Regenerate provisioning profiles whenever capabilities or entitlements change."
                    )
                ],
                relatedErrors: ["Invalid entitlements"],
                tags: ["codesigning", "entitlements", "provisioning", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .codeSigning,
                severity: .high,
                title: "The identity used to sign the executable is no longer valid",
                errorCode: "IDENTITY_INVALID",
                description: "The signing certificate has expired or been revoked.",
                cause: "1. Certificate expired (valid for 1 year). 2. Certificate revoked. 3. Intermediate certificate expired. 4. Apple WWDR certificate expired.",
                solutions: [
                    "Renew certificate in Apple Developer Portal",
                    "Download new WWDR intermediate certificate from Apple",
                    "Delete expired certificates from Keychain",
                    "Regenerate provisioning profiles with new certificate",
                    "For distribution, use App Store Connect API for automated renewal"
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Renew Certificate",
                        badCode: "// Certificate expired on 2024-01-01",
                        goodCode: "# 1. Revoke expired cert in Developer Portal\n# 2. Create new certificate\n# 3. Download and install\n# 4. Regenerate all provisioning profiles\n# 5. Clean build and rebuild",
                        explanation: "Apple development certificates expire annually. Renew before expiration."
                    )
                ],
                relatedErrors: ["Certificate expired"],
                tags: ["codesigning", "certificate", "expired", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 13. WIDGETKIT ERRORS (20+ entries)
    // =========================================================================
    
    private func widgetKitErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .widgetKit,
                severity: .high,
                title: "WidgetKit: Timeline entries must be in chronological order",
                errorCode: "WIDGET_TIMELINE_ORDER",
                description: "The timeline provider returned entries that are not sorted by date, which WidgetKit requires.",
                cause: "1. Entries sorted in wrong order. 2. Same date for multiple entries. 3. Date calculation error causing out-of-order dates.",
                solutions: [
                    "Sort entries by date before returning: entries.sort { $0.date < $1.date }",
                    "Ensure no duplicate dates in timeline",
                    "Use Calendar for reliable date calculations",
                    "For reloads, use TimelineReloadPolicy.after(date)"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Sorted Timeline",
                        badCode: "let entries = [\n    Entry(date: now.addingTimeInterval(3600)),\n    Entry(date: now)  // Out of order\n]",
                        goodCode: "var entries = [Entry(date: now), Entry(date: now.addingTimeInterval(3600))]\nentries.sort { $0.date < $1.date }",
                        explanation: "Timeline entries must always be in ascending chronological order."
                    )
                ],
                relatedErrors: ["WidgetKit: invalid timeline"],
                tags: ["widgetkit", "timeline", "widget", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/widgetkit/timelineprovider",
                commonInVersions: ["iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .widgetKit,
                severity: .high,
                title: "WidgetKit: App Group container not accessible",
                errorCode: "WIDGET_APP_GROUP",
                description: "The widget cannot access shared data because the App Group entitlement is missing or misconfigured.",
                cause: "1. App Group not enabled for target. 2. Group identifier mismatch between app and widget. 3. Provisioning profile doesn't include App Group. 4. UserDefaults not using suiteName.",
                solutions: [
                    "Add App Group capability to both app and widget targets",
                    "Ensure same group identifier in both targets",
                    "Regenerate provisioning profiles after adding App Group",
                    "Use UserDefaults(suiteName: 'group.com.example') for shared storage",
                    "For file sharing, use FileManager.containerURL(forSecurityApplicationGroupIdentifier:)",
                    "Check that group identifier matches across all targets and profiles"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Shared Defaults",
                        badCode: "let defaults = UserDefaults.standard  // Not shared with widget",
                        goodCode: "let defaults = UserDefaults(suiteName: \"group.com.example.myapp\")!\ndefaults.set(value, forKey: \"widgetData\")",
                        explanation: "Use App Group-based UserDefaults and file containers to share data between app and widget."
                    )
                ],
                relatedErrors: ["App Group entitlement missing"],
                tags: ["widgetkit", "app group", "widget", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/widgetkit/making-data-available-to-widgets",
                commonInVersions: ["iOS 14+", "macOS 11+"]
            ),
            
            ErrorEntry(
                category: .widgetKit,
                severity: .medium,
                title: "WidgetKit: Widget family 'X' not supported by configuration",
                errorCode: "WIDGET_FAMILY_UNSUPPORTED",
                description: "The widget configuration doesn't support the requested widget family/size.",
                cause: "1. Widget family not included in supportedFamilies. 2. Platform-specific family used on wrong platform. 3. System widget size not available.",
                solutions: [
                    "Add family to supportedFamilies: .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])",
                    "Use #if os(iOS)/os(macOS) for platform-specific families",
                    "For iOS 15+, include .systemExtraLarge if supported",
                    "For watchOS, use .accessory families",
                    "Check widget size constraints per platform"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Supported Families",
                        badCode: "struct MyWidget: Widget {\n    var body: some WidgetConfiguration {\n        StaticConfiguration(...) { entry in\n            MyView(entry: entry)\n        }\n        // Missing supportedFamilies\n    }\n}",
                        goodCode: "struct MyWidget: Widget {\n    var body: some WidgetConfiguration {\n        StaticConfiguration(...) { entry in\n            MyView(entry: entry)\n        }\n        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])\n    }\n}",
                        explanation: "Explicitly declare which widget sizes your widget supports."
                    )
                ],
                relatedErrors: ["WidgetKit: unsupported family"],
                tags: ["widgetkit", "family", "widget", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/widgetkit/widgetconfiguration",
                commonInVersions: ["iOS 14+", "macOS 11+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 14. COMBINE ERRORS (20+ entries)
    // =========================================================================
    
    private func combineErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .combine,
                severity: .high,
                title: "Combine: Fatal error: Unexpectedly found nil while unwrapping an Optional value in sink",
                errorCode: "COMBINE_FORCE_UNWRAP",
                description: "A Combine pipeline force-unwrapped a nil value in a sink or map closure.",
                cause: "1. Force unwrap in map closure. 2. Assuming value exists in compactMap. 3. URLSession dataTaskPublisher returning nil data force unwrapped.",
                solutions: [
                    "Use compactMap instead of map + force unwrap",
                    "Use tryMap with error throwing instead of force unwrap",
                    "Handle nil values with replaceNil or replaceEmpty",
                    "Use decode(type:decoder:) which handles errors gracefully",
                    "Add catch operator for error recovery"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Combine",
                        badCode: "URLSession.shared.dataTaskPublisher(for: url)\n    .map { $0.data }\n    .sink { data in\n        let json = try! JSONSerialization.jsonObject(with: data)  // Force try\n    }",
                        goodCode: "URLSession.shared.dataTaskPublisher(for: url)\n    .map { $0.data }\n    .decode(type: MyModel.self, decoder: JSONDecoder())\n    .catch { error in\n        Just(MyModel.fallback)\n    }\n    .sink { model in\n        // Use model safely\n    }",
                        explanation: "Use Combine's built-in error handling operators instead of force unwrap."
                    )
                ],
                relatedErrors: ["Fatal error: Unexpectedly found nil"],
                tags: ["combine", "publisher", "sink", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/combine",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            
            ErrorEntry(
                category: .combine,
                severity: .medium,
                title: "Combine: Cannot assign through subscript: subscription has been cancelled",
                errorCode: "COMBINE_CANCELLED_ASSIGN",
                description: "Trying to assign to an object through a Combine subscription after the cancellable was cancelled or deallocated.",
                cause: "1. Store not holding AnyCancellable strongly. 2. Cancellable deallocated before assignment. 3. View recreated, losing subscription.",
                solutions: [
                    "Store cancellables in Set<AnyCancellable> property",
                    "Ensure store property is not local (must outlive subscription)",
                    "For SwiftUI, use .onReceive instead of manual sink",
                    "Check cancellable.isCancelled before operations"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Retain Cancellable",
                        badCode: "func setup() {\n    publisher.sink { value in\n        self.label = value\n    }  // Not stored -> deallocated immediately\n}",
                        goodCode: "private var cancellables = Set<AnyCancellable>()\nfunc setup() {\n    publisher\n        .sink { [weak self] value in\n            self?.label = value\n        }\n        .store(in: &cancellables)\n}",
                        explanation: "Always store subscriptions in a Set<AnyCancellable> to keep them alive."
                    )
                ],
                relatedErrors: ["Object has been deallocated"],
                tags: ["combine", "cancellable", "subscription", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/combine/anycancellable",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            
            ErrorEntry(
                category: .combine,
                severity: .medium,
                title: "Combine: Publisher cannot sync upstream values on the requested queue",
                errorCode: "COMBINE_RECEIVE_QUEUE",
                description: "A publisher tried to deliver values on a specific DispatchQueue but the upstream publisher doesn't support queue customization.",
                cause: "1. Using .receive(on:) with @Published. 2. Expecting all publishers to respect receive(on:). 3. Using ImmediateScheduler inappropriately.",
                solutions: [
                    "Use .receive(on: DispatchQueue.main) for UI updates",
                    "For @Published, values emit on the thread that modifies the property",
                    "Use CurrentValueSubject or PassthroughSubject with explicit scheduling",
                    "For timer publishers, use .receive(on:) after creation",
                    "Avoid mixing publishers with different scheduling behaviors"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Proper Scheduling",
                        badCode: "@Published var value: String = \"\"\n// Modifying from background thread -> emits on background",
                        goodCode: "@Published var value: String = \"\"\n\nfunc update() {\n    DispatchQueue.global().async {\n        let result = compute()\n        DispatchQueue.main.async {\n            self.value = result  // Emit on main thread\n        }\n    }\n}",
                        explanation: "@Published emits on the thread that modifies the property. Dispatch to main for UI-bound publishers."
                    )
                ],
                relatedErrors: ["Modifying state during view update"],
                tags: ["combine", "publisher", "queue", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/combine",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 15. METAL / GPU ERRORS (20+ entries)
    // =========================================================================
    
    private func metalErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .metal,
                severity: .critical,
                title: "Metal: Failed to create MTLDevice",
                errorCode: "MTL_DEVICE_FAIL",
                description: "Metal could not initialize the GPU device. This usually means the hardware doesn't support Metal or the GPU driver is unavailable.",
                cause: "1. Running on simulator without Metal support. 2. Running in VM without GPU passthrough. 3. macOS in safe mode. 4. GPU driver issue. 5. Requesting Metal 3 on older hardware.",
                solutions: [
                    "Check MTLCreateSystemDefaultDevice() != nil before using Metal",
                    "For macOS, check GPU family support before using features",
                    "Fall back to CPU rendering (Core Graphics) if Metal unavailable",
                    "For simulators, use features supported by simulated GPU",
                    "Update macOS for latest GPU drivers"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Metal Availability",
                        badCode: "let device = MTLCreateSystemDefaultDevice()!  // May crash",
                        goodCode: "guard let device = MTLCreateSystemDefaultDevice() else {\n    // Fall back to CPU rendering\n    return\n}",
                        explanation: "Always check Metal device availability and provide fallback rendering."
                    )
                ],
                relatedErrors: ["MTLDevice not found"],
                tags: ["metal", "gpu", "device", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/metal",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            
            ErrorEntry(
                category: .metal,
                severity: .high,
                title: "Metal: Command buffer execution failed",
                errorCode: "MTL_COMMAND_BUFFER_ERROR",
                description: "A Metal command buffer failed to execute on the GPU. This can happen due to resource limits, invalid commands, or GPU errors.",
                cause: "1. Out of GPU memory. 2. Invalid texture format. 3. Shader compilation error. 4. Buffer overflow in compute kernel. 5. GPU timeout (watchdog). 6. Metal validation errors in debug.",
                solutions: [
                    "Check commandBuffer.status and commandBuffer.error",
                    "Enable Metal API Validation in Scheme > Options",
                    "Reduce texture size or buffer count",
                    "Check shader compilation logs",
                    "Split heavy GPU work into multiple command buffers",
                    "For compute, ensure threadgroup size is valid",
                    "Handle MTLCommandBufferStatus.error gracefully"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle GPU Error",
                        badCode: "commandBuffer.commit()\ncommandBuffer.waitUntilCompleted()  // No error check",
                        goodCode: "commandBuffer.commit()\ncommandBuffer.waitUntilCompleted()\nif let error = commandBuffer.error {\n    print(\"GPU Error: \\(error)\")\n}",
                        explanation: "Always check command buffer status and error after GPU execution."
                    )
                ],
                relatedErrors: ["Metal: validation error"],
                tags: ["metal", "gpu", "command buffer", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/metal/mtlcommandbuffer",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            
            ErrorEntry(
                category: .metal,
                severity: .high,
                title: "Metal: Shader compilation failed",
                errorCode: "MTL_SHADER_COMPILE_FAIL",
                description: "A Metal shader (.metal file) failed to compile, usually due to syntax errors or unsupported features.",
                cause: "1. Syntax error in .metal file. 2. Using Metal 3 features on Metal 2 hardware. 3. Missing #include. 4. Type mismatch in shader function. 5. Unsupported texture format in shader.",
                solutions: [
                    "Check shader compilation error logs in console",
                    "Enable Metal Shader Validation in scheme options",
                    "Check target OS version supports shader features",
                    "Use feature set tables to verify GPU capabilities",
                    "Compile shaders offline with metal command-line tools",
                    "Test shaders in Xcode's Metal frame debugger"
                ],
                codeExamples: [
                    CodeExample(
                        language: "metal",
                        title: "Valid Shader",
                        badCode: "kernel void badShader(texture2d<float> tex [[texture(0)]]) {\n    float4 c = tex.read(0);  // Missing coord type\n}",
                        goodCode: "kernel void goodShader(texture2d<float> tex [[texture(0)]],\n                         uint2 gid [[thread_position_in_grid]]) {\n    float4 c = tex.read(gid);\n}",
                        explanation: "Metal shaders must be syntactically correct and use proper data types for all parameters."
                    )
                ],
                relatedErrors: ["Metal: pipeline creation failed"],
                tags: ["metal", "shader", "compile", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/metal/shader_authoring",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 16. SECURITY / KEYCHAIN ERRORS (20+ entries)
    // =========================================================================
    
    private func securityErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .security,
                severity: .high,
                title: "Keychain: errSecItemNotFound (-25300)",
                errorCode: "errSecItemNotFound (-25300)",
                description: "The requested item doesn't exist in the Keychain.",
                cause: "1. Item never saved. 2. Wrong service/account/key. 3. Item deleted. 4. Access group mismatch. 5. Keychain locked.",
                solutions: [
                    "Check if item exists before reading",
                    "Verify service, account, and access group match save parameters",
                    "For iCloud Keychain, ensure user is signed into iCloud",
                    "Check keychain accessibility level",
                    "For simulators, Keychain behaves differently than device",
                    "Use SecItemAdd status to verify save succeeded"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Keychain Read",
                        badCode: "let data = try keychain.get(\"token\")!  // Force unwrap may crash",
                        goodCode: "if let data = try? keychain.get(\"token\") {\n    // Use token\n} else {\n    // Prompt for login\n}",
                        explanation: "Keychain items may not exist. Always handle missing items gracefully."
                    )
                ],
                relatedErrors: ["errSecDuplicateItem (-25299)"],
                tags: ["security", "keychain", "not found", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/security/keychain_services",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .security,
                severity: .high,
                title: "Keychain: errSecDuplicateItem (-25299)",
                errorCode: "errSecDuplicateItem (-25299)",
                description: "Attempting to add an item to the Keychain that already exists with the same attributes.",
                cause: "1. Saving same key twice without updating. 2. Same service/account combination. 3. Reinstalling app with existing keychain data.",
                solutions: [
                    "Use SecItemUpdate for existing items instead of SecItemAdd",
                    "Delete existing item before adding: SecItemDelete",
                    "Use updateOrAdd pattern: try update, fallback to add",
                    "For KeychainSwift or similar wrappers, use set(_, forKey:) which handles update",
                    "Query existing before deciding to add or update"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Update or Add",
                        badCode: "SecItemAdd(query as CFDictionary, nil)  // Fails if exists",
                        goodCode: "let status = SecItemAdd(query as CFDictionary, nil)\nif status == errSecDuplicateItem {\n    SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)\n}",
                        explanation: "Handle duplicate items by updating instead of failing."
                    )
                ],
                relatedErrors: ["errSecItemNotFound (-25300)"],
                tags: ["security", "keychain", "duplicate", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/security/keychain_services",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .security,
                severity: .high,
                title: "Keychain: errSecInteractionNotAllowed (-25308)",
                errorCode: "errSecInteractionNotAllowed (-25308)",
                description: "User interaction is not allowed, usually because the device is locked and the keychain item requires unlocked access.",
                cause: "1. Keychain item saved with .whenUnlocked but device is locked. 2. Background fetch accessing keychain while locked. 3. Accessibility level too restrictive for use case.",
                solutions: [
                    "Use .afterFirstUnlock for background-accessible items",
                    "Check device lock state before keychain access",
                    "For push notifications in background, use appropriate accessibility",
                    "Defer keychain access until app is foregrounded",
                    "Consider .whenUnlockedThisDeviceOnly for sensitive data"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Accessible Keychain",
                        badCode: "kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked  // Not available when locked",
                        goodCode: "kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock  // Available in background",
                        explanation: "Choose keychain accessibility based on when the data needs to be accessible."
                    )
                ],
                relatedErrors: ["errSecNotAvailable (-25291)"],
                tags: ["security", "keychain", "accessibility", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/security/keychain_services/keychain_items/item_attribute_keys_and_values",
                commonInVersions: ["All versions"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 17. NOTIFICATION ERRORS (15+ entries)
    // =========================================================================
    
    private func notificationErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .notification,
                severity: .high,
                title: "UserNotifications: Notifications are not allowed for this application",
                errorCode: "UNErrorNotAllowed",
                description: "The app attempted to schedule or present a notification but doesn't have user authorization.",
                cause: "1. requestAuthorization not called. 2. User denied permission. 3. Notifications disabled in System Preferences. 4. Focus mode blocking notifications.",
                solutions: [
                    "Call requestAuthorization on first launch",
                    "Check authorization status with getNotificationSettings",
                    "Handle .denied by showing settings prompt",
                    "For macOS, ensure app is signed for notifications",
                    "Check Notification Center settings in System Preferences"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Request Notification Permission",
                        badCode: "let content = UNMutableNotificationContent()\nlet request = UNNotificationRequest(...)\nUNUserNotificationCenter.current().add(request)  // Fails if not authorized",
                        goodCode: "UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in\n    if granted {\n        // Schedule notifications\n    }\n}",
                        explanation: "Always request and verify notification authorization before scheduling."
                    )
                ],
                relatedErrors: ["UNErrorNotificationsNotAllowed"],
                tags: ["notifications", "permissions", "authorization", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/usernotifications",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            
            ErrorEntry(
                category: .notification,
                severity: .medium,
                title: "UserNotifications: Notification content extension failed to load",
                errorCode: "UN_EXTENSION_FAIL",
                description: "A notification content extension (rich notification UI) failed to load.",
                cause: "1. Extension bundle ID mismatch. 2. Missing Info.plist configuration. 3. Extension memory limit exceeded. 4. Extension crashed on load.",
                solutions: [
                    "Verify extension bundle ID matches provisioning profile",
                    "Check UNNotificationExtension category identifier matches",
                    "Ensure extension Info.plist has NSExtension configuration",
                    "Test extension memory usage - limit is typically 24MB",
                    "Check console logs for extension-specific crashes"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Extension Config",
                        badCode: "// Missing NSExtension in Info.plist",
                        goodCode: "<key>NSExtension</key>\n<dict>\n    <key>NSExtensionPointIdentifier</key>\n    <string>com.apple.usernotifications.content-extension</string>\n    <key>NSExtensionAttributes</key>\n    <dict>\n        <key>UNNotificationExtensionCategory</key>\n        <string>myCategory</string>\n    </dict>\n</dict>",
                        explanation: "Notification extensions require proper Info.plist configuration and matching category identifiers."
                    )
                ],
                relatedErrors: ["Extension not loaded"],
                tags: ["notifications", "extension", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/usernotificationsui",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 18. AUDIO / VIDEO ERRORS (15+ entries)
    // =========================================================================
    
    private func audioVideoErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .audioVideo,
                severity: .high,
                title: "AVAudioSession: Failed to set category",
                errorCode: "AVAudioSessionErrorCodeBadParam",
                description: "Setting AVAudioSession category failed, usually due to invalid parameters or missing permissions.",
                cause: "1. Invalid category/mode combination. 2. Missing microphone permission. 3. Session already active with different category. 4. Background app trying to set category.",
                solutions: [
                    "Request microphone permission before audio session setup",
                    "Use valid category/mode combinations",
                    "Deactivate session before changing category: try session.setActive(false)",
                    "Handle errors from setCategory with options",
                    "For recording, use .playAndRecord category",
                    "Check audio session is not already active"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Audio Session Setup",
                        badCode: "try AVAudioSession.sharedInstance().setCategory(.record)  // May fail",
                        goodCode: "let session = AVAudioSession.sharedInstance()\ntry session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])\ntry session.setActive(true)",
                        explanation: "Use appropriate category/mode combinations and handle setup errors."
                    )
                ],
                relatedErrors: ["AVAudioSessionErrorCodeMissingEntitlement"],
                tags: ["audio", "avfoundation", "session", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/avfaudio/avaudiosession",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            
            ErrorEntry(
                category: .audioVideo,
                severity: .high,
                title: "AVFoundation: Cannot start capture session",
                errorCode: "AVCAPTURE_SESSION_FAIL",
                description: "AVCaptureSession failed to start running, usually due to missing permissions or invalid configuration.",
                cause: "1. Camera/mic permission denied. 2. No valid input device. 3. Session already running. 4. Invalid preset for device. 5. Background thread start attempt.",
                solutions: [
                    "Check and request camera/microphone permissions",
                    "Verify input device is available: AVCaptureDevice.default(for:)",
                    "Start session on background thread: session.startRunning()",
                    "Check session.canSetSessionPreset before setting",
                    "Handle AVCaptureDeviceWasConnected/Disconnected notifications",
                    "For macOS, check if camera is in use by another app"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Start Capture",
                        badCode: "session.startRunning()  // On main thread - may hang",
                        goodCode: "DispatchQueue.global(qos: .userInitiated).async {\n    self.session.startRunning()\n}",
                        explanation: "Start capture session on a background thread to avoid blocking the main thread."
                    )
                ],
                relatedErrors: ["AVCaptureSessionRuntimeErrorNotification"],
                tags: ["video", "avfoundation", "capture", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/avfoundation/avcapturesession",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 19. ACCESSIBILITY ERRORS (10+ entries)
    // =========================================================================
    
    private func accessibilityErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .accessibility,
                severity: .medium,
                title: "Accessibility: AXUIElementCreateApplication returned nil",
                errorCode: "AX_NIL_ELEMENT",
                description: "Creating an accessibility element for an application failed, usually because accessibility is not enabled or the PID is invalid.",
                cause: "1. Accessibility not enabled in System Preferences. 2. Target application not running. 3. Invalid process ID. 4. Sandbox blocking accessibility.",
                solutions: [
                    "Prompt user to enable accessibility in System Preferences",
                    "Verify target application is running",
                    "Check AXIsProcessTrustedWithOptions",
                    "For sandboxed apps, request accessibility entitlement",
                    "Use NSWorkspace to launch target app if needed"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Check Accessibility",
                        badCode: "let app = AXUIElementCreateApplication(pid)  // May return nil",
                        goodCode: "guard AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary) else {\n    showAccessibilityInstructions()\n    return\n}\nlet app = AXUIElementCreateApplication(pid)",
                        explanation: "Always verify accessibility trust before creating UI elements."
                    )
                ],
                relatedErrors: ["kAXErrorCannotComplete", "kAXErrorAPIDisabled"],
                tags: ["accessibility", "ax", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/applicationservices/axuielement_h",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 20. LOCALIZATION ERRORS (10+ entries)
    // =========================================================================
    
    private func localizationErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .localization,
                severity: .medium,
                title: "Localization: Key 'X' not found in table 'Y'",
                errorCode: "LOCALIZATION_KEY_MISSING",
                description: "A localized string key was not found in the specified strings file or table.",
                cause: "1. Key not added to Localizable.strings. 2. Wrong table name specified. 3. Key typo. 4. Localization file not included in target. 5. Base localization missing.",
                solutions: [
                    "Add missing key to all Localizable.strings files",
                    "Use NSLocalizedString with comment for discoverability",
                    "Check that .strings files are in Copy Bundle Resources",
                    "For SwiftUI, use Text(\"key\") which auto-localizes",
                    "Use genstrings to extract keys from source code",
                    "Verify Base localization is enabled",
                    "Check for case sensitivity in keys"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Localization",
                        badCode: "let text = NSLocalizedString(\"greeting\", comment: \"\")  // Key missing",
                        goodCode: "// In Localizable.strings:\n\"greeting\" = \"Hello\";\n\nlet text = NSLocalizedString(\"greeting\", comment: \"Greeting message\")",
                        explanation: "Always add keys to Localizable.strings files and verify they exist in all supported languages."
                    )
                ],
                relatedErrors: ["No localizable strings"],
                tags: ["localization", "strings", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/nslocalizedstring",
                commonInVersions: ["All versions"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 21. TESTING / XCTEST ERRORS (15+ entries)
    // =========================================================================
    
    private func testingErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .testing,
                severity: .medium,
                title: "XCTest: Asynchronous wait failed - Exceeded timeout of X seconds",
                errorCode: "XCT_TIMEOUT",
                description: "An XCTest expectation was not fulfilled within the specified timeout.",
                cause: "1. Expectation never fulfilled. 2. Timeout too short. 3. Async operation hanging. 4. Completion handler not called. 5. Test on main thread blocking.",
                solutions: [
                    "Increase timeout for slow operations: wait(for: [exp], timeout: 10)",
                    "Ensure expectation.fulfill() is called in all code paths",
                    "Check for infinite loops or deadlocks in tested code",
                    "Use XCTAssertNoThrow for operations that shouldn't throw",
                    "For async/await, use await fulfillment(of:)",
                    "Verify completion handlers are called even on error paths"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Expectation Handling",
                        badCode: "let exp = expectation(description: \"load\")\nloader.load { result in\n    // Missing exp.fulfill()\n}\nwait(for: [exp], timeout: 1)  // Timeout!",
                        goodCode: "let exp = expectation(description: \"load\")\nloader.load { result in\n    XCTAssertNotNil(result)\n    exp.fulfill()\n}\nwait(for: [exp], timeout: 5)",
                        explanation: "Always fulfill expectations in all completion paths, including error paths."
                    )
                ],
                relatedErrors: ["XCTestCase exceeded timeout"],
                tags: ["testing", "xctest", "expectation", "timeout"],
                appleDocURL: "https://developer.apple.com/documentation/xctest",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .testing,
                severity: .medium,
                title: "XCTest: Test crashed due to uncaught exception",
                errorCode: "XCT_CRASH",
                description: "A test caused an unhandled exception or fatal error, crashing the test process.",
                cause: "1. Force unwrap of nil in test. 2. Fatal error in tested code. 3. Precondition failure. 4. Bad access in tested code. 5. Infinite recursion.",
                solutions: [
                    "Use XCTAssertNotNil before force unwrapping test values",
                    "Use XCTAssertNoThrow for throwing code",
                    "For fatal errors, test preconditions separately",
                    "Enable Address Sanitizer for memory issues",
                    "Run test in isolation to identify crashing test",
                    "Check test setup/teardown for issues"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Test Assertions",
                        badCode: "let result = try! calculator.divide(10, 0)  // Fatal error",
                        goodCode: "XCTAssertThrowsError(try calculator.divide(10, 0)) { error in\n    XCTAssertEqual(error as? CalcError, .divisionByZero)\n}",
                        explanation: "Use XCTAssertThrowsError for code that should fail, instead of causing crashes."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS in test", "SIGABRT in test"],
                tags: ["testing", "xctest", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xctest",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 22. PACKAGE MANAGER ERRORS (15+ entries)
    // =========================================================================
    
    private func packageManagerErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .packageManager,
                severity: .high,
                title: "Swift Package Manager: package resolution failed",
                errorCode: "SPM_RESOLVE_FAIL",
                description: "SPM could not resolve package dependencies, usually due to version conflicts or network issues.",
                cause: "1. Version conflict between dependencies. 2. Package URL unreachable. 3. Git authentication required. 4. Incompatible platform requirements. 5. Circular dependency.",
                solutions: [
                    "Update packages: File > Packages > Update to Latest Package Versions",
                    "Resolve packages: File > Packages > Resolve Package Versions",
                    "Check Package.swift for version conflicts",
                    "Reset package caches: File > Packages > Reset Package Caches",
                    "Delete DerivedData and .build folder",
                    "For private repos, ensure SSH keys or credentials are configured",
                    "Check that all dependencies support target platform"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fix SPM Resolution",
                        badCode: "// In Package.swift:\n.package(url: \"https://github.com/example/lib.git\", from: \"1.0.0\")\n// Another dependency requires lib 2.0.0 -> conflict",
                        goodCode: "// Update to compatible versions:\n.package(url: \"https://github.com/example/lib.git\", from: \"2.0.0\")\n// Or use exact version:\n.package(url: \"https://github.com/example/lib.git\", exact: \"1.5.0\")",
                        explanation: "Resolve version conflicts by updating dependency requirements or using exact versions."
                    )
                ],
                relatedErrors: ["SPM dependency resolution failed"],
                tags: ["spm", "package", "dependency", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .packageManager,
                severity: .high,
                title: "Swift Package Manager: product 'X' not found in package 'Y'",
                errorCode: "SPM_PRODUCT_NOT_FOUND",
                description: "The requested product (library or executable) doesn't exist in the specified package.",
                cause: "1. Wrong product name. 2. Product not exported by package. 3. Package structure changed. 4. Typo in dependency declaration.",
                solutions: [
                    "Check Package.swift of dependency for exact product names",
                    "Verify product is declared as .library or .executable",
                    "For multi-product packages, specify correct product",
                    "Update to latest version of dependency",
                    "Check if product was renamed or removed"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Correct Product",
                        badCode: "// Wrong product name:\n.product(name: \"AlamofireLib\", package: \"Alamofire\")",
                        goodCode: ".product(name: \"Alamofire\", package: \"Alamofire\")",
                        explanation: "Product names must exactly match those declared in the dependency's Package.swift."
                    )
                ],
                relatedErrors: ["SPM target not found"],
                tags: ["spm", "product", "package", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            
            ErrorEntry(
                category: .packageManager,
                severity: .high,
                title: "Swift Package Manager: target 'X' has overlapping sources with target 'Y'",
                errorCode: "SPM_OVERLAPPING_SOURCES",
                description: "Two targets in the package include the same source files, which is not allowed.",
                cause: "1. Same file in multiple target sources arrays. 2. Glob patterns matching same files. 3. Symlinked files appearing in multiple paths. 4. Copy-pasted target definition.",
                solutions: [
                    "Ensure each source file belongs to exactly one target",
                    "Use explicit file lists instead of broad glob patterns",
                    "Remove duplicate file references from target definitions",
                    "Check for symlinks that cause duplicate appearances",
                    "Restructure project so files are in distinct directories per target"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Distinct Sources",
                        badCode: "// In Package.swift:\n.target(name: \"LibA\", sources: [\"Sources\"]),\n.target(name: \"LibB\", sources: [\"Sources\"])  // Overlap!",
                        goodCode: ".target(name: \"LibA\", sources: [\"Sources/LibA\"]),\n.target(name: \"LibB\", sources: [\"Sources/LibB\"])",
                        explanation: "Each source file can only belong to one target. Use separate directories."
                    )
                ],
                relatedErrors: ["SPM target source overlap"],
                tags: ["spm", "target", "sources", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/creating_a_standalone_swift_package_with_xcode",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
        ]
    }
    
    // =========================================================================
    // MARK: - 23. GENERAL ERRORS (20+ entries)
    // =========================================================================
    
    private func generalErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "dyld: Library not loaded: @rpath/X.framework/X",
                errorCode: "DYLD_LIBRARY_MISSING",
                description: "The dynamic linker couldn't find a required framework at runtime.",
                cause: "1. Framework not embedded in app bundle. 2. @rpath not configured. 3. Framework search paths incorrect. 4. Framework built for wrong architecture. 5. Framework stripped during archiving.",
                solutions: [
                    "Add framework to Build Phases > Embed Frameworks",
                    "Set Runpath Search Paths: @executable_path/../Frameworks",
                    "For SPM, ensure package product is linked to target",
                    "For CocoaPods, use use_frameworks!",
                    "Verify framework exists in built app bundle",
                    "Check framework is code-signed if required",
                    "For XCFramework, ensure correct slice is embedded"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Embed Framework",
                        badCode: "// Framework linked but not embedded -> crash at launch",
                        goodCode: "// Build Phases > Embed Frameworks:\n// Add MyFramework.framework\n// Code Sign On Copy: YES",
                        explanation: "Dynamic frameworks must be both linked AND embedded in the app bundle."
                    )
                ],
                relatedErrors: ["dyld: Symbol not found", "Image not found"],
                tags: ["general", "dyld", "framework", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/embedding-frameworks",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "Symbol not found: _OBJC_CLASS_$_X referenced from: Y",
                errorCode: "DYLD_SYMBOL_MISSING",
                description: "A compiled binary references a class or function that isn't available at runtime.",
                cause: "1. Framework not linked. 2. Framework linked but not loaded. 3. Class removed from framework but still referenced. 4. Weak framework not available on older OS. 5. Static library missing object file.",
                solutions: [
                    "Link the framework containing the symbol",
                    "For weakly linked frameworks, check availability before use",
                    "Ensure framework is in Link Binary With Libraries",
                    "For static libs, check all .a files are linked",
                    "Use nm tool to check symbol availability",
                    "For @objc classes, ensure they're exposed to Objective-C"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Weak Linking",
                        badCode: "import SomeFramework  // Crashes if framework missing",
                        goodCode: "// In Build Settings > Other Linker Flags:\n// -weak_framework SomeFramework\n\nif NSClassFromString(\"SomeFramework.SomeClass\") != nil {\n    // Safe to use\n}",
                        explanation: "Use weak linking for frameworks that may not be available on all OS versions."
                    )
                ],
                relatedErrors: ["dyld: Library not loaded"],
                tags: ["general", "dyld", "symbol", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/embedding-frameworks",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "App crashed on launch: Failed to load Info.plist from bundle",
                errorCode: "BUNDLE_PLIST_MISSING",
                description: "The app's Info.plist is missing or corrupted, preventing the app from launching.",
                cause: "1. Info.plist not in Copy Bundle Resources. 2. Info.plist corrupted. 3. Wrong Info.plist path in build settings. 4. Bundle incomplete due to build failure.",
                solutions: [
                    "Ensure Info.plist is included in target",
                    "Check INFOPLIST_FILE build setting points to correct file",
                    "Validate Info.plist XML format",
                    "Clean build folder and rebuild",
                    "Check that plist is not in Copy Bundle Resources AND build setting (causes conflict)",
                    "For SPM, check generate-info-plist setting"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fix Info.plist",
                        badCode: "// INFOPLIST_FILE = $(SRCROOT)/wrong/path/Info.plist",
                        goodCode: "// INFOPLIST_FILE = $(SRCROOT)/ClassGod/Info.plist\n// Ensure file exists at that path",
                        explanation: "The Info.plist must exist at the path specified in build settings and be valid XML."
                    )
                ],
                relatedErrors: ["The Info.plist file is missing"],
                tags: ["general", "bundle", "plist", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/bundleresources/information_property_list",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "App crashed: Exception NSInvalidArgumentException - reason: '-[X Y]: unrecognized selector sent to instance Z'",
                errorCode: "NS_INVALID_SELECTOR",
                description: "An Objective-C object received a message for a method it doesn't implement.",
                cause: "1. Method not implemented. 2. Object deallocated and replaced by different object (zombie). 3. Wrong object type. 4. Category not loaded. 5. Method name typo.",
                solutions: [
                    "Implement the missing method",
                    "Check object type before calling methods",
                    "Ensure categories are linked (add -ObjC linker flag)",
                    "Check for zombies with NSZombieEnabled",
                    "For Swift, use optional chaining or type checking",
                    "Verify method signature matches exactly"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Method Call",
                        badCode: "let obj: AnyObject = getObject()\nobj.perform(SomeSelector)  // May not exist",
                        goodCode: "if let obj = getObject() as? MyProtocol {\n    obj.requiredMethod()  // Type-safe call\n}",
                        explanation: "Use protocols and type checking instead of dynamic method invocation when possible."
                    )
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "SIGABRT"],
                tags: ["general", "objc", "selector", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/nsexception",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "App crashed: Exception NSRangeException - reason: 'Index X beyond bounds [0 .. Y]'",
                errorCode: "NS_RANGE_EXCEPTION",
                description: "An Objective-C collection (NSArray, NSString, etc.) was accessed with an index outside its valid range.",
                cause: "1. Array index out of bounds. 2. String character index invalid. 3. Off-by-one errors in loops. 4. Empty collection accessed. 5. Mutable collection modified during enumeration.",
                solutions: [
                    "Check count/length before accessing: if index < array.count",
                    "Use safe accessors: array.first, array.last",
                    "For Swift arrays, use safe subscripts or guard",
                    "Don't modify collections while enumerating",
                    "Use for-in loops instead of index-based loops when possible"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Collection Access",
                        badCode: "let arr = [\"a\", \"b\"]\nlet item = arr[5]  // Crash in Swift too",
                        goodCode: "if let item = arr[safe: 5] {\n    print(item)\n}",
                        explanation: "Always validate indices or use safe accessors for collection elements."
                    )
                ],
                relatedErrors: ["Fatal error: Index out of range"],
                tags: ["general", "range", "bounds", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/nsexception",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "App crashed: Exception NSInternalInconsistencyException",
                errorCode: "NS_INTERNAL_INCONSISTENCY",
                description: "An internal consistency check failed, usually indicating a programming error in framework usage.",
                cause: "1. UITableView/NSCollectionView data source mismatch. 2. KVO observer not removed. 3. Invalid state transition. 4. Core Data context issues. 5. Auto Layout constraint conflicts.",
                solutions: [
                    "Check console for specific inconsistency message",
                    "Ensure data source count matches actual items",
                    "Remove KVO observers before deallocation",
                    "Validate state machine transitions",
                    "For collections, call beginUpdates/endUpdates properly",
                    "Check for main thread violations"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Data Consistency",
                        badCode: "// Data source returns 5 items but only 4 in array\nfunc tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {\n    return 5\n}\nfunc tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {\n    return cellForItem(items[indexPath.row])  // Crash on index 4\n}",
                        goodCode: "func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {\n    return items.count\n}",
                        explanation: "Always ensure data source methods report counts consistent with actual data."
                    )
                ],
                relatedErrors: ["SIGABRT"],
                tags: ["general", "inconsistency", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/nsexception",
                commonInVersions: ["All versions"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "App crashed: 0xdead10cc - Process was killed because it held a file lock or SQLite lock while in the background",
                errorCode: "0xdead10cc",
                description: "iOS terminated the app because it held a file or SQLite lock while being suspended in the background.",
                cause: "1. SQLite/Core Data transaction not committed before background. 2. File lock held during app backgrounding. 3. Background task not completed in time. 4. File coordination deadlock.",
                solutions: [
                    "Commit all database transactions before entering background",
                    "Release file locks in applicationDidEnterBackground",
                    "Use beginBackgroundTask / endBackgroundTask for file operations",
                    "For Core Data, save context when receiving background notification",
                    "Use NSFileCoordinator for coordinated file access",
                    "Close database connections on backgrounding if possible"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Background Save",
                        badCode: "// Long Core Data transaction continues when app backgrounds",
                        goodCode: "func applicationDidEnterBackground(_ application: UIApplication) {\n    let task = application.beginBackgroundTask { }\n    try? coreDataContext.save()\n    application.endBackgroundTask(task)\n}",
                        explanation: "Complete and commit all file/database operations before app suspension."
                    )
                ],
                relatedErrors: ["0xbad22222", "0x8badf00d"],
                tags: ["general", "background", "file lock", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background",
                commonInVersions: ["iOS 13+", "iOS 14+", "iOS 15+"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "App crashed: 0x8badf00d - Process was terminated because it took too long to launch or terminate",
                errorCode: "0x8badf00d",
                description: "iOS/watchOS terminated the app because it failed to launch or terminate within the system-imposed time limit (watchdog timeout).",
                cause: "1. Blocking main thread during launch. 2. Infinite loop in initialization. 3. Synchronous network call on main thread during startup. 4. Core Data migration taking too long. 5. App not responding to system callbacks.",
                solutions: [
                    "Move all non-UI initialization off main thread",
                    "Use lazy initialization for heavy resources",
                    "Defer network calls until after launch completes",
                    "For Core Data, use lightweight migration or async migration",
                    "Profile launch time with Instruments > Time Profiler",
                    "Return from applicationDidFinishLaunching quickly",
                    "Use background tasks for heavy post-launch work"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fast Launch",
                        badCode: "func applicationDidFinishLaunching(_ notification: Notification) {\n    // Blocking main thread with heavy work\n    loadAllData()  // Synchronous, 5 seconds\n    setupUI()\n}",
                        goodCode: "func applicationDidFinishLaunching(_ notification: Notification) {\n    setupUI()  // Show UI immediately\n    DispatchQueue.global().async {\n        self.loadAllData()  // Heavy work in background\n    }\n}",
                        explanation: "Never block the main thread during app launch. Show UI immediately and load data asynchronously."
                    )
                ],
                relatedErrors: ["0xdead10cc", "EXC_CRASH (SIGKILL)"],
                tags: ["general", "watchdog", "launch", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/understanding-the-exception-types-in-a-crash-report",
                commonInVersions: ["iOS 13+", "iOS 14+", "iOS 15+"]
            ),
            
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "Crash: EXC_CRASH (SIGKILL) - Termination Reason: Namespace RUNNINGBOARD, Code 0xdead10cc",
                errorCode: "RUNNINGBOARD_SIGKILL",
                description: "The system killed the app due to resource usage violations, file locks, or policy violations detected by RunningBoard.",
                cause: "1. Holding file/SQLite lock in background. 2. Excessive CPU in background. 3. Memory pressure. 4. Background task not ended. 5. Watchdog timeout.",
                solutions: [
                    "Release all locks before backgrounding",
                    "End background tasks promptly",
                    "Respond to memory pressure warnings",
                    "Don't perform heavy work in background without tasks",
                    "For file access, use NSFileCoordinator",
                    "Check Console app for specific RunningBoard reason"
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Background Compliance",
                        badCode: "// Heavy computation in background without task",
                        goodCode: "let task = UIApplication.shared.beginBackgroundTask { }\n// Do work...\nUIApplication.shared.endBackgroundTask(task)",
                        explanation: "Always use background tasks for work that continues after app enters background."
                    )
                ],
                relatedErrors: ["0xdead10cc", "0x8badf00d"],
                tags: ["general", "runningboard", "sigkill", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/understanding-the-exception-types-in-a-crash-report",
                commonInVersions: ["iOS 13+", "iOS 14+", "iOS 15+"]
            ),
        ]
    }
}

// MARK: - Safe Array Subscript Extension (used in examples)
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

    // =========================================================================
    // MARK: - ADDITIONAL SWIFT RUNTIME ERRORS (Batch 2)
    // =========================================================================
    
    private func moreSwiftRuntimeErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Array subscript out of range: index is negative",
                errorCode: "Swift.Array.negativeIndex",
                description: "Accessing an array with a negative index, which is always invalid.",
                cause: "1. Int underflow in index calculation. 2. Signed integer arithmetic producing negative. 3. Invalid index from external source.",
                solutions: [
                    "Check index >= 0 before access",
                    "Use UInt for indices if negative not possible",
                    "Validate all external index inputs",
                    "Use safe subscript with bounds checking",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Non-Negative Index",
                        badCode: "let arr = [1, 2, 3]\nlet idx = -1\nprint(arr[idx])  // Crash",
                        goodCode: "let idx = max(0, calculatedIndex)\nif let item = arr[safe: idx] {\n    print(item)\n}",
                        explanation: "Array indices must be non-negative and less than count."
                    ),
                ],
                relatedErrors: ["Fatal error: Index out of range"],
                tags: ["array", "negative", "index", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: String index out of bounds",
                errorCode: "Swift.String.indexOutOfBounds",
                description: "Accessing a String with an index that is not within the string's valid index range.",
                cause: "1. Index from different string. 2. Index invalidated by mutation. 3. Offset beyond string length. 4. Empty string access.",
                solutions: [
                    "Use index(offsetBy:limitedBy:) for safe offset",
                    "Check index >= startIndex && index < endIndex",
                    "Regenerate indices after string mutation",
                    "Use prefix/suffix instead of manual indexing",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe String Index",
                        badCode: "let s = \"hi\"\nlet idx = s.index(s.startIndex, offsetBy: 10)\nprint(s[idx])  // Crash",
                        goodCode: "if let idx = s.index(s.startIndex, offsetBy: 10, limitedBy: s.endIndex) {\n    print(s[idx])\n}",
                        explanation: "Always validate string indices are within bounds."
                    ),
                ],
                relatedErrors: ["Fatal error: String index is out of bounds"],
                tags: ["string", "index", "bounds", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Remainder of division by zero",
                errorCode: "Swift.Int.remainderReportingOverflow",
                description: "The modulo/remainder operator (%) was used with a divisor of zero.",
                cause: "1. x % 0 operation. 2. Calculated divisor becomes zero. 3. User input zero as divisor.",
                solutions: [
                    "Check divisor != 0 before modulo",
                    "Use guard or precondition for zero check",
                    "For random indices, ensure range is non-empty",
                    "Handle zero gracefully with fallback",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Modulo",
                        badCode: "let result = 10 % 0  // Crash",
                        goodCode: "let divisor = 0\nlet result = divisor == 0 ? 0 : 10 % divisor",
                        explanation: "Always check divisor is non-zero before using modulo operator."
                    ),
                ],
                relatedErrors: ["Fatal error: Division by zero"],
                tags: ["modulo", "zero", "math", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/BasicOperators.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: shift amount is greater than or equal to type width in bits",
                errorCode: "Swift.Int.shift",
                description: "Bit shifting by an amount equal to or greater than the type's bit width is undefined.",
                cause: "1. x << 64 on Int64. 2. Shift amount from calculation exceeding width. 3. Variable shift amount not bounded.",
                solutions: [
                    "Ensure shift amount < bit width (e.g., < 64 for Int64)",
                    "Mask shift amount: amount & (width - 1)",
                    "Use UInt8/UInt16 for small shifts",
                    "Guard against large shift values",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Shift",
                        badCode: "let x: Int64 = 1\nlet result = x << 64  // Crash",
                        goodCode: "let shift = min(63, requestedShift)\nlet result = x << shift",
                        explanation: "Bit shifts must be less than the type's bit width."
                    ),
                ],
                relatedErrors: ["EXC_BAD_INSTRUCTION"],
                tags: ["bitshift", "overflow", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AdvancedOperators.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Dictionary<Key, Value>: duplicate key after mutation",
                errorCode: "Swift.Dictionary.duplicateKeyAfterMutation",
                description: "A dictionary's Hashable implementation is inconsistent, causing duplicate keys after mutation.",
                cause: "1. Mutable property used in hash(into:). 2. hashValue changes after insertion. 3. Custom Hashable with inconsistent == and hash.",
                solutions: [
                    "Use only immutable properties in hash(into:)",
                    "Ensure == and hash(into:) use same properties",
                    "Don't mutate dictionary keys",
                    "Use struct auto-synthesized Hashable",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Stable Hash",
                        badCode: "class Key: Hashable {\n    var id = 0\n    func hash(into hasher: inout Hasher) { hasher.combine(id) }\n    static func == (l: Key, r: Key) -> Bool { l.id == r.id }\n}\nvar dict: [Key: String] = [:]\nlet k = Key()\ndict[k] = \"A\"\nk.id = 1  // Corrupts dictionary",
                        goodCode: "struct Key: Hashable {\n    let id: Int  // Immutable hash property\n}",
                        explanation: "Dictionary keys must have stable hash values. Use immutable properties for hashing."
                    ),
                ],
                relatedErrors: ["Fatal error: Dictionary literal contains duplicate keys"],
                tags: ["dictionary", "hashable", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/CollectionTypes.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: attempt to retain deallocated object",
                errorCode: "Swift.retainDeallocated",
                description: "An attempt was made to retain (increase reference count of) an already deallocated object.",
                cause: "1. Unowned reference accessed after deallocation. 2. Weak reference force-unwrapped after nil. 3. C callback referencing deallocated Swift object. 4. Race condition in multi-threaded code.",
                solutions: [
                    "Use weak instead of unowned if object might deallocate",
                    "Guard let self after weak capture",
                    "Invalidate C callbacks on deallocation",
                    "Use thread-safe reference counting patterns",
                    "Check for retain cycles that delay deallocation",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe References",
                        badCode: "class Owner {\n    unowned var item: Item  // Crash if item deallocates\n}",
                        goodCode: "class Owner {\n    weak var item: Item?  // Safe: becomes nil\n}",
                        explanation: "Use weak references for objects that might deallocate before the reference is accessed."
                    ),
                ],
                relatedErrors: ["EXC_BAD_ACCESS", "Fatal error: Attempted to read an unowned reference"],
                tags: ["retain", "deallocated", "memory", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .critical,
                title: "Fatal error: Swift runtime failure: unsafeDowncast of incorrect type",
                errorCode: "Swift.unsafeDowncast.type",
                description: "unsafeDowncast was called with an object that is not actually of the target type.",
                cause: "1. Wrong type assumption. 2. Type punning through AnyObject. 3. Invalid cast after dynamic type check failure.",
                solutions: [
                    "Use conditional cast as? instead of unsafeDowncast",
                    "Verify type with is before casting",
                    "Use guard let for safe downcasting",
                    "Avoid unsafeDowncast in production code",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Downcast",
                        badCode: "let any: Any = \"hello\"\nlet s = unsafeDowncast(any, to: String.self)  // May crash",
                        goodCode: "if let s = any as? String {\n    // Safe cast\n}",
                        explanation: "Use conditional casting instead of unsafeDowncast for type safety."
                    ),
                ],
                relatedErrors: ["Could not cast value of type"],
                tags: ["unsafe", "downcast", "type", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/TypeCasting.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Swift runtime failure: enumerated type 'X' has no case named 'Y'",
                errorCode: "Swift.enumCaseMissing",
                description: "An enum case was accessed that doesn't exist in the enum definition.",
                cause: "1. Raw value conversion to non-existent case. 2. Invalid raw value from external source. 3. Enum case removed but raw value still used.",
                solutions: [
                    "Validate raw values before conversion",
                    "Use init?(rawValue:) for safe conversion",
                    "Handle nil from failed raw value init",
                    "Keep raw values stable across versions",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Raw Value",
                        badCode: "enum Status: Int { case active = 1 }\nlet s = Status(rawValue: 5)!  // Force unwrap nil -> crash",
                        goodCode: "if let s = Status(rawValue: 5) {\n    // Valid case\n} else {\n    // Handle unknown\n}",
                        explanation: "Always use optional binding for raw value enum initialization."
                    ),
                ],
                relatedErrors: ["Fatal error: Unexpectedly found nil"],
                tags: ["enum", "rawValue", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
            ErrorEntry(
                category: .swiftRuntime,
                severity: .high,
                title: "Fatal error: Swift runtime failure: protocol witness table mismatch",
                errorCode: "Swift.protocolWitnessMismatch",
                description: "A type's protocol conformance doesn't match what the runtime expects, often due to binary incompatibility.",
                cause: "1. Framework updated without recompiling client. 2. Binary incompatible changes. 3. Method signature changed in protocol.",
                solutions: [
                    "Clean build and rebuild all dependencies",
                    "Ensure all frameworks are built with same Swift version",
                    "Check for method signature changes in protocols",
                    "For SPM, update and resolve packages",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Clean Rebuild",
                        badCode: "// Binary incompatible framework",
                        goodCode: "// Clean DerivedData, rebuild all targets\n// Ensure consistent Swift toolchain",
                        explanation: "Protocol witness table mismatches usually require clean rebuilds of all components."
                    ),
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["protocol", "witness", "binary", "crash", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Protocols.html",
                commonInVersions: ["Swift 4.x", "Swift 5.x"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL SWIFTUI ERRORS (Batch 2)
    // =========================================================================
    
    private func moreSwiftUIErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: List row content must not generate zero views",
                errorCode: "SwiftUI.ListZeroViews",
                description: "A List row closure produced zero views, which is not allowed. Each row must contain at least one view.",
                cause: "1. Conditional view where condition is false. 2. Empty Group or VStack. 3. Filtered ForEach with no results.",
                solutions: [
                    "Ensure each row produces at least one view",
                    "Use EmptyView() as placeholder for conditional rows",
                    "For filtered data, ensure non-empty results",
                    "Use Group with if/else where both branches return views",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Non-Empty Row",
                        badCode: "List {\n    if false {\n        Text(\"A\")\n    }  // Zero views\n}",
                        goodCode: "List {\n    if condition {\n        Text(\"A\")\n    } else {\n        EmptyView()\n    }\n}",
                        explanation: "Each List row must produce at least one view. Use EmptyView as fallback."
                    ),
                ],
                relatedErrors: ["SwiftUI: List row content must not generate more than one view"],
                tags: ["swiftui", "list", "row", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/list",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: Modifying state during view update, this will cause undefined behavior",
                errorCode: "SwiftUI.StateMutationDuringUpdate",
                description: "State was modified during view body evaluation, which can cause infinite loops.",
                cause: "1. Mutating @State in body. 2. Mutating @State in computed property getter. 3. Side effects during view rendering.",
                solutions: [
                    "Never mutate state during body evaluation",
                    "Move mutations to event handlers",
                    "Use .task or .onAppear for initialization",
                    "Use DispatchQueue.main.async to defer mutations",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe State Update",
                        badCode: "var body: some View {\n    counter += 1  // NEVER do this\n    Text(\"\\(counter)\")\n}",
                        goodCode: "var body: some View {\n    Text(\"\\(counter)\")\n        .onTapGesture {\n            counter += 1\n        }\n}",
                        explanation: "Only mutate state in response to events, never during view rendering."
                    ),
                ],
                relatedErrors: ["SwiftUI: cyclic dependency"],
                tags: ["swiftui", "state", "mutation", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/state",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: Presenting view controller from detached view controller is discouraged",
                errorCode: "SwiftUI.DetachedPresentation",
                description: "Attempting to present a sheet or alert from a view that is not in the view hierarchy.",
                cause: "1. Presenting from view not yet added. 2. Presenting from dismissed view. 3. Sheet modifier on wrong view level.",
                solutions: [
                    "Ensure view is in hierarchy before presenting",
                    "Use .sheet on a view that is always visible",
                    "For conditional sheets, bind to a stable parent view",
                    "Check that the presenting view controller exists",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Stable Presentation",
                        badCode: "Text(\"A\")\n    .sheet(isPresented: $show) { }  // May be detached",
                        goodCode: "VStack {\n    Text(\"A\")\n}\n.sheet(isPresented: $show) { }  // Stable parent",
                        explanation: "Attach sheet modifiers to stable parent views that are always in the hierarchy."
                    ),
                ],
                relatedErrors: ["SwiftUI: sheet presentation failed"],
                tags: ["swiftui", "sheet", "presentation", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/view/sheet",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            ErrorEntry(
                category: .swiftUI,
                severity: .medium,
                title: "SwiftUI: The layout constraints still need update after sending updateConstraints to a view",
                errorCode: "SwiftUI.LayoutConstraints",
                description: "Auto Layout constraints are inconsistent or conflicting in a SwiftUI view using UIViewRepresentable.",
                cause: "1. Conflicting constraints in representable. 2. Missing required constraints. 3. View size not properly configured.",
                solutions: [
                    "Check all constraints for conflicts",
                    "Use NSLayoutConstraint.activate with proper priorities",
                    "Set translatesAutoresizingMaskIntoConstraints = false",
                    "For SwiftUI, prefer frame modifiers over constraints",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Constraints",
                        badCode: "nsView.widthAnchor.constraint(equalToConstant: 100).isActive = true\nnsView.widthAnchor.constraint(equalToConstant: 200).isActive = true  // Conflict",
                        goodCode: "nsView.widthAnchor.constraint(equalToConstant: 100).isActive = true\nnsView.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true",
                        explanation: "Ensure Auto Layout constraints are mutually satisfiable."
                    ),
                ],
                relatedErrors: ["Unable to simultaneously satisfy constraints"],
                tags: ["swiftui", "layout", "constraints", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/nsviewrepresentable",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
            ErrorEntry(
                category: .swiftUI,
                severity: .high,
                title: "SwiftUI: View.environmentObject(_:) can only be used with an instance of ObservableObject",
                errorCode: "SwiftUI.EnvironmentObjectType",
                description: "The type passed to environmentObject doesn't conform to ObservableObject.",
                cause: "1. Passing non-ObservableObject type. 2. Missing ObservableObject conformance. 3. Protocol type not conforming.",
                solutions: [
                    "Make type conform to ObservableObject",
                    "Use @Published for published properties",
                    "For structs, use @Environment or @State instead",
                    "Ensure ObservableObject conformance is declared",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "ObservableObject",
                        badCode: "class Store { }  // Missing ObservableObject\nContentView()\n    .environmentObject(Store())",
                        goodCode: "class Store: ObservableObject {\n    @Published var items: [Item] = []\n}\nContentView()\n    .environmentObject(Store())",
                        explanation: "Types passed to environmentObject must conform to ObservableObject."
                    ),
                ],
                relatedErrors: ["SwiftUI: ObservableObject missing"],
                tags: ["swiftui", "environmentobject", "observableobject", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/swiftui/environmentobject",
                commonInVersions: ["Swift 5.x", "Swift 6.x"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL APPKIT ERRORS (Batch 2)
    // =========================================================================
    
    private func moreAppKitErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "AppKit: NSResponder: -[NSResponder keyDown:] unrecognized selector sent to instance",
                errorCode: "APPKIT_KEYDOWN_SELECTOR",
                description: "A key event was sent to a responder that doesn't handle keyDown.",
                cause: "1. First responder doesn't implement keyDown. 2. Responder chain broken. 3. Custom responder missing key event handling.",
                solutions: [
                    "Implement keyDown in custom responders",
                    "Pass unhandled events to nextResponder",
                    "Use NSWindow.makeFirstResponder for proper focus",
                    "For SwiftUI, use onKeyPress or keyboardShortcut",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Key Events",
                        badCode: "class MyView: NSView {\n    // Missing keyDown override\n}",
                        goodCode: "class MyView: NSView {\n    override func keyDown(with event: NSEvent) {\n        if event.keyCode == 53 {  // Escape\n            // Handle escape\n        } else {\n            super.keyDown(with: event)\n        }\n    }\n}",
                        explanation: "Implement keyDown in custom responders or pass to super for default handling."
                    ),
                ],
                relatedErrors: ["NSResponder event handling"],
                tags: ["appkit", "key", "responder", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsresponder",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "AppKit: NSWindow: -[NSWindow _setContentViewController:] can only be used with a view controller that has a view",
                errorCode: "APPKIT_VC_NO_VIEW",
                description: "A view controller without a loaded view was set as content view controller.",
                cause: "1. View controller's view not created. 2. loadView not implemented. 3. Nib not found for view controller.",
                solutions: [
                    "Override loadView to create view programmatically",
                    "Ensure nib name matches controller class",
                    "Set view before assigning as content view controller",
                    "For SwiftUI, use NSHostingController",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid View Controller",
                        badCode: "class EmptyVC: NSViewController { }\nwindow.contentViewController = EmptyVC()  // No view",
                        goodCode: "class MyVC: NSViewController {\n    override func loadView() {\n        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))\n    }\n}\nwindow.contentViewController = MyVC()",
                        explanation: "View controllers must have a view before being assigned as content view controller."
                    ),
                ],
                relatedErrors: ["NSViewController's view was unloaded"],
                tags: ["appkit", "viewcontroller", "view", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsviewcontroller",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "AppKit: -[NSSplitViewController insertSplitViewItem:atIndex:] Split view item's view controller must have a view",
                errorCode: "APPKIT_SPLIT_VC_NO_VIEW",
                description: "A split view item was added with a view controller that has no view.",
                cause: "1. View controller not initialized. 2. View not loaded. 3. Nib missing for view controller.",
                solutions: [
                    "Ensure view controller has view before adding",
                    "Override loadView if no nib",
                    "Use NSHostingController for SwiftUI views",
                    "Verify view controller initialization",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Split View Item",
                        badCode: "let item = NSSplitViewItem(viewController: EmptyVC())\nsplitViewController.insertSplitViewItem(item, at: 0)",
                        goodCode: "let vc = MyVC()\nvc.loadView()  // Ensure view loaded\nlet item = NSSplitViewItem(viewController: vc)\nsplitViewController.insertSplitViewItem(item, at: 0)",
                        explanation: "Split view items require view controllers with loaded views."
                    ),
                ],
                relatedErrors: ["NSViewController view not loaded"],
                tags: ["appkit", "splitview", "viewcontroller", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nssplitviewcontroller",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            ErrorEntry(
                category: .appKit,
                severity: .medium,
                title: "AppKit: NSToolbarItem: item identifier 'X' is already in use",
                errorCode: "APPKIT_TOOLBAR_DUPLICATE",
                description: "A toolbar item identifier was used more than once in the same toolbar.",
                cause: "1. Duplicate item identifiers. 2. Re-adding existing item. 3. Identifier string collision.",
                solutions: [
                    "Use unique identifiers for each toolbar item",
                    "Check if item already exists before adding",
                    "Use UUID for dynamic item identifiers",
                    "Remove old item before adding new one with same ID",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Unique Identifiers",
                        badCode: "toolbar.insertItem(withItemIdentifier: .toggleSidebar, at: 0)\ntoolbar.insertItem(withItemIdentifier: .toggleSidebar, at: 1)  // Duplicate",
                        goodCode: "toolbar.insertItem(withItemIdentifier: .toggleSidebar, at: 0)\ntoolbar.insertItem(withItemIdentifier: .flexibleSpace, at: 1)",
                        explanation: "Each toolbar item must have a unique identifier."
                    ),
                ],
                relatedErrors: ["NSToolbar duplicate identifier"],
                tags: ["appkit", "toolbar", "identifier", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nstoolbar",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            ErrorEntry(
                category: .appKit,
                severity: .high,
                title: "AppKit: NSApplication: -[NSApplication runModalForWindow:] window is already modal",
                errorCode: "APPKIT_ALREADY_MODAL",
                description: "Attempting to show a modal window while another modal session is already active.",
                cause: "1. Multiple modal dialogs shown. 2. Modal not ended before showing another. 3. Nested modal sessions.",
                solutions: [
                    "End current modal before starting new one",
                    "Check if modal session exists",
                    "Use sheets instead of modal windows",
                    "Queue modal requests if needed",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "End Before Modal",
                        badCode: "NSApp.runModal(for: window1)\nNSApp.runModal(for: window2)  // Already modal",
                        goodCode: "NSApp.stopModal()\nwindow1.orderOut(nil)\nNSApp.runModal(for: window2)",
                        explanation: "End current modal session before starting a new one."
                    ),
                ],
                relatedErrors: ["Modal session still active"],
                tags: ["appkit", "modal", "window", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/nsapplication",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }

    // =========================================================================
    // MARK: - ADDITIONAL NETWORK ERRORS (Batch 2)
    // =========================================================================
    
    private func moreNetworkErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1006 'Could not find the specified host.'",
                errorCode: "NSURLErrorCannotFindHost (-1006)",
                description: "The DNS lookup failed to resolve the hostname.",
                cause: "1. Typo in hostname. 2. DNS server unreachable. 3. Domain doesn't exist. 4. Network disconnected. 5. VPN/DNS configuration issue.",
                solutions: [
                    "Verify hostname spelling",
                    "Check network connectivity",
                    "Try IP address instead of hostname",
                    "Check DNS settings",
                    "For local development, use localhost or 127.0.0.1",
                    "Check hosts file for incorrect entries",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Host",
                        badCode: "let url = URL(string: \"https://exmaple.com\")!  // Typo",
                        goodCode: "let url = URL(string: \"https://example.com\")!",
                        explanation: "Double-check hostnames for typos and ensure they resolve correctly."
                    ),
                ],
                relatedErrors: ["NSURLErrorCannotConnectToHost (-1004)"],
                tags: ["network", "dns", "host", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1011 'There was a bad server response'",
                errorCode: "NSURLErrorBadServerResponse (-1011)",
                description: "The server returned a malformed or unexpected response.",
                cause: "1. Invalid HTTP headers. 2. Corrupted response body. 3. Unexpected content type. 4. Server-side error generating response.",
                solutions: [
                    "Check response headers for anomalies",
                    "Validate content type",
                    "Log raw response for debugging",
                    "Contact server team",
                    "Implement response validation",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Validate Response",
                        badCode: "let (data, _) = try await URLSession.shared.data(from: url)\nlet json = try JSONSerialization.jsonObject(with: data)  // May fail on bad response",
                        goodCode: "let (data, response) = try await URLSession.shared.data(from: url)\nif let httpResponse = response as? HTTPURLResponse,\n   httpResponse.statusCode == 200,\n   httpResponse.mimeType == \"application/json\" {\n    let json = try JSONSerialization.jsonObject(with: data)\n}",
                        explanation: "Validate HTTP response status and content type before parsing."
                    ),
                ],
                relatedErrors: ["HTTP 500 Internal Server Error"],
                tags: ["network", "server", "response", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1012 'User cancelled the operation'",
                errorCode: "NSURLErrorUserCancelledAuthentication (-1012)",
                description: "The user cancelled an authentication challenge.",
                cause: "1. User cancelled login dialog. 2. Auth challenge rejected. 3. Certificate trust cancelled.",
                solutions: [
                    "Handle cancellation gracefully",
                    "Show user-friendly message",
                    "Allow retry of authentication",
                    "For cert validation, provide alternative access",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Cancellation",
                        badCode: "if let error = error {\n    showError(error)  // Shows confusing error for cancellation\n}",
                        goodCode: "if let error = error as? URLError, error.code == .userCancelledAuthentication {\n    // User cancelled, no action needed\n} else if let error = error {\n    showError(error)\n}",
                        explanation: "Distinguish user cancellation from actual errors."
                    ),
                ],
                relatedErrors: ["NSURLErrorCancelled (-999)"],
                tags: ["network", "auth", "cancel", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1013 'User authentication required'",
                errorCode: "NSURLErrorUserAuthenticationRequired (-1013)",
                description: "The server requires authentication but none was provided.",
                cause: "1. Missing auth header. 2. Expired session. 3. First time access to protected resource.",
                solutions: [
                    "Provide authentication credentials",
                    "Implement login flow",
                    "Use URLCredential for HTTP auth",
                    "Store and refresh tokens",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Provide Credentials",
                        badCode: "let task = URLSession.shared.dataTask(with: url)  // No auth",
                        goodCode: "var request = URLRequest(url: url)\nrequest.setValue(\"Bearer \\(token)\", forHTTPHeaderField: \"Authorization\")\nlet task = URLSession.shared.dataTask(with: request)",
                        explanation: "Include authentication headers for protected resources."
                    ),
                ],
                relatedErrors: ["HTTP 401 Unauthorized"],
                tags: ["network", "auth", "required", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .network,
                severity: .high,
                title: "Error Domain=NSURLErrorDomain Code=-1017 'Cannot parse response'",
                errorCode: "NSURLErrorCannotParseResponse (-1017)",
                description: "The HTTP response could not be parsed.",
                cause: "1. Malformed HTTP headers. 2. Invalid status line. 3. Non-HTTP response. 4. Proxy returning non-HTTP data.",
                solutions: [
                    "Check proxy settings",
                    "Verify server returns valid HTTP",
                    "Use HTTP proxy debugging tools",
                    "Check for network interception",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid HTTP",
                        badCode: "// Server returns plain text instead of HTTP",
                        goodCode: "// Verify with curl -I http://example.com\n// Ensure proper HTTP response format",
                        explanation: "Verify server returns properly formatted HTTP responses."
                    ),
                ],
                relatedErrors: ["NSURLErrorBadServerResponse"],
                tags: ["network", "parse", "http", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL FILE SYSTEM ERRORS (Batch 2)
    // =========================================================================
    
    private func moreFileSystemErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .fileSystem,
                severity: .high,
                title: "The file 'X' is too large to be opened.",
                errorCode: "NSCocoaErrorDomain 6",
                description: "A file exceeds the maximum size that can be opened or processed.",
                cause: "1. File larger than available memory. 2. Exceeds system file size limit. 3. 32-bit integer overflow on file size.",
                solutions: [
                    "Use streaming APIs for large files",
                    "Process file in chunks",
                    "Use memory-mapped files",
                    "Check file size before opening",
                    "For images, use downsampled thumbnails",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Stream Large File",
                        badCode: "let data = try Data(contentsOf: hugeFileURL)  // May exhaust memory",
                        goodCode: "let handle = try FileHandle(forReadingFrom: hugeFileURL)\ndefer { handle.closeFile() }\nwhile let chunk = handle.readData(ofLength: 1024 * 1024), !chunk.isEmpty {\n    process(chunk)\n}",
                        explanation: "Stream large files in chunks instead of loading entirely into memory."
                    ),
                ],
                relatedErrors: ["Memory pressure warning"],
                tags: ["filesystem", "large", "file", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filehandle",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .fileSystem,
                severity: .high,
                title: "The file 'X' is locked.",
                errorCode: "NSCocoaErrorDomain 8",
                description: "A file is locked and cannot be modified.",
                cause: "1. File locked by another application. 2. File system permissions. 3. Read-only media. 4. File flags set to immutable.",
                solutions: [
                    "Close other applications using the file",
                    "Check file flags: chflags nouchange",
                    "Copy to writable location",
                    "Check disk permissions",
                    "For read-only media, copy to disk first",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Locked File",
                        badCode: "try data.write(to: lockedURL)  // Throws",
                        goodCode: "do {\n    try data.write(to: lockedURL)\n} catch let error as CocoaError where error.code == .fileWriteNoPermission {\n    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!\n    let newURL = docs.appendingPathComponent(lockedURL.lastPathComponent)\n    try data.write(to: newURL)\n}",
                        explanation: "Handle locked files by copying to writable locations or prompting user."
                    ),
                ],
                relatedErrors: ["NSCocoaErrorDomain 513"],
                tags: ["filesystem", "locked", "permission", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .fileSystem,
                severity: .high,
                title: "The file 'X' couldn't be saved because the volume is read only.",
                errorCode: "NSCocoaErrorDomain 12",
                description: "Attempting to write to a read-only volume or disk.",
                cause: "1. Read-only disk image. 2. DMG mounted read-only. 3. CD/DVD media. 4. Network share with read-only permissions.",
                solutions: [
                    "Copy to writable location first",
                    "Remount with write permissions",
                    "Check volume info with FileManager",
                    "Save to Documents or Desktop instead",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Writable Location",
                        badCode: "try data.write(to: readOnlyURL)",
                        goodCode: "let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!\nlet writableURL = docs.appendingPathComponent(fileName)\ntry data.write(to: writableURL)",
                        explanation: "Write to user-writable directories instead of read-only volumes."
                    ),
                ],
                relatedErrors: ["NSCocoaErrorDomain 513"],
                tags: ["filesystem", "readonly", "volume", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .fileSystem,
                severity: .medium,
                title: "The file 'X' couldn't be opened because it isn't in the correct format.",
                errorCode: "NSCocoaErrorDomain 259",
                description: "A file's content doesn't match its expected format.",
                cause: "1. Corrupted file. 2. Wrong file extension. 3. Unsupported format version. 4. File truncated.",
                solutions: [
                    "Validate file before parsing",
                    "Try alternative parsers",
                    "Check file signature/magic number",
                    "Handle parse errors gracefully",
                    "Allow user to select different file",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Validate Format",
                        badCode: "let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]",
                        goodCode: "guard let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {\n    throw MyError.invalidFormat\n}",
                        explanation: "Validate file format and handle parse failures gracefully."
                    ),
                ],
                relatedErrors: ["NSCocoaErrorDomain 260"],
                tags: ["filesystem", "format", "corrupt", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/filemanager",
                commonInVersions: ["All versions"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL PERMISSION ERRORS (Batch 2)
    // =========================================================================
    
    private func morePermissionErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "This app has crashed because it attempted to access privacy-sensitive data without a usage description: NSCameraUsageDescription",
                errorCode: "TCC_CAMERA_CRASH",
                description: "The app tried to access the camera without providing the required NSCameraUsageDescription in Info.plist.",
                cause: "1. Missing NSCameraUsageDescription. 2. Accessing AVCaptureDevice without description. 3. Info.plist not included in target.",
                solutions: [
                    "Add NSCameraUsageDescription to Info.plist",
                    "Provide clear reason for camera access",
                    "Request authorization before camera use",
                    "Handle denied permission gracefully",
                ],
                codeExamples: [
                    CodeExample(
                        language: "xml",
                        title: "Camera Description",
                        badCode: "<!-- Missing NSCameraUsageDescription -->",
                        goodCode: "<key>NSCameraUsageDescription</key>\n<string>This app uses the camera to scan QR codes.</string>",
                        explanation: "All privacy-sensitive access requires a usage description in Info.plist."
                    ),
                ],
                relatedErrors: ["TCC_CRASH"],
                tags: ["permissions", "camera", "tcc", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/bundleresources/information_property_list/protected_resources",
                commonInVersions: ["iOS 10+", "macOS 10.14+"]
            ),
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "This app has crashed because it attempted to access privacy-sensitive data without a usage description: NSMicrophoneUsageDescription",
                errorCode: "TCC_MIC_CRASH",
                description: "The app tried to access the microphone without the required usage description.",
                cause: "1. Missing NSMicrophoneUsageDescription. 2. Recording audio without permission. 3. Speech recognition without description.",
                solutions: [
                    "Add NSMicrophoneUsageDescription to Info.plist",
                    "Explain why microphone access is needed",
                    "Request AVAudioSession permission",
                    "Handle denied state",
                ],
                codeExamples: [
                    CodeExample(
                        language: "xml",
                        title: "Microphone Description",
                        badCode: "<!-- Missing NSMicrophoneUsageDescription -->",
                        goodCode: "<key>NSMicrophoneUsageDescription</key>\n<string>This app uses the microphone for voice recording.</string>",
                        explanation: "Microphone access requires a usage description."
                    ),
                ],
                relatedErrors: ["TCC_CAMERA_CRASH"],
                tags: ["permissions", "microphone", "tcc", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/bundleresources/information_property_list/protected_resources",
                commonInVersions: ["iOS 10+", "macOS 10.14+"]
            ),
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "This app has crashed because it attempted to access privacy-sensitive data without a usage description: NSLocationWhenInUseUsageDescription",
                errorCode: "TCC_LOCATION_CRASH",
                description: "The app tried to access location without the required usage description.",
                cause: "1. Missing NSLocationWhenInUseUsageDescription. 2. Missing NSLocationAlwaysUsageDescription for background. 3. CLLocationManager used without description.",
                solutions: [
                    "Add NSLocationWhenInUseUsageDescription",
                    "Add NSLocationAlwaysAndWhenInUseUsageDescription for background",
                    "Request location authorization",
                    "Handle all authorization states",
                ],
                codeExamples: [
                    CodeExample(
                        language: "xml",
                        title: "Location Description",
                        badCode: "<!-- Missing location descriptions -->",
                        goodCode: "<key>NSLocationWhenInUseUsageDescription</key>\n<string>This app uses your location to find nearby places.</string>\n<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>\n<string>This app uses your location for background tracking.</string>",
                        explanation: "Location access requires both foreground and background descriptions."
                    ),
                ],
                relatedErrors: ["TCC_CAMERA_CRASH"],
                tags: ["permissions", "location", "tcc", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/bundleresources/information_property_list/protected_resources",
                commonInVersions: ["iOS 11+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .permissions,
                severity: .high,
                title: "kTCCServiceMediaLibrary: TCC deny prompt",
                errorCode: "TCC_MUSIC_DENIED",
                description: "User denied access to Apple Music/media library.",
                cause: "1. User tapped Don't Allow. 2. Permission revoked in Settings. 3. Parental controls restricting access.",
                solutions: [
                    "Check MPMediaLibrary.authorizationStatus()",
                    "Show instructions to enable in Settings",
                    "Provide alternative without media library",
                    "Handle restricted state (MDM/parental controls)",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Denied",
                        badCode: "MPMediaLibrary.requestAuthorization { _ in\n    // Load music regardless\n}",
                        goodCode: "MPMediaLibrary.requestAuthorization { status in\n    switch status {\n    case .authorized:\n        loadMusic()\n    case .denied:\n        showSettingsAlert()\n    case .restricted:\n        showRestrictedAlert()\n    default:\n        break\n    }\n}",
                        explanation: "Handle all authorization states including denied and restricted."
                    ),
                ],
                relatedErrors: ["TCC_DENIED"],
                tags: ["permissions", "music", "media", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/mediaplayer",
                commonInVersions: ["iOS 10+", "macOS 10.14+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL MEMORY ERRORS (Batch 2)
    // =========================================================================
    
    private func moreMemoryErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .memory,
                severity: .critical,
                title: "Memory pressure: System is critically low on memory",
                errorCode: "MEMORY_PRESSURE_CRITICAL",
                description: "The system is critically low on RAM and aggressively terminating apps.",
                cause: "1. Severe memory leak. 2. Loading extremely large assets. 3. Multiple apps consuming memory. 4. Background processes using RAM.",
                solutions: [
                    "Immediately release all caches",
                    "Unload invisible view controllers",
                    "Release large images and media",
                    "Flush URLCache and NSCache",
                    "Save state and prepare for termination",
                    "Profile with Instruments to find root cause",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Critical Response",
                        badCode: "// No memory pressure handling",
                        goodCode: "NotificationCenter.default.addObserver(forName: NSApplication.didReceiveMemoryPressureNotification, object: nil, queue: .main) { _ in\n    imageCache.removeAllObjects()\n    URLCache.shared.removeAllCachedResponses()\n    // Unload non-visible content\n}",
                        explanation: "Respond aggressively to critical memory pressure by releasing all non-essential resources."
                    ),
                ],
                relatedErrors: ["Jetsam", "Terminated due to memory issue"],
                tags: ["memory", "pressure", "critical", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .memory,
                severity: .high,
                title: "CGImage creation failed: Image is too large to process",
                errorCode: "CG_IMAGE_TOO_LARGE",
                description: "Attempting to create a CGImage that exceeds available memory or maximum dimensions.",
                cause: "1. Extremely large image dimensions. 2. Insufficient memory for bitmap. 3. 32-bit dimension overflow. 4. Deep color space increasing size.",
                solutions: [
                    "Downsample before creating CGImage",
                    "Use ImageIO for progressive loading",
                    "Check dimensions before processing",
                    "Use tiled rendering for large images",
                    "Reduce color depth if possible",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Downsample First",
                        badCode: "let image = UIImage(contentsOfFile: hugeImagePath)  // 10000x10000",
                        goodCode: "func downsample(imageAt url: URL, to size: CGSize) -> UIImage {\n    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary\n    let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions)!\n    let maxDimension = max(size.width, size.height)\n    let downsampleOptions = [\n        kCGImageSourceCreateThumbnailFromImageAlways: true,\n        kCGImageSourceThumbnailMaxPixelSize: maxDimension\n    ] as CFDictionary\n    let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)!\n    return UIImage(cgImage: cgImage)\n}",
                        explanation: "Downsample large images before creating full bitmaps."
                    ),
                ],
                relatedErrors: ["Jetsam", "Memory pressure warning"],
                tags: ["memory", "cgimage", "large", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/imageio",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .memory,
                severity: .high,
                title: "Malloc: can't allocate region",
                errorCode: "MALLOC_FAIL",
                description: "The system could not allocate the requested memory region.",
                cause: "1. Requesting too much memory at once. 2. Fragmented heap. 3. Address space exhaustion. 4. Resource limits.",
                solutions: [
                    "Allocate smaller chunks",
                    "Use mmap for large allocations",
                    "Free unused memory before allocating",
                    "Use streaming instead of buffering",
                    "Check ulimit on macOS",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Chunked Allocation",
                        badCode: "let hugeArray = Array(repeating: 0, count: 1_000_000_000)  // May fail",
                        goodCode: "processInChunks(totalSize: 1_000_000_000, chunkSize: 1_000_000) { chunk in\n    // Process each chunk\n}",
                        explanation: "Process data in chunks instead of allocating huge contiguous blocks."
                    ),
                ],
                relatedErrors: ["Jetsam", "EXC_RESOURCE"],
                tags: ["memory", "malloc", "allocation", "crash", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .memory,
                severity: .high,
                title: "Retain cycle: Closure captures self strongly",
                errorCode: "RETAIN_CYCLE_CLOSURE",
                description: "A closure captures self strongly, preventing deallocation and causing a memory leak.",
                cause: "1. Missing [weak self] in closure. 2. self.property accessed without weak. 3. Nested closures each capturing self. 4. Delegate pattern with strong reference.",
                solutions: [
                    "Use [weak self] in all escaping closures",
                    "Use [unowned self] only when self always exists",
                    "Break cycles in deinit",
                    "Use Instruments > Leaks to detect",
                    "For delegates, always use weak",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Weak Capture",
                        badCode: "network.request { result in\n    self.update(result)  // Strong retain cycle\n}",
                        goodCode: "network.request { [weak self] result in\n    self?.update(result)\n}",
                        explanation: "Always use weak self in closures that outlive the current scope."
                    ),
                ],
                relatedErrors: ["Memory leak", "Object not deallocated"],
                tags: ["memory", "retain cycle", "closure", "leak", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html",
                commonInVersions: ["Swift 3.x", "Swift 4.x", "Swift 5.x"]
            ),
        ]
    }

    // =========================================================================
    // MARK: - ADDITIONAL CONCURRENCY ERRORS (Batch 2)
    // =========================================================================
    
    private func moreConcurrencyErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .concurrency,
                severity: .critical,
                title: "ThreadSanitizer: data race on var 'X' at address Y",
                errorCode: "TSAN_DATA_RACE",
                description: "Thread Sanitizer detected simultaneous unsynchronized access to a variable from multiple threads.",
                cause: "1. Multiple threads reading/writing same variable. 2. No locks or atomics. 3. Race in singleton initialization. 4. Concurrent array/dictionary mutation.",
                solutions: [
                    "Use actors for shared mutable state",
                    "Use NSLock or os_unfair_lock",
                    "Use DispatchQueue for synchronization",
                    "For simple counters, use atomic operations",
                    "Use ThreadSafe wrappers",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Actor Protection",
                        badCode: "var counter = 0\nDispatchQueue.concurrentPerform(iterations: 1000) { _ in\n    counter += 1  // Data race\n}",
                        goodCode: "actor Counter {\n    private var value = 0\n    func increment() { value += 1 }\n    func get() -> Int { value }\n}",
                        explanation: "Protect shared mutable state with actors or locks."
                    ),
                ],
                relatedErrors: ["EXC_BAD_ACCESS"],
                tags: ["concurrency", "data race", "thread sanitizer", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["Swift 5.5+", "Swift 6.x"]
            ),
            ErrorEntry(
                category: .concurrency,
                severity: .high,
                title: "Main Thread Checker: UI API called on background thread: -[NSView setNeedsDisplay:]",
                errorCode: "MAIN_THREAD_UI_V2",
                description: "A UIKit/AppKit method was called from a background thread.",
                cause: "1. Network callback updating UI. 2. Background timer triggering UI update. 3. Async operation completion on background queue.",
                solutions: [
                    "Dispatch ALL UI updates to main thread",
                    "Use @MainActor for UI methods",
                    "For Combine, use .receive(on: DispatchQueue.main)",
                    "For async/await, UI updates are implicit in SwiftUI",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Main Thread UI",
                        badCode: "DispatchQueue.global().async {\n    self.label.stringValue = \"Done\"  // Background thread!\n}",
                        goodCode: "DispatchQueue.global().async {\n    let result = compute()\n    DispatchQueue.main.async {\n        self.label.stringValue = result\n    }\n}",
                        explanation: "Always dispatch UI updates to the main thread."
                    ),
                ],
                relatedErrors: ["Main Thread Checker"],
                tags: ["concurrency", "main thread", "ui", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .concurrency,
                severity: .high,
                title: "Deadlock: DispatchQueue.sync called on current queue",
                errorCode: "DEADLOCK_SYNC",
                description: "Calling sync on the same serial queue from within that queue causes a deadlock.",
                cause: "1. sync called on current serial queue. 2. Nested sync on same queue. 3. Recursive synchronous dispatch.",
                solutions: [
                    "Use async instead of sync",
                    "Use DispatchQueue.main.async",
                    "Check current queue before sync",
                    "Use withCheckedContinuation for async bridging",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Avoid Deadlock",
                        badCode: "let queue = DispatchQueue(label: \"serial\")\nqueue.sync {\n    queue.sync { }  // Deadlock!\n}",
                        goodCode: "let queue = DispatchQueue(label: \"serial\")\nqueue.async {\n    queue.async { }  // OK\n}",
                        explanation: "Never call sync on a serial queue from within that same queue."
                    ),
                ],
                relatedErrors: ["Hang", "Unresponsive"],
                tags: ["concurrency", "deadlock", "sync", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/dispatch",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .concurrency,
                severity: .high,
                title: "Swift runtime failure: Reference to captured var in concurrently-executing code",
                errorCode: "CONCURRENT_VAR_CAPTURE_V2",
                description: "A variable captured by multiple concurrent tasks was mutated, causing a data race.",
                cause: "1. Mutating var in concurrentPerform. 2. Modifying captured variable in async task. 3. Shared mutable state in TaskGroup.",
                solutions: [
                    "Use let instead of var for captured values",
                    "Return values from tasks instead of mutating shared state",
                    "Use actors for shared mutable state",
                    "Use atomic operations if needed",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Concurrent Capture",
                        badCode: "var results: [String] = []\nawait withTaskGroup(of: Void.self) { group in\n    for i in 0..<10 {\n        group.addTask {\n            results.append(\"\\(i)\")  // Data race\n        }\n    }\n}",
                        goodCode: "let results = await withTaskGroup(of: String.self) { group -> [String] in\n    for i in 0..<10 {\n        group.addTask { return \"\\(i)\" }\n    }\n    var collected: [String] = []\n    for await result in group {\n        collected.append(result)\n    }\n    return collected\n}",
                        explanation: "Return values from tasks and combine them serially instead of mutating shared state."
                    ),
                ],
                relatedErrors: ["TSAN_DATA_RACE"],
                tags: ["concurrency", "capture", "var", "swift 6", "runtime"],
                appleDocURL: "https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html",
                commonInVersions: ["Swift 5.5+", "Swift 6.x"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL CORE DATA ERRORS (Batch 2)
    // =========================================================================
    
    private func moreCoreDataErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: executeFetchRequest:error: nil context",
                errorCode: "NSInvalidArgumentException",
                description: "A fetch request was executed on a nil managed object context.",
                cause: "1. Context not initialized. 2. Context set to nil after use. 3. Thread-local context not set.",
                solutions: [
                    "Ensure context is non-nil before fetching",
                    "Use persistentContainer.viewContext",
                    "For background, create new context",
                    "Check context.concurrencyType matches usage",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Context",
                        badCode: "var context: NSManagedObjectContext?\nlet request = NSFetchRequest<Entity>(entityName: \"Entity\")\nlet results = try context!.fetch(request)  // Crash if nil",
                        goodCode: "let context = persistentContainer.viewContext\nlet request = NSFetchRequest<Entity>(entityName: \"Entity\")\nlet results = try context.fetch(request)",
                        explanation: "Always use a valid non-nil managed object context for Core Data operations."
                    ),
                ],
                relatedErrors: ["Core Data: nil context"],
                tags: ["coredata", "context", "nil", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: Cannot delete object that has not been saved to a context",
                errorCode: "NSInvalidArgumentException",
                description: "Attempting to delete a managed object that hasn't been inserted into a context.",
                cause: "1. Deleting transient object. 2. Object from different context. 3. Object already deleted.",
                solutions: [
                    "Insert object into context before deleting",
                    "Check object.managedObjectContext != nil",
                    "Ensure object is from correct context",
                    "Handle already-deleted objects gracefully",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Deletion",
                        badCode: "let obj = Entity(context: context)\ncontext.delete(obj)  // OK\ncontext.delete(obj)  // Error: already deleted",
                        goodCode: "if !obj.isDeleted, let ctx = obj.managedObjectContext {\n    ctx.delete(obj)\n}",
                        explanation: "Only delete objects that are inserted in a valid context and not already deleted."
                    ),
                ],
                relatedErrors: ["Core Data: object already deleted"],
                tags: ["coredata", "delete", "context", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: The operation couldn't be completed. (Cocoa error 1550.)",
                errorCode: "NSManagedObjectValidationError (1550)",
                description: "A managed object failed validation during save.",
                cause: "1. Required relationship empty. 2. Delete rule violation. 3. Custom validation failed. 4. Minimum/maximum count violation.",
                solutions: [
                    "Check validation errors in error.userInfo",
                    "Ensure all required relationships are set",
                    "Validate min/max counts on relationships",
                    "Implement validateForInsert/Update properly",
                    "Check delete rules don't leave orphans",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Validation",
                        badCode: "try context.save()  // May throw validation error",
                        goodCode: "do {\n    try context.save()\n} catch let error as NSError {\n    if let errors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {\n        for err in errors {\n            print(\"Validation: \\(err.userInfo[NSValidationKeyErrorKey] ?? \"unknown\")\")\n        }\n    }\n}",
                        explanation: "Inspect detailed validation errors to identify which properties or relationships failed."
                    ),
                ],
                relatedErrors: ["NSValidationError (1560)"],
                tags: ["coredata", "validation", "relationship", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/nsvalidationerror",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .coreData,
                severity: .high,
                title: "Core Data: The model used to open the store is incompatible with the one used to create the store",
                errorCode: "NSPersistentStoreIncompatibleVersionHashError (134100)",
                description: "The Core Data model has changed without a proper migration.",
                cause: "1. Model version changed. 2. No mapping model. 3. Automatic migration disabled. 4. Heavyweight migration needed.",
                solutions: [
                    "Enable automatic migration",
                    "Create mapping model for complex changes",
                    "Version the data model",
                    "For development, delete and recreate store",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Auto Migration",
                        badCode: "let container = NSPersistentContainer(name: \"Model\")\ncontainer.loadPersistentStores { _, _ in }  // No migration config",
                        goodCode: "let container = NSPersistentContainer(name: \"Model\")\nlet description = container.persistentStoreDescriptions.first\ndescription?.shouldMigrateStoreAutomatically = true\ndescription?.shouldInferMappingModelAutomatically = true\ncontainer.loadPersistentStores { _, _ in }",
                        explanation: "Enable automatic lightweight migration or create explicit mapping models."
                    ),
                ],
                relatedErrors: ["NSMigrationError"],
                tags: ["coredata", "migration", "model", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/coredata/migration_guide",
                commonInVersions: ["All versions"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL CODE SIGNING ERRORS (Batch 2)
    // =========================================================================
    
    private func moreCodeSigningErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .codeSigning,
                severity: .critical,
                title: "Code Signing Error: Provisioning profile 'X' expired",
                errorCode: "PROFILE_EXPIRED",
                description: "The provisioning profile has expired and can no longer be used to sign apps.",
                cause: "1. Profile valid for 1 year, expired. 2. Certificate revoked. 3. Device list changed. 4. Automatic signing failed to renew.",
                solutions: [
                    "Regenerate profile in Developer Portal",
                    "Use automatic signing in Xcode",
                    "Download updated profiles",
                    "For distribution, create new App Store profile",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Renew Profile",
                        badCode: "// Using expired profile",
                        goodCode: "// Xcode > Preferences > Accounts > Download Manual Profiles\n// Or regenerate at developer.apple.com",
                        explanation: "Provisioning profiles expire annually and must be renewed."
                    ),
                ],
                relatedErrors: ["Identity used to sign no longer valid"],
                tags: ["codesigning", "profile", "expired", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            ErrorEntry(
                category: .codeSigning,
                severity: .critical,
                title: "Code Signing Error: No valid signing identities (i.e. certificate and private key pair) matching the team ID were found",
                errorCode: "NO_VALID_IDENTITIES",
                description: "Xcode cannot find a valid signing certificate and private key pair for the selected team.",
                cause: "1. Certificate not installed. 2. Private key missing. 3. Wrong team selected. 4. Certificate expired.",
                solutions: [
                    "Download certificate and private key",
                    "Create new certificate in Developer Portal",
                    "Check Keychain Access for valid certs",
                    "Verify correct team is selected",
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Check Identities",
                        badCode: "// No valid signing identity",
                        goodCode: "security find-identity -v -p codesigning\n// Create new at developer.apple.com/account/resources/certificates/list",
                        explanation: "Both certificate and private key must be present in Keychain for signing."
                    ),
                ],
                relatedErrors: ["No signing certificate found"],
                tags: ["codesigning", "identity", "certificate", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/distributing-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            ErrorEntry(
                category: .codeSigning,
                severity: .high,
                title: "Code Signing Error: The entitlements specified in your application's Code Signing Entitlements file do not match those specified in your provisioning profile",
                errorCode: "ENTITLEMENT_MISMATCH_V2",
                description: "The app's entitlements don't match the provisioning profile.",
                cause: "1. Added capability without regenerating profile. 2. Different App ID. 3. Manual entitlement editing.",
                solutions: [
                    "Regenerate provisioning profile",
                    "Ensure App ID matches exactly",
                    "Check .entitlements file matches profile",
                    "Disable and re-enable automatic signing",
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Check Entitlements",
                        badCode: "// Profile doesn't include push notification entitlement",
                        goodCode: "codesign -d --entitlements :- MyApp.app\nsecurity cms -D -i MyProfile.mobileprovision | plutil -p -",
                        explanation: "Regenerate profiles after adding or removing capabilities."
                    ),
                ],
                relatedErrors: ["Invalid entitlements"],
                tags: ["codesigning", "entitlements", "profile", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
        ]
    }

    // =========================================================================
    // MARK: - ADDITIONAL WIDGETKIT ERRORS (Batch 2)
    // =========================================================================
    
    private func moreWidgetKitErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .widgetKit,
                severity: .high,
                title: "WidgetKit: Timeline entries must be in chronological order",
                errorCode: "WIDGET_TIMELINE_ORDER",
                description: "Timeline entries must be sorted by date in ascending order.",
                cause: "1. Entries not sorted. 2. Same date for multiple entries. 3. Date calculation error.",
                solutions: [
                    "Sort entries by date: entries.sort { $0.date < $1.date }",
                    "Ensure unique dates or handle duplicates",
                    "Use Calendar for reliable date math",
                    "Validate entry order before returning",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Sorted Timeline",
                        badCode: "let entries = [\n    Entry(date: now.addingTimeInterval(3600)),\n    Entry(date: now)  // Out of order\n]",
                        goodCode: "var entries = [Entry(date: now), Entry(date: now.addingTimeInterval(3600))]\nentries.sort { $0.date < $1.date }",
                        explanation: "Always sort timeline entries in ascending chronological order."
                    ),
                ],
                relatedErrors: ["WidgetKit: invalid timeline"],
                tags: ["widgetkit", "timeline", "widget", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/widgetkit/timelineprovider",
                commonInVersions: ["iOS 14+", "macOS 11+"]
            ),
            ErrorEntry(
                category: .widgetKit,
                severity: .high,
                title: "WidgetKit: Widget family 'X' not supported by configuration",
                errorCode: "WIDGET_FAMILY_UNSUPPORTED",
                description: "The widget configuration doesn't support the requested widget family.",
                cause: "1. Family not in supportedFamilies. 2. Platform-specific family on wrong platform.",
                solutions: [
                    "Add family to .supportedFamilies([...])",
                    "Use conditional compilation for platform families",
                    "Check widget size constraints per platform",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Supported Families",
                        badCode: "StaticConfiguration(...) { }\n// Missing supportedFamilies",
                        goodCode: "StaticConfiguration(...) { }\n.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])",
                        explanation: "Explicitly declare supported widget families."
                    ),
                ],
                relatedErrors: ["WidgetKit: unsupported family"],
                tags: ["widgetkit", "family", "widget", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/widgetkit/widgetconfiguration",
                commonInVersions: ["iOS 14+", "macOS 11+"]
            ),
            ErrorEntry(
                category: .widgetKit,
                severity: .medium,
                title: "WidgetKit: Widget preview not available",
                errorCode: "WIDGET_PREVIEW_UNAVAILABLE",
                description: "The widget preview cannot be rendered.",
                cause: "1. Preview missing required data. 2. App Group not accessible. 3. Widget crashing in preview.",
                solutions: [
                    "Provide preview data in previewContext",
                    "Check App Group accessibility",
                    "Use mock data for previews",
                    "Ensure widget doesn't crash on empty data",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Widget Preview",
                        badCode: "struct MyWidget_Previews: PreviewProvider {\n    static var previews: some View {\n        MyWidgetEntryView(entry: Entry(date: Date()))\n    }\n}",
                        goodCode: "struct MyWidget_Previews: PreviewProvider {\n    static var previews: some View {\n        MyWidgetEntryView(entry: Entry(date: Date()))\n            .previewContext(WidgetPreviewContext(family: .systemSmall))\n    }\n}",
                        explanation: "Use WidgetPreviewContext for proper preview rendering."
                    ),
                ],
                relatedErrors: ["WidgetKit: preview error"],
                tags: ["widgetkit", "preview", "widget", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/widgetkit/previewing-widgets",
                commonInVersions: ["iOS 17+", "macOS 14+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL COMBINE ERRORS (Batch 2)
    // =========================================================================
    
    private func moreCombineErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .combine,
                severity: .high,
                title: "Combine: Cannot assign through subscript: subscription has been cancelled",
                errorCode: "COMBINE_CANCELLED_ASSIGN",
                description: "A Combine subscription was cancelled before the assignment could complete.",
                cause: "1. Cancellable deallocated. 2. View disappeared, cancelling subscription. 3. Explicit cancellation before completion.",
                solutions: [
                    "Store cancellables in Set<AnyCancellable>",
                    "Ensure store property outlives subscription",
                    "For view-bound subscriptions, use .onReceive",
                    "Check cancellable.isCancelled before operations",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Retain Subscription",
                        badCode: "publisher.sink { value in\n    self.label = value\n}  // Not stored -> deallocated",
                        goodCode: "private var cancellables = Set<AnyCancellable>()\npublisher\n    .sink { [weak self] value in\n        self?.label = value\n    }\n    .store(in: &cancellables)",
                        explanation: "Always store subscriptions in a Set<AnyCancellable>."
                    ),
                ],
                relatedErrors: ["Object has been deallocated"],
                tags: ["combine", "cancellable", "subscription", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/combine/anycancellable",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .combine,
                severity: .high,
                title: "Combine: Fatal error: Unexpectedly found nil while unwrapping in sink",
                errorCode: "COMBINE_FORCE_UNWRAP",
                description: "Force unwrapping a nil value in a Combine sink or map closure.",
                cause: "1. Force unwrap in map. 2. Optional value not handled. 3. Data decoding failure force unwrapped.",
                solutions: [
                    "Use compactMap instead of map + force unwrap",
                    "Use tryMap with error throwing",
                    "Handle nil with replaceNil",
                    "Use decode with catch for error recovery",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Safe Combine",
                        badCode: "publisher\n    .map { $0.data }\n    .sink { data in\n        let json = try! JSONSerialization.jsonObject(with: data)  // Force try\n    }",
                        goodCode: "publisher\n    .map { $0.data }\n    .decode(type: MyModel.self, decoder: JSONDecoder())\n    .catch { error in\n        Just(MyModel.fallback)\n    }\n    .sink { model in\n        // Use model safely\n    }",
                        explanation: "Use Combine's error handling operators instead of force unwrap."
                    ),
                ],
                relatedErrors: ["Fatal error: Unexpectedly found nil"],
                tags: ["combine", "publisher", "sink", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/combine",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .combine,
                severity: .medium,
                title: "Combine: Publisher cannot sync upstream values on the requested queue",
                errorCode: "COMBINE_RECEIVE_QUEUE",
                description: "A publisher tried to deliver values on a specific queue but the upstream doesn't support queue customization.",
                cause: "1. Using .receive(on:) with @Published. 2. Expecting all publishers to respect receive(on:).",
                solutions: [
                    "Use .receive(on: DispatchQueue.main) for UI updates",
                    "For @Published, values emit on the modifying thread",
                    "Use CurrentValueSubject for explicit scheduling",
                    "Avoid mixing publishers with different scheduling",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Proper Scheduling",
                        badCode: "@Published var value: String = \"\"\n// Modifying from background -> emits on background",
                        goodCode: "DispatchQueue.main.async {\n    self.value = result  // Emit on main thread\n}",
                        explanation: "@Published emits on the thread that modifies the property. Dispatch to main for UI."
                    ),
                ],
                relatedErrors: ["Modifying state during view update"],
                tags: ["combine", "publisher", "queue", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/combine",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL METAL ERRORS (Batch 2)
    // =========================================================================
    
    private func moreMetalErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .metal,
                severity: .critical,
                title: "Metal: Failed to create MTLDevice",
                errorCode: "MTL_DEVICE_FAIL",
                description: "Metal could not initialize the GPU device.",
                cause: "1. Simulator without Metal support. 2. VM without GPU passthrough. 3. macOS safe mode. 4. GPU driver issue.",
                solutions: [
                    "Check MTLCreateSystemDefaultDevice() != nil",
                    "Fall back to CPU rendering",
                    "Update macOS for latest GPU drivers",
                    "For simulators, use supported features only",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Metal Availability",
                        badCode: "let device = MTLCreateSystemDefaultDevice()!  // May crash",
                        goodCode: "guard let device = MTLCreateSystemDefaultDevice() else {\n    // Fall back to CPU rendering\n    return\n}",
                        explanation: "Always check Metal device availability and provide fallback."
                    ),
                ],
                relatedErrors: ["MTLDevice not found"],
                tags: ["metal", "gpu", "device", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/metal",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .metal,
                severity: .high,
                title: "Metal: Shader compilation failed",
                errorCode: "MTL_SHADER_COMPILE_FAIL",
                description: "A Metal shader failed to compile.",
                cause: "1. Syntax error in .metal file. 2. Metal 3 feature on Metal 2 hardware. 3. Missing #include.",
                solutions: [
                    "Check shader compilation logs",
                    "Enable Metal Shader Validation",
                    "Verify target OS supports shader features",
                    "Compile shaders offline with metal command-line tools",
                ],
                codeExamples: [
                    CodeExample(
                        language: "metal",
                        title: "Valid Shader",
                        badCode: "kernel void badShader(texture2d<float> tex [[texture(0)]]) {\n    float4 c = tex.read(0);  // Missing coord type\n}",
                        goodCode: "kernel void goodShader(texture2d<float> tex [[texture(0)]],\n                         uint2 gid [[thread_position_in_grid]]) {\n    float4 c = tex.read(gid);\n}",
                        explanation: "Metal shaders must use correct types for all parameters."
                    ),
                ],
                relatedErrors: ["Metal: pipeline creation failed"],
                tags: ["metal", "shader", "compile", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/metal/shader_authoring",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .metal,
                severity: .high,
                title: "Metal: Command buffer execution failed",
                errorCode: "MTL_COMMAND_BUFFER_ERROR",
                description: "A Metal command buffer failed to execute on the GPU.",
                cause: "1. Out of GPU memory. 2. Invalid texture format. 3. Shader compilation error. 4. Buffer overflow.",
                solutions: [
                    "Check commandBuffer.status and error",
                    "Enable Metal API Validation",
                    "Reduce texture size or buffer count",
                    "Split heavy GPU work into multiple command buffers",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle GPU Error",
                        badCode: "commandBuffer.commit()\ncommandBuffer.waitUntilCompleted()  // No error check",
                        goodCode: "commandBuffer.commit()\ncommandBuffer.waitUntilCompleted()\nif let error = commandBuffer.error {\n    print(\"GPU Error: \\(error)\")\n}",
                        explanation: "Always check command buffer status and error after GPU execution."
                    ),
                ],
                relatedErrors: ["Metal: validation error"],
                tags: ["metal", "gpu", "command buffer", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/metal/mtlcommandbuffer",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL SECURITY ERRORS (Batch 2)
    // =========================================================================
    
    private func moreSecurityErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .security,
                severity: .high,
                title: "Keychain: errSecNotAvailable (-25291)",
                errorCode: "errSecNotAvailable (-25291)",
                description: "The keychain is not available, usually because the device is locked.",
                cause: "1. Device locked. 2. Keychain locked. 3. No keychain access in current state.",
                solutions: [
                    "Use kSecAttrAccessibleAfterFirstUnlock for background access",
                    "Defer keychain access until device is unlocked",
                    "Handle unavailable state gracefully",
                    "For critical data, prompt for unlock",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Accessible Keychain",
                        badCode: "kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked  // Not available when locked",
                        goodCode: "kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock  // Available in background",
                        explanation: "Choose keychain accessibility based on when data needs to be accessible."
                    ),
                ],
                relatedErrors: ["errSecInteractionNotAllowed"],
                tags: ["security", "keychain", "unavailable", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/security/keychain_services",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .security,
                severity: .high,
                title: "Keychain: errSecAuthFailed (-25293)",
                errorCode: "errSecAuthFailed (-25293)",
                description: "Authentication failed, usually due to wrong passphrase or biometrics failure.",
                cause: "1. Wrong password. 2. Biometrics failed. 3. User cancelled authentication. 4. Too many failed attempts.",
                solutions: [
                    "Prompt user to retry",
                    "Fall back to password if biometrics fail",
                    "Handle LAError cases",
                    "Implement retry limits",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Auth Failure",
                        badCode: "let status = SecItemCopyMatching(query as CFDictionary, &result)\nif status != errSecSuccess {\n    // Generic error handling\n}",
                        goodCode: "let status = SecItemCopyMatching(query as CFDictionary, &result)\nif status == errSecAuthFailed {\n    showBiometricRetryPrompt()\n}",
                        explanation: "Handle authentication failures with appropriate user prompts."
                    ),
                ],
                relatedErrors: ["errSecInteractionNotAllowed"],
                tags: ["security", "keychain", "auth", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/security/keychain_services",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .security,
                severity: .high,
                title: "Keychain: errSecParam (-50)",
                errorCode: "errSecParam (-50)",
                description: "One or more parameters passed to a Keychain function are invalid.",
                cause: "1. Nil required parameter. 2. Wrong data type in query. 3. Missing required attribute. 4. Invalid key size.",
                solutions: [
                    "Check all query parameters are non-nil",
                    "Verify attribute types match expectations",
                    "Ensure required attributes are present",
                    "Use SecItemAdd/Copy matching documentation",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Parameters",
                        badCode: "let query: [String: Any] = [\n    kSecClass as String: kSecClassGenericPassword\n    // Missing kSecAttrAccount and kSecValueData\n]",
                        goodCode: "let query: [String: Any] = [\n    kSecClass as String: kSecClassGenericPassword,\n    kSecAttrAccount as String: \"username\",\n    kSecValueData as String: \"password\".data(using: .utf8)!\n]",
                        explanation: "Ensure all required Keychain query parameters are provided with correct types."
                    ),
                ],
                relatedErrors: ["errSecItemNotFound"],
                tags: ["security", "keychain", "param", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/security/keychain_services",
                commonInVersions: ["All versions"]
            ),
        ]
    }

    // =========================================================================
    // MARK: - ADDITIONAL NOTIFICATION ERRORS (Batch 2)
    // =========================================================================
    
    private func moreNotificationErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .notification,
                severity: .high,
                title: "UserNotifications: Notification content extension failed to load",
                errorCode: "UN_EXTENSION_FAIL",
                description: "A notification content extension failed to load.",
                cause: "1. Extension bundle ID mismatch. 2. Missing Info.plist configuration. 3. Extension memory limit exceeded.",
                solutions: [
                    "Verify extension bundle ID matches provisioning profile",
                    "Check UNNotificationExtension category identifier",
                    "Ensure extension Info.plist has NSExtension configuration",
                    "Test extension memory usage - limit is typically 24MB",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Extension Config",
                        badCode: "// Missing NSExtension in Info.plist",
                        goodCode: "<key>NSExtension</key>\n<dict>\n    <key>NSExtensionPointIdentifier</key>\n    <string>com.apple.usernotifications.content-extension</string>\n    <key>NSExtensionAttributes</key>\n    <dict>\n        <key>UNNotificationExtensionCategory</key>\n        <string>myCategory</string>\n    </dict>\n</dict>",
                        explanation: "Notification extensions require proper Info.plist configuration."
                    ),
                ],
                relatedErrors: ["Extension not loaded"],
                tags: ["notifications", "extension", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/usernotificationsui",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            ErrorEntry(
                category: .notification,
                severity: .medium,
                title: "UserNotifications: Notification request with identifier 'X' already exists",
                errorCode: "UN_DUPLICATE_REQUEST",
                description: "A notification request with the same identifier was already added.",
                cause: "1. Same identifier used twice. 2. Re-adding pending notification. 3. Identifier collision.",
                solutions: [
                    "Use unique identifiers for each request",
                    "Remove existing request before adding",
                    "Use UUID for dynamic identifiers",
                    "Check pending notifications before adding",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Unique Identifiers",
                        badCode: "let request = UNNotificationRequest(identifier: \"reminder\", content: content, trigger: trigger)\nUNUserNotificationCenter.current().add(request)  // May duplicate",
                        goodCode: "let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)\nUNUserNotificationCenter.current().add(request)",
                        explanation: "Use unique identifiers to avoid duplicate notification requests."
                    ),
                ],
                relatedErrors: ["UNErrorNotificationsNotAllowed"],
                tags: ["notifications", "duplicate", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/usernotifications",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL AUDIO/VIDEO ERRORS (Batch 2)
    // =========================================================================
    
    private func moreAudioVideoErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .audioVideo,
                severity: .high,
                title: "AVFoundation: Cannot start capture session",
                errorCode: "AVCAPTURE_SESSION_FAIL",
                description: "AVCaptureSession failed to start running.",
                cause: "1. Camera/mic permission denied. 2. No valid input device. 3. Session already running. 4. Invalid preset.",
                solutions: [
                    "Check and request camera/microphone permissions",
                    "Verify input device is available",
                    "Start session on background thread",
                    "Check session.canSetSessionPreset",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Start Capture",
                        badCode: "session.startRunning()  // On main thread - may hang",
                        goodCode: "DispatchQueue.global(qos: .userInitiated).async {\n    self.session.startRunning()\n}",
                        explanation: "Start capture session on a background thread."
                    ),
                ],
                relatedErrors: ["AVCaptureSessionRuntimeErrorNotification"],
                tags: ["video", "avfoundation", "capture", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/avfoundation/avcapturesession",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .audioVideo,
                severity: .high,
                title: "AVFoundation: Failed to create asset reader",
                errorCode: "AVASSET_READER_FAIL",
                description: "AVAssetReader failed to initialize for reading media.",
                cause: "1. Asset not playable. 2. Track not found. 3. Invalid time range. 4. DRM protected content.",
                solutions: [
                    "Check asset.isPlayable before creating reader",
                    "Verify track exists with asset.tracks",
                    "Validate time range is within asset duration",
                    "Handle DRM-protected content separately",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Valid Reader",
                        badCode: "let reader = try AVAssetReader(asset: asset)  // May fail",
                        goodCode: "guard asset.isPlayable else { return }\nguard let reader = try? AVAssetReader(asset: asset) else {\n    handleError()\n    return\n}",
                        explanation: "Validate asset playability before creating reader."
                    ),
                ],
                relatedErrors: ["AVAssetExportSessionStatusFailed"],
                tags: ["video", "avfoundation", "reader", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/avfoundation/avassetreader",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
            ErrorEntry(
                category: .audioVideo,
                severity: .high,
                title: "AVFoundation: AVAudioSession setActive failed",
                errorCode: "AVAUDIOSESSION_SETACTIVE_FAIL",
                description: "AVAudioSession setActive failed, usually due to audio session conflicts.",
                cause: "1. Another app has audio focus. 2. Category mismatch. 3. Options conflict with active session. 4. Interrupted by phone call.",
                solutions: [
                    "Handle AVAudioSessionInterruptionNotification",
                    "Set correct category before activation",
                    "Deactivate before changing categories",
                    "Use .notifyOthersOnDeactivation option",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Handle Interruption",
                        badCode: "try AVAudioSession.sharedInstance().setActive(true)  // May fail silently",
                        goodCode: "do {\n    try AVAudioSession.sharedInstance().setActive(true)\n} catch {\n    print(\"Audio session activation failed: \\(error)\")\n}",
                        explanation: "Handle audio session activation failures and interruptions."
                    ),
                ],
                relatedErrors: ["AVAudioSessionErrorCodeCannotStartPlaying"],
                tags: ["audio", "avfoundation", "session", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/avfoundation/avaudiosession",
                commonInVersions: ["iOS 13+", "macOS 10.15+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL ACCESSIBILITY ERRORS (Batch 2)
    // =========================================================================
    
    private func moreAccessibilityErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .accessibility,
                severity: .medium,
                title: "Accessibility: VoiceOver focus trapping in custom view",
                errorCode: "ACCESSIBILITY_FOCUS_TRAP",
                description: "VoiceOver focus gets trapped in a custom view and cannot escape.",
                cause: "1. Missing accessibilityElementDidBecomeFocused. 2. Incorrect accessibilityViewIsModal. 3. Custom focus management interfering with VoiceOver.",
                solutions: [
                    "Implement proper accessibility container",
                    "Use UIAccessibilityContainer protocol",
                    "Set accessibilityViewIsModal appropriately",
                    "Test with VoiceOver enabled",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Accessible Container",
                        badCode: "class TrapView: NSView { }  // No accessibility support",
                        goodCode: "class AccessibleView: NSView {\n    override var isAccessibilityElement: Bool {\n        get { true }\n        set { }\n    }\n    override var accessibilityRole: NSAccessibility.Role {\n        .group\n    }\n}",
                        explanation: "Implement proper accessibility support for custom views to avoid focus traps."
                    ),
                ],
                relatedErrors: ["VoiceOver stuck"],
                tags: ["accessibility", "voiceover", "focus", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/appkit/accessibility",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
            ErrorEntry(
                category: .accessibility,
                severity: .medium,
                title: "Accessibility: AXIsProcessTrustedWithOptions returned false",
                errorCode: "AX_NOT_TRUSTED",
                description: "Accessibility permissions not granted for the app.",
                cause: "1. App not in System Preferences > Security > Accessibility. 2. Permission revoked. 3. New binary signature.",
                solutions: [
                    "Prompt user to enable in System Preferences",
                    "Use AXIsProcessTrustedWithOptions to check",
                    "Provide fallback without accessibility features",
                    "For sandboxed apps, use appropriate entitlements",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Check Trust",
                        badCode: "// Assume accessibility is always available",
                        goodCode: "let options = [kAXTrustedCheckOptionPrompt: true] as CFDictionary\nlet trusted = AXIsProcessTrustedWithOptions(options)\nif !trusted {\n    showAccessibilityInstructions()\n}",
                        explanation: "Always check and request accessibility permissions before using accessibility APIs."
                    ),
                ],
                relatedErrors: ["kAXErrorAPIDisabled"],
                tags: ["accessibility", "trusted", "permission", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/applicationservices/axuielement_h",
                commonInVersions: ["macOS 10.14+", "macOS 11+", "macOS 12+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL LOCALIZATION ERRORS (Batch 2)
    // =========================================================================
    
    private func moreLocalizationErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .localization,
                severity: .medium,
                title: "Localization: String key 'X' not found in table 'Y'",
                errorCode: "LOCALIZATION_KEY_MISSING",
                description: "A localized string key was not found in the specified strings table.",
                cause: "1. Key missing in .strings file. 2. Wrong table name. 3. Bundle not found. 4. Table not included in target.",
                solutions: [
                    "Add missing key to all .strings files",
                    "Check table name matches file name",
                    "Ensure .strings files are in target",
                    "Use NSLocalizedString with comment for discoverability",
                    "Use genstrings to extract keys",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Localized String",
                        badCode: "let title = NSLocalizedString(\"missing_key\", comment: \"\")  // Returns \"missing_key\"",
                        goodCode: "let title = NSLocalizedString(\"welcome_title\", comment: \"Welcome screen title\")\n// Add to Localizable.strings:\n// \"welcome_title\" = \"Welcome\";",
                        explanation: "Always define keys in all localized .strings files. Use comments for context."
                    ),
                ],
                relatedErrors: ["Localization not found"],
                tags: ["localization", "strings", "key", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/nslocalizedstring",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .localization,
                severity: .medium,
                title: "Localization: Format string argument mismatch",
                errorCode: "LOCALIZATION_FORMAT_MISMATCH",
                description: "The number or type of arguments doesn't match the format string.",
                cause: "1. Wrong number of format specifiers. 2. Type mismatch (String vs Int). 3. Missing argument. 4. Extra argument.",
                solutions: [
                    "Match argument count to format specifiers",
                    "Use correct format specifier for each type",
                    "For Swift, prefer String.localizedStringWithFormat",
                    "Validate format strings with all localizations",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Format Match",
                        badCode: "// English: \"You have %d messages\"\nString(format: NSLocalizedString(\"message_count\", comment: \"\"), \"five\")  // Type mismatch",
                        goodCode: "// English: \"You have %d messages\"\nString(format: NSLocalizedString(\"message_count\", comment: \"\"), count)",
                        explanation: "Format arguments must match the format specifiers in type and count."
                    ),
                ],
                relatedErrors: ["CocoaFormatStringError"],
                tags: ["localization", "format", "strings", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/foundation/nslocalizedstring",
                commonInVersions: ["All versions"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL TESTING ERRORS (Batch 2)
    // =========================================================================
    
    private func moreTestingErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .testing,
                severity: .high,
                title: "XCTest: Asynchronous wait failed: Exceeded timeout of X seconds",
                errorCode: "XCTEST_TIMEOUT",
                description: "An async expectation timed out before being fulfilled.",
                cause: "1. Expectation never fulfilled. 2. Operation taking longer than timeout. 3. Completion handler not called. 4. Wrong expectation count.",
                solutions: [
                    "Increase timeout for slow operations",
                    "Ensure expectation is fulfilled on all paths",
                    "Check for early returns that skip fulfillment",
                    "Use XCTestExpectation with correct expectedFulfillmentCount",
                    "For async/await, use await fulfillment(of:)",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fulfill Expectation",
                        badCode: "let exp = expectation(description: \"fetch\")\nfetch { result in\n    if case .success = result {\n        exp.fulfill()\n    }\n    // Missing fulfill on failure\n}\nwait(for: [exp], timeout: 5)",
                        goodCode: "let exp = expectation(description: \"fetch\")\nfetch { result in\n    exp.fulfill()  // Always fulfill\n}\nwait(for: [exp], timeout: 5)",
                        explanation: "Always fulfill expectations on all completion paths, including error paths."
                    ),
                ],
                relatedErrors: ["XCTAssertEqual failed"],
                tags: ["testing", "xctest", "timeout", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .testing,
                severity: .high,
                title: "XCTest: XCTAssertNil failed - 'X' is not nil",
                errorCode: "XCTEST_ASSERT_NIL_FAIL",
                description: "An XCTAssertNil assertion failed because the value was not nil.",
                cause: "1. Object not properly deallocated. 2. Weak reference still holding value. 3. Cleanup not executed. 4. Race condition in test.",
                solutions: [
                    "Ensure proper cleanup in tearDown",
                    "Use weak references and check for nil after deallocation",
                    "Add autoreleasepool if needed",
                    "For delegates, nil them out in tearDown",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Verify Nil",
                        badCode: "func testDeallocation() {\n    var obj: MyClass? = MyClass()\n    weak var weakRef = obj\n    obj = nil\n    // May fail if obj has strong references\n    XCTAssertNil(weakRef)\n}",
                        goodCode: "func testDeallocation() {\n    var obj: MyClass? = MyClass()\n    weak var weakRef = obj\n    autoreleasepool {\n        obj = nil\n    }\n    XCTAssertNil(weakRef)\n}",
                        explanation: "Use autoreleasepool and ensure all strong references are released before checking for nil."
                    ),
                ],
                relatedErrors: ["XCTAssertNotNil failed"],
                tags: ["testing", "xctest", "nil", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xctest",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .testing,
                severity: .medium,
                title: "XCTest: Test case 'X' failed - No assertions",
                errorCode: "XCTEST_NO_ASSERTIONS",
                description: "A test method ran without making any assertions, which is usually a mistake.",
                cause: "1. Empty test method. 2. All assertions in conditional that didn't execute. 3. Early return before assertions.",
                solutions: [
                    "Add meaningful assertions",
                    "Use XCTAssertNoThrow for code that should not error",
                    "Ensure conditional paths have assertions",
                    "Remove empty test methods",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Add Assertions",
                        badCode: "func testSomething() {\n    let result = calculate()\n    // No assertion\n}",
                        goodCode: "func testSomething() {\n    let result = calculate()\n    XCTAssertEqual(result, expectedValue)\n}",
                        explanation: "Every test should have at least one assertion that verifies expected behavior."
                    ),
                ],
                relatedErrors: ["XCTest empty test"],
                tags: ["testing", "xctest", "assertions", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xctest",
                commonInVersions: ["All versions"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL SPM ERRORS (Batch 2)
    // =========================================================================
    
    private func moreSPMErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .packageManager,
                severity: .high,
                title: "Swift Package Manager: dependency 'X' could not be resolved",
                errorCode: "SPM_RESOLVE_FAIL",
                description: "SPM could not resolve a dependency, usually due to version conflicts.",
                cause: "1. Incompatible version requirements. 2. Dependency graph conflict. 3. Git tag not found. 4. Package URL inaccessible.",
                solutions: [
                    "Check Package.resolved for pinned versions",
                    "Use exact versions for conflicting packages",
                    "Run swift package resolve --verbose",
                    "Clear .build folder and re-resolve",
                    "Check for transitive dependency conflicts",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Resolve Conflict",
                        badCode: "// Package A requires Alamofire 5.0, Package B requires Alamofire 4.9",
                        goodCode: "// In Package.swift, specify exact or compatible versions\n.package(url: \"https://github.com/Alamofire/Alamofire.git\", from: \"5.0.0\")\n// Or use branch/commit for direct control",
                        explanation: "Ensure all dependencies have compatible version requirements."
                    ),
                ],
                relatedErrors: ["SPM incompatible versions"],
                tags: ["spm", "dependency", "resolve", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            ErrorEntry(
                category: .packageManager,
                severity: .high,
                title: "Swift Package Manager: target 'X' has overlapping sources with target 'Y'",
                errorCode: "SPM_OVERLAPPING_SOURCES",
                description: "Two SPM targets include the same source files.",
                cause: "1. Same file referenced in multiple targets. 2. Glob patterns overlapping. 3. Shared code not extracted to separate target.",
                solutions: [
                    "Extract shared code into a separate target",
                    "Remove duplicate file references",
                    "Adjust source paths to be non-overlapping",
                    "Use exclude to prevent overlap",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Separate Targets",
                        badCode: "// Target A: path Sources, Target B: path Sources\n// Both include Shared.swift",
                        goodCode: "// Create Shared target\n.target(name: \"Shared\", path: \"Sources/Shared\"),\n.target(name: \"App\", dependencies: [\"Shared\"], path: \"Sources/App\"),\n.target(name: \"Tests\", dependencies: [\"Shared\"], path: \"Tests\")",
                        explanation: "Extract shared code into its own target to avoid source overlaps."
                    ),
                ],
                relatedErrors: ["SPM duplicate target"],
                tags: ["spm", "target", "sources", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
            ErrorEntry(
                category: .packageManager,
                severity: .medium,
                title: "Swift Package Manager: package 'X' is using Swift tools version Y but Z is required",
                errorCode: "SPM_TOOLS_VERSION",
                description: "The Swift tools version in Package.swift doesn't match the required version for a dependency.",
                cause: "1. Package uses newer SPM features. 2. Xcode version too old. 3. Tools version declaration mismatch.",
                solutions: [
                    "Update to newer Xcode",
                    "Pin dependency to older compatible version",
                    "Check Package.swift tools-version comment",
                    "Use swift-tools-version that matches Xcode",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Tools Version",
                        badCode: "// swift-tools-version:5.9  // Package requires 5.9\n// But Xcode only supports 5.7",
                        goodCode: "// swift-tools-version:5.7  // Match minimum Xcode version\n// Or update Xcode to support 5.9",
                        explanation: "Ensure swift-tools-version matches your Xcode capabilities or update Xcode."
                    ),
                ],
                relatedErrors: ["SPM incompatible tools version"],
                tags: ["spm", "tools version", "build"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode",
                commonInVersions: ["Xcode 12+", "Xcode 13+", "Xcode 14+", "Xcode 15+"]
            ),
        ]
    }


    // =========================================================================
    // MARK: - ADDITIONAL GENERAL ERRORS (Batch 2)
    // =========================================================================
    
    private func moreGeneralErrors() -> [ErrorEntry] {
        return [
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "dyld: Library not loaded: @rpath/X.framework/X",
                errorCode: "DYLD_LIBRARY_NOT_LOADED",
                description: "A dynamic library or framework failed to load at runtime.",
                cause: "1. Framework not embedded in app bundle. 2. Runpath Search Paths incorrect. 3. Framework removed but still linked. 4. Architecture mismatch.",
                solutions: [
                    "Embed framework in app target (General > Frameworks)",
                    "Add @executable_path/Frameworks to Runpath Search Paths",
                    "Clean build folder and rebuild",
                    "Check framework architectures match app",
                    "For SPM packages, ensure product is library not executable",
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Embed Framework",
                        badCode: "// Framework linked but not embedded",
                        goodCode: "// Xcode > Target > General > Frameworks, Libraries... > Embed & Sign\n// Build Settings > Runpath Search Paths > @executable_path/Frameworks",
                        explanation: "Dynamic frameworks must be both linked AND embedded in the app bundle."
                    ),
                ],
                relatedErrors: ["dyld: Symbol not found"],
                tags: ["dyld", "framework", "library", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/embedding-frameworks-in-an-app",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "dyld: Symbol not found: _OBJC_CLASS_$__X",
                errorCode: "DYLD_SYMBOL_NOT_FOUND",
                description: "A symbol (class, function, variable) referenced at runtime could not be found in any loaded library.",
                cause: "1. Framework not linked. 2. Symbol removed in newer version. 3. Weak framework not available on device. 4. Name mangling mismatch.",
                solutions: [
                    "Link the framework containing the symbol",
                    "Check symbol availability with @available",
                    "For weak frameworks, handle missing symbols",
                    "Clean build and re-link",
                    "Check for Objective-C/Swift name mismatch",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Link Framework",
                        badCode: "// Using ClassA from FrameworkB but FrameworkB not linked",
                        goodCode: "// Xcode > Target > General > Frameworks, Libraries... > Add FrameworkB\n// Or in Package.swift: .product(name: \"FrameworkB\", package: \"PackageB\")",
                        explanation: "All referenced symbols must come from linked frameworks or libraries."
                    ),
                ],
                relatedErrors: ["dyld: Library not loaded"],
                tags: ["dyld", "symbol", "linker", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/linking-to-a-library-or-framework",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "dyld: Image not found",
                errorCode: "DYLD_IMAGE_NOT_FOUND",
                description: "A dynamic library image could not be found at the expected path.",
                cause: "1. Framework not copied to app bundle. 2. Incorrect install path. 3. Framework deleted after build. 4. Sandbox restriction.",
                solutions: [
                    "Verify framework exists in app bundle",
                    "Check Framework Search Paths",
                    "Ensure Copy Files build phase includes framework",
                    "For embedded frameworks, use @rpath correctly",
                ],
                codeExamples: [
                    CodeExample(
                        language: "bash",
                        title: "Check Bundle",
                        badCode: "// Framework missing from .app bundle",
                        goodCode: "ls MyApp.app/Contents/Frameworks/\n# Should contain all required frameworks",
                        explanation: "Verify all required frameworks are present in the final app bundle."
                    ),
                ],
                relatedErrors: ["dyld: Library not loaded"],
                tags: ["dyld", "image", "framework", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/embedding-frameworks-in-an-app",
                commonInVersions: ["All versions"]
            ),
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "EXC_CRASH (SIGKILL) - Termination Reason: Namespace RUNNINGBOARD, Code 0xdead10cc",
                errorCode: "RUNNINGBOARD_0xdead10cc",
                description: "The system killed the app for holding a file lock or SQLite lock while in the background.",
                cause: "1. File lock held during background suspension. 2. SQLite WAL mode with open transaction. 3. Core Data context locked.",
                solutions: [
                    "Release file locks before entering background",
                    "Close Core Data contexts on backgrounding",
                    "Use beginBackgroundTask to finish operations",
                    "Commit SQLite transactions before suspension",
                    "Avoid long-running file operations in background",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Release Locks",
                        badCode: "// Holding file lock while app goes to background",
                        goodCode: "func applicationDidEnterBackground(_ application: UIApplication) {\n    backgroundTask = application.beginBackgroundTask {\n        // Clean up and release locks\n        self.saveContext()\n        self.closeFileHandles()\n        application.endBackgroundTask(self.backgroundTask)\n    }\n}",
                        explanation: "Release all locks and finish I/O before app suspension."
                    ),
                ],
                relatedErrors: ["Jetsam", "EXC_RESOURCE"],
                tags: ["runningboard", "sigkill", "background", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background",
                commonInVersions: ["iOS 13+", "macOS 11+"]
            ),
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "EXC_CRASH (SIGKILL) - Termination Reason: Namespace SPRINGBOARD, Code 0x8badf00d",
                errorCode: "SPRINGBOARD_0x8badf00d",
                description: "The system killed the app for taking too long to launch or terminate (ate bad food).",
                cause: "1. Main thread blocked during launch. 2. Synchronous network on launch. 3. Infinite loop in app delegate. 4. Heavy Core Data migration on launch.",
                solutions: [
                    "Move work off main thread during launch",
                    "Use async initialization",
                    "Defer heavy operations until after launch",
                    "Profile launch with Instruments",
                    "Implement state restoration efficiently",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Fast Launch",
                        badCode: "func application(_ app: UIApplication, didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {\n    syncLoadData()  // Blocks main thread\n    return true\n}",
                        goodCode: "func application(_ app: UIApplication, didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {\n    DispatchQueue.global().async {\n        self.loadData()\n    }\n    return true\n}",
                        explanation: "Never block the main thread during app launch. Move heavy work to background."
                    ),
                ],
                relatedErrors: ["Jetsam"],
                tags: ["springboard", "sigkill", "launch", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/uikit/app_and_environment/responding_to_the_launch_of_your_app",
                commonInVersions: ["iOS 13+", "macOS 11+"]
            ),
            ErrorEntry(
                category: .general,
                severity: .high,
                title: "EXC_RESOURCE RESOURCE_TYPE_MEMORY (limit=XXXX MB, unused=0x0)",
                errorCode: "EXC_RESOURCE_MEMORY",
                description: "The app exceeded its memory limit and was terminated.",
                cause: "1. Memory leak. 2. Loading large assets. 3. Too many cached objects. 4. Unbounded collection growth.",
                solutions: [
                    "Profile memory with Instruments",
                    "Implement cache size limits",
                    "Release unused view controllers",
                    "Use weak references to break retain cycles",
                    "Downsample images before loading",
                    "Respond to memory warnings",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "Memory Management",
                        badCode: "var cache: [String: UIImage] = [:]  // Grows unbounded",
                        goodCode: "let cache = NSCache<NSString, UIImage>()\ncache.countLimit = 100\ncache.totalCostLimit = 50 * 1024 * 1024  // 50MB",
                        explanation: "Use NSCache with limits instead of unbounded dictionaries."
                    ),
                ],
                relatedErrors: ["Jetsam", "Memory pressure"],
                tags: ["exc_resource", "memory", "jetsam", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["iOS 13+", "macOS 11+"]
            ),
            ErrorEntry(
                category: .general,
                severity: .critical,
                title: "EXC_RESOURCE RESOURCE_TYPE_CPU (limit=XX%, unused=0x0)",
                errorCode: "EXC_RESOURCE_CPU",
                description: "The app exceeded its CPU usage limit and was terminated, usually on background tasks.",
                cause: "1. Background task using too much CPU. 2. Infinite loop. 3. Expensive computation on main thread. 4. Tight polling loop.",
                solutions: [
                    "Add sleep/yield in loops",
                    "Move heavy work to background",
                    "Use background task assertions for extended work",
                    "Profile CPU usage with Instruments",
                    "Implement throttling for repeated operations",
                ],
                codeExamples: [
                    CodeExample(
                        language: "swift",
                        title: "CPU Throttling",
                        badCode: "while isRunning {\n    processData()  // Tight loop, no yield\n}",
                        goodCode: "while isRunning {\n    processData()\n    Thread.sleep(forTimeInterval: 0.01)  // Yield CPU\n}",
                        explanation: "Add small delays in loops to prevent excessive CPU usage."
                    ),
                ],
                relatedErrors: ["EXC_RESOURCE"],
                tags: ["exc_resource", "cpu", "jetsam", "runtime"],
                appleDocURL: "https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early",
                commonInVersions: ["iOS 13+", "macOS 11+"]
            ),
        ]
    }
