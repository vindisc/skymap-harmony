#include "jpeg_scanline_encoder.h"

#include <stdexcept>
#include <string>
#include <unistd.h>

JpegScanlineEncoder::JpegScanlineEncoder() = default;

JpegScanlineEncoder::~JpegScanlineEncoder()
{
  Abort();
}

void JpegScanlineEncoder::OnJpegError(j_common_ptr commonInfo)
{
  auto *manager = reinterpret_cast<ErrorManager *>(commonInfo->err);
  commonInfo->err->format_message(commonInfo, manager->message);
  longjmp(manager->jumpBuffer, 1);
}

[[noreturn]] void JpegScanlineEncoder::ThrowLastJpegError()
{
  const std::string message = errorManager_.message[0] == '\0'
    ? "libjpeg-turbo encode failed"
    : errorManager_.message;
  Cleanup();
  throw std::runtime_error(message);
}

void JpegScanlineEncoder::Start(int fd, int width, int height, int quality)
{
  if (started_) {
    throw std::runtime_error("JPEG encoder session has already started");
  }
  if (fd < 0 || width <= 0 || height <= 0 || quality < 1 || quality > 100) {
    throw std::invalid_argument("Invalid JPEG encoder arguments");
  }

  const int duplicatedFd = dup(fd);
  if (duplicatedFd < 0) {
    throw std::runtime_error("Failed to duplicate JPEG output file descriptor");
  }
  outputFile_ = fdopen(duplicatedFd, "wb");
  if (outputFile_ == nullptr) {
    close(duplicatedFd);
    throw std::runtime_error("Failed to open JPEG output stream");
  }

  compressInfo_.err = jpeg_std_error(&errorManager_.base);
  errorManager_.base.error_exit = OnJpegError;
  errorManager_.message[0] = '\0';
  if (setjmp(errorManager_.jumpBuffer) != 0) {
    ThrowLastJpegError();
  }

  jpeg_create_compress(&compressInfo_);
  jpegCreated_ = true;
  jpeg_stdio_dest(&compressInfo_, outputFile_);
  compressInfo_.image_width = static_cast<JDIMENSION>(width);
  compressInfo_.image_height = static_cast<JDIMENSION>(height);
  compressInfo_.input_components = 3;
  compressInfo_.in_color_space = JCS_RGB;
  jpeg_set_defaults(&compressInfo_);
  jpeg_set_quality(&compressInfo_, quality, TRUE);
  jpeg_start_compress(&compressInfo_, TRUE);

  width_ = width;
  height_ = height;
  started_ = true;
}

void JpegScanlineEncoder::WriteStrip(int stripHeight, const uint8_t *rgbData, size_t byteLength)
{
  if (!started_ || rgbData == nullptr || stripHeight <= 0) {
    throw std::invalid_argument("Invalid JPEG strip arguments");
  }
  const size_t rowBytes = static_cast<size_t>(width_) * 3U;
  const size_t expectedBytes = rowBytes * static_cast<size_t>(stripHeight);
  if (byteLength != expectedBytes) {
    throw std::invalid_argument("JPEG strip byte length does not match width and height");
  }
  if (compressInfo_.next_scanline + static_cast<JDIMENSION>(stripHeight) >
      static_cast<JDIMENSION>(height_)) {
    throw std::invalid_argument("JPEG strip exceeds declared image height");
  }

  errorManager_.message[0] = '\0';
  if (setjmp(errorManager_.jumpBuffer) != 0) {
    ThrowLastJpegError();
  }

  for (int row = 0; row < stripHeight; row += 1) {
    JSAMPROW rowPointer = const_cast<JSAMPROW>(rgbData + static_cast<size_t>(row) * rowBytes);
    if (jpeg_write_scanlines(&compressInfo_, &rowPointer, 1) != 1) {
      Cleanup();
      throw std::runtime_error("libjpeg-turbo did not consume the JPEG scan-line");
    }
  }
}

void JpegScanlineEncoder::Finalize()
{
  if (!started_) {
    throw std::runtime_error("JPEG encoder session is not active");
  }
  if (compressInfo_.next_scanline != static_cast<JDIMENSION>(height_)) {
    Cleanup();
    throw std::runtime_error("JPEG encoder did not receive all declared scan-lines");
  }

  errorManager_.message[0] = '\0';
  if (setjmp(errorManager_.jumpBuffer) != 0) {
    ThrowLastJpegError();
  }

  jpeg_finish_compress(&compressInfo_);
  if (fflush(outputFile_) != 0 || ferror(outputFile_) != 0) {
    Cleanup();
    throw std::runtime_error("Failed to flush JPEG output stream");
  }
  Cleanup();
}

void JpegScanlineEncoder::Abort() noexcept
{
  Cleanup();
}

void JpegScanlineEncoder::Cleanup() noexcept
{
  if (jpegCreated_) {
    jpeg_destroy_compress(&compressInfo_);
  }
  jpegCreated_ = false;
  started_ = false;
  width_ = 0;
  height_ = 0;
  if (outputFile_ != nullptr) {
    fclose(outputFile_);
    outputFile_ = nullptr;
  }
}
