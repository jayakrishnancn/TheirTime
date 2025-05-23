import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @EnvironmentObject private var clockStore: ClockStore
    @Environment(\.dismiss) var dismiss // Added for dismissing the view
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportData: Data?
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importedClockCount = 0
    @State private var showExportFailureAlert = false
    @State private var exportErrorDetails = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Import & Export")
                .font(.headline)
                .padding(.top)
            
            Text("Share your clock configurations with others or back up your settings")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: exportClocks) {
                    VStack {
                        Image(systemName: "arrow.up.doc")
                            .font(.system(size: 28))
                        Text("Export")
                            .font(.system(size: 14))
                    }
                    .frame(width: 100, height: 80)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: { isImporting = true }) {
                    VStack {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 28))
                        Text("Import")
                            .font(.system(size: 14))
                    }
                    .frame(width: 100, height: 80)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
            
            if showExportSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Export successful")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showExportSuccess = false
                    }
                }
            }
            
            if showImportSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Successfully imported \(importedClockCount) clocks")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showImportSuccess = false
                    }
                }
            }
            
            if showImportError {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Failed to import clocks")
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showImportError = false
                    }
                }
            }
        }
        .padding()
        .fileExporter(
            isPresented: $isExporting,
            document: ClockDocument(data: exportData),
            contentType: .json,
            defaultFilename: "TheirTimeClocks.json"
        ) { result in
            print("[DEBUG] .fileExporter completion block executed. isExporting is now \(self.isExporting) (should be false)") // New debug line
            // SwiftUI should set isExporting back to false automatically.
            switch result {
            case .success(let url):
                print("[DEBUG] Export successful. URL: \(url)") // New debug line
                showExportSuccess = true
                showExportFailureAlert = false
            case .failure(let error):
                print("[DEBUG] Export failed in .fileExporter completion. Error: \(error.localizedDescription)") // New debug line
                exportErrorDetails = "Failed to save the file. Error: \(error.localizedDescription)"
                showExportFailureAlert = true
                showExportSuccess = false
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                let startCount = clockStore.clocks.count
                if clockStore.importClocks(from: url) {
                    let endCount = clockStore.clocks.count
                    importedClockCount = endCount - startCount
                    showImportSuccess = true
                    
                    // Schedule dismissal after a short delay so the user can see the success message.
                    // The success message auto-hides after 3 seconds. Dismiss slightly after.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                } else {
                    showImportError = true
                }
                
            case .failure(let error):
                print("Import error: \(error)")
                showImportError = true
            }
        }
        .alert("Export Failed", isPresented: $showExportFailureAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorDetails)
        }
    }
    
    private func exportClocks() {
        print("[DEBUG] exportClocks() called") // New debug line
        showExportSuccess = false
        showExportFailureAlert = false
        exportErrorDetails = ""

        if let data = clockStore.exportClocksData() {
            print("[DEBUG] Successfully got data from clockStore.exportClocksData(). Data size: \(data.count)") // New debug line
            if data.isEmpty && !clockStore.clocks.isEmpty {
                 print("[DEBUG] Data is empty but clocks are not. Setting error.") // New debug line
                 exportErrorDetails = "Failed to prepare data for export: generated data is empty despite having clocks."
                 showExportFailureAlert = true
                 return
            }
            exportData = data
            print("[DEBUG] Setting isExporting = true") // New debug line
            isExporting = true
        } else {
            print("[DEBUG] Failed to get data from clockStore.exportClocksData(). Setting error.") // New debug line
            exportErrorDetails = "Failed to prepare data for export. This might happen if there are no clocks or if data encoding failed."
            showExportFailureAlert = true
        }
    }
}

// Document struct needed for the fileExporter
struct ClockDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data?

    init(data: Data?) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            print("ClockDocument: ReadConfiguration failed to get regularFileContents.")
            throw CocoaError(.fileReadCorruptFile, userInfo: [NSLocalizedDescriptionKey: "Could not read file data."])
        }
        self.data = fileData
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = self.data else {
            print("ClockDocument: fileWrapper called but self.data is nil.")
            throw CocoaError(.fileWriteUnknown, userInfo: [NSLocalizedDescriptionKey: "Cannot export empty or invalid data."])
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

struct ImportExportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportExportView()
            .environmentObject(ClockStore())
    }
}