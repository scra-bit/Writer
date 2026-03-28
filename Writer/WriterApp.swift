//
//  WriterApp.swift
//  Writer
//
//  Created by Emmett on 3/28/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct WriterApp: App {
    var body: some Scene {
        DocumentGroup(editing: .itemDocument, migrationPlan: WriterMigrationPlan.self) {
            ContentView()
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

struct WriterMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        WriterVersionedSchema.self,
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct WriterVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Item.self,
    ]
}
