@echo off
echo Cleaning...
if exist target\site rd /s /q target\site

haxelib list | findstr dox >NUL
if errorlevel 1 (
    echo Installing [dox]...
    haxelib install dox
)

echo Analyzing source code...
haxe -xml target/doc.xml -cp src --macro include('hx.strings')

echo Generating HTML files...
haxelib run dox ^
  -in "^hx" ^
  -ex "^haxe" ^
  -ex "^[A-Z]" ^
  -i target/doc.xml ^
  -o target/site

setlocal
set pwd=%~dp0
echo Documentation generated at [file:///%pwd:\=/%target/site/index.html]...
endlocal

