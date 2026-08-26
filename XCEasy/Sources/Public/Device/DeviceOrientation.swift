import UIKit

public enum DeviceOrientation {
    case unknown, portrait, portraitUpsideDown, landscapeLeft, landscapeRight, faceUp, faceDown

    var properties: Orientation {
        switch self {
        case .unknown:
            Orientation(
                name: LocalizationManager.shared.string(forKey: "device_orientation_unknown"),
                key: UIDeviceOrientation.unknown
            )
        case .portrait:
            Orientation(
                name: LocalizationManager.shared.string(forKey: "device_orientation_portrait"),
                key: UIDeviceOrientation.portrait
            )
        case .portraitUpsideDown:
            Orientation(
                name: LocalizationManager.shared.string(forKey: "device_orientation_portrait_upside_down"),
                key: UIDeviceOrientation.portraitUpsideDown
            )
        case .landscapeLeft:
            Orientation(
                name: LocalizationManager.shared.string(forKey: "device_orientation_landscape_left"),
                key: UIDeviceOrientation.landscapeLeft
            )
        case .landscapeRight:
            Orientation(
                name: LocalizationManager.shared.string(forKey: "device_orientation_landscape_right"),
                key: UIDeviceOrientation.landscapeRight
            )
        case .faceUp:
            Orientation(
                name: LocalizationManager.shared.string(forKey: "device_orientation_face_up"),
                key: UIDeviceOrientation.faceUp
            )
        case .faceDown:
            Orientation(
                name: LocalizationManager.shared.string(forKey: "device_orientation_face_down"),
                key: UIDeviceOrientation.faceDown
            )
        }
    }
}

public struct Orientation {
    let name: String
    let key: UIDeviceOrientation
}
