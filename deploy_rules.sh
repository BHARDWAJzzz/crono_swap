#!/bin/bash
# Deploy Firestore rules for Crono Swap

echo "🚀 Deploying Firestore Security Rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Rules deployed successfully! You can now access your skills and profile."
else
    echo "❌ Deployment failed. Please make sure you are logged in (firebase login) and in the project directory."
fi
