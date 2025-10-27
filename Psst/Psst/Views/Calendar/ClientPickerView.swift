//
//  ClientPickerView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Picker for selecting clients or prospects for events
//

import SwiftUI

struct ClientPickerView: View {

    @ObservedObject var contactsViewModel: ContactsViewModel
    @Binding var selectedClientId: String?
    @Binding var selectedProspectId: String?
    @Environment(\.dismiss) var dismiss

    @State private var searchQuery = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchQuery)
                    .padding()

                if contactsViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contactsViewModel.filteredClients.isEmpty && contactsViewModel.filteredProspects.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No clients or prospects yet")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Add clients in the Contacts tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Clients section
                        if !contactsViewModel.filteredClients.isEmpty {
                            Section(header: Text("My Clients")) {
                                ForEach(contactsViewModel.filteredClients) { client in
                                    ClientRow(
                                        name: client.displayName,
                                        subtitle: client.email,
                                        isSelected: selectedClientId == client.id
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedClientId = client.id
                                        selectedProspectId = nil
                                        dismiss()
                                    }
                                }
                            }
                        }

                        // Prospects section
                        if !contactsViewModel.filteredProspects.isEmpty {
                            Section(header: Text("Prospects")) {
                                ForEach(contactsViewModel.filteredProspects) { prospect in
                                    ClientRow(
                                        name: prospect.displayName,
                                        subtitle: "Prospect",
                                        isSelected: selectedProspectId == prospect.id
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedProspectId = prospect.id
                                        selectedClientId = nil
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                contactsViewModel.searchQuery = searchQuery
            }
            .onChange(of: searchQuery) { newValue in
                contactsViewModel.searchQuery = newValue
            }
        }
    }
}

// MARK: - Client Row Component

struct ClientRow: View {
    let name: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                )

            // Name and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Search Bar Component

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search clients...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Preview

struct ClientPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ClientPickerView(
            contactsViewModel: ContactsViewModel(
                contactService: .shared,
                userService: .shared
            ),
            selectedClientId: .constant(nil),
            selectedProspectId: .constant(nil)
        )
    }
}
