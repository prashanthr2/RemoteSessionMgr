# RemoteDeskMac

RemoteDeskMac is a native macOS SwiftUI app for managing personal SSH and RDP sessions. It is inspired by the workflow of remote session managers like mRemoteNG, but this implementation is written from scratch for macOS and only targets SSH and RDP for v1.

## Features

- Create, edit, and delete SSH or RDP sessions
- Organize sessions into nested folders in a sidebar tree
- Search sessions by name, host, username, notes, or protocol
- Edit session details in a native SwiftUI detail pane
- Launch SSH connections in Terminal.app or iTerm2
- Launch RDP sessions through `xfreerdp` or a custom command template
- Persist sessions and settings locally as JSON
- Seed sample data on first launch

## Project Structure

```text
Sources/RemoteDeskMac
├── Launchers
├── Models
├── Persistence
├── Utilities
├── ViewModels
└── Views
```

The app follows a lightweight MVVM structure:

- `Models`: session, folder, selection, and settings types
- `ViewModels`: application state, mutations, persistence hooks, and launching actions
- `Views`: sidebar, detail editors, settings, and empty state
- `Persistence`: JSON-backed local storage
- `Launchers`: SSH and RDP process launch services

## Building In Xcode

### Option 1: Open as a Swift Package

1. Open Xcode.
2. Choose `File > Open...`.
3. Select `/Users/prashanth/Documents/Playground/Package.swift`.
4. Let Xcode resolve and load the package.
5. Run the `RemoteDeskMac` executable target on `My Mac`.

### Option 2: Build from Terminal

```bash
swift build
swift run
```

If terminal builds fail because only Command Line Tools are installed or the local Apple toolchain is mismatched, switch to a full Xcode installation and select it with:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## SSH Launching

SSH connections use the system `ssh` command. RemoteDeskMac does not implement the SSH protocol itself.

For a session with:

- username: `alice`
- host: `server.example.com`
- port: `2222`

the app builds and launches:

```bash
ssh 'alice@server.example.com' -p 2222
```

The default SSH launcher is configurable in Settings:

- `Terminal.app`: opens a new Terminal window/tab via AppleScript and runs the command
- `iTerm2`: opens a new iTerm2 tab or window via AppleScript and runs the command

## RDP Launching

RDP is delegated to an external client. RemoteDeskMac does not render RDP sessions natively.

By default, the app uses this command template:

```bash
xfreerdp /v:{host} /u:{username} /port:{port}
```

Supported placeholders:

- `{host}`
- `{port}`
- `{username}`
- `{name}`

If `xfreerdp` is not installed, either:

- install it locally, or
- change the RDP command template in Settings to another launcher command

Example custom template:

```bash
open -a "Microsoft Remote Desktop" "rdp://full%20address=s:{host}"
```

## Persistence

The app stores JSON files in the user Application Support directory:

```text
~/Library/Application Support/RemoteDeskMac/sessions.json
~/Library/Application Support/RemoteDeskMac/settings.json
```

On first launch, the app writes:

- sample folders
- sample SSH sessions
- sample RDP sessions
- default settings

## Notes

- This project is intended for personal local use.
- It is not designed for App Store distribution.
- No heavy third-party dependencies are required for v1.
