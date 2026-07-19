#ifndef SKYMAP_JPEG_SCANLINE_ENCODER_H
#define SKYMAP_JPEG_SCANLINE_ENCODER_H

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <setjmp.h>

extern "C" {
#include "jpeglib.h"
}

class JpegScanlineEncoder {
public:
  JpegScanlineEncoder();
  ~JpegScanlineEncoder();

  JpegScanlineEncoder(const JpegScanlineEncoder &) = delete;
  JpegScanlineEncoder &operator=(const JpegScanlineEncoder &) = delete;

  void Start(int fd, int width, int height, int quality);
  void WriteStrip(int stripHeight, const uint8_t *rgbData, size_t byteLength);
  void Finalize();
  void Abort() noexcept;

private:
  struct ErrorManager {
    jpeg_error_mgr base;
    jmp_buf jumpBuffer;
    char message[JMSG_LENGTH_MAX];
  };

  static void OnJpegError(j_common_ptr commonInfo);
  [[noreturn]] void ThrowLastJpegError();
  void Cleanup() noexcept;

  jpeg_compress_struct compressInfo_ {};
  ErrorManager errorManager_ {};
  FILE *outputFile_ = nullptr;
  int width_ = 0;
  int height_ = 0;
  bool jpegCreated_ = false;
  bool started_ = false;
};

#endif
