import SwiftUI

struct FolderInspectorView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let folderID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Folder")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Form {
                TextField("Folder name", text: viewModel.bindingForSelectedFolderName())

                if let folder = viewModel.selectedFolder, folder.id == folderID {
                    LabeledContent("Subfolders", value: "\(folder.folders.count)")
                    LabeledContent("Sessions", value: "\(folder.sessions.count)")
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Delete Folder", role: .destructive) {
                    viewModel.deleteSelectedItem()
                }
                .disabled(folderID == viewModel.library.rootFolder.id)
            }

            Spacer()
        }
        .padding(24)
    }
}
