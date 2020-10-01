// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import CAudioKit

/// This is an implementation of Zoelzer's parametric equalizer filter.
public class HighShelfParametricEqualizerFilter: Node, AudioUnitContainer, Tappable, Toggleable {

    /// Unique four-letter identifier "peq2"
    public static let ComponentDescription = AudioComponentDescription(effect: "peq2")

    /// Internal type of audio unit for this node
    public typealias AudioUnitType = InternalAU

    /// Internal audio unit 
    public private(set) var internalAU: AudioUnitType?

    // MARK: - Parameters

    /// Specification details for centerFrequency
    public static let centerFrequencyDef = NodeParameterDef(
        identifier: "centerFrequency",
        name: "Corner Frequency (Hz)",
        address: akGetParameterAddress("HighShelfParametricEqualizerFilterParameterCenterFrequency"),
        range: 12.0 ... 20_000.0,
        unit: .hertz,
        flags: .default)

    /// Corner frequency.
    @Parameter public var centerFrequency: AUValue

    /// Specification details for gain
    public static let gainDef = NodeParameterDef(
        identifier: "gain",
        name: "Gain",
        address: akGetParameterAddress("HighShelfParametricEqualizerFilterParameterGain"),
        range: 0.0 ... 10.0,
        unit: .generic,
        flags: .default)

    /// Amount at which the corner frequency value shall be changed. A value of 1 is a flat response.
    @Parameter public var gain: AUValue

    /// Specification details for q
    public static let qDef = NodeParameterDef(
        identifier: "q",
        name: "Q",
        address: akGetParameterAddress("HighShelfParametricEqualizerFilterParameterQ"),
        range: 0.0 ... 2.0,
        unit: .generic,
        flags: .default)

    /// Q of the filter. sqrt(0.5) is no resonance.
    @Parameter public var q: AUValue

    // MARK: - Audio Unit

    /// Internal Audio Unit for HighShelfParametricEqualizerFilter
    public class InternalAU: AudioUnitBase {

        public override func getParameterDefs() -> [NodeParameterDef] {
            [HighShelfParametricEqualizerFilter.centerFrequencyDef,
             HighShelfParametricEqualizerFilter.gainDef,
             HighShelfParametricEqualizerFilter.qDef]
        }

        public override func createDSP() -> DSPRef {
            akCreateDSP("HighShelfParametricEqualizerFilterDSP")
        }
    }

    // MARK: - Initialization

    /// Initialize this equalizer node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - centerFrequency: Corner frequency.
    ///   - gain: Amount at which the corner frequency value shall be changed. A value of 1 is a flat response.
    ///   - q: Q of the filter. sqrt(0.5) is no resonance.
    ///
    public init(
        _ input: Node,
        centerFrequency: AUValue = 1_000,
        gain: AUValue = 1.0,
        q: AUValue = 0.707
        ) {
        super.init(avAudioNode: AVAudioNode())

        instantiateAudioUnit { avAudioUnit in
            self.avAudioUnit = avAudioUnit
            self.avAudioNode = avAudioUnit

            guard let audioUnit = avAudioUnit.auAudioUnit as? AudioUnitType else {
                fatalError("Couldn't create audio unit")
            }
            self.internalAU = audioUnit

            self.centerFrequency = centerFrequency
            self.gain = gain
            self.q = q
        }
        connections.append(input)
    }
}
