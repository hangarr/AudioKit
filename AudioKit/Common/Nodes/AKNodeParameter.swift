// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

/// AKNodeParameter wraps AUParameter in a user-friendly interface and adds some AudioKit-specific functionality.
/// New version for use with Parameter property wrapper.
public class AKNodeParameter {

    private var dsp: AKDSPRef?
    private var avAudioUnit: AVAudioUnit!

    public private(set) var parameter: AUParameter?

    // MARK: Parameter properties

    public var value: AUValue = 0 {
        didSet {
            guard let min = parameter?.minValue, let max = parameter?.maxValue else { return }
            value = (min...max).clamp(value)
            if value == oldValue { return }
            parameter?.value = value
        }
    }

    public var boolValue: Bool {
        get { value > 0.5 }
        set { value = newValue ? 1.0 : 0.0 }
    }

    public var minValue: AUValue {
        parameter?.minValue ?? 0
    }

    public var maxValue: AUValue {
        parameter?.maxValue ?? 1
    }

    public var range: ClosedRange<AUValue> {
        (parameter?.minValue ?? 0) ... (parameter?.maxValue ?? 1)
    }

    public var rampDuration: Float = Float(AKSettings.rampDuration) {
        didSet {
            guard let dsp = dsp, let addr = parameter?.address else { return }
            setParameterRampDurationDSP(dsp, addr, rampDuration)
        }
    }

    public var rampTaper: Float = 1 {
        didSet {
            guard let dsp = dsp, let addr = parameter?.address else { return }
            setParameterRampTaperDSP(dsp, addr, rampTaper)
        }
    }

    public var rampSkew: Float = 0 {
        didSet {
            guard let dsp = dsp, let addr = parameter?.address else { return }
            setParameterRampSkewDSP(dsp, addr, rampSkew)
        }
    }

    // MARK: Automation

    private var renderObserverToken: Int?

    /// Begin automation immediately.
    ///
    /// Time is relative to the approximate time when the function
    /// is called. This is only sample accurate if called prior to `AKManager.start()`.
    /// - Parameter points: automation curve
    public func automate(points: [AKParameterAutomationPoint]) {
        var lastTime = avAudioUnit.lastRenderTime ?? AVAudioTime(sampleTime: 0, atRate: AKSettings.sampleRate)
        guard let parameter = parameter else { return }

        // In tests, we may not have a valid lastRenderTime, so
        // assume no rendering has yet occurred.
        if !lastTime.isSampleTimeValid {
            lastTime = AVAudioTime(sampleTime: 0, atRate: AKSettings.sampleRate)
            assert(lastTime.isSampleTimeValid)
        }

        stopAutomation()

        points.withUnsafeBufferPointer { automationPtr in

            guard let automationBaseAddress = automationPtr.baseAddress else { return }

            guard let observer = AKParameterAutomationGetRenderObserver(parameter.address,
                                                                  avAudioUnit.auAudioUnit.scheduleParameterBlock,
                                                                  AKSettings.sampleRate,
                                                                  Double(lastTime.sampleTime),
                                                                  automationBaseAddress,
                                                                  points.count) else { return }

            renderObserverToken = avAudioUnit.auAudioUnit.token(byAddingRenderObserver: observer)
        }

    }

    public func stopAutomation() {

        if let token = renderObserverToken {
            avAudioUnit.auAudioUnit.removeRenderObserver(token)
        }

    }

    private var parameterObserverToken: AUParameterObserverToken?

    /// Records automation for this parameter.
    /// - Parameter callback: Called on the main queue for each parameter event.
    public func recordAutomation(callback: @escaping (AUParameterAutomationEvent) -> Void) {

        guard let parameter = parameter else { return }
        parameterObserverToken = parameter.token(byAddingParameterAutomationObserver: { (numberEvents, events) in

            for index in 0..<numberEvents {
                let event = events[index]

                // Dispatching to main thread avoids the restrictions
                // required of parameter automation observers.
                DispatchQueue.main.async {
                    callback(event)
                }

            }
        })
    }

    /// Stop calling the function passed to `recordAutomation`
    public func stopRecording() {

        guard let parameter = parameter else { return }

        if let token = parameterObserverToken {
            parameter.removeParameterObserver(token)
        }
    }

    // MARK: Lifecycle

    /// This function should be called from AKNode subclasses as soon as a valid AU is obtained
    public func associate(with avAudioUnit: AVAudioUnit,
                          identifier: String) {

        self.avAudioUnit = avAudioUnit
        guard let akAudioUnit = avAudioUnit.auAudioUnit as? AKAudioUnitBase else {
            fatalError("AUAudioUnit is not an AKAudioUnitBase")
        }
        dsp = akAudioUnit.dsp
        parameter = akAudioUnit.parameterTree?[identifier]
        assert(parameter != nil)

        guard let dsp = dsp, let addr = parameter?.address else { return }
        setParameterRampDurationDSP(dsp, addr, rampDuration)
        setParameterRampTaperDSP(dsp, addr, rampTaper)
        setParameterRampSkewDSP(dsp, addr, rampSkew)

        guard let min = parameter?.minValue, let max = parameter?.maxValue else { return }
        parameter?.value = (min...max).clamp(value)
    }

    /// Sends a .touch event to the parameter automation observer, beginning automation recording if
    /// enabled in AKParameterAutomation.
    /// A value may be passed as the initial automation value. The current value is used if none is passed.
    public func beginTouch(value: AUValue? = nil) {
        guard let value = value ?? parameter?.value else { return }
        parameter?.setValue(value, originator: nil, atHostTime: 0, eventType: .touch)
    }

    /// Sends a .release event to the parameter observation observer, ending any automation recording.
    /// A value may be passed as the final automation value. The current value is used if none is passed.
    public func endTouch(value: AUValue? = nil) {
        guard let value = value ?? parameter?.value else { return }
        parameter?.setValue(value, originator: nil, atHostTime: 0, eventType: .release)
    }
}

/// Base protocol for any type supported by @Parameter
public protocol AKNodeParameterType {
    func toAUValue() -> AUValue
    init(_ value: AUValue)
}

extension Bool: AKNodeParameterType {
    public func toAUValue() -> AUValue {
        self ? 1.0 : 0.0
    }
    public init(_ value: AUValue) {
        self = value > 0.5
    }
}

extension AUValue: AKNodeParameterType {
    public func toAUValue() -> AUValue {
        self
    }
}

/// Used internally so we can iterate over parameters using reflection.
protocol ParameterBase {
    var projectedValue: AKNodeParameter { get }
}

/// Wraps AKNodeParameter so we can easily assign values to it.
///
/// Instead of`osc.frequency.value = 440`, we have `osc.frequency = 440`
///
/// Use the $ operator to access the underlying AKNodeParameter. For example:
/// `osc.$frequency.maxValue`
///
/// When writing an AKNode, use:
/// ```
/// @Parameter var myParameterName: AUValue
/// ```
/// This syntax gives us additional flexibility for how parameters are implemented internally.
@propertyWrapper
public struct Parameter<Value: AKNodeParameterType>: ParameterBase {

    var param = AKNodeParameter()

    public init() { }

    public init(wrappedValue: Value) {
        param.value = wrappedValue.toAUValue()
    }

    public var wrappedValue: Value {
        get { Value(param.value) }
        set { param.value = newValue.toAUValue() }
    }

    public var projectedValue: AKNodeParameter {
        get { param }
        set { param = newValue }
    }
}