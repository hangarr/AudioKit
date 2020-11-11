Standalone Soundpipe 
====================
Soundpipe was absorbed into [AudioKit](https://github.com/AudioKit/AudioKit) at some point.  In late summer 2020 the Soundpipe components were re-segregated into a separate section of AudioKit (`AudioKit/Sources/soundpipe`).  

This version includes two added files:

- `Makefile`
- `config.def.mk`

these two files allow one to build a static shared object library for use in other projects without the rest of AudioKit. No claim is made here that this is an optimal `Makefile`.  One builds the static shared object library with:
```
> cd ./AudioKit/Sources/soundpipe
> make all
```
Optionally one could install the results in the C search path with

```
> make install
```
Generally this would be an unpreferred approach for using Soundpipe in non-AudioKit applications.


In the end there are several artifacts of interest:

1. `libsoundpipe.a *`
2. `libsoundpipe.so *`
3. `include/dr_wav.h *`
4. `include/kiss_fft.h`
5. `include/kiss_fftr.h`
6. `include/md5.h *`
7. `include/soundpipe.h *`
8. `include/vocwrapper.h`

At a minimum the five files marked "`*`" are needed to use Soundpipe in other applications.

About `dr_wav.h`
----------------

[`dr_wav.h`](https://mackron.github.io/dr_wav) is a standalone module for reading and writing `.wav` files.  This is a combined `.h` header and `.c` source file.  The file provides info how to build a `dr_wav.o` object from the file and then use the `dr_wav.h` file as a header file.  The `libsoundpipe.so` static shared object library includes a `dr_wav.o` object.

Other Resources
---------------

Once Soundpipe was absorbed into [AudioKit](https://github.com/AudioKit/AudioKit) the creator, Paul Batchelor, appears to have taken some of his info about Soundpipe down from the web.  Various copies can be found as of the time this fork was created whose Makefiles served as the starting point for the Makefile here.

- [narner/Soundpipe](https://github.com/narner/Soundpipe)
- [SeesePlusPlus/soundpipe](https://github.com/SeesePlusPlus/soundpipe)
- [eljeff/Soundpipe](https://github.com/eljeff/Soundpipe)
- [dan-f/Soundpipe](https://github.com/dan-f/Soundpipe)
- [alessandrostone/soundpipe-1](https://github.com/alessandrostone/soundpipe-1)
- [shybyte/soundpipe](https://github.com/shybyte/soundpipe)

Some useful background documentation is available here: [AudioKit Tutorial: Getting Started](https://www.raywenderlich.com/835-audiokit-tutorial-getting-started)


Soundpipe
=========

Soundpipe is a lightweight music DSP library written in C. It aims to provide
a set of high-quality DSP modules for composers, sound designers,
and creative coders. 

Soundpipe supports a wide range of synthesis and audio DSP 
techniques which include:

- Classic Filter Design (Moog, Butterworth, etc)
- High-precision and linearly interpolated wavetable oscillators
- Bandlimited oscillators (square, saw, triangle)
- FM synthesis
- Karplus-strong instruments
- Variable delay lines
- String resonators
- Spectral Resynthesis
- Partitioned Convolution
- Physical modeling
- Pitch tracking
- Distortion
- Reverberation
- Samplers / sample playback
- Padsynth algorithm
- Beat repeat
- Paulstretch algorithm
- FOF and FOG granular synthesis
- Time-domain pitch shifting

More information on specific Soundpipe modules can be found in the
[Soundpipe module reference guide](https://paulbatchelor.github.com/res/soundpipe/docs/).

Features
---------
- Sample accurate timing
- Small codebase
- Static library
- Easy to extend
- Easy to embed

The Soundpipe Model
-------------------

Soundpipe is callback driven. Every time Soundpipe needs a frame, it will
call upon a single function specified by the user. Soundpipe modules are
designed to process a signal one sample at a time.  Every module follows the
same life cycle:

1. Create: Memory is allocated for the data struct.
2. Initialize: Buffers are allocated, and initial variables and constants
are set.
3. Compute: the module takes in inputs (if applicable), and generates a
single sample of output.
4. Destroy: All memory allocated is freed.
