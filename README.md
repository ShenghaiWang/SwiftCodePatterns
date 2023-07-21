#  Swift Code Patterns

While appreciating the power of Swift macros to help redue boilerplate code, 
we find it not straightforward(or not even possible due to its design goal limitation) in some cases.
This package is to try bridge this gap to allow us to generate pattern code using templates based on some other piece of code.
It is very practical for cases like generating:

1. the corresponding variable in `EnvironmentValues` extension for new defined `EnvironmentKey`.
2. the corresponding variable in `UITraitCollection` extension for new defined `UITraitDefinition`.
3. the corresponding method in `View` extension for new defined `ViewModifer`.

## Install

    .package(url: "https://github.com/ShenghaiWang/SwiftCodePatterns.git", from: "1.0.0")
    
    
## Usage

The same functionality is made available via both SPM Command Plugin and SPM Build Tool Plugin. 
Configure the rule and explore it first using SPM Command Plugin. 
At the end of the output of this command, find the generated code file name and path. 
Open it and confirm if the generated code is expected.
Integrate Build Tool Plugin into target build phase after happy with the result.
In this mode, the generated code will be included into project automatically.
More info about SPM plugins can be found [here](https://developer.apple.com/videos/play/wwdc2022/110359/).

## Configuration

One sample configuration file `AutoCodePatterns.yml` is included in this package, 
which provids rules to generate code for new defined `EnvironmentKey`, `UITraitDefinition`, `ViewModifer`.
It also has two methods for generating code for `Equatable`, `Hashable` conformance to a class type.
Please tailer the template to suit the project needs and put this configureation file at the root folder of the project
(Please keep the file name unchanged).

Currently, it supports two types of transformation. One is with `template` and another using `Swift` code. 
Please check the example below for details.

## Example

### Configuration

```yaml
scope:
#  include: # either using `include` or `exclude`, if both are configured, the `exclude` will be ingored.
#    - /a.swift # include this file - ending with `.swift`
#    - /a/ # include this path prefix
  exclude:
    - /a.swift # exclude this file - ending with `.swift`
    - /a/ # exclude this path prefix
rules:
-
  rule: autoEnvironmentKey # rule name to help reason about the purpose of the rule
  selector: # the criteria to apply this rule, could be a combinstion of type, inheritence, included names, excluded names
    type: struct # the data type
    inherits:   # the inheritence
      - EnvironmentKey # only the type that inherits this type will be eligible for this rule
  imports: # the frameworks that need to be imported in the file
    - SwiftUI
# The transform if the rule applies. The code quoted by `#` will be expanded.
# If the code inside two # need to expand again, quote it using two `|`. In this case, #name# becomes |name|
# In total, we have 3 types of expansion so far: name, type, properties.
# Name expansion will be based on the type name
# Type expansion will be based on the data type name
# Properties expansion will be based on the properties defined in the type.
# Properties expansion is different from name and type expansion as it could be a loop in cased of more than 1 properties defined in the type.
# Both name and type expansion can have transformers followed.
# All the transformers are separated using `*` and they will be applied into name and type in order.
# And they all have a straightforward name to reason about their functionality.
# The possible transformers for name and type are:
# `identity`, `lowerInitial`, `upperInitial`: these 3 don't need parameter
# `replaceTo(Value)`, `removeSuffix(Value)`, `addSuffix(Value)`, `removePrefix(Value)`, `addPrefix(Value)`: these 4 need one parameters, just put a new string in bracket without quotes.
# `replace(oldValue,newValue)`: these one need two parameters, it will replace the oldValue to newValue using `String.replacingOccurrences(of:with:)`
# Combine these in orders to get the right possible name
# Properties expansion needs a `joiner`. For example `#properties*joiner( && )<lhs.|name| == rhs.|name|>#`.
# in this case the name inside this property expansion was quoted using `|`.
# Can also do the same for type here if you need type in the destination code.
# Can even following the transformers like |name.upperInital| or |type.lowerInitial| etc. Combine them in a sensible way to get the code looks right.
#  transform: >
#    extension EnvironmentValues {
#        var #name*lowerInitial#: String {
#            get { self[#name#.self] }
#            set { self[#name#.self] = newValue }
#        }
#
#        var #name*lowerInitial*removeSuffix(Key)*addSuffix(Value)#: String {
#            get { self[#name#.self] }
#            set { self[#name#.self] = newValue }
#        }
#    }
# If feeling swifty, choose code transform instead. The codeTransform below is identical to the transform above.
# Even though it looks wordy for this case, this approach might be useful for some cases where need more flexibilities of transforming code.
# The `name` is a `String` type and `properties` is an array of tuple type of `(name: String, type: String)`
# The code write can directly access to these two values
  codeTransform: | # Write swift code as usual and assign the final result to `generatedCode` variable in `String` format
    let name1 = name.prefix(1).lowercased() + name.dropFirst()
    let name2 = (name.prefix(1).lowercased() + name.dropFirst()).replacingOccurrences(of: "Key", with: "Value")
    generatedCode =
    """
    extension EnvironmentValues {
        var \(name1): String {
            get { self[\(name).self] }
            set { self[\(name).self] = newValue }
        }
        var \(name2): String {
            get { self[\(name).self] }
            set { self[\(name).self] = newValue }
        }
    }
    """
-
  rule: autoTraitDefinition
  selector:
    type: struct
    inherits:
      - UITraitDefinition
  imports:
    - SwiftUI
  transform: >
    extension UITraitCollection {
        var #name*addPrefix(is)*removeSuffix(Trait)#: Bool { self[#name#.self] }
    }

    extension UIMutableTraits {
        var #name*addPrefix(is)*removeSuffix(Trait)#: Bool {
            get { self[#name#.self] }
            set { self[#name#.self] = newValue }
        }
    }
-
  rule: autoViewModifier
  selector:
    type: struct
    inherits:
      - ViewModifier
  imports:
    - SwiftUI
  transform: >
    extension View {
        func #name*lowerInitial#(#properties*joiner(, )<|name|: |type|>#) -> some View {
            modifier(#name#(#properties*joiner(, )<|name|: |name|>#))
        }
    }
-
  rule: autoEquatable
  selector:
    type: class
    inherits:
      - MyType
  transform: >
    extension #name#: Equatable {
        static func == (lhs: #name#, rhs: #name#) -> Bool {
            #properties*joiner( && )<lhs.|name| == rhs.|name|>#
        }
    }
-
  rule: autoHashable
  selector:
    type: class
    inherits:
      - MyType
  transform: >
    extension #name#: Hashable {
        func hash(into hasher: inout Hasher) {
            #properties*joiner()<hasher.combine(|name|)>#
        }
    }
```

### Source Code

```swift
import Foundation

struct MyEnvironmentKey: EnvironmentKey {
    static let defaultValue: String = "Default value"
}

struct ContainedInSettingsTrait: UITraitDefinition {
    static let defaultValue = false
}

struct SimpleViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption2)
    }
}

struct ViewModifierWithInit: ViewModifier {
    let font: Font
    let padding: CGFloat
    let color: Color?

    func body(content: Content) -> some View {
        content
            .font(font)
            .padding(padding)
            .foregroundColor(color)
    }
}

protocol MyType {}

class ABC: MyType {
    var a: String
    var b: Int
}

```

### Generated Code

```swift
import SwiftUI

extension EnvironmentValues {
    var myEnvironmentKey: String {
        get {
            self [MyEnvironmentKey.self]
        }
        set {
            self [MyEnvironmentKey.self] = newValue
        }
    }

    var myEnvironmentValue: String {
        get {
            self [MyEnvironmentKey.self]
        }
        set {
            self [MyEnvironmentKey.self] = newValue
        }
    }
}

extension UITraitCollection {
    var isContainedInSettings: Bool {
        self [ContainedInSettingsTrait.self]
    }
}

extension UIMutableTraits {
    var isContainedInSettings: Bool {
        get {
            self [ContainedInSettingsTrait.self]
        }
        set {
            self [ContainedInSettingsTrait.self] = newValue
        }
    }
}

extension View {
    func simpleViewModifier() -> some View {
        modifier(SimpleViewModifier())
    }
}

extension View {
    func viewModifierWithInit(font: Font, padding: CGFloat, color: Color?) -> some View {
        modifier(ViewModifierWithInit(font: font, padding: padding, color: color))
    }
}

extension ABC: Equatable {
    static func == (lhs: ABC, rhs: ABC) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

extension ABC: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(a)
        hasher.combine(b)
    }
}
```
