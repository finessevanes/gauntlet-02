//
//  AIAssistantView.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import SwiftUI

/// Main AI Assistant chat interface
struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                mainContentView
                overlaysView
            }
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        VStack(spacing: 0) {
            messagesScrollView
            Divider()
            inputView
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    viewModel.clearConversation()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") {
                viewModel.retry()
            }
            Button("Cancel", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: viewModel.pendingSelection) { newValue in
            print("🎨 [AIAssistantView.onChange] pendingSelection changed to: \(newValue?.prompt ?? "nil")")
        }
        .onChange(of: viewModel.pendingAction) { newValue in
            print("🎨 [AIAssistantView.onChange] pendingAction changed to: \(newValue?.functionName ?? "nil")")
        }
        .onChange(of: viewModel.lastActionResult) { newValue in
            print("🎨 [AIAssistantView.onChange] lastActionResult changed to: success=\(newValue?.success ?? false)")
        }
    }

    private var messagesScrollView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                if viewModel.conversation.messages.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.conversation.messages) { message in
                            AIMessageRow(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            AILoadingIndicator()
                                .id("loading")
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .onChange(of: viewModel.conversation.messages.count) { _ in
                if let lastMessage = viewModel.conversation.messages.last {
                    withAnimation {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                if isLoading {
                    withAnimation {
                        scrollProxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlaysView: some View {
        selectionOverlay
        confirmationOverlay
        resultOverlay
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if let selection = viewModel.pendingSelection {
            VStack {
                Spacer()

                AISelectionCard(
                    request: selection,
                    onSelect: { option in
                        print("🎨 [AIAssistantView] User tapped option: \(option.title)")
                        withAnimation {
                            print("🎨 [AIAssistantView] Calling viewModel.handleSelection...")
                            viewModel.handleSelection(option)
                            print("🎨 [AIAssistantView] handleSelection returned")
                        }
                    },
                    onCancel: {
                        print("🎨 [AIAssistantView] User tapped Cancel")
                        withAnimation {
                            viewModel.cancelSelection()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            .edgesIgnoringSafeArea(.all)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.pendingSelection != nil)
            .onAppear {
                print("🎨 [AIAssistantView] Selection card appeared")
            }
            .onDisappear {
                print("🎨 [AIAssistantView] Selection card disappeared")
            }
        }
    }

    @ViewBuilder
    private var confirmationOverlay: some View {
        if let action = viewModel.pendingAction {
            VStack {
                Spacer()

                ActionConfirmationCard(
                    action: action,
                    isExecuting: viewModel.isExecutingAction,
                    onConfirm: {
                        print("🎨 [AIAssistantView] User tapped Confirm")
                        viewModel.confirmAction()
                    },
                    onCancel: {
                        print("🎨 [AIAssistantView] User tapped Cancel action")
                        viewModel.cancelAction()
                    },
                    onEdit: {
                        print("🎨 [AIAssistantView] User tapped Edit")
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                print("🎨 [AIAssistantView] Confirmation card appeared for: \(action.functionName)")
            }
            .onDisappear {
                print("🎨 [AIAssistantView] Confirmation card disappeared")
            }
        }
    }

    @ViewBuilder
    private var resultOverlay: some View {
        VStack {
            if let result = viewModel.lastActionResult {
                if result.success {
                    ActionSuccessView(
                        result: result,
                        onDismiss: {
                            withAnimation {
                                viewModel.dismissActionResult()
                            }
                        }
                    )
                } else {
                    ActionErrorView(
                        result: result,
                        onDismiss: {
                            withAnimation {
                                viewModel.dismissActionResult()
                            }
                        },
                        onRetry: {
                            // Retry not implemented yet
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.top, 20)
        .animation(.spring(), value: viewModel.lastActionResult != nil)
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("AI Assistant")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Ask me anything about your clients and conversations. I can help you search, summarize, and find information quickly.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                ForEach(["Show me recent messages from John", "Summarize my conversation with Sarah", "Find messages about the project"], id: \.self) { suggestion in
                    Button {
                        viewModel.currentInput = suggestion
                        viewModel.sendMessage()
                    } label: {
                        HStack {
                            Text(suggestion)
                                .font(.callout)
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var inputView: some View {
        HStack(spacing: 12) {
            TextField("Ask me anything...", text: $viewModel.currentInput)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .disabled(viewModel.isLoading)
                .onSubmit {
                    viewModel.sendMessage()
                }

            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.currentInput.isEmpty && !viewModel.isLoading ? .gray : .blue)
            }
            .disabled(viewModel.currentInput.isEmpty && !viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

struct AIAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        AIAssistantView()
    }
}
