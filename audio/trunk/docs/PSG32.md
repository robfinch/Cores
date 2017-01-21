# Welcome to PSG Cores

PSG32 is a programmable sound generator or sound interface device.

# Features
-	four ADSR / wave table channels (“voices”)
-	programmable frequency and pulse width control
-	0.0116 Hz frequency resolution (with 50.0MHz clock)
-	attack, decay, sustain and release
-	test, ringmod, sync and gate controls
-	five voice types: triangle, sawtooth, pulse, noise and wave
-	FM synthesis
-	digital exponential decay and release modelling (2**n)
-	31 tap digital FIR filter

# Clocks

The PSG32 core uses two clocks. The first of which is the system bus clock. The second clock is a 50MHz timing reference clock. The 50MHz reference clock is used during tone and the envelope generation. In order to have consistent values for frequency settings and envelope settings between systems a 50MHz reference clock should be used.

## Computing Frequency Resolution

The frequency resolution depends on the core clock used. 32 bit harmonic synthesizers are used as frequency generators. The minimum frequency resolution is then the clock frequency divided by 2^32. For a 100MHz clock this would be 100MHz/(2^32) = 0.0233 Hz.

## Maximum Frequency Generated
The maximum frequency that can be generated is 2^20 * the minimum frequency resolution. For a 50MHz clock this would be 12.2kHz.

## Example Tone Frequency Calc.
For a tone of 1kHz with a 50MHz clock, the value needed in the frequency control register is 1kHz/0.0116 = 85899.

# Registers

reg |              bits                   | R/W | Brief
----|-------------------------------------|-----|-----------------------------
 00 | ........ ....nnnn nnnnnnnn nnnnnnnn | R/W | channel 0 frequency
 04 | ........ ........ pppppppp pppppppp | R/W | channel 0 pusle width
 08 |                   trsgFefo vvvvvv.. | R/W | channel 0 control
 0C |    aaaaa aaaaaaaa aaaaaaaa aaaaaaaa | R/W | channel 0 attack
 10 |          dddddddd dddddddd dddddddd | R/W | channel 0 decay
 14 |                            ssssssss | R/W | channel 0 sustain
 18 |          rrrrrrrr rrrrrrrr rrrrrrrr | R/W | channel 0 release
 1C |                   ..aaaaaa aaaaaaa. | R/W | channel 0 wave table address
 20 |              nnnn nnnnnnnn nnnnnnnn | R/W | channel 1 frequency
 24 |                   pppppppp pppppppp | R/W | channel 1 pusle width
 28 |                   trsgFefo vvvvvv-- | R/W | channel 1 control
 2C |    aaaaa aaaaaaaa aaaaaaaa aaaaaaaa | R/W | channel 1 attack
 30 |          dddddddd dddddddd dddddddd | R/W | channel 1 decay
 34 |                            ssssssss | R/W | channel 1 sustain
 38 |          rrrrrrrr rrrrrrrr rrrrrrrr | R/W | channel 1 release
 3C |                   ..aaaaaa aaaaaaa. | R/W | channel 1 wave table address
 40 |              nnnn nnnnnnnn nnnnnnnn | R/W | channel 2 frequency
 44 |                   pppppppp pppppppp | R/W | channel 2 pusle width
 48 |                   trsgFefo vvvvvv-- | R/W | channel 2 control
 4C |    aaaaa aaaaaaaa aaaaaaaa aaaaaaaa | R/W | channel 2 attack
 50 |          dddddddd dddddddd dddddddd | R/W | channel 2 decay
 54 |                            ssssssss | R/W | channel 2 sustain
 58 |          rrrrrrrr rrrrrrrr rrrrrrrr | R/W | channel 2 release
 5C |                   ..aaaaaa aaaaaaa. | R/W | channel 2 wave table address
 60 |              nnnn nnnnnnnn nnnnnnnn | R/W | channel 3 frequency
 64 |                   pppppppp pppppppp | R/W | channel 3 pusle width
 68 |                   trsgFefo vvvvvv-- | R/W | channel 3 control
 6C |    aaaaa aaaaaaaa aaaaaaaa aaaaaaaa | R/W | channel 3 attack
 70 |          dddddddd dddddddd dddddddd | R/W | channel 3 decay
 74 |                            ssssssss | R/W | channel 3 sustain
 78 |          rrrrrrrr rrrrrrrr rrrrrrrr | R/W | channel 3 release
 7C |                   ..aaaaaa aaaaaaa. | R/W | channel 3 wave table address
 B0 |                                mmmm | R/W | master volume
 B4 | nnnnnnnn nnnnnnnn nnnnnnnn nnnnnnnn |  R  | oscillator 3 output
 B8 |                            nnnnnnnn |  R  | envelope 3 output
 BC |                   .sss.sss .sss.sss |  R  | envelope state
 C0 |                   RRRRRRRR RRRRRRRR | R/W | filter sample clock rate divider
100-178 |                   s...kkkk kkkkkkkk |  W  | filter coefficients

## Frequency Register

This register sets the tone frequency for the voice. In order to set the frequency specify a value that is a multiple of the base frequency step. For example for an 800 Hz tone with a 50MHz clock, 800/0.0116 = 68719 would need to be specified.

## Pulse Width Register

This register controls the pulse-width when the pulse output waveform is selected. Pulse frequency is controlled by the frequency register.

## Control Register

‘o’ bit enables the output for the voice
‘e’ bit when set routes the tone generator through the envelope generator. When clear the raw tone generator is used without an envelope. This is primarily for debugging.
‘F’ bit tells the PSG to use the previous channels output to frequency modulate this channel.
‘f’ bit tells the sound generator to route the voice’s output to the filter
‘vvvvvv’ sets the output voice type
101000 = reverse sawtooth
010000 = triangle wave
001000 = sawtooth wave
000100 = pulse (or possibly square) 
000010 = noise
000001 = wave 
‘g’ bit ‘gates’ the envelop generator which when set causes it to begin generating the envelope for the voice. When the gate is turned off, the envelope generator enters the release phase.


## ADSR Register

Rate Divider Values (decay and release)
The value required in the rate register can be calculated as:

reg value = 1/(1/clock frequency)/desired time)/256
Example: reg value = 1/(1/100e6) / 2e-3)/256
		       = 781.25

## ‘a’ - Attack

The attack code controls the attack rate of the sound envelope. The attack slope is triggered when the gate signal is activated. The envelope travels from a zero level to it’s peak during the attack phase.


## ‘d’ = Decay

The decay code controls the decay rate of the sound envelope just after the peak has been reached from the attack phase. The envelop decays from it’s peak value down to the value set by the sustain code.

## ‘s’ = Sustain

Sustain sets the signal level at which the signal is ‘sustained’ relative to it’s peak value. There are 255 sustain levels from 0x0 to 0xFF with 0x0 being the lowest and 0xFF the maximum.

## ‘r’ = Release

The release code controls the rate at which the signal is ‘released’ after the gate is turned off. When the gate signal is made inactive, the release phase of the ADSR envelope begins.  This is an exponential of 2 release.

## Wave Table Base Address
This register sets the beginning address for the wave table scan. Data values are read offset from this address by the output of the tone generator bits 17 to 27. Up to 2047 samples may be scanned. A repeating linear scan of the wave table can be accomplished by setting the tone generator to generate a sawtooth waveform.

## Global Registers
A0,A4,A8,AC – these are 32 bit scratchpad registers which may be used to store data.
B0h – VOL – master volume.
BCh - ES – reflects the envelope state for each of the four envelope generators.

# I/O Ports
I/O is via a standard WISHBONE slave port with the addition of a circuit select line. An additional non-WISHBONE port is used to access the wave table memory. All accesses are 32 bit word wide accesses.
Reading the PSG has a three cycle latency before the core responds with an ack. Writing the PSG is single cycle.

Name    | Wid | I/O | Description
--------|-----|-----|--------------------------------
rst_i   |  1  |  I  | synchronous reset (active high)
clk_i   |  1  |  I  | system bus clock
clk50_i |  1  |  I  | 50MHz reference clock
s_cs_i  |  1  |  I  | circuit select
s_cyc_i |  1  |  I  | cycle active
s_stb_i |  1  |  I  | data strobe
s_ack_o |  1  |  O  | data transfer acknowledge
s_we_i  |  1  |  I  | write cycle
s_adr_i |  9  |  I  | register address, 2LSB's not used
s_dat_i | 32  |  I  | data input to core
s_dat_o | 32  |  O  | data output from core
m_adr_o | 14  |  O  | wave table address output
m_dat_i | 12  |  I  | wave table data input
o       | 18  |  O  | audio output

# Operation:

## Frequency Synthesis

The PSG uses a harmonic frequency synthesizer with a 32 bit accumulator. This gives the generator a base frequency step of 0.0116Hz. (50e6 / 2^32). The upper bits of the accumulator are used as a source for audio waves.

## FM Synthesis
Tone generators may be linked together for FM synthesis. Setting the ‘F’ bit in the channel control register links in the previous channels tone generator as a source for FM modulation of the tone. FM modulation can be used to generate complex waveforms.

## Wave Table
It is anticipated that the PSG core will be used in a system where dual port block memories are available and so the PSG core has a dedicated bus for the wave table memory. It’s assumed that the wave table memory is capable of an access every clock cycle. The PSG uses the tone generator accumulator to generate 11 bit address offsets from which to read. The address used is the sum of the wave table base address register and 11 bits from the tone generator. Up to 16kiB of wave table memory is supported, allowing several different waveforms to be stored simultaneously. Access to the wave table is pipelined. Each channel of the PSG is given access to the wave table on successive clock cycles. Three clock cycles later data for the channel is latched in. There must be a memory latency of three clock cycles for wave table memory in order for the PSG’s wave input to work correctly. Note that data is latched on every clock cycle for successive channels.
The wave table is always being addressed by the core, however data latched in is not used unless selected in the control register for the channel. The wave table can be scanned at different rates depending on the frequency the channel is setup for. The same data value will be loaded from the wave table if the address does not change. The address may not change every clock cycle, however data will still be latched in.

## Filter
The filter is a time domain multiplexed (TDM) filter in order to conserve resources. A digital FIR (finite impulse response) filter is used.

### Filter Sample Frequency
The filter’s sampling frequency is one of the characteristics controlling filter output. The sampling frequency factors into the calculations for the filter coefficients.

The sample frequency of the filter may be set using a sixteen bit control register which contains a clock divider value. This register is provided to make it easier to use the same filter coefficients in systems with different clock rates. The filter sample rate should be set to a rate substantially higher than the highest frequency to be filtered. For example 100kHz. To get a 100kHz sample rate from a 50MHz clock the clock needs to be divided by 500. So the clock rate divider (CRD) register should be set to 500.

### Taps
The filter contains a number of taps, which are points at which filter coefficients are applied to the input signal. The filter has a fixed number of 31 taps. Filter coefficients must be supplied for each tap.

### Filter Coefficients
The filter coefficients control the resulting type of filter (low pass, band pass, high pass, band stop) and the frequency response of the filter. The filter coefficients are 12 fractional bits plus a sign bit. Filter coefficients range in value from -.9999 to +.9999
