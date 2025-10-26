//
//  UpgradeProspectView.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//  Form to upgrade prospect to client by adding email
//

import SwiftUI

struct UpgradeProspectView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    let prospect: Prospect
    @ObservedObject var viewModel: ContactsViewModel

    @State private var email = ""
    @State private var isUpgrading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(prospect.displayName)
                    }
                } header: {
                    Text("Prospect Details")
                }

                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Client Email")
                } footer: {
                    Text("Enter the email address of this prospect's Psst account to upgrade them to a client.")
                }

                Section {
                    Button {
                        upgradeProspect()
                    } label: {
                        if isUpgrading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Upgrading...")
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        } else {
                            Text("Upgrade to Client")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isEmailValid || isUpgrading)
                }
            }
            .navigationTitle("Upgrade Prospect")
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
            .onChange(of: viewModel.errorMessage) { newValue in
                if let error = newValue {
                    // Error occurred - show alert
                    errorMessage = error
                    showErrorAlert = true
                }
            }
            .alert("Upgrade Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {
                    viewModel.clearMessages()
                }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var isEmailValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }

    // MARK: - Methods

    private func upgradeProspect() {
        isUpgrading = true

        Task {
            await viewModel.upgradeProspect(
                prospectId: prospect.id,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isUpgrading = false
        }
    }
}

// MARK: - Preview

struct UpgradeProspectView_Previews: PreviewProvider {
    static var previews: some View {
        let mockProspect = Prospect(displayName: "John Doe")
        return UpgradeProspectView(prospect: mockProspect, viewModel: ContactsViewModel())
    }
}
