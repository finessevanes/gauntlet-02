//
//  CalendarView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Main calendar view with week timeline and event management
//

import SwiftUI

struct CalendarView: View {

    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var contactsViewModel = ContactsViewModel(
        contactService: .shared,
        userService: .shared
    )
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingProfile = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    // Loading state
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.hasEventsThisWeek {
                    // Empty state
                    CalendarEmptyStateView {
                        viewModel.showEventCreationSheet = true
                    }
                } else {
                    // Vertical agenda view
                    VerticalAgendaView(viewModel: viewModel)
                }

                // Floating action button (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showEventCreationSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // User avatar on left - taps to open Profile view
                ToolbarItem(placement: .navigationBarLeading) {
                    if let user = authViewModel.currentUser {
                        Button {
                            showingProfile = true
                        } label: {
                            ProfilePhotoPreview(
                                imageURL: user.photoURL,
                                userID: user.id,
                                selectedImage: nil,
                                isLoading: false,
                                size: 32,
                                displayName: user.displayName
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $viewModel.showEventCreationSheet) {
                EventCreationSheet(
                    viewModel: viewModel,
                    contactsViewModel: contactsViewModel
                )
            }
            .sheet(isPresented: $viewModel.showEventDetailSheet) {
                if let event = viewModel.selectedEvent {
                    EventDetailView(eventId: event.id, viewModel: viewModel)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .task {
                await viewModel.loadEvents()
                await contactsViewModel.loadContacts()
            }
        }
    }
}

// MARK: - Week Navigation Bar

struct WeekNavigationBar: View {
    @ObservedObject var viewModel: CalendarViewModel

    var body: some View {
        HStack {
            // Previous week button
            Button(action: {
                viewModel.previousWeek()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            Spacer()

            // Current week label
            Text(weekLabel)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // Next week button
            Button(action: {
                viewModel.nextWeek()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }

    private var weekLabel: String {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: viewModel.currentWeekStart)!

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startString = formatter.string(from: viewModel.currentWeekStart)
        let endString = formatter.string(from: weekEnd)

        // Add year if different from current year
        let currentYear = calendar.component(.year, from: Date())
        let weekYear = calendar.component(.year, from: viewModel.currentWeekStart)

        if weekYear != currentYear {
            return "\(startString) - \(endString), \(weekYear)"
        } else {
            return "\(startString) - \(endString)"
        }
    }
}

// MARK: - Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
