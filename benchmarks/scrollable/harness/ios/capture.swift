// Records the screen of an iPhone connected by cable, as QuickTime Player's
// "New Movie Recording" does, without opening a window on the Mac.
//
//   swift capture.swift <seconds> <out.mov> [device name]
//
// The iPhone appears to macOS as a capture device once screen capture
// devices are allowed (a CoreMediaIO setting QuickTime Player turns on the
// same way); the first such device is recorded, or the one whose name
// contains [device name]. The terminal running this needs the Camera
// permission once (System Settings, Privacy & Security, Camera).
import AVFoundation
import CoreMediaIO
import Foundation

let args = CommandLine.arguments
guard args.count >= 3, let seconds = Double(args[1]) else {
    FileHandle.standardError.write("usage: swift capture.swift <seconds> <out.mov> [device name]\n".data(using: .utf8)!)
    exit(2)
}
let out = URL(fileURLWithPath: args[2])
let wanted = args.count > 3 ? args[3] : nil

var address = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
var allow: UInt32 = 1
CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil,
                          UInt32(MemoryLayout<UInt32>.size), &allow)

func findDevice() -> AVCaptureDevice? {
    let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external], mediaType: .muxed, position: .unspecified)
    return session.devices.first { d in wanted.map { d.localizedName.contains($0) } ?? true }
}

// The device shows up a moment after capture devices are allowed.
var device: AVCaptureDevice?
for _ in 0..<50 {
    device = findDevice()
    if device != nil { break }
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
}
guard let device else {
    FileHandle.standardError.write("no iPhone screen to capture: is it connected by cable and unlocked?\n".data(using: .utf8)!)
    exit(1)
}

let session = AVCaptureSession()
let input = try AVCaptureDeviceInput(device: device)
guard session.canAddInput(input) else { fatalError("cannot use \(device.localizedName)") }
session.addInput(input)
let output = AVCaptureMovieFileOutput()
guard session.canAddOutput(output) else { fatalError("cannot record \(device.localizedName)") }
session.addOutput(output)

final class Done: NSObject, AVCaptureFileOutputRecordingDelegate {
    var finished = false
    var error: Error?
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo url: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        self.error = error
        finished = true
    }
}
let done = Done()
try? FileManager.default.removeItem(at: out)
session.startRunning()
// The iPhone sends its screen a moment after the session starts; a
// recording started before that has nothing to write and fails.
let deadline = Date().addingTimeInterval(10)
while !(output.connection(with: .video)?.isActive ?? false) && Date() < deadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
}
RunLoop.current.run(until: Date().addingTimeInterval(1.5))
output.startRecording(to: out, recordingDelegate: done)
print("recording \(device.localizedName) for \(seconds) s")
RunLoop.current.run(until: Date().addingTimeInterval(seconds))
output.stopRecording()
while !done.finished { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
session.stopRunning()
// A recording that ended early still leaves a playable file.
let recorded = (done.error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? true
if let error = done.error, !recorded {
    FileHandle.standardError.write("the recording failed: \(error.localizedDescription)\n".data(using: .utf8)!)
    exit(1)
}
print("\(out.path): written")
