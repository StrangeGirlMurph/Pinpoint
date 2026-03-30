# Contributing

This project is open to contributions! Feel free to open issues and/or create pull requests. 

## Tips

- To update `database.g.dart` according to database.dart use `flutter pub run build_runner build --delete-conflicting-outputs`.
- To update the icons run `flutter pub run flutter_launcher_icons`

## Releasing a New Version

- Changelog: Add a new file in `metadata/en-GB/changelogs/` named `<build_number>.txt` containing a short bulleted list of your changes. (Max 500 characters). This will automatically be imported by F-Droid.
- Version: Update `version:` in the `pubspec.yaml`. Change the version number and increment the build number after the `+` sign. This is required by App Stores to recognize it as a newer build.
- Commit and Push: `git commit -am "Prepare release vx.y.z" && git push`
- Tag and Release: `git tag vx.y.z && git push origin vx.y.z`