import Foundation
import AVFoundation
import AVKit
import MediaPlayer
import Flutter

@available(iOS 11.0, *)
class AirPlayManager: NSObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerViewController: AVPlayerViewController?
    private var channel: FlutterMethodChannel
    private var routeDetector: AVRouteDetector?
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        setupRouteDetector()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Route Detection
    
    private func setupRouteDetector() {
        routeDetector = AVRouteDetector()
        routeDetector?.isRouteDetectionEnabled = true
        
        // Configure for video routes
        if #available(iOS 16.0, *) {
            routeDetector?.detectsCustomRoutes = true
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(routeChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // Monitor external playback availability
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalPlaybackAvailabilityChanged),
            name: .MPVolumeViewWirelessRoutesAvailableDidChange,
            object: nil
        )
        
        // Also monitor screen connection/disconnection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidConnect),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidDisconnect),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }
    
    @objc private func routeChanged(notification: Notification) {
        DispatchQueue.main.async {
            self.notifyAirPlayStateChanged()
        }
    }
    
    @objc private func externalPlaybackAvailabilityChanged() {
        DispatchQueue.main.async {
            self.notifyAirPlayAvailabilityChanged()
        }
    }
    
    @objc private func screenDidConnect(notification: Notification) {
        print("External screen connected")
        notifyAirPlayStateChanged()
    }
    
    @objc private func screenDidDisconnect(notification: Notification) {
        print("External screen disconnected")
        notifyAirPlayStateChanged()
    }
    
    private func notifyAirPlayAvailabilityChanged() {
        let isAvailable = isAirPlayAvailable()
        channel.invokeMethod("onAirPlayAvailabilityChanged", arguments: isAvailable)
    }
    
    private func notifyAirPlayStateChanged() {
        let isActive = isAirPlayActive()
        let deviceName = getConnectedAirPlayDeviceName()
        
        let data: [String: Any] = [
            "isActive": isActive,
            "deviceName": deviceName ?? NSNull()
        ]
        
        channel.invokeMethod("onAirPlayStateChanged", arguments: data)
    }
    
    // MARK: - External Playback Monitoring
    
    private func setupExternalPlaybackMonitoring() {
        // Monitor external playback changes
        player?.addObserver(self, forKeyPath: "externalPlaybackActive", options: [.new, .old], context: nil)
        player?.addObserver(self, forKeyPath: "allowsExternalPlayback", options: [.new, .old], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "externalPlaybackActive" {
            if let isActive = change?[.newKey] as? Bool {
                print("External playback active changed to: \(isActive)")
                
                // If external playback is not active but should be, try to force it
                if !isActive && isAirPlayActive() {
                    DispatchQueue.main.async { [weak self] in
                        self?.player?.allowsExternalPlayback = true
                        self?.player?.usesExternalPlaybackWhileExternalScreenIsActive = true
                    }
                }
            }
        } else if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                print("Player item status changed to: \(item.status.rawValue)")
                
                switch item.status {
                case .readyToPlay:
                    print("Player item is ready to play")
                    // Try to play when ready
                    DispatchQueue.main.async { [weak self] in
                        self?.player?.play()
                    }
                case .failed:
                    print("Player item failed: \(item.error?.localizedDescription ?? "unknown error")")
                case .unknown:
                    print("Player item status unknown")
                @unknown default:
                    print("Player item unknown status")
                }
            }
        }
    }
    
    // MARK: - AirPlay Control Methods
    
    func showAirPlaySelector() {
        DispatchQueue.main.async {
            if #available(iOS 11.0, *) {
                let routePickerView = AVRoutePickerView()
                routePickerView.activeTintColor = UIColor.systemBlue
                routePickerView.backgroundColor = UIColor.clear

                // Find the current view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {

                    // Create a temporary container for the route picker
                    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
                    routePickerView.frame = containerView.bounds
                    containerView.addSubview(routePickerView)

                    // Add to view hierarchy temporarily
                    rootViewController.view.addSubview(containerView)

                    // Trigger the route picker
                    for subview in routePickerView.subviews {
                        if let button = subview as? UIButton {
                            button.sendActions(for: .touchUpInside)
                            break
                        }
                    }

                    // Remove the temporary container after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        containerView.removeFromSuperview()
                    }
                }
            } else {
                // Fallback for iOS < 11.0 - use MPVolumeView
                self.showLegacyAirPlaySelector()
            }
        }
    }

    @available(iOS, deprecated: 11.0, message: "Use AVRoutePickerView instead")
    private func showLegacyAirPlaySelector() {
        let volumeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        volumeView.showsVolumeSlider = false
        volumeView.showsRouteButton = true

        // Find the current view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            // Add to view hierarchy temporarily
            rootViewController.view.addSubview(volumeView)

            // Trigger the route button
            for subview in volumeView.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: .touchUpInside)
                    break
                }
            }

            // Remove after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                volumeView.removeFromSuperview()
            }
        }
    }
    
    func startAirPlay(url: String, headers: [String: String]?) -> Bool {
        print("=== Starting AirPlay ===")
        print("URL: \(url)")
        print("Headers: \(headers ?? [:])")
        
        guard let videoURL = URL(string: url) else {
            print("Invalid URL: \(url)")
            return false
        }
        
        // Stop any existing playback
        stopAirPlay()
        
        // Check if it's an HLS stream
        let isHLS = url.hasSuffix(".m3u8") || url.contains("m3u8")
        print("Is HLS stream: \(isHLS)")
        
        // Create player item with headers if provided
        let asset: AVURLAsset
        if let headers = headers, !headers.isEmpty {
            var options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": headers]
            
            // Add additional options for HLS streams
            if isHLS {
                options["AVURLAssetPreferPreciseDurationAndTimingKey"] = true
            }
            
            asset = AVURLAsset(url: videoURL, options: options)
        } else {
            let options: [String: Any] = isHLS ? ["AVURLAssetPreferPreciseDurationAndTimingKey": true] : [:]
            asset = AVURLAsset(url: videoURL, options: options)
        }
        
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        // CRITICAL: Set these properties BEFORE any UI setup
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        // Setup monitoring for external playback
        setupExternalPlaybackMonitoring()
        
        // Observe player item status
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        
        // Create and configure player view controller on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create player view controller
            self.playerViewController = AVPlayerViewController()
            self.playerViewController?.player = self.player
            
            // Configure for external playback
            self.playerViewController?.updatesNowPlayingInfoCenter = true
            self.playerViewController?.allowsPictureInPicturePlayback = false
            
            // IMPORTANT: These settings help with AirPlay video routing
            self.playerViewController?.entersFullScreenWhenPlaybackBegins = true
            self.playerViewController?.exitsFullScreenWhenPlaybackEnds = false
            self.playerViewController?.showsPlaybackControls = true
            
            // Find the topmost view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                var topController = window.rootViewController
                while let presented = topController?.presentedViewController {
                    topController = presented
                }
                
                // Present the player view controller
                self.playerViewController?.modalPresentationStyle = .fullScreen
                
                topController?.present(self.playerViewController!, animated: true) { [weak self] in
                    guard let self = self else { return }
                    
                    // Configure the video output after presentation
                    if let playerLayer = self.playerViewController?.view.layer.sublayers?.first(where: { $0 is AVPlayerLayer }) as? AVPlayerLayer {
                        playerLayer.videoGravity = .resizeAspect
                        
                        // Force video to external display if available
                        if self.isAirPlayActive() {
                            print("Forcing video to external display")
                            playerLayer.player = self.player
                        }
                    }
                    
                    // Start playback after a small delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.player?.play()
                        
                        // Log playback state
                        if let player = self.player {
                            print("Player state after play:")
                            print("- Is playing: \(player.rate > 0)")
                            print("- External playback active: \(player.isExternalPlaybackActive)")
                            print("- Allows external playback: \(player.allowsExternalPlayback)")
                            print("- Current time: \(player.currentTime().seconds)")
                            print("- Player status: \(player.status.rawValue)")
                            print("- Player error: \(player.error?.localizedDescription ?? "none")")
                            
                            if let currentItem = player.currentItem {
                                print("- Item status: \(currentItem.status.rawValue)")
                                print("- Item error: \(currentItem.error?.localizedDescription ?? "none")")
                                print("- Item duration: \(currentItem.duration.seconds)")
                            }
                        }
                        
                        // Check and enable video routing if needed
                        self.checkAndEnableVideoRouting()
                    }
                }
            }
        }
        
        return true
    }
    
    func stopAirPlay() {
        // Remove observers
        player?.removeObserver(self, forKeyPath: "externalPlaybackActive")
        player?.removeObserver(self, forKeyPath: "allowsExternalPlayback")
        playerItem?.removeObserver(self, forKeyPath: "status")
        
        player?.pause()
        
        // Dismiss the player view controller
        DispatchQueue.main.async { [weak self] in
            self?.playerViewController?.dismiss(animated: true) {
                self?.playerViewController = nil
                self?.player = nil
                self?.playerItem = nil
            }
        }
    }
    
    func syncPosition(positionMs: Int) {
        guard let player = player else { return }
        
        let time = CMTime(value: Int64(positionMs), timescale: 1000)
        player.seek(to: time)
    }
    
    func setPlaybackRate(rate: Double) {
        player?.rate = Float(rate)
    }
    
    func getPlaybackPosition() -> Int {
        guard let player = player else { return 0 }
        
        let time = player.currentTime()
        return Int(CMTimeGetSeconds(time) * 1000)
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        routeDetector?.isRouteDetectionEnabled = false
        playerViewController = nil
        player = nil
        playerItem = nil
    }
    
    // MARK: - Force Video Routing
    
    private func forceVideoToExternalDisplay() {
        guard let player = player else { return }
        
        // Check if we have an external screen
        if UIScreen.screens.count > 1 {
            // Get the external screen
            let externalScreen = UIScreen.screens[1]
            
            // Create a window for the external screen
            let externalWindow = UIWindow(frame: externalScreen.bounds)
            externalWindow.screen = externalScreen
            
            // Create a view controller for the external display
            let externalViewController = UIViewController()
            externalViewController.view.backgroundColor = .black
            
            // Add player layer to external view
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = externalViewController.view.bounds
            playerLayer.videoGravity = .resizeAspect
            externalViewController.view.layer.addSublayer(playerLayer)
            
            // Set up the external window
            externalWindow.rootViewController = externalViewController
            externalWindow.isHidden = false
            
            print("Video forced to external display")
        }
    }
    
    // Call this method after setting up the player
    private func checkAndEnableVideoRouting() {
        // Ensure video routing is properly configured
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self,
                  let player = self.player else { return }
            
            // If AirPlay is active but video is not routing, try to force it
            if self.isAirPlayActive() && !player.isExternalPlaybackActive {
                print("AirPlay is active but video not routing, attempting to force...")
                
                // Try setting the properties again
                player.allowsExternalPlayback = true
                player.usesExternalPlaybackWhileExternalScreenIsActive = true
                
                // Force video to external display if available
                self.forceVideoToExternalDisplay()
            }
        }
    }
    
    // MARK: - AirPlay Status Methods
    
    func isAirPlayAvailable() -> Bool {
        // Check if wireless routes are available
        let volumeView = MPVolumeView()
        return volumeView.areWirelessRoutesAvailable
    }
    
    func isAirPlayActive() -> Bool {
        // Check multiple conditions for AirPlay active state
        
        // First check if player has external playback active
        if let player = player, player.isExternalPlaybackActive {
            return true
        }
        
        // Also check audio session route
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        for output in currentRoute.outputs {
            if output.portType == .airPlay {
                return true
            }
        }
        
        // Check if there's an external screen connected
        if UIScreen.screens.count > 1 {
            return true
        }
        
        return false
    }
    
    private func getConnectedAirPlayDeviceName() -> String? {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        for output in currentRoute.outputs {
            if output.portType == .airPlay {
                return output.portName
            }
        }
        return nil
    }
}

// MARK: - Flutter Method Channel Handler

@available(iOS 11.0, *)
extension AirPlayManager {
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAirPlayAvailable":
            result(isAirPlayAvailable())
            
        case "isAirPlayActive":
            result(isAirPlayActive())
            
        case "showAirPlaySelector":
            showAirPlaySelector()
            result(nil)
            
        case "startAirPlay":
            guard let args = call.arguments as? [String: Any],
                  let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing URL", details: nil))
                return
            }
            
            let headers = args["headers"] as? [String: String]
            let success = startAirPlay(url: url, headers: headers)
            result(success)
            
        case "stopAirPlay":
            stopAirPlay()
            result(nil)
            
        case "syncPosition":
            guard let args = call.arguments as? [String: Any],
                  let position = args["position"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing position", details: nil))
                return
            }
            
            syncPosition(positionMs: position)
            result(nil)
            
        case "setPlaybackRate":
            guard let args = call.arguments as? [String: Any],
                  let rate = args["rate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing rate", details: nil))
                return
            }
            
            setPlaybackRate(rate: rate)
            result(nil)
            
        case "getPlaybackPosition":
            result(getPlaybackPosition())
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
