# Master Trading Engine — Cloud APK Build

The repository contains the GitHub Actions Android build workflow.

## Required project payload
Upload `Master_Trading_Engine_Cloud_Build_Payload.zip` to the repository root. The workflow will extract it, prepare the Android wrapper if needed, run Flutter dependency resolution, analysis, tests, and build a debug APK artifact.

## Safety
This build is Paper Trading only. Real broker order execution and Auto-Trading remain disabled.
