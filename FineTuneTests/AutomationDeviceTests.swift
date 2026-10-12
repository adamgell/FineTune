import Foundation
import Testing
@testable import FineTune

@Suite("Device and routing automation") @MainActor
struct AutomationDeviceTests {
    @Test func missingDeviceDoesNotMutate() async {
        let e = makeAutomationEngine(); let s = AutomationService(engine: e)
        let r = await s.execute(.init(id: "1", method: "device.volume.set", params: ["target": .object(["deviceUID": .string("absent")]), "percent": .number(25)]))
        #expect(r.error?.code == .unavailable)
        #expect(e.deviceVolumeMonitor.volumes.isEmpty)
    }
    @Test func routesInactiveOnlyWithOfflinePermission() async {
        let e = makeAutomationEngine(); let s = AutomationService(engine: e)
        let params: [String: AutomationValue] = ["target": .object(["appId": .string("com.test.player")]), "mode": .string("single"), "deviceUIDs": .array([.string("offline")])]
        let denied = await s.execute(.init(id: "1", method: "app.routing.set", params: params))
        #expect(denied.error?.code == .unavailable)
        #expect(e.settingsManager.getDeviceRouting(for: "com.test.player") == nil)
        var allowed = params; allowed["allowOffline"] = .bool(true)
        let r = await s.execute(.init(id: "2", method: "app.routing.set", params: allowed))
        #expect(r.result?.object?["status"] == .string("stored"))
        #expect(e.settingsManager.getDeviceRouting(for: "com.test.player") == "offline")
    }
    @Test func rejectsRoutingBeforeChangingMode() async {
        let e = makeAutomationEngine(); let s = AutomationService(engine: e)
        let r = await s.execute(.init(id: "1", method: "app.routing.set", params: ["target": .object(["appId": .string("com.test.player")]), "mode": .string("multi"), "deviceUIDs": .array([])]))
        #expect(r.error?.code == .invalidParameter)
        #expect(e.getDeviceSelectionModeForInactive(identifier: "com.test.player") == .single)
    }
    @Test func deviceManagementKeepsDirectionSeparate() async {
        let e = makeAutomationEngine(); let s = AutomationService(engine: e)
        _ = await s.execute(.init(id: "1", method: "device.hidden.set", params: ["target": .object(["deviceUID": .string("offline"), "direction": .string("input")]), "hidden": .bool(true)]))
        #expect(e.settingsManager.hiddenInputDeviceUIDs.contains("offline"))
        #expect(!e.settingsManager.hiddenOutputDeviceUIDs.contains("offline"))
    }
}
