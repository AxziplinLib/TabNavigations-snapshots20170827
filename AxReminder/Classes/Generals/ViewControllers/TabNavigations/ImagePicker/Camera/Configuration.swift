//
//  Configuration.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AVFoundation

extension CaptureVideoPreviewView {
    /// Get the current video input device's pos position if any. 
    /// Returns `.unspecified` if the video input device is not available.
    ///
    /// - Returns: Any of the values in `AVCaptureDevicePosition` indicates the position of device's pos.
    public var position: AVCaptureDevicePosition { return videoDevice?.position ?? .unspecified }
}

extension CaptureVideoPreviewView {
    /// Toggle the position of device's pos to the opposite sides.
    ///
    /// - Changes the pos's position to the `.front` if the current position is at back.
    /// - Changes the pos's position to the `.back` if the current position is at front or unknown.
    ///
    /// - Returns: A boolean value indicates the result(true for success) of position changing.
    @discardableResult
    public func toggle() -> Bool {
        switch position {
        case .back:
            return toggle(to: .front)
        default:
            return toggle(to: .back)
        }
    }
    @discardableResult
    public func toggle(to pos: AVCaptureDevicePosition) -> Bool {
        guard pos != position && pos != .unspecified else { return false }
        guard let session = previewLayer.session else { return false }
        
        // Get new device.
        var devices: [AVCaptureDevice] = []
        if #available(iOS 10.0, *) {
            var deviceTypes: [AVCaptureDeviceType] = [.builtInWideAngleCamera, .builtInTelephotoCamera]
            if #available(iOS 10.2, *) {
                deviceTypes.append(.builtInDualCamera)
            } else {
                deviceTypes.append(.builtInDuoCamera)
            }
            if let _devices = AVCaptureDeviceDiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaTypeVideo, position: pos).devices { devices = _devices }
        } else {
            if let _devices = AVCaptureDevice.devices() as? [AVCaptureDevice] { devices = _devices }
        }
        guard !devices.isEmpty else { return false }
        
        let targetDevices = devices.flatMap({ $0.position == pos && $0.hasMediaType(AVMediaTypeVideo) ? $0 : nil })
        guard targetDevices.count == 1 else { return false }// Only one device for the specified position.
        
        let newDevice = targetDevices[0]
        guard let newDeviceInput = try? AVCaptureDeviceInput(device: newDevice) else {  return false }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        // Get the devices inputs.
        let oldDevices = session.inputs.flatMap({ ($0 is AVCaptureDeviceInput && ($0 as! AVCaptureDeviceInput).device.hasMediaType(AVMediaTypeVideo)) ? $0 : nil }) as! [AVCaptureDeviceInput]
        // Remove the KVO observing info of the old devices.
        // Remove all the device inputs if any.
        oldDevices.forEach({ observe(device:$0.device , removing: true); session.removeInput($0) })
        // Add the new device input if new device can be added.
        if session.canAddInput(newDeviceInput) { session.addInput(newDeviceInput); observe(device: newDeviceInput.device) } else {
            // Reverse the old devices.
            oldDevices.forEach({ if session.canAddInput($0) { session.addInput($0); observe(device: $0.device) } })
        }
        // Add transition animation.
        let transition = CATransition()
        // cube, suckEffect, oglFlip, rippleEffect, pageCurl, pageUnCurl, cameraIrisHollowOpen, cameraIrisHollowClose
        transition.type = "oglFlip"
        transition.subtype = kCATransitionFromLeft
        transition.duration = 0.25 * 2.0
        previewLayer.add(transition, forKey: "transition")
        
        return true
    }
}
