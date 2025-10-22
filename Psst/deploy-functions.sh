#!/bin/bash

# Deploy Cloud Functions for Psst messaging app
# This script deploys the notification trigger function to Firebase

echo "🚀 Deploying Cloud Functions for Psst..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please run:"
    echo "firebase login"
    exit 1
fi

# Navigate to functions directory
cd functions

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Deploy functions
echo "🚀 Deploying functions..."
firebase deploy --only functions

echo "✅ Cloud Functions deployed successfully!"
echo "📱 You can now test push notifications in the iOS app"
