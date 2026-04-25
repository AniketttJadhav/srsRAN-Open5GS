#!/usr/bin/env python3
"""
Jammer Proxy with delayed activation and SNR logging.
- First 2000 slots: clean passthrough, UE connects normally
- After 2000 slots: jammer activates, SNR drops, connection degrades
- Logs SNR per block to CSV for .mat conversion
"""
import zmq
import numpy as np
import argparse
import csv
import time

parser = argparse.ArgumentParser()
parser.add_argument("--ue-port",     type=int,   default=2003)
parser.add_argument("--gnb-port",    type=int,   default=2001)
parser.add_argument("--srate",       type=float, default=23.04e6)
parser.add_argument("--jammer-freq", type=float, default=100e3)
parser.add_argument("--jammer-amp",  type=float, default=0.8)
parser.add_argument("--delay-slots", type=int,   default=2000,
                    help="Slots before jammer activates")
parser.add_argument("--log-file",    default="/tmp/snr_log.csv")
args = parser.parse_args()

SAMPLES_PER_SLOT = 11520

print(f"[JAMMER] freq={args.jammer_freq/1e3:.0f}kHz amp={args.jammer_amp}")
print(f"[JAMMER] Jammer activates after {args.delay_slots} slots")
print(f"[JAMMER] SNR log: {args.log_file}")

ctx = zmq.Context()
ue_sock  = ctx.socket(zmq.REQ)
ue_sock.connect(f"tcp://127.0.0.1:{args.ue_port}")
gnb_sock = ctx.socket(zmq.REP)
gnb_sock.bind(f"tcp://127.0.0.1:{args.gnb_port}")

print(f"[JAMMER] Ready. Waiting for gNB...")

total_samples  = 0
blocks         = 0
jammer_active  = False
log_rows       = []
start_time     = time.time()

try:
    while True:
        req = gnb_sock.recv()
        ue_sock.send(req)
        ue_data = ue_sock.recv()

        raw = np.frombuffer(ue_data, dtype=np.int16).copy()
        iq  = raw[0::2].astype(np.float32)/32767 +               1j*raw[1::2].astype(np.float32)/32767
        n = len(iq)

        # Slot counter
        slot_idx = total_samples // SAMPLES_PER_SLOT

        # Activate jammer after delay
        if slot_idx >= args.delay_slots and not jammer_active:
            jammer_active = True
            print(f"[JAMMER] *** JAMMER ACTIVATED at slot {slot_idx} ***")

        # Generate jammer tone
        t = np.arange(total_samples, total_samples + n)
        if jammer_active:
            jammer = args.jammer_amp * np.exp(
                1j * 2 * np.pi * args.jammer_freq * t / args.srate
            ).astype(np.complex64)
        else:
            jammer = np.zeros(n, dtype=np.complex64)

        # Mix
        mixed = iq + jammer
        mixed.real = np.clip(mixed.real, -1, 1)
        mixed.imag = np.clip(mixed.imag, -1, 1)

        # Convert back to int16
        out = np.zeros(n * 2, dtype=np.int16)
        out[0::2] = (mixed.real * 32767).astype(np.int16)
        out[1::2] = (mixed.imag * 32767).astype(np.int16)

        gnb_sock.send(out.tobytes())

        # Measure SNR
        ue_pwr  = float(np.mean(np.abs(iq)**2))
        jam_pwr = float(np.mean(np.abs(jammer)**2))
        if ue_pwr > 1e-6 and jam_pwr > 1e-6:
            snr_db = 10 * np.log10(ue_pwr / jam_pwr)
        elif ue_pwr > 1e-6:
            snr_db = 99.0   # no jammer
        elif jam_pwr > 1e-6:
            snr_db = -99.0  # jammer only, no UE
        else:
            snr_db = 0.0    # both silent

        log_rows.append({
            "block":        blocks,
            "slot_idx":     slot_idx,
            "time_sec":     round(time.time() - start_time, 3),
            "ue_power":     round(ue_pwr, 6),
            "jammer_power": round(jam_pwr, 6),
            "snr_db":       round(snr_db, 2),
            "jammer_on":    1 if jammer_active else 0
        })

        total_samples += n
        blocks += 1

        if blocks % 500 == 0:
            status = "JAMMER ON" if jammer_active else f"clean ({args.delay_slots - slot_idx} slots left)"
            print(f"[JAMMER] slot={slot_idx:6d} UE={ue_pwr:.4f} "
                  f"JAM={jam_pwr:.4f} SNR={snr_db:+.1f}dB [{status}]")

except KeyboardInterrupt:
    print(f"[JAMMER] Stopped. Writing SNR log...")
finally:
    # Write CSV log
    if log_rows:
        with open(args.log_file, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=log_rows[0].keys())
            writer.writeheader()
            writer.writerows(log_rows)
        print(f"[JAMMER] SNR log written: {args.log_file} ({len(log_rows)} rows)")
    ue_sock.close()
    gnb_sock.close()
    ctx.term()
