# Data Format and File Naming

## Raw measurement data

Each raw measurement file must contain three numeric columns in this order:

| Column | Variable | Unit | Description |
|---|---|---|---|
| 1 | `Frequency_Hz` | Hz | Lock-in reference frequency |
| 2 | `Amplitude_V` | V | Measured response magnitude |
| 3 | `Phase_deg` | degrees | Measured phase |

The acquisition script writes a CSV file with these headers and a MAT file containing the table and acquisition metadata. Legacy TXT files containing the same three numeric columns can also be loaded by the processing script.

## Processed impedance data

`calculate_complex_impedance.m` writes the following columns:

| Variable | Unit | Description |
|---|---|---|
| `Frequency_Hz` | Hz | Measured frequency |
| `AngularFrequency_rad_s` | rad/s | `2*pi*Frequency_Hz` |
| `Amplitude_V` | V | Lock-in magnitude |
| `Phase_deg` | degrees | Lock-in phase |
| `ImpedanceReal_Ohm` | Ω | Real part of complex impedance |
| `ImpedanceImag_Ohm` | Ω | Imaginary part of complex impedance |
| `ImpedanceMagnitude_Ohm` | Ω | Magnitude of complex impedance |
| `Capacitance_F` | F | Signed capacitance quantity calculated using the supplied equation |

The visualization script plots `-Capacitance_F`, matching the sign convention used in the supplied working MATLAB script.

## Recommended file naming

The acquisition script creates files in this pattern:

```text
<sampleID>_<YYYYMMDD_HHMMSS>_raw.csv
<sampleID>_<YYYYMMDD_HHMMSS>_raw.mat
```

For manual imports, use descriptive names that capture the sample and experimental configuration, for example:

```text
water_silver_electrodes_vertical_run01_raw.csv
ethanol_gold_nanoparticles_run02_raw.csv
```

Do not use a filename as the only record of experimental conditions. Record the sample composition, electrode material and orientation, electrode spacing, measurement resistor, temperature, illumination state, and other relevant conditions in a separate experiment log or metadata file.
