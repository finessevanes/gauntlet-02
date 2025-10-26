//
//  AddProspectView.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//  Form to add new prospect by name
//

import SwiftUI

struct AddProspectView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ContactsViewModel

    @State private var name = ""
    @State private var isAdding = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                } header: {
                    Text("Prospect Name")
                } footer: {
                    Text("Add a lead who doesn't have a Psst account yet. You can upgrade them to a client later.")
                }

                Section {
                    Button {
                        addProspect()
                    } label: {
                        if isAdding {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Adding...")
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        } else {
                            Text("Add Prospect")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isNameValid || isAdding)
                }
            }
            .navigationTitle("Add Prospect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.successMessage) { newValue in
                if newValue != nil {
                    // Success - dismiss sheet
                    dismiss()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Methods

    private func addProspect() {
        isAdding = true

        Task {
            await viewModel.addProspect(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            isAdding = false
        }
    }
}

// MARK: - Preview

struct AddProspectView_Previews: PreviewProvider {
    static var previews: some View {
        AddProspectView(viewModel: ContactsViewModel())
    }
}
