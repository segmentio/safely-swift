import XCTest
@testable import Safely
#if canImport(SafelyInternal)
import SafelyInternal
#endif

final class FunctionalTests: XCTestCase {
    func testSwiftThrowsScenario() throws {
        enum MyError: Error {
            case someError
        }
        func myThrowingFunc() throws -> Void {
            throw MyError.someError
        }
        
        Safely.logErrorsToConsole = true
        Safely.handleThrows = true
        Safely.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        
        let error = Safely.call(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
            try myThrowingFunc()
        }

        XCTAssertNotNil(error)
    }
    
    func testSwiftThrowsDisabledScenario() throws {
        enum MyError: Error {
            case someError
        }
        func myThrowingFunc() throws -> Void {
            throw MyError.someError
        }
        
        Safely.handleThrows = false
        Safely.logErrorsToConsole = true
        Safely.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        
        let error = Safely.call(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
            try myThrowingFunc()
        }

        XCTAssertNil(error)
    }

    #if canImport(SafelyInternal)
    func testObjCExceptionScenario() throws {
        Safely.logErrorsToConsole = true
        Safely.handleExceptions = true
        Safely.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        
        struct UserDefaultsContext {
            let userDefaults: UserDefaults
            let valueToWrite: Sendable
            let keyToWrite: String
        }
        
        let context = UserDefaultsContext(userDefaults: UserDefaults(), valueToWrite: NSNull(), keyToWrite: "myNull")
        
        let error = Safely.call(scenario: Scenarios.nullPListSettings, context: context) { context in
            let userDefaults = context.userDefaults
            userDefaults.set(context.valueToWrite, forKey: context.keyToWrite)
        }

        XCTAssertNotNil(error)
    }
    
    func testObjCExceptionDisabledScenario() throws {
        Safely.logErrorsToConsole = true
        Safely.handleExceptions = false
        Safely.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        
        struct UserDefaultsContext {
            let userDefaults: UserDefaults
            let valueToWrite: Sendable
            let keyToWrite: String
        }
        
        let context = UserDefaultsContext(userDefaults: UserDefaults(), valueToWrite: NSNull(), keyToWrite: "myNull")
        
        let error = SafelyInternal.SACatchException {
            let _ = Safely.call(scenario: Scenarios.nullPListSettings, context: context) { context in
                let userDefaults = context.userDefaults
                userDefaults.set(context.valueToWrite, forKey: context.keyToWrite)
            }
        }
        
        XCTAssertNotNil(error)
    }
    
    func testForceUnwrap() throws {
        Safely.logErrorsToConsole = true
        Safely.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        Safely.handleSignals = true
        Safely.handleAssertions = true
        
        var e: Error? = nil
        do {
            try Safely.catchCall(scenario: Scenarios.forceUnwrap, context: NoContext()) { context in
                let s: String? = nil
                print(s!)
            }
        } catch {
            e = error
            print("\(error)")
        }
        
        XCTAssertNotNil(e)
    }

    func testSignalHandlers() throws {
        Safely.logErrorsToConsole = true
        Safely.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        Safely.handleSignals = true
        Safely.handleAssertions = false
        
        let error = Safely.call(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
            raise(SIGALRM)
        }
        XCTAssertNotNil(error)
    }
    #endif
}
