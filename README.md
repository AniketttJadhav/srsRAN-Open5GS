```markdown
# Near-Real-Time ISAC-Based Jammer Detection and Localization using srsRAN
**Rice University | Master of ECE | Spring 2026**

**Team:** Aniket Jadhav, Samanvitha Balijepalli, Sandra Mansour  
**Advisor:** Dr. Rahman Doost

---

## Overview
This project presents a software-based 5G framework for jammer 
detection and future localization using the srsRAN stack without 
any hardware modification. The system reserves quiet symbol 
intervals within the 5G NR frame — creating standards-compliant 
sensing windows at only ~1.4% scheduling overhead — and feeds 
SNR and jammer power extracted from these windows into lightweight 
threshold-based classifiers. In a controlled ZMQ software testbed, 
jammer power achieves perfect classification (F1 = 1.0) while 
SNR-based detection reaches 92.18% accuracy (F1 = 0.957). A 
MUSIC-based angle-of-arrival baseline is separately validated, 
confirming readiness for Phase 2 localization on USRP hardware.

---

## System Architecture
- **Core Network:** Open5GS (5GC)
- **gNB:** srsRAN Project (modified scheduler + IQ capture)
- **UE:** srsUE (srsRAN 4G)
- **RF Transport:** ZeroMQ (simulation) → USRP (Phase 2)
- **Post-processing:** Python + MATLAB

---

## Radio Configuration
| Parameter | Value |
|-----------|-------|
| Band | NR Band 3 |
| ARFCN | 368500 |
| Carrier Frequency | 1842.5 MHz |
| Bandwidth | 20 MHz |
| Subcarrier Spacing | 30 kHz (μ=1) |
| Duplex | TDD |
| Antennas | 1 (single antenna gNB) |
| Sensing Symbols | 12–13 (flexible, per TS 38.211) |
| Sensing Period | Every 10 slots |
| Sensing Overhead | ~1.4% |

---

## Key Results
| Detector | Accuracy | F1 Score |
|----------|----------|----------|
| SNR-based | 92.18% | 0.957 |
| Jammer Power | 100% | 1.000 |
| Combined | 100% | 1.000 |

- Baseline SNR (jammer OFF): +11.07 dB
- SNR after jammer activation: −91.10 dB
- Class distribution: 501 OFF samples, 8953 ON samples
- MUSIC pseudospectrum peak validated at 25° ground-truth AoA

---

## Contributions

### Aniket Jadhav — Scheduler Modification & Sensing Pipeline
- Modified srsRAN gNB scheduler to blank symbols 12–13 every
  10 slots per 3GPP TS 38.211 Table 4.3.2-1 (1.4% overhead)
- Developed IQ capture writer integrated into ZMQ RX stream,
  writing structured binary records to /tmp/sensing_capture.bin
- Built jammer_proxy.py — ZMQ-based CW jammer injection with
  synchronized SNR/power logging to /tmp/snr_log.csv
- Developed to_mat.py and iq_postprocess.py for MATLAB and
  HDF5 export of captured data

### Samanvitha Balijepalli — Algorithm Analysis & Detection
- Analyzed threshold-based detection framework using SNR and
  jammer power features from sensing windows
- Evaluated three detectors (SNR, jammer power, combined)
  with precision, recall, F1, and accuracy metrics
- Analyzed class imbalance (1:18 OFF:ON ratio) and its
  effect on detection performance

### Sandra Mansour — MUSIC Baseline & Localization
- Implemented MUSIC-based AoA estimation using 3-element ULA
- Validated CSI phase stability, I-Q constellation integrity,
  covariance eigenvalue structure, and pseudospectrum peak
- Established Phase 2 localization reference model

---

## Repository Structure
```
srsRAN-Open5GS/
├── Final-Report/
│   ├── report.pdf               # Final IEEE-format paper
│   ├── report.tex               # LaTeX source
│   ├── references.bib           # Bibliography
│   └── figures/                 # Paper figures
├── report/                      # Midterm report
├── scripts/                     # Modified and developed files
│   ├── inter_slice_scheduler.cpp   # Sensing scheduler modification
│   ├── iq_capture_writer.h         # IQ capture writer class
│   ├── radio_zmq_rx_stream.cpp     # RX pipeline hook
│   ├── jammer_proxy.py             # CW jammer injection + SNR logging
│   └── to_mat.py                   # Binary → MATLAB .mat converter
├── config/
│   ├── gnb_zmq.yaml                # gNB configuration
│   └── ue_zmq.conf                 # UE configuration
├── matlab/                      # Sandra's MUSIC localization code
└── README.md
```
---

## How to Run
```bash
# Terminal 1 — Core Network
sudo bash ~/capstone/start_5g.sh

# Terminal 2 — gNB
sudo ~/capstone/srsRAN_Project/build/apps/gnb/gnb \
  -c ~/capstone/gnb_zmq.yaml

# Terminal 3 — Jammer Proxy (must start before UE)
python3 ~/capstone/jammer_proxy.py \
  --jammer-freq 100000 --jammer-amp 0.8 --delay-slots 2000

# Terminal 4 — UE
sudo ~/capstone/srsRAN_4G/build/srsue/src/srsue \
  ~/capstone/ue_zmq.conf

# Terminal 5 — Traffic (after UE attaches)
sudo ip netns exec ue1 ping 10.45.0.1 -i 0.01 -s 1400

# After experiment — convert data
python3 ~/capstone/to_mat.py
```

---

## Output Files
| File | Description |
|------|-------------|
| /tmp/sensing_capture.bin | Raw IQ binary (6592 bytes/record) |
| /tmp/snr_log.csv | SNR timeline (9454 rows) |
| /tmp/sensing_data.mat | MATLAB file with all data |
| /tmp/all_iq_data.h5 | HDF5 structured IQ captures |

---

## Known Limitations
- ZMQ transport injects padding zeros into quiet-symbol IQ
  buffers — detection results rely on proxy logs, not raw IQ
- UE drops consistently at 158 IQ captures, root cause unknown
- MUSIC localization validated in simulation only, not yet
  integrated into the srsRAN sensing path
- Results reflect a controlled software testbed; hardware
  validation on USRP required for real RF sensing

---

## Future Work
- Deploy on USRP hardware for real ambient RF IQ capture
- Integrate MUSIC pipeline with quiet-window CSI matrices
  for near-real-time jammer AoA estimation
- Multi-gNB cooperative sensing for 2D position estimation
- ML-based classifier (CNN/Random Forest on FFT features)
  to distinguish jamming from natural interference
- Package detection logic as xApp on Near-RT RIC via E2
- Validate on n77/n78 (3.5 GHz) primary 5G bands

---

## References
- 3GPP TS 38.211 — NR Physical Channels and Modulation
- Schmidt (1986) — MUSIC algorithm
- Kotaru et al. (2015) — SpotFi, ACM SIGCOMM
- srsRAN Project: https://docs.srsran.com
- Open5GS: https://open5gs.org
```
