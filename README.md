
## Task Overview
You are tasked with building a prototype application that implements key features of a video
conferencing system, focusing on external device connectivity and video data processing.

### Requirements:
- [x] Device Integration:
    - [x] Detect and list all connected video devices (e.g., integrated or external webcams)
    - [x] Provide functionality for users to select specific devices for the video conferencing session.
    - [x] Include a feature to check the connection status of the selected devices and notify the user if a device is disconnected.
- [ ] Video Preview:
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

### Submission Instructions
To share the results of your work, please include the following:
- Source Code:
    - Provide all source code files in a structured format.
    - Ensure the code is easy to understand.
- Executable File(Optional):
    - Share a compiled executable file for the platform(s) you developed the application on (MacOS).
    - Ensure the executable can be run without additional configuration or dependencies.
- README File:
    - Include a README file with the following details:
        - Instructions on how to run the application, including any prerequisites or dependencies.  
        - An explanation of your approach and any challenges you encountered.
- Demonstration(Optional):
    - If possible, include a short video demonstrating the application in action (e.g., showing the device integration, a video preview, etc.).
- Submission Method:
    - Upload all required files to a GitHub repository or a cloud storage service (e.g., Google Drive, Dropbox, or OneDrive).
    - Share the repository link or download link in your response.

### How to run
- Open `.xcodeproj`.
- In `Target` settings under `Signing & Capabilities` change `Team` and `Bundle Identifier` if needed.
- Build and Run.

### Approach
- Ignoring architecture as it was not a requirement, using DI though.
- Using `ObservableObject` instead of `@Observable` for sake of utilizing DI framework without any hassle.
- Leaving documentation comments wherever i see fit or necessary.
- Adding `print()` where handling errors and where appropriate.
- Git history not preserved.

### Challenges
- Procrastination while doing this on the weekend in multiple session with long breaks in between.
- Getting audio output devices, even though not required it definitely makes UI appear more real than just a test task demo. Up until now i didn't realize theres no `AVAudioSession` on `macOS` and i'll need to interact with `CoreAudio` just to list devices, totally spent time here for no other reason than just figure out how.
- Window management, haven't done much of it with SwiftUI, you'll see some borrowed code which makes it a tad simpler.
- Naming things is hard, i would totally ruminate more over names of things, they can totally be improved.
- I probably did overengineer some things.
