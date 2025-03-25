
## Task Overview
You are tasked with building a prototype application that implements key features of a video
conferencing system, focusing on external device connectivity and video data processing.

### Requirements:
- [x] Device Integration:
    - [x] Detect and list all connected video devices (e.g., integrated or external webcams)
    - [x] Provide functionality for users to select specific devices for the video conferencing session.
    - [x] Include a feature to check the connection status of the selected devices and notify the user if a device is disconnected.
- [x] Video Preview:
    - [x] Capture live video from the selected webcam and display it in a video preview window.
    - [x] Implement basic video processing, such as converting the video feed to grayscale or adding a simple filter.
- [x] User Interface:
    - [x] Create a simple and intuitive UI that includes:
        - [x] Dropdown menus to list and select video devices.
        - [x] Buttons to start/stop video preview.
        - [x] A status indicator for each device to display its current state (connected/disconnected).
### Bonus:
- [ ] Implement a feature to record the video and audio streams and save them as separate files.
- [ ] Use platform-specific libraries to handle video and audio processing efficiently (AVFoundation).

### How to run
- Open `.xcodeproj`.
- In `Target` settings under `Signing & Capabilities` change `Team` and `Bundle Identifier` if needed.
- Build and Run.

### Approach
- Ignoring architecture as it was not a requirement, using DI though.
- Using `ObservableObject` instead of `@Observable` for sake of utilizing DI framework without any hassle.
- Leaving documentation comments wherever i see fit or necessary.
- Adding `print()` where handling errors and where appropriate.
- No real error handling or presenting them to user.
- Git history not preserved.
- CaptureSession is rebuilt whenever devices change(probably more times than actually required)
- If current selected device disconnects it will be replace with default one.
- Audio devices presented for selection but not used as there is no such requirement.

### Challenges
- Procrastination while doing this on the weekend in multiple session with long breaks in between.
- Getting audio output devices, even though not required it definitely makes UI appear more real than just a test task demo. Up until now i didn't realize theres no `AVAudioSession` on `macOS` and i'll need to interact with `CoreAudio` just to list devices, totally spent time here for no other reason than just figure out how.
- Window management, haven't done much of it with SwiftUI, you'll see some borrowed code which makes it a tad simpler.
- Naming things is hard, i would totally ruminate more over names of things, they can totally be improved.
- I probably did overengineer some things.
