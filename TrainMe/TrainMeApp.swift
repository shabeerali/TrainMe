//
//  TrainMeApp.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import SwiftUI

@main
struct TrainMeApp: App {
    @State private var container = AppContainer()
    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
