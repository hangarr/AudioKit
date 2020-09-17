// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import CAudioKit

/// This is an oscillator with linear interpolation that is capable of morphing
/// between an arbitrary number of wavetables.
/// 
public class MorphingOscillator: Node, AudioUnitContainer, Toggleable {

    public static let ComponentDescription = AudioComponentDescription(generator: "morf")

    public typealias AudioUnitType = InternalAU

    public private(set) var internalAU: AudioUnitType?

    // MARK: - Parameters

    fileprivate var waveformArray = [Table]()

    public static let frequencyDef = NodeParameterDef(
        identifier: "frequency",
        name: "Frequency (in Hz)",
        address: akGetParameterAddress("MorphingOscillatorParameterFrequency"),
        range: 0.0 ... 22_050.0,
        unit: .hertz,
        flags: .default)

    /// Frequency (in Hz)
    @Parameter public var frequency: AUValue

    public static let amplitudeDef = NodeParameterDef(
        identifier: "amplitude",
        name: "Amplitude (typically a value between 0 and 1).",
        address: akGetParameterAddress("MorphingOscillatorParameterAmplitude"),
        range: 0.0 ... 1.0,
        unit: .hertz,
        flags: .default)

    /// Amplitude (typically a value between 0 and 1).
    @Parameter public var amplitude: AUValue

    public static let indexDef = NodeParameterDef(
        identifier: "index",
        name: "Index of the wavetable to use (fractional are okay).",
        address: akGetParameterAddress("MorphingOscillatorParameterIndex"),
        range: 0.0 ... 1_000.0,
        unit: .hertz,
        flags: .default)

    /// Index of the wavetable to use (fractional are okay).
    @Parameter public var index: AUValue

    public static let detuningOffsetDef = NodeParameterDef(
        identifier: "detuningOffset",
        name: "Frequency offset (Hz)",
        address: akGetParameterAddress("MorphingOscillatorParameterDetuningOffset"),
        range: -1_000.0 ... 1_000.0,
        unit: .hertz,
        flags: .default)

    /// Frequency offset in Hz.
    @Parameter public var detuningOffset: AUValue

    public static let detuningMultiplierDef = NodeParameterDef(
        identifier: "detuningMultiplier",
        name: "Frequency detuning multiplier",
        address: akGetParameterAddress("MorphingOscillatorParameterDetuningMultiplier"),
        range: 0.9 ... 1.11,
        unit: .generic,
        flags: .default)

    /// Frequency detuning multiplier
    @Parameter public var detuningMultiplier: AUValue

    // MARK: - Audio Unit

    public class InternalAU: AudioUnitBase {

        public override func getParameterDefs() -> [NodeParameterDef] {
            [MorphingOscillator.frequencyDef,
             MorphingOscillator.amplitudeDef,
             MorphingOscillator.indexDef,
             MorphingOscillator.detuningOffsetDef,
             MorphingOscillator.detuningMultiplierDef]
        }

        public override func createDSP() -> AKDSPRef {
            akCreateDSP("MorphingOscillatorDSP")
        }
    }

    // MARK: - Initialization

    /// Initialize this Morpher node
    ///
    /// - Parameters:
    ///   - waveformArray: An array of exactly four waveforms
    ///   - frequency: Frequency (in Hz)
    ///   - amplitude: Amplitude (typically a value between 0 and 1).
    ///   - index: Index of the wavetable to use (fractional are okay).
    ///   - detuningOffset: Frequency offset in Hz.
    ///   - detuningMultiplier: Frequency detuning multiplier
    ///
    public init(
        waveformArray: [Table] = [Table(.triangle), Table(.square), Table(.sine), Table(.sawtooth)],
        frequency: AUValue = 440,
        amplitude: AUValue = 0.5,
        index: AUValue = 0.0,
        detuningOffset: AUValue = 0,
        detuningMultiplier: AUValue = 1
    ) {
        super.init(avAudioNode: AVAudioNode())

        instantiateAudioUnit { avAudioUnit in
            self.avAudioUnit = avAudioUnit
            self.avAudioNode = avAudioUnit

            guard let audioUnit = avAudioUnit.auAudioUnit as? AudioUnitType else {
                fatalError("Couldn't create audio unit")
            }
            self.internalAU = audioUnit

            for (i, waveform) in waveformArray.enumerated() {
                self.internalAU?.setWavetable(waveform.content, index: i)
            }
            self.waveformArray = waveformArray 
            self.frequency = frequency
            self.amplitude = amplitude
            self.index = index
            self.detuningOffset = detuningOffset
            self.detuningMultiplier = detuningMultiplier
        }

    }
}
