import Foundation

@MainActor
protocol AutomationAdapter: AnyObject {
    var descriptors: [AutomationDescriptor] { get }
    func execute(method: String, params: [String: AutomationValue]) async throws -> AutomationValue
    func snapshot() -> AutomationValue
}

/// Transport-independent command boundary. Never called from an audio callback.
@MainActor
final class AutomationService {
    let engine: AudioEngine
    let appAdapter: AppAutomationAdapter
    var adapters: [any AutomationAdapter]
    let instanceId = UUID().uuidString
    private(set) var revision = 0
    private var lastState: AutomationValue = .null
    init(engine: AudioEngine, resolver: (any TargetAppResolving)? = nil) {
        self.engine = engine
        let adapter = AppAutomationAdapter(engine: engine, resolver: resolver)
        self.appAdapter = adapter; self.adapters = [adapter, DeviceAutomationAdapter(engine: engine), RoutingAutomationAdapter(engine: engine, apps: adapter)]
    }
    func snapshot() -> AutomationValue {
        let data = AutomationValue.object(Dictionary(uniqueKeysWithValues: adapters.enumerated().map { ("\($0.offset)", $0.element.snapshot()) }))
        if data != lastState { revision += 1; lastState = data }
        return .object(["instanceId": .string(instanceId), "revision": .number(Double(revision)), "state": data])
    }
    func execute(_ request: AutomationRequest) async -> AutomationResponse {
        do {
            try request.validate()
            let result: AutomationValue
            switch request.method {
            case "api.describe":
                result = .object(["apiVersion": .number(1), "instanceId": .string(instanceId), "methods": try .encode(adapters.flatMap(\.descriptors))])
            case "state.get": result = snapshot()
            default:
                guard let adapter = adapters.first(where: { $0.descriptors.contains(where: { $0.method == request.method }) }) else { throw AutomationError(.unknownMethod, "Unknown automation method") }
                result = try await adapter.execute(method: request.method, params: request.params)
            }
            _ = snapshot()
            var object = result.object ?? ["value": result]
            object["revision"] = .number(Double(revision)); object["instanceId"] = .string(instanceId)
            return .init(id: request.id, result: .object(object))
        } catch let error as AutomationError { return .init(id: request.id, error: error) }
        catch { return .init(id: request.id, error: .init(.internalError, "Automation operation failed")) }
    }
}
