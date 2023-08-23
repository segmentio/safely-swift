# Safely for Swift


Safely is a library intended to make calling system level, unknown, or 3rd party code a LITTLE bit safer.  It does so by catching any unhandled exceptions or throws and allow the caller to treat them as a Swift error and ignore, attempt to recover, or even just log the issue somewhere useful.

There are extreme cases where sometimes an error just isn't predicted or can be reasonably handled without crashing.  Maybe it's writing to disk and the disk space is full?  Maybe a 3rd party library crashes if some calls are done out of order?  Either way, Safely provides a mechanism to help you get this information quickly and recover from it without crashing.  While you are still responsible for sending the information or storing it for when you actually can, Safely's call and catching capabilities can be enabled for all uncaught exceptions, throws, signals and assertions.

## Options

Safely contains many high level options to assist in your development.

`Safely.onError` can be optionally set as a global handler for when errors are thrown or exceptions occur within a safe call.

`Safely.logErrorsToConsole` allows errors to be logged to the debug console.  The default value is `false`.

`Safely.handleThrows` specifies that unhandled throws that may occur are to be caught and treated as a failure of the safe call and prevent the app from crashing.  The errors thrown will be the same ones that are propogated back to `Safely.call` and `Safely.catchCall`.  The default value is `true`.

`Safely.handleExceptions` specifies that unhandled ObjC exceptions are to be caught (on supported platforms) and treated as a failure of the safe call and prevent the app from crashing.  Exceptions will be propogated back as `ExceptionError`.  The default value is `true`.

`Safely.handleSignals` specifies that unhandled signals are to be caught and treated as a failure of the safe call and prevent the app from crashing.  The signals that will be caught are SIGILL, SIGABRT, SIGTRAP and SIGALRM (in debug).  Signals will be propogated back as `SignalError`. The default value is `false`.

`Safely.handleAssertions` specifies that any assertions (assert, assertionFailure, fatalAssertion, etc) will be caught and treated as a failure of the safe call, preventing the app from crashing.  Assertions will be propogated back as `AssertionError`.  The default value is `false`.

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
let error = Safely.call(scenario: Scenario.nullPListSettings, context: context) { context in
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
let error = Safely.call(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
    try myThrowingFunc()
}
```

It may be useful to treat all possible errors in the exact same way in some aspect.  `safely` is marked as having a discardable result, so we could instead do this:

```swift
Safely.onError = { error in
    myAppLogging.log("ERROR: Oh noes, we got an error: \(error)")
}

// some other code ...
 
Safely.call(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
    try myThrowingFunc()
}
```

If we wanted to handle the error above in a special way, we could still do so, but the onError handler will do the logging that is desired on every error.

## Try/Catch

In addition to `Safely.call`'s returned error, there's an alternative version that works exactly the same but provides a try/catch friendly interface.

```
do {
    try Safely.catchCall(scenario: Scenarios.forceUnwrap, context: NoContext()) { context in
        let s: String? = nil
        print(s!)
    }
} catch {
    print("\(error)")
}
```





