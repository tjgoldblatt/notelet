//
//  SwiftUIView.swift
//  Notelet
//
//  Created by Mykola Harmash on 05.05.26.
//

import SwiftUI

struct NoteletSheetContentView<LastPageAccessory: View>: View {
    let versionNotes: [NoteletVersionNoteItem]
    let configuration: NoteletConfiguration
    let lastPageAccessory: LastPageAccessory

    @State private var selectedPageID: Int? = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    /// When the host supplies a last-page accessory, it replaces the Done button on the last
    /// page and a close button in the toolbar becomes the explicit way out.
    private var hasLastPageAccessory: Bool {
        LastPageAccessory.self != EmptyView.self
    }

    private var currentPage: Int {
        return selectedPageID ?? 0
    }

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var sheetBackgroundStyle: AnyShapeStyle {
        if #available(iOS 26, *) {
            let color: Color = colorScheme == .dark ? .black : .white

            return AnyShapeStyle(color.opacity(0.55))
        }

        return AnyShapeStyle(.regularMaterial)
    }

    var body: some View {
        let isOnLastPage = isOnLastPage(versionNotes: versionNotes, currentPage: currentPage)

        NavigationStack {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(versionNotes.enumerated()), id: \.offset) { index, item in
                        ScrollView(.vertical) {
                            NoteItemView(
                                item: item,
                                isCurrent: index == currentPage,
                                configuration: configuration
                            )
                            .id(index)
                        }
                        .contentMargins(.bottom, 80)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $selectedPageID)
            .modifier(SoftScrollEdgeEffect(hidesTopEdge: hasLastPageAccessory))
            // The close button brings in a navigation bar; let pages keep their own top
            // spacing instead of being pushed down by the bar's height.
            .ignoresSafeArea(.container, edges: hasLastPageAccessory ? .top : [])
            .toolbar {
                if hasLastPageAccessory {
                    ToolbarItem(placement: .topBarTrailing) {
                        closeButton
                    }
                }
            }
        }
        .modifier(
            SafeAreaView {
                VStack(spacing: 16) {
                    if versionNotes.count > 1 {
                        let selectedIndicatorColor = colorScheme == .light ? Color.black : Color.white
                        let pageIndicatorAccessibilityLabel: LocalizedStringResource = "Page \(currentPage + 1) of \(versionNotes.count)"

                        HStack(spacing: 6) {
                            ForEach(versionNotes.indices, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentPage ? selectedIndicatorColor.opacity(0.35) : Color.secondary.opacity(0.35))
                                    .frame(width: index == currentPage ? 14 : 7, height: 7)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(pageIndicatorAccessibilityLabel))
                        .padding(.top, 14)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }

                    if !versionNotes.isEmpty {
                        let showsAccessory = isOnLastPage && hasLastPageAccessory

                        Button {
                            if isOnLastPage {
                                onDoneTap()
                            } else {
                                withAnimation(.smooth) {
                                    selectedPageID = min(currentPage + 1, versionNotes.count - 1)
                                }
                            }
                        } label: {
                            let buttonTitle: LocalizedStringResource = isOnLastPage
                            ? configuration.doneButtonLabel
                            : configuration.nextButtonLabel

                            Text(buttonTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 28)
                        .tint(configuration.accentColor)
                        // The accessory takes the button's exact frame, so it matches the
                        // Next/Done size at every Dynamic Type setting.
                        .opacity(showsAccessory ? 0 : 1)
                        .allowsHitTesting(!showsAccessory)
                        .accessibilityHidden(showsAccessory)
                        .overlay {
                            if showsAccessory {
                                lastPageAccessory
                                    .padding(.horizontal, 28)
                                    .transition(.opacity)
                            }
                        }
                    }
                }
                .animation(.smooth, value: isOnLastPage)
                .safeAreaPadding(.bottom, isIPad ? 24 : 0)
            }
        )
        .presentationDetents([
            isIPad || configuration.sheetHeight == .full ? .large : .fraction(0.85)
        ])
        .presentationDragIndicator(.visible)
        .presentationBackground(sheetBackgroundStyle)
    }

    @ViewBuilder
    private var closeButton: some View {
        if #available(iOS 26, *) {
            Button(role: .close) { onDoneTap() }
        } else {
            Button("Close", systemImage: "xmark") { onDoneTap() }
        }
    }

    private func onDoneTap() {
        dismiss()
    }

    private func isOnLastPage(versionNotes: [NoteletVersionNoteItem], currentPage: Int) -> Bool {
        guard !versionNotes.isEmpty else {
            return true
        }

        return currentPage >= versionNotes.count - 1
    }
}

fileprivate struct SoftScrollEdgeEffect: ViewModifier {
    /// Pages extend under the close button's bar; without this the top edge effect blurs
    /// each page's title at rest.
    var hidesTopEdge = false

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .all)
                .scrollEdgeEffectHidden(hidesTopEdge, for: .top)
        } else {
            content
        }
    }
}
