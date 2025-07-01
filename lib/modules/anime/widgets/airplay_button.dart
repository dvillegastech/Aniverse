import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/services/airplay_service.dart';

/// AirPlay button widget that shows AirPlay device selector on iOS
class AirPlayButton extends ConsumerStatefulWidget {
  final VoidCallback? onAirPlayStateChanged;
  
  const AirPlayButton({
    super.key,
    this.onAirPlayStateChanged,
  });

  @override
  ConsumerState<AirPlayButton> createState() => _AirPlayButtonState();
}

class _AirPlayButtonState extends ConsumerState<AirPlayButton> {
  final AirPlayService _airPlayService = AirPlayService.instance;

  bool _isAirPlayAvailable = false;
  bool _isAirPlayActive = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _initializeAirPlay();
    }
  }

  /// Initialize AirPlay service and setup listeners
  Future<void> _initializeAirPlay() async {
    await _airPlayService.initialize();

    // Set initial state
    setState(() {
      _isAirPlayAvailable = _airPlayService.isAvailable;
      _isAirPlayActive = _airPlayService.isActive;
    });

    // Listen to availability changes
    _airPlayService.availabilityStream.listen((isAvailable) {
      if (mounted) {
        setState(() {
          _isAirPlayAvailable = isAvailable;
        });
      }
    });

    // Listen to connection state changes
    _airPlayService.connectionStream.listen((connectionState) {
      if (mounted) {
        setState(() {
          _isAirPlayActive = connectionState.isActive;
        });
        widget.onAirPlayStateChanged?.call();
      }
    });
  }

  /// Show AirPlay device selector
  Future<void> _showAirPlaySelector() async {
    try {
      // Store the initial state
      final wasActive = _airPlayService.isActive;
      
      await _airPlayService.showDeviceSelector();
      
      // After showing the selector, wait a bit and check if state changed
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Check if state changed from inactive to active
      final isNowActive = _airPlayService.isActive;
      if (!wasActive && isNowActive && widget.onAirPlayStateChanged != null) {
        debugPrint('AirPlay device was selected, notifying parent');
        widget.onAirPlayStateChanged!();
      }
    } catch (e) {
      debugPrint('Error showing AirPlay selector: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on iOS - always show for testing purposes
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: _showAirPlaySelector,
      icon: Icon(
        _isAirPlayActive ? Icons.cast_connected : Icons.cast,
        color: _isAirPlayActive ? Colors.blue : (_isAirPlayAvailable ? Colors.white : Colors.grey),
      ),
      tooltip: _isAirPlayActive
          ? 'Disconnect AirPlay'
          : _isAirPlayAvailable
              ? 'Connect to AirPlay'
              : 'AirPlay (No devices found)',
    );
  }
}

/// Provider for AirPlay state management
final airPlayStateProvider = StateNotifierProvider<AirPlayStateNotifier, AirPlayState>((ref) {
  return AirPlayStateNotifier();
});

/// AirPlay state data class
class AirPlayState {
  final bool isAvailable;
  final bool isActive;
  final String? connectedDeviceName;

  const AirPlayState({
    this.isAvailable = false,
    this.isActive = false,
    this.connectedDeviceName,
  });

  AirPlayState copyWith({
    bool? isAvailable,
    bool? isActive,
    String? connectedDeviceName,
  }) {
    return AirPlayState(
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
    );
  }
}

/// State notifier for managing AirPlay state
class AirPlayStateNotifier extends StateNotifier<AirPlayState> {
  final AirPlayService _airPlayService = AirPlayService.instance;

  AirPlayStateNotifier() : super(const AirPlayState()) {
    if (Platform.isIOS) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await _airPlayService.initialize();

    // Set initial state
    state = state.copyWith(
      isAvailable: _airPlayService.isAvailable,
      isActive: _airPlayService.isActive,
      connectedDeviceName: _airPlayService.connectedDeviceName,
    );

    // Listen to availability changes
    _airPlayService.availabilityStream.listen((isAvailable) {
      state = state.copyWith(isAvailable: isAvailable);
    });

    // Listen to connection state changes
    _airPlayService.connectionStream.listen((connectionState) {
      state = state.copyWith(
        isActive: connectionState.isActive,
        connectedDeviceName: connectionState.deviceName,
      );
    });
  }

  /// Show AirPlay device selector
  Future<void> showAirPlaySelector() async {
    await _airPlayService.showDeviceSelector();
  }

  /// Start AirPlay with current video URL
  Future<void> startAirPlay(String videoUrl, {Map<String, String>? headers}) async {
    await _airPlayService.startStreaming(videoUrl, headers: headers);
  }

  /// Stop AirPlay
  Future<void> stopAirPlay() async {
    await _airPlayService.stopStreaming();
  }

  /// Sync playback position with AirPlay
  Future<void> syncPosition(Duration position) async {
    await _airPlayService.syncPosition(position);
  }
}
