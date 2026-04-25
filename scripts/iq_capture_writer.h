#pragma once

#include "srsran/adt/complex.h"
#include "srsran/adt/span.h"
#include <cstdio>
#include <mutex>
#include <string>

namespace srsran {

class iq_capture_writer
{
public:
  static constexpr unsigned SAMPLES_PER_SLOT   = 11520;
  static constexpr unsigned SYMBOLS_PER_SLOT   = 14;
  static constexpr unsigned SAMPLES_PER_SYMBOL = SAMPLES_PER_SLOT / SYMBOLS_PER_SLOT;
  static constexpr unsigned QUIET_SYM_START    = 12;
  static constexpr unsigned QUIET_SYM_COUNT    = 2;
  static constexpr unsigned SENSING_PERIOD     = 1;
  static constexpr unsigned MAX_CAPTURES       = 200;

  explicit iq_capture_writer(const std::string& filename) : fp(nullptr), capture_count(0)
  {
    fp = fopen(filename.c_str(), "wb");
    if (!fp) {
      fprintf(stderr, "[IQ_CAPTURE] Failed to open file: %s\n", filename.c_str());
    } else {
      fprintf(stdout, "[IQ_CAPTURE] Binary capture file opened: %s\n", filename.c_str());
    }
  }

  ~iq_capture_writer()
  {
    if (fp) {
      fflush(fp);
      fclose(fp);
      fprintf(stdout, "[IQ_CAPTURE] Binary capture file closed. Total captures: %u\n", capture_count);
    }
  }

  void try_capture(uint64_t slot_idx, span<const ci16_t> data)
  {
    if (!fp)                            return;
    if (data.size() < SAMPLES_PER_SLOT) return;
    if (slot_idx % SENSING_PERIOD != 0) return;
    if (capture_count >= MAX_CAPTURES)  return;

    std::lock_guard<std::mutex> lock(mtx);

    for (unsigned sym = QUIET_SYM_START; sym < QUIET_SYM_START + QUIET_SYM_COUNT; ++sym) {
      unsigned           offset   = sym * SAMPLES_PER_SYMBOL;
      span<const ci16_t> sym_data = data.subspan(offset, SAMPLES_PER_SYMBOL);

      uint32_t nof   = SAMPLES_PER_SYMBOL;
      uint32_t sym32 = sym;
      fwrite(&slot_idx, sizeof(uint64_t), 1, fp);
      fwrite(&sym32,    sizeof(uint32_t), 1, fp);
      fwrite(&nof,      sizeof(uint32_t), 1, fp);

      for (const auto& s : sym_data) {
        float re = static_cast<float>(s.real()) / 32767.0f;
        float im = static_cast<float>(s.imag()) / 32767.0f;
        fwrite(&re, sizeof(float), 1, fp);
        fwrite(&im, sizeof(float), 1, fp);
      }

      ++capture_count;
      fprintf(stdout, "[IQ_CAPTURE] slot=%06lu sym=%02u written (%u/%u)\n",
              static_cast<unsigned long>(slot_idx), sym,
              capture_count, MAX_CAPTURES * QUIET_SYM_COUNT);
    }

    if (capture_count % 10 == 0) fflush(fp);
  }

private:
  FILE*             fp;
  unsigned          capture_count;
  std::mutex        mtx;
};

} // namespace srsran
