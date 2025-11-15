# AI Rewards System - Web Deployment Guide

## Build Status
✅ **Production build completed successfully!**

Build location: `build/web/`

---

## Deployment Options

### Option 1: Firebase Hosting (Recommended)

Since you're already using Firebase for authentication and Firestore, Firebase Hosting is the easiest option.

#### Steps:

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase Hosting** (if not already done):
   ```bash
   firebase init hosting
   ```
   - Select your existing Firebase project
   - Set public directory to: `build/web`
   - Configure as single-page app: **Yes**
   - Set up automatic builds: **No** (optional)

4. **Deploy to Firebase Hosting**:
   ```bash
   firebase deploy --only hosting
   ```

5. **Your app will be live at**:
   - `https://your-project-id.web.app`
   - `https://your-project-id.firebaseapp.com`

#### Custom Domain (Optional):
- Go to Firebase Console → Hosting → Add custom domain
- Follow the instructions to connect your domain

---

### Option 2: GitHub Pages

#### Steps:

1. **Create a new repository on GitHub** (or use existing)

2. **Copy build files**:
   ```bash
   cp -r build/web/* docs/
   ```
   Or manually copy all files from `build/web/` to a `docs/` folder

3. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Deploy web app"
   git push origin main
   ```

4. **Enable GitHub Pages**:
   - Go to repository Settings → Pages
   - Source: Deploy from a branch
   - Branch: main, folder: /docs
   - Save

5. **Your app will be live at**:
   - `https://713zhao.github.io/airewards/`

---

### Option 3: Netlify

#### Steps:

1. **Sign up at** [netlify.com](https://netlify.com)

2. **Deploy via drag-and-drop**:
   - Drag the `build/web` folder to Netlify
   - Or connect your GitHub repo for automatic deploys

3. **Configure rewrites** for SPA routing:
   - Create `build/web/_redirects` file with:
     ```
     /*    /index.html   200
     ```

4. **Deploy**:
   - Your app will be live at `https://your-app.netlify.app`

---

### Option 4: Vercel

#### Steps:

1. **Sign up at** [vercel.com](https://vercel.com)

2. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

3. **Deploy**:
   ```bash
   vercel --prod
   ```
   - Select the `build/web` directory when prompted

4. **Your app will be live at**:
   - `https://your-app.vercel.app`

---

## Important Notes

### Firebase Configuration
Ensure your Firebase configuration in `lib/firebase_options.dart` matches your production project settings.

### Security Rules
Before deploying, verify your Firestore security rules are properly configured in `firestore.rules`:
```bash
firebase deploy --only firestore:rules
```

### Environment Variables
If you have any API keys or sensitive data, ensure they are:
1. Not committed to the repository
2. Properly configured in your hosting provider's environment settings

### HTTPS
All hosting options above provide HTTPS by default, which is required for:
- Firebase Authentication
- Service Workers
- Secure cookies

---

## Testing the Deployment

After deployment, test the following:
1. ✅ User login (Email/Password, Google Sign-In)
2. ✅ Family creation and management
3. ✅ Task creation and completion
4. ✅ Rewards system
5. ✅ Points tracking
6. ✅ Child account joining families

---

## Updating the App

To deploy updates:

1. **Make your code changes**

2. **Rebuild the web app**:
   ```bash
   flutter build web --release --no-tree-shake-icons
   ```

3. **Deploy** using your chosen hosting method:
   - Firebase: `firebase deploy --only hosting`
   - GitHub Pages: Commit and push changes
   - Netlify/Vercel: Push to GitHub or use CLI

---

## Performance Optimization

The current build is optimized with:
- ✅ Minified JavaScript
- ✅ Tree-shaken dependencies
- ✅ Compressed assets

For even better performance:
- Enable CDN caching on your hosting provider
- Use Cloudflare or similar CDN
- Enable GZIP compression (usually automatic)

---

## Troubleshooting

### Issue: "Failed to load"
- Check Firebase configuration matches your project
- Verify Firestore rules allow authenticated access

### Issue: "Cannot read properties of undefined"
- Clear browser cache
- Check console for specific errors
- Verify all Firebase services are enabled

### Issue: Routes not working (404 on refresh)
- Ensure SPA redirect rules are configured
- For Firebase: `"rewrites": [{"source": "**", "destination": "/index.html"}]`

---

## Support

For issues or questions:
- Check Firebase Console for errors
- Review browser console logs
- Verify Firestore security rules
- Check Authentication settings

---

**Build Date**: November 14, 2025
**Build Output**: `build/web/`
**Status**: ✅ Ready for deployment
