# Near-Real-Time ISAC-Based Jammer Detection and Localization using OCUDU
**Rice University | Master of ECE | Fall 2026**

**Team:** Aniket Jadhav, Samanvitha Balijepalli, Sandra Mansour  
**Advisor:** Dr. Rahman Doost-Mohammady

---

## Overview
This project develops a software-based 5G framework for jammer detection and
localization that reuses the communication infrastructure instead of dedicated
sensing hardware.

- **Phase 1 (Spring 2026):** a controlled ZeroMQ testbed on srsRAN. Quiet symbols
  reserved in the 5G NR frame (~1.4% overhead) fed SNR and jammer power into
  threshold detectors, and a MUSIC angle-of-arrival (AoA) baseline was validated
  in simulation.
- **Phase 2 (Fall 2026, current):** a live over-the-air 5G NR testbed on band n78
  using a modified OCUDU gNB on a USRP B210, a Quectel 5G modem as the UE, and an
  ADALM-Pluto as the jammer. A read-only tap inside the gNB's upper PHY records
  the full frequency-domain uplink grid on every slot. Slots in which the UE is
  silent contain only noise, interference, and the jammer, and are used for
  detection and for AoA estimation from the phase difference between the two
  receive antennas.

**Current hardware results (single runs, jammer about 30 cm from the gNB, UE about 2 m):**
- The interference floor in UE-silent slots rises by 5.9 dB when the jammer turns
  on (0.0014 to 0.0053).
- Spatial coherence between the two receive antennas rises from about 0.12 to 0.9.
- The calibrated AoA moves from -49.3 deg to +28.0 deg (about 77 deg) when the
  jammer is moved between two positions.

**Next phase:** two base stations, each with a 2x2 antenna array, using ESPRIT for
azimuth and elevation and triangulation for 3D (x, y, z) localization, then
integration as a Near-RT RIC xApp.

---

## System Architecture

### Phase 2 (hardware, current)
- **Core network:** Open5GS
- **gNB:** OCUDU (srsRAN Project fork) with a modified scheduler and a per-slot uplink tap
- **gNB radio:** USRP B210 (2 receive antennas)
- **UE:** Quectel RM520N-GL 5G modem, uplink traffic from iperf3
- **Jammer:** ADALM-Pluto, broadband noise, co-channel on n78
- **RF transport:** over the air
- **Post-processing:** Python (capture, calibration, AoA, detection analysis)

### Phase 1 (simulation, Spring 2026)
- **gNB:** srsRAN Project (modified scheduler + IQ capture)
- **UE:** srsUE (srsRAN 4G)
- **RF transport:** ZeroMQ
- **Post-processing:** Python + MATLAB

---

## Radio Configuration

| Parameter | Phase 2 (hardware) | Phase 1 (ZMQ) |
|-----------|--------------------|---------------|
| Band | n78 | NR Band 3 |
| Center frequency | 3489.42 MHz | 1842.5 MHz |
| Bandwidth | 20 MHz | 20 MHz |
| Subcarrier spacing | 30 kHz | 30 kHz |
| Duplex | TDD | TDD |
| gNB receive antennas | 2 (USRP B210) | 1 |
| Subcarriers captured | 612 per receive port | n/a |

---

## Methods
- **Sensing-slot capture:** a scheduler modification that reserves symbols on every
  fourth slot, and a per-slot uplink tap that captures every received uplink slot,
  scheduled or not. Both are enabled by environment flags
  (`OCUDU_RESERVE_SYM9`, `OCUDU_UL_TAP`).
- **Detection:** interference floor in the quietest slots, spatial coherence, and
  eigenvalue ratio of the 2x2 spatial covariance matrix.
- **Localization:** phase-difference AoA with a one-time hardware phase calibration
  (phi0 = -1.857 rad).
- **Planned:** 2D ESPRIT on a 2x2 array and least-squares triangulation from two stations.

---

## Key Results

### Phase 2 (hardware, single runs)
| Metric | Jammer OFF | Jammer ON |
|--------|-----------|-----------|
| Idle-slot interference floor | 0.0014 | 0.0053 (+5.9 dB) |
| Spatial coherence | ~0.12 | ~0.9 |
| Max. eigenvalue ratio | n/a | 16.8 dB |

| Jammer position | Calibrated AoA | Coherence | Floor rise |
|-----------------|----------------|-----------|------------|
| 1 | -49.3 deg | 0.788 | 4.5 dB |
| 2 | +28.0 deg | 0.552 | 1.9 dB |

### Phase 1 (ZMQ simulation)
| Detector | Accuracy | F1 Score |
|----------|----------|----------|
| SNR-based | 92.18% | 0.957 |
| Jammer power | 100% | 1.000 |
| Combined | 100% | 1.000 |

MUSIC pseudospectrum peak validated at the 25 deg ground-truth AoA (simulation).

---

## Contributions

### Aniket Jadhav - Hardware Testbed, Sensing Pipeline & Data Collection
- Brought up the live 5G NR testbed (OCUDU gNB, Open5GS, B210, Quectel UE, Pluto jammer)
- Implemented the sensing-slot capture: scheduler symbol reservation and the per-slot uplink tap
- Measured the AoA phase calibration and ran the jammer detection and AoA experiments
- Phase 1: modified the srsRAN scheduler (symbols 12-13 every 10 slots), built the IQ
  capture writer, `jammer_proxy.py`, and `to_mat.py`

### Samanvitha Balijepalli - Algorithm Refinement & Detection
- Phase 1: threshold-based detection framework and evaluation of the three detectors
  (precision, recall, F1, accuracy), including class-imbalance analysis
- Phase 2: algorithm refinement for localization

### Sandra Mansour - Algorithm Refinement & Localization
- Phase 1: MUSIC-based AoA baseline on a 3-element ULA (MATLAB)
- Phase 2: algorithm refinement for localization

---

## Repository Structure
```
srsRAN-Open5GS/
├── Final-Report/
│   ├── report.pdf                   # Spring 2026 final paper
│   ├── report.tex
│   ├── ELEC594_Project_Midterm_Report_Fall_2026.pdf   # Fall 2026 midterm report
│   ├── report f26 midterm.tex       # Fall 2026 midterm LaTeX source
│   ├── references.bib
│   └── figures/
├── report/                          # Spring 2026 midterm report + testbed/AoA figures
├── scripts/                         # Phase 1 (srsRAN + ZMQ) files
│   ├── inter_slice_scheduler.cpp
│   ├── iq_capture_writer.h
│   ├── radio_zmq_rx_stream.cpp
│   ├── jammer_proxy.py
│   └── to_mat.py
├── config/                          # Phase 1 gNB and UE configuration
├── matlab/                          # MUSIC localization and detection analysis
└── README.md
```
TODO: add the Phase 2 OCUDU files (scheduler change, uplink tap, capture and analysis
scripts, config) and the report figures once they are committed.

---

## How to Run

### Phase 1 (ZMQ simulation)
```bash
# Terminal 1 - Core Network
sudo bash ~/capstone/start_5g.sh

# Terminal 2 - gNB
sudo ~/capstone/srsRAN_Project/build/apps/gnb/gnb \
  -c ~/capstone/gnb_zmq.yaml

# Terminal 3 - Jammer Proxy (must start before UE)
python3 ~/capstone/jammer_proxy.py \
  --jammer-freq 100000 --jammer-amp 0.8 --delay-slots 2000

# Terminal 4 - UE
sudo ~/capstone/srsRAN_4G/build/srsue/src/srsue \
  ~/capstone/ue_zmq.conf

# Terminal 5 - Traffic (after UE attaches)
sudo ip netns exec ue1 ping 10.45.0.1 -i 0.01 -s 1400

# After experiment - convert data
python3 ~/capstone/to_mat.py
```

### Phase 2 (hardware)
TODO: add the run steps once the OCUDU files are in the repo. Enable the tap with
`OCUDU_UL_TAP` and the symbol reservation with `OCUDU_RESERVE_SYM9` before starting the gNB.

---

## Output Files (Phase 1)
| File | Description |
|------|-------------|
| /tmp/sensing_capture.bin | Raw IQ binary (6592 bytes/record) |
| /tmp/snr_log.csv | SNR timeline (9454 rows) |
| /tmp/sensing_data.mat | MATLAB file with all data |
| /tmp/all_iq_data.h5 | HDF5 structured IQ captures |

---

## Known Limitations
- **Two receive antennas:** the B210 testbed yields a single bearing angle with
  coarse resolution, so 3D localization is not yet possible.
- **Single runs:** each hardware test case was recorded once, so results have no
  repeats or confidence intervals.
- **Reserved symbols stay busy:** with the single-layer (rank-1) uplink of the UE,
  the scheduler repacks data into fewer symbols, so the reserved symbols do not
  become UE-silent.
- **Idle slots are not guaranteed:** the per-slot tap relies on spare uplink
  capacity, which will not exist under sustained traffic.
- **Phase 1 limits:** ZMQ transport injects padding zeros into quiet-symbol IQ
  buffers, so those detection results rely on proxy logs, not raw IQ.

---

## Future Work
- Reserve whole uplink slots for sensing so detection does not depend on idle traffic
- Move to two stations with 2x2 antenna arrays (O-RAN 7.2 split radios)
- ESPRIT azimuth and elevation estimation, and two-station triangulation for 3D (x, y, z)
- Systematic data collection over jammer position, power, and distance
- Package detection and localization as an xApp on the Near-RT RIC via E2
- ML-based classifier to separate jamming from natural interference

---

## References
- 3GPP TS 38.211 - NR Physical Channels and Modulation
- Schmidt (1986) - MUSIC algorithm
- Roy and Kailath (1989) - ESPRIT
- Kotaru et al. (2015) - SpotFi, ACM SIGCOMM
- OCUDU project
- Open5GS: https://open5gs.org
