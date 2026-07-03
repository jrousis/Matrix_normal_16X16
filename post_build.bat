@echo off
REM Copy compiled binary to the project folder
copy /Y "{build.path}\{build.project_name}.bin" "{source_path}\"
echo Compiled file copied to project folder.