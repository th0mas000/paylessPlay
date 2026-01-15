# Deployment Guide for PaylessPlay

This guide explains how to deploy your PaylessPlay Flutter web app to Firebase Hosting.

## Prerequisites

Before deploying, ensure you have:

1. **Node.js and npm** installed
   - Download from [nodejs.org](https://nodejs.org/)
   - Verify installation: `node --version` and `npm --version`

2. **Firebase CLI** installed
   ```powershell
   npm install -g firebase-tools
   ```
   - Verify installation: `firebase --version`

3. **Flutter SDK** installed and configured
   - Verify installation: `flutter doctor`

## Initial Setup (One-Time)

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard
4. Note your project ID (you'll need this later)

### 2. Initialize Firebase in Your Project

Run this command in your project directory:

```powershell
firebase login
```

This will open a browser window to authenticate with your Google account.

Then initialize Firebase:

```powershell
firebase init
```

When prompted:
- **Select features**: Choose "Firestore", "Hosting", and "Storage" (use spacebar to select)
- **Firestore rules**: Use existing `firestore.rules` file
- **Firestore indexes**: Use existing `firestore.indexes.json` file
- **Public directory**: Enter `build/web`
- **Configure as single-page app**: Yes
- **Set up automatic builds**: No (unless you want GitHub Actions)
- **Storage rules**: Use existing `storage.rules` file

The `.firebaserc` file will be automatically updated with your project ID.

### 3. Install Flutter Dependencies

```powershell
flutter pub get
```

## Deployment

### Quick Deployment

Use the provided PowerShell script:

```powershell
.\deploy.ps1
```

This script will:
1. Build your Flutter web app for production
2. Deploy to Firebase Hosting
3. Display the deployment URL

### Manual Deployment

If you prefer to deploy manually:

1. **Build the app**:
   ```powershell
   flutter build web --release
   ```

2. **Deploy to Firebase**:
   ```powershell
   firebase deploy
   ```

   Or deploy only specific services:
   ```powershell
   # Deploy hosting only
   firebase deploy --only hosting
   
   # Deploy security rules only
   firebase deploy --only firestore:rules,storage
   
   # Deploy everything
   firebase deploy
   ```

## Security Rules

Your app includes comprehensive security rules for Firestore and Storage:

### Firestore Security Rules

Located in `firestore.rules`, these rules ensure:
- **Default deny**: All access is denied by default
- **User data isolation**: Users can only access their own data
- **Authenticated access**: Most operations require authentication
- **Reviews**: Anyone can read, but only authenticated users can create/edit their own

Key collections:
- `/users/{userId}` - User profiles
- `/users/{userId}/favorites/{favoriteId}` - User's favorite deals
- `/reviews/{reviewId}` - Game reviews
- `/users/{userId}/alerts/{alertId}` - Price alert preferences

### Storage Security Rules

Located in `storage.rules`, these rules enforce:
- **File size limits**: Maximum 5MB per file
- **File type validation**: Only image files allowed
- **User isolation**: Users can only upload/delete their own files
- **Public read**: Uploaded images are publicly readable

Storage paths:
- `/users/{userId}/profile/{filename}` - Profile pictures
- `/users/{userId}/uploads/{filename}` - User-uploaded content

## Testing Security Rules

### Firestore Rules

You can test Firestore rules locally:

```powershell
firebase emulators:start --only firestore
```

### Storage Rules

Test Storage rules:

```powershell
firebase emulators:start --only storage
```

### Test All Services

```powershell
firebase emulators:start
```

## Viewing Your Deployed App

After deployment, Firebase will provide a hosting URL in the format:
```
https://your-project-id.web.app
```

You can also find it in the Firebase Console under Hosting.

## Troubleshooting

### Issue: "Firebase command not found"

**Solution**: Install Firebase CLI globally:
```powershell
npm install -g firebase-tools
```

### Issue: "Build folder not found"

**Solution**: Make sure to run `flutter build web` before deploying.

### Issue: "Permission denied for Firestore/Storage"

**Solution**: This is expected! The security rules deny access by default. You need to implement Firebase Authentication in your app first. Once users sign in, they'll be able to access their own data.

### Issue: "Old version still showing after deployment"

**Solution**: Clear your browser cache or open in incognito/private mode. Firebase Hosting uses aggressive caching.

## Updating Security Rules

To update security rules without redeploying the entire app:

```powershell
firebase deploy --only firestore:rules,storage
```

## Continuous Deployment (Optional)

For automatic deployment on GitHub push, see `.github/workflows/firebase-hosting-merge.yml` (create this if you want CI/CD).

## Next Steps

To make full use of Firebase features:

1. **Add Firebase Authentication**:
   - Enable authentication methods in Firebase Console
   - Implement sign-in UI in your Flutter app
   - Use `firebase_auth` package

2. **Enable Firestore Database**:
   - Create database in Firebase Console
   - Choose production mode (rules are already configured)

3. **Enable Storage**:
   - Create storage bucket in Firebase Console
   - Choose production mode (rules are already configured)

## Useful Commands

```powershell
# Check deployment status
firebase hosting:channel:list

# View project info
firebase projects:list

# Open Firebase Console
firebase open

# View logs
firebase functions:log

# Test locally before deployment
flutter run -d chrome
```

## Cost Considerations

Firebase has a generous free tier (Spark Plan):
- **Hosting**: 10 GB storage, 360 MB/day transfer
- **Firestore**: 1 GB storage, 50K reads/day, 20K writes/day
- **Storage**: 5 GB storage, 1 GB/day download

This should be more than enough for most small to medium applications. Monitor usage in the Firebase Console.

---

**Need help?** Check the [Firebase Documentation](https://firebase.google.com/docs) or visit the [Flutter Firebase guides](https://firebase.flutter.dev/).
