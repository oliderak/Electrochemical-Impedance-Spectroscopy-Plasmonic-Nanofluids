# Known Limitations and Items to Confirm

This repository is a structured and documented reconstruction of the MATLAB workflow represented by the supplied thesis and two MATLAB scripts. The following items remain open because the corresponding source information was not included or is inconsistent.

## 1. Experimental data files are missing

The uploaded files include the thesis PDF, the acquisition script, and the impedance-processing script. They do not include the original experimental TXT, CSV, or MAT datasets. In particular, the thesis Appendix A refers to measurement arrays `A`, `B`, `C`, and `D`; their source files were not supplied.

Consequences:

- The acquisition and processing workflows can be reviewed and run with new data.
- The reference-circuit and cell-model simulations can be run from the documented parameters.
- The original experimental comparison plots cannot be reproduced until the raw measurements are recovered.

## 2. Series-resistor value in the impedance equation

The separately uploaded working file `impedancia.m` uses `Rs = 50`. The thesis' impedance listing uses `Rs = 147`. The processing script in this repository defaults to 50 Ω because it matches the uploaded working file. Confirm the physical component value and the correct value for each experiment before final scientific interpretation.

## 3. Instrument model and command compatibility

The acquisition script retains the original VISA resource string `GPIB0::8::0::INSTR` and commands `FREQ` and `SNAP? 3,4`. The instrument model is not identified in the supplied files. Verify the resource address, command syntax, returned measurement fields, and output amplitude configuration against the instrument used in the laboratory.

## 4. Measurement labels and metadata

The original acquisition filename contains `ElectrAGVertical`, while the plot titles in the supplied impedance script refer to horizontal silver electrodes. The filename also contains `5000`, whose meaning is not documented in the supplied code. Confirm the sample identity, electrode orientation, and meaning of this token before reusing those labels.

## 5. RCR transfer-function listing

The RCR thesis listing defines a symbolic expression `H1`, but the actual frequency-response call uses the coefficient arrays `a` and `b`. The simulation script follows the active coefficient arrays. Compare the listing with the original circuit derivation and measurement topology before treating the transfer function as a definitive analytical model.

## 6. Cell model validation

The four parameter configurations are transcribed from Appendix A. The associated experimental data and the complete laboratory component records were not supplied. The simulations should therefore be described as reproductions of the thesis' model parameter sets, not as independently revalidated experimental fits.
