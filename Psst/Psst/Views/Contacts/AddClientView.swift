//
//  AddClientView.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//  Form to add new client by email lookup
//

import SwiftUI

struct AddClientView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ContactsViewModel

    @State private var email = ""
    @State private var isLookingUp = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Client Email")
                } footer: {
                    Text("Enter the email address of an existing Psst user. Their name will be automatically filled in.")
                }

                Section {
                    Button {
                        addClient()
                    } label: {
                        if isLookingUp {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Looking up user...")
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        } else {
                            Text("Add Client")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isEmailValid || isLookingUp)
                }
            }
            .navigationTitle("Add Client")
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

    private var isEmailValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }

    // MARK: - Methods

    private func addClient() {
        isLookingUp = true

        Task {
            await viewModel.addClient(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            isLookingUp = false
        }
    }
}

// MARK: - Preview

struct AddClientView_Previews: PreviewProvider {
    static var previews: some View {
        AddClientView(viewModel: ContactsViewModel())
    }
}
