@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

call %~dp0_test-prepare.cmd cppia hxcpp

echo Compiling...
haxe %~dp0..\tests.hxml -D HXCPP_CHECK_POINTER -cppia "%~dp0..\target\cppia\TestRunner.cppia"
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
haxelib run hxcpp "%~dp0..\target\cppia\TestRunner.cppia"
