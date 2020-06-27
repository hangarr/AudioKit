// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import Foundation

var configChangeObserver: Any?

// Utility function to simplify adding listener blocks:
func addListenerBlock( listenerBlock: @escaping AudioObjectPropertyListenerBlock,
                       onAudioObjectID: AudioObjectID,
                       forPropertyAddress: AudioObjectPropertyAddress) {
    var address = forPropertyAddress
    if (kAudioHardwareNoError != AudioObjectAddPropertyListenerBlock(onAudioObjectID, &address, nil, listenerBlock)) {
        print("Error calling: AudioObjectAddPropertyListenerBlock") }
}

func audioObjectPropertyListenerBlock (numberAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>) {
    
    for index in 0..<Int(numberAddresses) {
        
        let address: AudioObjectPropertyAddress = addresses[index]
        switch address.mSelector {
        case kAudioHardwarePropertyDefaultOutputDevice:
            
            print("kAudioHardwarePropertyDefaultOutputDevice")
            
            // AKManager.engine.stop()
            
        default:
            
            print("We didn't expect this!")
            
        }
        
    }
    
}

extension AKManager {
    /// Start up the audio engine with periodic functions
    public static func start(withPeriodicFunctions functions: AKPeriodicFunction...) throws {
        // ensure that an output has been set previously
        guard let finalMixer = finalMixer else {
            AKLog("No output has been assigned yet.")
            return
        }

        for function in functions {
            function.connect(to: finalMixer)
        }
        try start()
    }

    /// Start up the audio engine
    @objc public static func start() throws {
        if output == nil {
            AKLog("No output node has been set yet, no processing will happen.")
        }
        // Start the engine.
        try AKTry {
            engine.prepare()
        }

        #if os(iOS)
        if !AKSettings.disableAVAudioSessionCategoryManagement {
            try updateSessionCategoryAndOptions()
            try AVAudioSession.sharedInstance().setActive(true)
        }

        /// Notification observers

        // Subscribe to route changes that may affect our engine
        // Automatic handling of this change can be disabled via AKSettings.enableRouteChangeHandling
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restartEngineAfterRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)

        // Subscribe to session/configuration changes to our engine
        // Automatic handling of this change can be disabled via AKSettings.enableCategoryChangeHandling
        NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restartEngineAfterConfigurationChange),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: nil)
        #elseif os(macOS)
        
        // Listen for changes to the system audio device.
        addListenerBlock(listenerBlock: audioObjectPropertyListenerBlock,
                         onAudioObjectID: AudioObjectID(bitPattern: kAudioObjectSystemObject),
                         forPropertyAddress: AudioObjectPropertyAddress(
                            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                            mScope: kAudioObjectPropertyScopeGlobal,
                            mElement: kAudioObjectPropertyElementMaster))

        configChangeObserver = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                                          object: engine,
                                                          queue: OperationQueue.main,
                                                          using: { (notification) in
            print("configuration change")
            
            /*
            do {
                try engine.start()
            } catch {
                AKLog("error restarting engine after configuration change")
                // Note: doesn't throw since this is called from a notification observer
            }
            */
        })

        #endif

        try AKTry {
            try engine.start()
            // Send AudioKit started and ready for connections notification.
            // If you listen this notification, you may not need the `shouldBeRunning` variable.
            if AKSettings.notificationsEnabled {
                NotificationCenter.default.post(
                    name: .AKEngineStarted,
                    object: nil,
                    userInfo: nil)
            }
        }
        shouldBeRunning = true
    }

    /// Stop the audio engine
    @objc public static func stop() throws {
        // Stop the engine.
        try AKTry {
            engine.stop()
        }
        shouldBeRunning = false

        #if os(iOS)
        do {
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
            if !AKSettings.disableAudioSessionDeactivationOnStop {
                try AVAudioSession.sharedInstance().setActive(false)
            }
        } catch {
            AKLog("couldn't stop session \(error)")
            throw error
        }
        #endif
    }

    @objc public static func shutdown() throws {
        engine = AVAudioEngine()
        finalMixer = nil
        output = nil
        shouldBeRunning = false
    }
}

#if !os(macOS)
extension AKManager {
    @objc internal static func updateSessionCategoryAndOptions() throws {
        guard AKSettings.disableAVAudioSessionCategoryManagement == false else { return }

        let sessionCategory = AKSettings.computedSessionCategory()

        #if os(iOS)
        let sessionOptions = AKSettings.computedSessionOptions()
        try AKSettings.setSession(category: sessionCategory, with: sessionOptions)
        #elseif os(tvOS)
        try AKSettings.setSession(category: sessionCategory)
        #endif
    }

    // MARK: - Configuration Change Response

    // Listen to changes in audio configuration
    // and restart the audio engine if it stops and should be playing
    @objc fileprivate static func restartEngineAfterConfigurationChange(_ notification: Notification) {
        // Notifications aren't guaranteed to be on the main thread
        let attemptRestart = {
            do {
                // By checking the notification sender in this block rather than during observer configuration
                // we avoid needing to create a new observer if the engine somehow changes
                guard let notifyingEngine = notification.object as? AVAudioEngine, notifyingEngine == engine else {
                    return
                }

                if AKSettings.enableCategoryChangeHandling, !engine.isRunning, shouldBeRunning {
                    #if os(iOS)
                    let appIsNotActive = UIApplication.shared.applicationState != .active
                    let appDoesNotSupportBackgroundAudio = !AKSettings.appSupportsBackgroundAudio

                    if appIsNotActive && appDoesNotSupportBackgroundAudio {
                        AKLog("engine not restarted after configuration change since app was not active " +
                            "and does not support background audio")
                        return
                    }
                    #endif

                    try engine.start()

                    // Sends notification after restarting the engine, so it is safe to resume AudioKit functions.
                    if AKSettings.notificationsEnabled {
                        NotificationCenter.default.post(
                            name: .AKEngineRestartedAfterConfigurationChange,
                            object: nil,
                            userInfo: notification.userInfo)
                    }
                }
            } catch {
                AKLog("error restarting engine after route change")
                // Note: doesn't throw since this is called from a notification observer
            }
        }
        if Thread.isMainThread {
            attemptRestart()
        } else {
            DispatchQueue.main.async(execute: attemptRestart)
        }
    }

    // Restarts the engine after audio output has been changed, like headphones plugged in.
    @objc fileprivate static func restartEngineAfterRouteChange(_ notification: Notification) {
        // Notifications aren't guaranteed to come in on the main thread

        let attemptRestart = {
            if AKSettings.enableRouteChangeHandling, shouldBeRunning, !engine.isRunning {
                do {
                    #if os(macOS)
                    let appIsNotActive = UIApplication.shared.applicationState != .active
                    let appDoesNotSupportBackgroundAudio = !AKSettings.appSupportsBackgroundAudio

                    if appIsNotActive && appDoesNotSupportBackgroundAudio {
                        AKLog("engine not restarted after configuration change since app was not active " +
                            "and does not support background audio")
                        return
                    }
                    #endif

                    try engine.start()

                    // Sends notification after restarting the engine, so it is safe to resume AudioKit functions.
                    if AKSettings.notificationsEnabled {
                        NotificationCenter.default.post(
                            name: .AKEngineRestartedAfterRouteChange,
                            object: nil,
                            userInfo: notification.userInfo)
                    }
                } catch {
                    AKLog("error restarting engine after route change")
                    // Note: doesn't throw since this is called from a notification observer
                }
            }
        }
        if Thread.isMainThread {
            attemptRestart()
        } else {
            DispatchQueue.main.async(execute: attemptRestart)
        }
    }
}
#endif
