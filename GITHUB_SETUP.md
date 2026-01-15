# 📤 GitHub Setup Guide for PaylessPlay

Your project is now ready to be published to GitHub! All Firebase configuration files have been excluded from version control.

## ✅ What's Already Done

- ✅ Git repository initialized
- ✅ All project files added (excluding Firebase configs)
- ✅ Initial commit created
- ✅ `.gitignore` configured to exclude:
  - `.firebase/` folder
  - `.firebaserc`
  - `firebase.json`
  - `firestore.rules`
  - `firestore.indexes.json`
  - `storage.rules`
  - `deploy.ps1`
  - Firebase GitHub Actions workflows

## 🚀 Next Steps: Push to GitHub

### Option 1: Create a New Repository on GitHub (Recommended)

1. **Go to GitHub** and create a new repository:
   - Visit [github.com/new](https://github.com/new)
   - Repository name: `paylessPlay` (or your preferred name)
   - Description: "A Flutter web app for discovering the best video game deals"
   - Choose **Public** or **Private**
   - **DO NOT** initialize with README, .gitignore, or license (we already have them)
   - Click "Create repository"

2. **Add the remote and push:**
   ```powershell
   # Replace 'yourusername' with your actual GitHub username
   git remote add origin https://github.com/yourusername/paylessPlay.git
   
   # Rename branch to 'main' (GitHub's default)
   git branch -M main
   
   # Push to GitHub
   git push -u origin main
   ```

3. **Enter your credentials** when prompted:
   - Username: Your GitHub username
   - Password: Your GitHub **Personal Access Token** (not your regular password)
   
   > **Note**: If you don't have a Personal Access Token:
   > 1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   > 2. Generate new token with `repo` scope
   > 3. Copy and save it (you won't see it again!)

### Option 2: Use GitHub CLI (If Installed)

If you have GitHub CLI installed:

```powershell
# Authenticate (first time only)
gh auth login

# Create repository and push
gh repo create paylessPlay --public --source=. --remote=origin --push

# Or for private repo:
gh repo create paylessPlay --private --source=. --remote=origin --push
```

## 🔍 Verify What Will Be Published

To see what files are included in your repository:

```powershell
git ls-files
```

To verify Firebase files are **NOT** included:

```powershell
# Should return nothing or only .github/workflows files that aren't Firebase-related
git ls-files | Select-String -Pattern "firebase|firestore|storage.rules|deploy.ps1"
```

## 📝 Update README

After publishing, don't forget to update your `README.md`:

1. Replace `https://github.com/yourusername/paylessPlay.git` with your actual repository URL
2. Add screenshots or demo GIFs if you have them
3. Update the contact email if needed

## 🔐 Important Security Notes

### ✅ What's Excluded (Safe)
- Firebase configuration files (`.firebaserc`, `firebase.json`)
- Security rules (`firestore.rules`, `storage.rules`)
- Deployment scripts (`deploy.ps1`)
- Firebase local cache (`.firebase/`)

### ⚠️ Before Making Repository Public

If you plan to make your repository public, ensure:
- No API keys or secrets are in the code
- No Firebase service account credentials
- No environment-specific configurations

## 🎯 Common Commands

```powershell
# Check repository status
git status

# View commit history
git log --oneline

# View remote repository
git remote -v

# Pull latest changes from GitHub
git pull origin main

# Push new changes to GitHub
git add .
git commit -m "Your commit message"
git push origin main
```

## 🐛 Troubleshooting

### Issue: "remote origin already exists"

```powershell
# Remove existing remote
git remote remove origin

# Add the correct remote
git remote add origin https://github.com/yourusername/paylessPlay.git
```

### Issue: Authentication failed

- Use a **Personal Access Token** instead of your password
- Or use GitHub CLI: `gh auth login`
- Or use SSH keys instead of HTTPS

### Issue: "Updates were rejected"

```powershell
# If you accidentally initialized GitHub repo with README
git pull origin main --allow-unrelated-histories
git push origin main
```

## ✨ Next Steps After Publishing

1. **Add a License**: Choose and add a LICENSE file (MIT, Apache, etc.)
2. **Add Topics**: On GitHub, add topics like `flutter`, `game-deals`, `cheapshark-api`
3. **Add Description**: Add a description to your GitHub repository
4. **Enable GitHub Pages** (optional): If you want to host on GitHub Pages instead of Firebase
5. **Set up Branch Protection** (optional): Protect your main branch from force pushes

## 🎉 You're All Set!

Your project is ready to be published to GitHub. The Firebase configuration files are safely excluded, so you can collaborate without exposing your deployment settings.

---

**Need Help?** Check the [GitHub Documentation](https://docs.github.com) or use `git --help`
