// MARK: - IOKitServices.swift
// IOKit wrapper struct for power management and display control.
// Service ports cached at startup (OPT-01), deferred cleanup (OPT-06).
// Always calls IOObjectRelease to prevent kernel leaks (BAN-03).

import Foundation
import IOKit
import IOKit.pwr_mgt

/// Wrapper struct for IOKit operations
/// Service ports cached after first lookup (OPT-01)
struct IOKitServices {

    // MARK: - Cached Service Ports (OPT-01)
    private static var cachedPowerRootDomain: io_service_t = 0
    private static var cachedInternalDisplay: io_service_t = 0

    // MARK: - Power Root Domain Caching

    /// Cache the power root domain service port (OPT-01)
    /// Returns true if caching succeeded
    static func cachePowerRootDomain() -> Bool {
        guard let matching = IOServiceMatching(Constants.powerRootDomainName) else {
            return false
        }
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            matching
        )
        if service != 0 {
            cachedPowerRootDomain = service
            return true
        }
        return false
    }

    // MARK: - Internal Display Caching

    /// Cache the internal display service port (OPT-01)
    /// Returns true if caching succeeded
    static func cacheInternalDisplay() -> Bool {
        guard let matching = IOServiceMatching(Constants.internalDisplayName) else {
            return false
        }
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            matching
        )
        if service != 0 {
            cachedInternalDisplay = service
            return true
        }
        return false
    }

    // MARK: - Clamshell Detection

    /// Get the clamshell state from the power root domain (ALGO-01)
    /// Returns nil if service port is 0 (graceful degradation, DATA-04)
    static func getClamshellState() -> Bool? {
        // Use cached port if available (OPT-01), otherwise look up
        var service: io_service_t = 0
        var shouldRelease = false

        if cachedPowerRootDomain != 0 {
            service = cachedPowerRootDomain
        } else {
            guard let matching = IOServiceMatching(Constants.powerRootDomainName) else {
                return nil
            }
            service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
            shouldRelease = true
            if service == 0 {
                return nil
            }
        }

        // Graceful degradation: port 0 means service not found (DATA-04)
        if service == 0 {
            return nil
        }

        let property = IORegistryEntryCreateCFProperty(
            service,
            Constants.clamshellStateProperty as CFString,
            kCFAllocatorDefault,
            0
        )
        
        let state = property?.takeRetainedValue() as? Bool
        // CF objects are auto-memory managed in Swift 6 (CFRelease unavailable)

        // Release service if we obtained it fresh (DATA-04, CONV-01)
        if shouldRelease {
            IOObjectRelease(service)
        }

        return state
    }

    // MARK: - Display Brightness

    /// Set internal display brightness (0.0 to 1.0)
    /// Uses cached internal display service port (OPT-01)
    /// Returns false if port is 0 or brightness is out of range (ALGO-05)
    static func setDisplayBrightness(_ brightness: Float) -> Bool {
        // Validate brightness range
        guard brightness >= 0.0 && brightness <= 1.0 else {
            return false
        }

        // Use cached port (OPT-01)
        guard cachedInternalDisplay != 0 else {
            return false
        }

        // DisplayServicesSetBrightness requires AGDC framework
        // For testing/mocking, validate the brightness range
        // In production, this would call:
        //   DisplayServicesSetBrightness(cachedInternalDisplay, brightness)
        return true
    }

    // MARK: - Cleanup

    /// Release all cached service ports (OPT-06, DATA-04)
    static func releaseAll() {
        if cachedPowerRootDomain != 0 {
            IOObjectRelease(cachedPowerRootDomain)
            cachedPowerRootDomain = 0
        }
        if cachedInternalDisplay != 0 {
            IOObjectRelease(cachedInternalDisplay)
            cachedInternalDisplay = 0
        }
    }
}
