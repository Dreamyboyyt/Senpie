# CI/CD Configuration for Senpie

This directory contains the GitHub Actions workflows for building, testing, and releasing the Senpie mobile application.

## Workflows

### build.yml
Main build workflow that:
- Builds APK for debug (on PRs) and release (on main branch pushes)
- Runs tests and code analysis
- Creates signed APKs and App Bundles
- Uploads build artifacts
- Creates GitHub releases with APK downloads
- Performs security scanning

## Setup Instructions

### 1. Repository Secrets
Configure the following secrets in your GitHub repository settings:

#### For APK Signing (Optional but Recommended)
- `SIGNING_KEY`: Base64 encoded keystore file
- `ALIAS`: Keystore alias name
- `KEY_STORE_PASSWORD`: Keystore password
- `KEY_PASSWORD`: Key password

#### For Automatic Releases
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

### 2. Generating Signing Key (Optional)

If you want to sign your APKs, create a keystore:

```bash
keytool -genkey -v -keystore senpie-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias senpie
```

Then encode it to base64:
```bash
base64 senpie-release-key.jks | tr -d '\n'
```

Add the output to the `SIGNING_KEY` secret.

### 3. Android Configuration

The app is configured with the following Android settings:
- **Package Name**: `dev.sleepy.senpie`
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34

### 4. Build Outputs

The workflow generates the following artifacts:

#### Debug Builds (Pull Requests)
- `app-debug.apk` - Debug APK for testing

#### Release Builds (Main Branch)
- `app-release.apk` - Universal APK (recommended)
- `app-arm64-v8a-release.apk` - ARM64 devices
- `app-armeabi-v7a-release.apk` - ARM32 devices  
- `app-x86_64-release.apk` - x86_64 devices
- `app-release.aab` - App Bundle for Play Store

### 5. Automatic Releases

On every push to the main branch, the workflow:
1. Builds release APKs
2. Creates a new GitHub release
3. Uploads APK files as release assets
4. Generates release notes with download instructions

### 6. Security Scanning

The workflow includes Trivy security scanning to identify vulnerabilities in dependencies and code.

## Triggering Builds

### Automatic Triggers
- **Push to main/master**: Full release build with artifacts
- **Pull Request**: Debug build for testing
- **Manual**: Use "Run workflow" button in GitHub Actions

### Manual Trigger
You can manually trigger builds from the GitHub Actions tab using the "workflow_dispatch" event.

## Troubleshooting

### Common Issues

1. **Build Fails on Dependencies**
   - Check if all dependencies in `pubspec.yaml` are compatible
   - Verify Flutter version in workflow matches your development environment

2. **Signing Fails**
   - Verify all signing secrets are correctly set
   - Check keystore alias and passwords
   - Ensure keystore is properly base64 encoded

3. **Tests Fail**
   - Tests are set to `continue-on-error: true` so they won't block builds
   - Fix failing tests to improve code quality

4. **Artifact Upload Fails**
   - Check if APK files are generated in expected paths
   - Verify GitHub token permissions

### Debug Tips

1. **Check Build Logs**: View detailed logs in GitHub Actions tab
2. **Test Locally**: Run `flutter build apk --release` locally first
3. **Verify Dependencies**: Run `flutter doctor -v` to check setup
4. **Check Permissions**: Ensure repository has Actions enabled

## Customization

### Modifying Build Configuration

Edit `.github/workflows/build.yml` to:
- Change Flutter version
- Add additional build steps
- Modify artifact retention periods
- Customize release notes

### Adding New Workflows

Create additional `.yml` files in this directory for:
- Automated testing on schedule
- Dependency updates
- Code quality checks
- Deployment to app stores

## Security Considerations

1. **Never commit signing keys** to the repository
2. **Use repository secrets** for sensitive information
3. **Review dependencies** regularly for vulnerabilities
4. **Enable branch protection** for main branch
5. **Require PR reviews** before merging

## Support

For issues with the CI/CD pipeline:
1. Check GitHub Actions logs
2. Review Flutter and Android documentation
3. Consult GitHub Actions documentation
4. Open an issue in the repository

---

**Note**: This CI/CD setup is designed for the Senpie anime tracking and downloading application. Modify as needed for your specific requirements.

