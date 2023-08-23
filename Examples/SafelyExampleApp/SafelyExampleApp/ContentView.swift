//
//  ContentView.swift
//  SafelyExampleApp
//
//  Created by Brandon Sneed on 2/1/23.
//

import SwiftUI
import Safely

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            Safely.onError = { error in
                switch error {
                case is ExceptionError:
                    print("UNCAUGHT EXCEPTION!!! Oh noes, we got an error!!! \(error)")
                case is SignalError:
                    print("SIGNAL: We got a signal! \(error)")
                case is AssertionError:
                    print("We got an assertion! \(error)")
                default:
                    print("Something threw an error! \(error)")
                }
            }
            
            DispatchQueue.main.async {
                let scenario = SafeScenario(description: "blah", implementor: "bsneed")
                let error = Safely.call(scenario: scenario, context: NoContext()) { context in
                    let s: String? = nil
                    print(s!)
                }
                print(error as Any)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
