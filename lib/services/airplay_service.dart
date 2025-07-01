import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for managing AirPlay functionality
class AirPlayService {
  static const MethodChannel _channel = MethodChannel('com.dvillegas.mangayomi/airplay');
  
  static AirPlayService? _instance;
  static AirPlayService get instance => _instance ??= AirPlayService._();
  
  AirPlayService._();
  
  // Stream controllers for state changes
  final StreamController<bool> _availabilityController = StreamController<bool>.broadcast();
  final StreamController<AirPlayConnectionState> _connectionController = StreamController<AirPlayConnectionState>.broadcast();
  
  // Current state
  bool _isAvailable = false;
  bool _isActive = false;
  String? _connectedDeviceName;
  
  // Getters for current state
  bool get isAvailable => _isAvailable;
  bool get isActive => _isActive;
  String? get connectedDeviceName => _connectedDeviceName;
  
  // Streams for listening to state changes
  Stream<bool> get availabilityStream => _availabilityController.stream;
  Stream<AirPlayConnectionState> get connectionStream => _connectionController.stream;
  
  /// Initialize the AirPlay service
  Future<void> initialize() async {
    if (!Platform.isIOS) {
      debugPrint('AirPlay is only available on iOS');
      return;
    }
    
    try {
      // Set up method call handler for callbacks from native side
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Check initial state
      await _checkInitialState();
      
      debugPrint('AirPlay service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AirPlay service: $e');
    }
  }
  
  /// Handle method calls from native iOS code
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAirPlayAvailabilityChanged':
        final bool isAvailable = call.arguments as bool;
        _updateAvailability(isAvailable);
        break;
        
      case 'onAirPlayStateChanged':
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        final bool isActive = data['isActive'] as bool;
        final String? deviceName = data['deviceName'] as String?;
        _updateConnectionState(isActive, deviceName);
        break;
        
      default:
        debugPrint('Unknown method call: ${call.method}');
    }
  }
  
  /// Check initial AirPlay state
  Future<void> _checkInitialState() async {
    try {
      final bool isAvailable = await _channel.invokeMethod('isAirPlayAvailable');
      final bool isActive = await _channel.invokeMethod('isAirPlayActive');
      
      _updateAvailability(isAvailable);
      _updateConnectionState(isActive, null);
    } catch (e) {
      debugPrint('Error checking initial AirPlay state: $e');
    }
  }
  
  /// Update availability state and notify listeners
  void _updateAvailability(bool isAvailable) {
    if (_isAvailable != isAvailable) {
      _isAvailable = isAvailable;
      _availabilityController.add(isAvailable);
      debugPrint('AirPlay availability changed: $isAvailable');
    }
  }
  
  /// Update connection state and notify listeners
  void _updateConnectionState(bool isActive, String? deviceName) {
    if (_isActive != isActive || _connectedDeviceName != deviceName) {
      _isActive = isActive;
      _connectedDeviceName = deviceName;
      
      final state = AirPlayConnectionState(
        isActive: isActive,
        deviceName: deviceName,
      );
      
      _connectionController.add(state);
      debugPrint('AirPlay connection state changed: active=$isActive, device=$deviceName');
    }
  }
  
  /// Show the AirPlay device selector
  Future<void> showDeviceSelector() async {
    if (!Platform.isIOS) {
      debugPrint('AirPlay is only available on iOS');
      return;
    }
    
    try {
      await _channel.invokeMethod('showAirPlaySelector');
    } on PlatformException catch (e) {
      debugPrint('Error showing AirPlay selector: ${e.message}');
      rethrow;
    }
  }
  
  /// Start AirPlay streaming with the given video URL
  Future<bool> startStreaming(String videoUrl, {Map<String, String>? headers}) async {
    if (!Platform.isIOS) {
      debugPrint('AirPlay is only available on iOS');
      return false;
    }
    
    try {
      final bool success = await _channel.invokeMethod('startAirPlay', {
        'url': videoUrl,
        'headers': headers ?? {},
      });
      
      if (success) {
        debugPrint('AirPlay streaming started for: $videoUrl');
      } else {
        debugPrint('Failed to start AirPlay streaming');
      }
      
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error starting AirPlay streaming: ${e.message}');
      return false;
    }
  }
  
  /// Stop AirPlay streaming
  Future<void> stopStreaming() async {
    if (!Platform.isIOS) {
      debugPrint('AirPlay is only available on iOS');
      return;
    }
    
    try {
      await _channel.invokeMethod('stopAirPlay');
      debugPrint('AirPlay streaming stopped');
    } on PlatformException catch (e) {
      debugPrint('Error stopping AirPlay streaming: ${e.message}');
    }
  }
  
  /// Sync playback position with AirPlay device
  Future<void> syncPosition(Duration position) async {
    if (!Platform.isIOS || !_isActive) {
      return;
    }
    
    try {
      await _channel.invokeMethod('syncPosition', {
        'position': position.inMilliseconds,
      });
    } on PlatformException catch (e) {
      debugPrint('Error syncing AirPlay position: ${e.message}');
    }
  }
  
  /// Set playback rate for AirPlay
  Future<void> setPlaybackRate(double rate) async {
    if (!Platform.isIOS || !_isActive) {
      return;
    }
    
    try {
      await _channel.invokeMethod('setPlaybackRate', {
        'rate': rate,
      });
    } on PlatformException catch (e) {
      debugPrint('Error setting AirPlay playback rate: ${e.message}');
    }
  }
  
  /// Get current playback position from AirPlay
  Future<Duration> getPlaybackPosition() async {
    if (!Platform.isIOS || !_isActive) {
      return Duration.zero;
    }
    
    try {
      final int positionMs = await _channel.invokeMethod('getPlaybackPosition');
      return Duration(milliseconds: positionMs);
    } on PlatformException catch (e) {
      debugPrint('Error getting AirPlay playback position: ${e.message}');
      return Duration.zero;
    }
  }
  
  /// Dispose the service and clean up resources
  void dispose() {
    _availabilityController.close();
    _connectionController.close();
  }
}

/// Data class representing AirPlay connection state
class AirPlayConnectionState {
  final bool isActive;
  final String? deviceName;
  
  const AirPlayConnectionState({
    required this.isActive,
    this.deviceName,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirPlayConnectionState &&
        other.isActive == isActive &&
        other.deviceName == deviceName;
  }
  
  @override
  int get hashCode => Object.hash(isActive, deviceName);
  
  @override
  String toString() {
    return 'AirPlayConnectionState(isActive: $isActive, deviceName: $deviceName)';
  }
}
