//
//  ShowTagsAndManageTagsView.swift
//  TheirTime
//
//  Created by Jayakrishnan Nampoothiri on 05/04/25.
//
import SwiftUI

// New struct for the individual tag appearance
struct IndividualTagView: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) { // Spacing between text and button
            Text(tag)
                .font(.system(size: 11))
                .lineLimit(1)
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 8) // Padding inside the tag
        .padding(.vertical, 4)   // Padding inside the tag
        .background(Color.accentColor.opacity(0.15))
        .clipShape(Capsule()) // Capsule shape for the tag
    }
}

struct ShowTagsAndManageTagsView: View {
    let clockInfo: ClockInfo
    @EnvironmentObject private var clockStore: ClockStore
    @State private var newTag: String = ""
    @State private var availableWidthForTags: CGFloat = 10 // Initial small non-zero width

    // This computed property ensures we always get the latest data from the store
    private var currentClock: ClockInfo {
        clockStore.clocks.first(where: { $0.id == clockInfo.id }) ?? clockInfo
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // Increased spacing slightly for overall layout
            Group {
                if currentClock.tags.isEmpty {
                    Text("No tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    _flowLayout(tags: currentClock.tags, availableWidth: availableWidthForTags)
                        .background(
                            GeometryReader { geometryProxy in
                                Color.clear
                                    .onAppear {
                                        availableWidthForTags = geometryProxy.size.width
                                    }
                                    .onChange(of: geometryProxy.size.width) { oldWidth, newWidth in
                                        availableWidthForTags = newWidth
                                    }
                            }
                        )
                }
            }
            
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.subheadline)
                    .submitLabel(.done)
                    .onSubmit(addTag)
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.horizontal, 5)
    }
     
    private func deleteTag(tag: String) {
        clockStore.removeTag(from: clockInfo.id, tag: tag)
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !currentClock.tags.contains(tag) {
            clockStore.addTag(to: clockInfo.id, tag: tag)
            newTag = ""
        }
    }
    
    // Helper to compute rows based on estimated widths
    private func computeRows(availableWidth: CGFloat, tags: [String]) -> [[String]] {
        var rows: [[String]] = [[]]
            guard availableWidth > 0, !tags.isEmpty else {
            if !tags.isEmpty && availableWidth <= 0 { // Handle edge case of no width by putting one tag per row
                 return tags.map { [$0] }
            }
            return rows
        }

        var currentRowIndex = 0
        
        var currentWidth: CGFloat = 0
        let tagSpacing: CGFloat = 5 // Horizontal spacing between tags in a row

        for tag in tags {
            let tagWidth = estimateTagViewWidth(tag: tag)

            if rows[currentRowIndex].isEmpty || currentWidth + tagSpacing + tagWidth <= availableWidth {
                rows[currentRowIndex].append(tag)
                currentWidth += (rows[currentRowIndex].count == 1 ? 0 : tagSpacing) + tagWidth
            } else {
                // New row
                currentRowIndex += 1
                rows.append([tag])
                currentWidth = tagWidth
            }
        }
        return rows.filter { !$0.isEmpty }
    }

    // Estimate width of a single IndividualTagView
    private func estimateTagViewWidth(tag: String) -> CGFloat {
        // For IndividualTagView:
        // Text: count * char_width_for_size_11 (approx 6.5-7 for SF Text)
        // Button: icon_width (approx 10-12 for systemImage size 9 + touch area)
        // HStack spacing: 4
        // Horizontal padding on HStack: 8 + 8
        let textWidth = CGFloat(tag.count) * 7.0
        let buttonWidth: CGFloat = 12.0
        let internalSpacing: CGFloat = 4.0
        let horizontalPaddingTotal: CGFloat = 8.0 + 8.0
        return textWidth + buttonWidth + internalSpacing + horizontalPaddingTotal
    }

    @ViewBuilder
    private func _flowLayout(tags: [String], availableWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5) { // Spacing between rows
            ForEach(computeRows(availableWidth: availableWidth, tags: tags).indices, id: \.self) { rowIndex in
                let rowTags = computeRows(availableWidth: availableWidth, tags: tags)[rowIndex]
                HStack(spacing: 5) { // Spacing between tags in a row
                    ForEach(rowTags, id: \.self) { tag in
                        IndividualTagView(tag: tag, onDelete: { deleteTag(tag: tag) })
                    }
                }
            }
        }
    }
}
