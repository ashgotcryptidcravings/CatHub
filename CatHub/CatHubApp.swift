//
//  CatHubApp.swift
//  CatHub
//
//  Created by ZZZerosworld on 1/29/26.
//

import SwiftUI

@main
struct CatHubApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
