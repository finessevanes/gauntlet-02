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
    @StateObject var viewModel = AIAssistantViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages list
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
                                
                                // Loading indicator
                                if viewModel.isLoading {
                                    AILoadingIndicator()
                                        .id("loading")
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .onChange(of: viewModel.conversation.messages.count) { _ in
                        // Auto-scroll to bottom when new message appears
                        if let lastMessage = viewModel.conversation.messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { isLoading in
                        // Auto-scroll to loading indicator
                        if isLoading {
                            withAnimation {
                                scrollProxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input area
                inputView
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.loadMockConversation()
                        } label: {
                            Label("Load Mock Data", systemImage: "doc.text")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.clearConversation()
                        } label: {
                            Label("Clear Conversation", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
        }
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
                        isInputFocused = true
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.blue)
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
    }
    
    private var inputView: some View {
        HStack(spacing: 12) {
            // Text input
            TextField("Ask me anything...", text: $viewModel.currentInput, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .disabled(viewModel.isLoading)
                .onSubmit {
                    if canSendMessage {
                        viewModel.sendMessage()
                        isInputFocused = false
                    }
                }
            
            // Send button
            Button {
                viewModel.sendMessage()
                isInputFocused = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSendMessage ? .blue : .gray)
            }
            .disabled(!canSendMessage)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        !viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isLoading
    }
}

// MARK: - Previews

#Preview("Empty State") {
    AIAssistantView()
}

#Preview("With Messages") {
    let view = AIAssistantView()
    view.viewModel.loadMockConversation()
    return view
}

