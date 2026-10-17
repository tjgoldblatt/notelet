//
//  SwiftUIView.swift
//  Notelet
//
//  Created by Mykola Harmash on 05.05.26.
//

import SwiftUI

struct NoteletSheet<LastPageAccessory: View>: ViewModifier {
    @State private var isPresented = false

    let notes: [NoteletVersionNotes]
    let version: NoteletPresentedVersion?
    let onDismiss: () -> Void
    let configuration: NoteletConfiguration
    let userDefaults: UserDefaults
    let lastPageAccessory: LastPageAccessory?

    private var versionToShow: String? {
        switch version {
        case .current:
            Helpers.getCurrentAppVersion()
        case .v(let providedVersion):
            providedVersion
        case nil:
            nil
        }
    }

    private var versionNotes: [NoteletVersionNoteItem] {
        guard let versionToShow else {
            return []
        }

        return Helpers.getVersionNotes(for: versionToShow, in: notes)
    }

    private var isCurrentVersionMode: Bool {
        if case .current = version {
            return true
        }

        return false
    }

    private var isCurrentVersionAlreadySeen: Bool {
        userDefaults.string(
            forKey: NoteletStorageKey.latestSeenAppVersion
        ) == Helpers.getCurrentAppVersion()
    }

    private var shouldPresent: Bool {
        guard version != nil else {
            return false
        }

        guard !versionNotes.isEmpty else {
            return false
        }

        if isCurrentVersionMode {
            return !isCurrentVersionAlreadySeen
        }

        return true
    }

    
    func body(content: Content) -> some View {
        content
            .onAppear {
                isPresented = shouldPresent
            }
            .onChange(of: version) {
                isPresented = shouldPresent
            }
            .sheet(isPresented: $isPresented, onDismiss: handleDismiss) {
                NoteletSheetContentView(
                    versionNotes: versionNotes,
                    configuration: configuration,
                    lastPageAccessory: lastPageAccessory
                )
            }
    }
    
    private func handleDismiss() {
        if isCurrentVersionMode {
            NoteletStorage.markCurrentVersionAsSeen(userDefaults: userDefaults)
        }

        onDismiss()
    }
}

extension View {
    /// Attach a release-notes sheet to the modified view.
    ///
    /// - Parameter userDefaults: Storage backing the "seen version" check used
    ///   in `.current` presentation mode. Defaults to `.standard`. Pass an App
    ///   Group `UserDefaults` (e.g. `UserDefaults(suiteName: "group.com.example.myapp")`)
    ///   when the host app needs to share "seen" state with an extension
    ///   target like a widget, intent, or share extension.
    public func noteletSheet(
        notes: [NoteletVersionNotes],
        version: NoteletPresentedVersion? = nil,
        onDismiss: @escaping () -> Void = { },
        configuration: NoteletConfiguration = .init(),
        userDefaults: UserDefaults = .standard
    ) -> some View {
        modifier(
            NoteletSheet<EmptyView>(
                notes: notes,
                version: version,
                onDismiss: onDismiss,
                configuration: configuration,
                userDefaults: userDefaults,
                lastPageAccessory: nil
            )
        )
    }

    /// Attach a release-notes sheet whose last page shows a custom view in
    /// place of the Done button, e.g. a call to action like "Leave a review".
    /// A close button in the top-trailing corner keeps the sheet dismissible.
    public func noteletSheet<LastPageAccessory: View>(
        notes: [NoteletVersionNotes],
        version: NoteletPresentedVersion? = nil,
        onDismiss: @escaping () -> Void = { },
        configuration: NoteletConfiguration = .init(),
        userDefaults: UserDefaults = .standard,
        @ViewBuilder lastPageAccessory: () -> LastPageAccessory
    ) -> some View {
        modifier(
            NoteletSheet(
                notes: notes,
                version: version,
                onDismiss: onDismiss,
                configuration: configuration,
                userDefaults: userDefaults,
                lastPageAccessory: lastPageAccessory()
            )
        )
    }
}
