import XCTest
@testable import Safely

final class FunctionalTests: XCTestCase {
    func testObjCExceptionScenario() throws {
        
        SafelyOptions.logErrorsToConsole = true
        SafelyOptions.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        
        struct UserDefaultsContext {
            let userDefaults: UserDefaults
            let valueToWrite: Sendable
            let keyToWrite: String
        }
        
        let context = UserDefaultsContext(userDefaults: UserDefaults(), valueToWrite: NSNull(), keyToWrite: "myNull")
        
        let error = safely(scenario: Scenarios.nullPListSettings, context: context) { context in
            let userDefaults = context.userDefaults
            userDefaults.set(context.valueToWrite, forKey: context.keyToWrite)
        }

        XCTAssertNotNil(error)
    }
    
    func testSwiftExceptionScenario() throws {
        enum MyError: Error {
            case someError
        }
        func myThrowingFunc() throws -> Void {
            throw MyError.someError
        }
        
        SafelyOptions.logErrorsToConsole = true
        SafelyOptions.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        
        let error = safely(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
            try myThrowingFunc()
        }

        XCTAssertNotNil(error)
    }
    
    func testForceUnwrap() throws {
        SafelyOptions.logErrorsToConsole = true
        SafelyOptions.onError = { error in
            print("ERROR: Oh noes, we got an error!")
        }
        SafelyOptions.onSignals = { error in
            print("SIGNAL: We got a signal! \(error)")
        }
        
        //let error = safely(scenario: Scenarios.dummyThrowingFunction, context: NoContext()) { context in
            //let s: String? = nil
            //print(s!)
            //siginterrupt(SIGILL, 0)
        //}
        
        do {
            try Fortify.protect {
                let s: String? = nil
                print(s!)
            }
        } catch {
            print("\(error)")
        }
        
        //XCTAssertNotNil(error)
    }
    
    /* XCTest catches the exception before our handler runs. :(
    func testUncaughtException() throws {
        SafelyOptions.onUncaughtException = { error in
            print("CRASH: Oh noes!  An uncaught exception!")
        }
        
        UserDefaults.setValue(NSNull(), forKey: "someKey")
    }
    */
}
