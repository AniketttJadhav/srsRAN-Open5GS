#!/usr/bin/env python3
"""
Convert sensing_capture.bin + snr_log.csv → sensing_data.mat
For MATLAB/SpotFi analysis.

MATLAB usage:
    data = load("sensing_data.mat");
    plot(data.slot_index, data.snr_db);
    xlabel("Slot"); ylabel("SNR (dB)");
"""
import numpy as np
import scipy.io
import struct
import csv
import os

BIN_FILE = "/tmp/sensing_capture.bin"
SNR_FILE = "/tmp/snr_log.csv"
MAT_FILE = "/tmp/sensing_data.mat"

print("Reading IQ capture...")
iq_slots, iq_syms, iq_data = [], [], []
with open(BIN_FILE, "rb") as f:
    while True:
        hdr = f.read(16)
        if len(hdr) < 16: break
        slot_idx, sym_idx, nof_samples = struct.unpack("<QII", hdr)
        raw = f.read(nof_samples * 2 * 4)
        if len(raw) < nof_samples * 2 * 4: break
        floats = np.frombuffer(raw, dtype=np.float32).reshape(-1, 2)
        iq_slots.append(slot_idx)
        iq_syms.append(sym_idx)
        iq_data.append(floats)

print(f"  {len(iq_slots)} IQ records loaded")

print("Reading SNR log...")
snr_blocks, snr_slots, snr_time = [], [], []
snr_ue_pwr, snr_jam_pwr, snr_db, snr_jammer_on = [], [], [], []

with open(SNR_FILE, "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        snr_blocks.append(int(row["block"]))
        snr_slots.append(int(row["slot_idx"]))
        snr_time.append(float(row["time_sec"]))
        snr_ue_pwr.append(float(row["ue_power"]))
        snr_jam_pwr.append(float(row["jammer_power"]))
        snr_db.append(float(row["snr_db"]))
        snr_jammer_on.append(int(row["jammer_on"]))

print(f"  {len(snr_blocks)} SNR records loaded")

# Build IQ matrix: [num_captures x num_samples x 2]
iq_matrix = np.array(iq_data, dtype=np.float32)  # shape: (N, 822, 2)
iq_complex = iq_matrix[:,:,0] + 1j*iq_matrix[:,:,1]  # shape: (N, 822)

print("Writing .mat file...")
scipy.io.savemat(MAT_FILE, {
    # ── IQ capture data ──────────────────────────────
    "iq_slot_index":   np.array(iq_slots, dtype=np.uint64),
    "iq_symbol_index": np.array(iq_syms,  dtype=np.uint32),
    "iq_real":         iq_matrix[:,:,0],  # shape (N, 822)
    "iq_imag":         iq_matrix[:,:,1],  # shape (N, 822)

    # ── SNR measurements ─────────────────────────────
    "slot_index":      np.array(snr_slots,      dtype=np.int64),
    "time_sec":        np.array(snr_time,        dtype=np.float64),
    "ue_power":        np.array(snr_ue_pwr,      dtype=np.float64),
    "jammer_power":    np.array(snr_jam_pwr,     dtype=np.float64),
    "snr_db":          np.array(snr_db,           dtype=np.float64),
    "jammer_on":       np.array(snr_jammer_on,   dtype=np.uint8),

    # ── Radio parameters ─────────────────────────────
    "srate_hz":        np.float64(23.04e6),
    "carrier_hz":      np.float64(1842.5e6),
    "band":            np.int32(3),
    "jammer_freq_hz":  np.float64(100e3),
    "samples_per_sym": np.int32(822),
    "sensing_period":  np.int32(1),
})

size_mb = os.path.getsize(MAT_FILE) / 1024 / 1024
print(f"Done. {MAT_FILE} ({size_mb:.2f} MB)")
print()
print("MATLAB variable names:")
print("  iq_slot_index    — slot number for each IQ capture")
print("  iq_symbol_index  — symbol number (12 or 13)")
print("  iq_real          — real part of IQ  [N x 822]")
print("  iq_imag          — imag part of IQ  [N x 822]")
print("  slot_index       — slot number for SNR measurements")
print("  time_sec         — elapsed time in seconds")
print("  ue_power         — UE signal power per block")
print("  jammer_power     — jammer signal power per block")
print("  snr_db           — SNR in dB (high=clean, low=jammed)")
print("  jammer_on        — 0=jammer off, 1=jammer on")
print("  srate_hz         — sample rate 23.04 MHz")
print("  carrier_hz       — carrier frequency 1842.5 MHz")
