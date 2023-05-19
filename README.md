# Safely for Swift


Safely is a library intended to make calling system level, unknown, or 3rd party code a LITTLE bit safer.  It does so by catching any unhandled exceptions or throws and allow the caller to treat them as a Swift error and ignore, attempt to recover, or even just log the issue somewhere useful.

## Options

Safely contains of high level options to assist in your development.

`SafelyOptions.onError` can be optionally be set as a global handler for when errors are thrown or exceptions occur within a safe call.

`SafelyOptions.logErrorsToConsole` allows errors to be logged to the debug console.  It's default is `false`.

`SafelyOptions.onUncaughtException` can catch all system level exceptions.  While it's not able to recover, it at least gives a reporting mechism for you to use as needed.

## Usage

Safely is structured to be explicit and maintain historical information about what's happening when you need to call something in a safe manner.  A developer should be able to look at the defined scenarios and get an idea of why a piece of code needed to be called safely, as well as who the original implementor was.

This is defined in SafeScenarios.  Scenarios are intended to be as minimal as possible rather than wrap large chunks of code.  See an example implementation below:

```swift
struct Scenarios {
    static let nullPListSettings = SafeScenario(
        description: "Guard against NULL potentially being set to UserDefaults",
        implementor: "@bsneed"
    )
    static let dummyThrowingFunction = SafeScenario(
        description: "Guard against a swift function throwing",
        implementor: "@bsneed"
    )
}
```

Once scenario(s) have been defined, they can then be used in a safe call.  A safe call also needs context.  In this case, context refers to all the necessary external bits a block or closure is going to need when it is executed.  Contexts in your code can be defined more globally if they're used frequently, or even just once as needed.

```swift
struct UserDefaultsContext {
    let userDefaults: UserDefaults
    let valueToWrite: Sendable
    let keyToWrite: String
}
let context = UserDefaultsContext(userDefaults: UserDefaults(), valueToWrite: NSNull(), keyToWrite: "myNull")
let error = safely(scenario: Scenario.nullPListSettings, context: context) { context in
    context.userDefaults.set(context.valueToWrite, forKey: context.keyToWrite)
}

if let e = error {
    // whatever needs to be done if an error is given.
    myAppLogging.log("ERROR: \(e)")
    tryToRecoverThisScenario()
}
```

In cases where no context is necessary or needed, you can use the `NoContext()` dummy struct.  As mentioned above, the intent is to be explicit.  We want to communicate to the reader that no context was actually necessary rather than just passing nil.  ie: We thought about it and made a conscious decision that context wasn't neeed.

```swift
let error = safely(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
    try myThrowingFunc()
}
```

It may be useful to treat all possible errors in the exact same way in some aspect.  `safely` is marked as having a discardable result, so we could instead do this:

```swift
SafelyOptions.onError = { error in
    myAppLogging.log("ERROR: Oh noes, we got an error: \(error)")
}

...
 
safely(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
    try myThrowingFunc()
}
```

If we wanted to handle the error above in a special way, we could still do so, but the onError handler will do the logging that is desired on every error.

There are extreme cases where sometimes an error just isn't predicted.  Maybe it's writing to disk and the disk space is full?  Maybe a 3rd party library crashes if some calls are done out of order?  Either way, a mechanism is provided to help you get this information quickly.  While you are still responsible for sending the information or storing it for when you actually can, a pass-through mechanism can be enabled for all uncaught exceptions.

```swift
SafelyOptions.onUncaughtException = { error in
    myAppLogging.fatal("UNCAUGHT EXCEPTION!!! This resulted in a crash on a users device: \(error)")
}
```

---

MIT License

Copyright (c) 2023 Segment

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.







