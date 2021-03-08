//
//  Memoji_image_genetatorApp.swift
//  Memoji image genetator
//
//  Created by Haruki Nazawa on 2021/03/08.
//

import SwiftUI

@main
struct Memoji_image_genetatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
