@echo off
:: @author Sebastian Thomschke, Vegard IT GmbH
::
:: creates a new release in GitHub and haxelib.org
::
:: requires GITHUB_ACCESS_TOKEN environment variable to be set
:: requires wget to be installed https://eternallybored.org/misc/wget/
::
setlocal
set PROJECT_ROOT=%~dp0
cd %PROJECT_ROOT%
set ARTIFACT=haxe-doctest
set REPO=vegardit/%ARTIFACT%
set DRAFT=false
set PREPRELEASE=false

REM extract release version
for /f "tokens=*" %%a in ( 'findstr version haxelib.json' ) do (set versionLine=%%a)
set RELEASE_VERSION=%versionLine:"version": "=%
set RELEASE_VERSION=%RELEASE_VERSION:",=%

REM extract release note
for /f "tokens=*" %%a in ( 'findstr releasenote haxelib.json' ) do (set releaseNoteLine=%%a)
set RELEASE_NOTE=%releaseNoteLine:"releasenote": "=%
set RELEASE_NOTE=%RELEASE_NOTE:",=%

if not exist target mkdir target

:: create github release https://developer.github.com/v3/repos/releases/#create-a-release
(
  echo {
  echo "tag_name":"v%RELEASE_VERSION%",
  echo "name":"v%RELEASE_VERSION%",
  echo "target_commitish":"master",
  echo "body":"%RELEASE_NOTE%",
  echo "draft":%DRAFT%,
  echo "prerelease":%PREPRELEASE%
  echo }
)>target/github_release.json
wget -qO- --post-file=target/github_release.json "https://api.github.com/repos/%REPO%/releases?access_token=%GITHUB_ACCESS_TOKEN%" || goto :eof

:: create haxelib release
zip target/haxelib-upload.zip src haxelib.json LICENSE.txt CONTRIBUTING.md README.md -r -9 || goto :eof

:: submit haxelib release
haxelib submit target/haxelib-upload.zip

:eof
endlocal
