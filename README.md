# NEXUS Mobile

NEXUS Mobile is an experimental iOS companion app for the NEXUS home setup. It is written with SwiftUI and is meant to connect to services already running on your own network.

## Open the app

You need a Mac with Xcode or a cloud macOS build service.

1. Open the `NexusMobile` folder in Xcode.
2. Use iOS 17 or newer as the deployment target.
3. Replace the example Tailscale hostname with your own.
4. Choose your Apple development team and build the app.

The PC wake feature needs a Wake-on-LAN relay running on a Raspberry Pi before it can work.

This project is still experimental. Its features depend on the services and network you set up.
