# Electrical Impedance Analysis of Plasmonic Nanofluids

MATLAB code and documentation for the experimental acquisition, complex-impedance processing, data visualization, and reference-circuit simulations used in the undergraduate thesis **“Analísis de la respuesta electrica de ciclos térmicos inducidos por luz en nanofluídos plasmónicos.”**

The repository is organized so that acquisition, impedance calculation, plotting, and circuit simulation can be run independently.

## Research workflow

1. **Acquire raw data** from a Lock-in amplifier using a logarithmic frequency sweep from **10 Hz to 100 kHz** with **200 points**.
2. **Calculate complex impedance** from the measured magnitude and phase, using the circuit parameters specified in the analysis script.
3. **Generate impedance plots** in a separate MATLAB script.
4. **Simulate reference circuits** (RC and RCR) and the four configurations of the measurement-cell equivalent model in one consolidated simulation script.

## Frequency sweep

The acquisition and simulation scripts use the same frequency definition:

```matlab
frequency_Hz = logspace(log10(10), log10(100e3), 200).';
omega_rad_s = 2*pi*frequency_Hz;
```

This produces 200 logarithmically spaced points from 10 Hz through **100,000 Hz (100 kHz)**. Frequency is stored and plotted in Hz; angular frequency is calculated separately in rad/s when required by the impedance equations.

## Repository structure

```text
plasmonic-nanofluid-impedance-analysis/
├── README.md
├── CITATION.cff
├── .gitignore
├── src/
│   ├── acquisition/
│   │   └── acquire_lockin_sweep.m
│   ├── analysis/
│   │   └── calculate_complex_impedance.m
│   ├── visualization/
│   │   └── plot_impedance_results.m
│   ├── simulation/
│   │   └── simulate_reference_circuits.m
│   └── original/
│       └── README.md
├── data/
│   ├── raw/
│   ├── processed/
│   └── experiment_metadata_template.csv
├── results/
│   ├── figures/
│   └── simulation_data/
└── docs/
    ├── experimental_method.md
    ├── electrical_models.md
    ├── data_format.md
    ├── thesis_reference.md
    ├── known_limitations.md
    ├── github_upload.md
    └── figures/
        ├── rc_circuit.png
        ├── rcr_circuit.png
        ├── measurement_cell_equivalent_circuit.png
        ├── experimental_setup.png
        └── source/
```

## Requirements

### MATLAB

- MATLAB R2019a or later is recommended for `readmatrix`, tables, and the supplied scripts.
- **Acquisition only:** Instrument Control Toolbox and NI-VISA must be installed and configured.
- The acquisition script uses MATLAB's legacy VISA interface (`visa`, `fopen`, `fprintf`, `fscanf`).
- The simulation script uses base MATLAB polynomial evaluation (`polyval`) and does not require Symbolic Math Toolbox or Control System Toolbox.

### Instrument configuration

The original acquisition code uses the VISA resource `GPIB0::8::0::INSTR` and the Lock-in commands `FREQ` and `SNAP? 3,4`. These settings are retained as defaults. Confirm the resource string and command compatibility with the actual instrument before running the script. The instrument model is not identified in the supplied source files.

Set the Lock-in reference/output amplitude to **0.1 V** before acquisition. The acquisition script records this value as metadata; it does not configure the instrument's output amplitude.

## How to run

Run each script from MATLAB. Scripts are independent and should be run in this order when processing a new experimental measurement.

### 1. Acquire data

Open and run:

```text
src/acquisition/acquire_lockin_sweep.m
```

Before running, edit `sampleID` if needed and confirm `visaResource`. The script performs the 10 Hz–100 kHz sweep, reads magnitude and phase using `SNAP? 3,4`, and saves both CSV and MAT files in `data/raw/`.

### 2. Calculate impedance

Open and run:

```text
src/analysis/calculate_complex_impedance.m
```

Select a raw CSV or TXT file. The script calculates complex impedance and capacitance, then saves processed CSV and MAT files in `data/processed/`.

### 3. Plot impedance results

Open and run:

```text
src/visualization/plot_impedance_results.m
```

Select a processed impedance CSV. Four figures are generated and saved as 300 dpi PNG files and editable MATLAB FIG files in `results/figures/impedance/`.

### 4. Run circuit simulations

Open and run:

```text
src/simulation/simulate_reference_circuits.m
```

The script simulates the RC reference circuit, the RCR reference circuit, and all four measurement-cell model configurations. Figures are saved in `results/figures/simulations/`; numerical results and parameter tables are saved in `results/simulation_data/`.

## Impedance-processing parameters

The supplied working script uses the following defaults:

| Parameter | Default | Meaning |
|---|---:|---|
| Reference amplitude, `V` | 0.1 V | Lock-in reference amplitude |
| Measurement resistor, `R` | 330 kΩ | Measurement resistor in the supplied impedance equation |
| Series resistor, `Rs` | 50 Ω | Value in the uploaded working `impedancia.m` |
| Parasitic capacitance, `Cp` | 25 pF | Capacitance used in the supplied impedance equation |

**Parameter requiring confirmation:** the thesis code listing reports `Rs = 147 Ω`, while the separately supplied working `impedancia.m` reports `Rs = 50 Ω`. The processing script intentionally defaults to 50 Ω to match the uploaded working file. Confirm the physical resistor and update the parameter before treating the calculated impedance as final.

## Circuit-simulation parameters

| Model | Parameters from the thesis |
|---|---|
| RC | `R = 100 Ω`, `C = 20 µF`, `Vref = 0.1 V` |
| RCR | `R = 100 Ω`, `R2 = 10 Ω`, `C = 20 µF`, `Vref = 0.1 V` |
| Cell configuration 1 | `R = 100 kΩ`, `C1 = 1 nF`, `C2 = 10 nF`, `C3 = 1 nF`, `R2 = 1 kΩ` |
| Cell configuration 2 | `R = 100 kΩ`, `C1 = 8.2 nF`, `C2 = 10 nF`, `C3 = 8.2 nF`, `R2 = 178 Ω` |
| Cell configuration 3 | `R = 100 kΩ`, `C1 = 100 nF`, `C2 = 10 nF`, `C3 = 100 nF`, `R2 = 178 Ω` |
| Cell configuration 4 | `R = 100 kΩ`, `C1 = 100 nF`, `C2 = 10 nF`, `C3 = 100 nF`, `R2 = 1 kΩ` |

The source-equation details and a note about the original RCR listing are documented in [`docs/electrical_models.md`](docs/electrical_models.md).

## Data availability

No experimental raw-data files were included with the thesis and two MATLAB scripts supplied for this repository build. The repository therefore contains the processing workflow and simulations, but does not claim to reproduce experimental curves that depend on missing datasets. Add the original CSV, TXT, or MAT measurements to `data/raw/` when available. See [`docs/known_limitations.md`](docs/known_limitations.md).

## Figures and thesis provenance

English-language schematic figures are provided in `docs/figures/`. Verbatim crops extracted from the supplied thesis are retained in `docs/figures/source/` for traceability. The English schematics are clean redraws based on the corresponding thesis figures; they are not new experimental measurements.

## Academic reference

Oliverio Castillo Rocha, *Analísis de la respuesta electrica de ciclos térmicos inducidos por luz en nanofluídos plasmónicos.*, undergraduate thesis, Universidad Autónoma de Querétaro, Facultad de Ingeniería, Ingeniería Física. See [`docs/thesis_reference.md`](docs/thesis_reference.md) for the bibliographic details available in the supplied PDF. For upload instructions, see [`docs/github_upload.md`](docs/github_upload.md).
