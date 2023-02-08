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
            SafelyOptions.onUncaughtException = { error in
                print("UNCAUGHT EXCEPTION!!! Oh noes, we got an error!!!")
            }
            SafelyOptions.onSignals = { error in
                print("SIGNAL: We got a signal! \(error)")
            }
            
            /*DispatchQueue.main.async {
                sleep(5)
                UserDefaults().set(NSNull(), forKey: "myKey")
            }*/
            DispatchQueue.main.async {
                let scenario = SafeScenario(description: "blah", implementor: "bsneed")
                let error = safely(scenario: scenario, context: NoContext()) { context in
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
