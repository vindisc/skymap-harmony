#include <napi/native_api.h>

#include <cstdint>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <unordered_map>

#include "jpeg_scanline_encoder.h"

namespace {

std::mutex gSessionsMutex;
std::unordered_map<int32_t, std::unique_ptr<JpegScanlineEncoder>> gSessions;
int32_t gNextHandleId = 1;

void ThrowNapiError(napi_env env, const std::string &message)
{
  napi_throw_error(env, nullptr, message.c_str());
}

int32_t GetInt32(napi_env env, napi_value value, const char *name)
{
  int32_t result = 0;
  if (napi_get_value_int32(env, value, &result) != napi_ok) {
    throw std::invalid_argument(std::string(name) + " must be an integer");
  }
  return result;
}

int32_t GetHandleId(napi_env env, napi_value handle)
{
  napi_value handleIdValue = nullptr;
  if (napi_get_named_property(env, handle, "handleId", &handleIdValue) != napi_ok) {
    throw std::invalid_argument("handle.handleId is required");
  }
  return GetInt32(env, handleIdValue, "handle.handleId");
}

JpegScanlineEncoder &RequireSession(int32_t handleId)
{
  const auto iterator = gSessions.find(handleId);
  if (iterator == gSessions.end()) {
    throw std::invalid_argument("JPEG encoder handle is invalid or already closed");
  }
  return *iterator->second;
}

napi_value StartJpeg(napi_env env, napi_callback_info info)
{
  try {
    size_t argumentCount = 4;
    napi_value arguments[4] = { nullptr, nullptr, nullptr, nullptr };
    if (napi_get_cb_info(env, info, &argumentCount, arguments, nullptr, nullptr) != napi_ok ||
        argumentCount != 4) {
      throw std::invalid_argument("startJpeg requires fd, width, height and quality");
    }

    const int fd = GetInt32(env, arguments[0], "fd");
    const int width = GetInt32(env, arguments[1], "width");
    const int height = GetInt32(env, arguments[2], "height");
    const int quality = GetInt32(env, arguments[3], "quality");

    auto session = std::make_unique<JpegScanlineEncoder>();
    session->Start(fd, width, height, quality);

    int32_t handleId = 0;
    {
      std::lock_guard<std::mutex> lock(gSessionsMutex);
      handleId = gNextHandleId;
      gNextHandleId += 1;
      gSessions.emplace(handleId, std::move(session));
    }

    napi_value handle = nullptr;
    napi_value handleIdValue = nullptr;
    if (napi_create_object(env, &handle) != napi_ok ||
        napi_create_int32(env, handleId, &handleIdValue) != napi_ok ||
        napi_set_named_property(env, handle, "handleId", handleIdValue) != napi_ok) {
      std::lock_guard<std::mutex> lock(gSessionsMutex);
      gSessions.erase(handleId);
      throw std::runtime_error("Failed to create JPEG encoder handle");
    }
    return handle;
  } catch (const std::exception &error) {
    ThrowNapiError(env, error.what());
    return nullptr;
  }
}

napi_value WriteStrip(napi_env env, napi_callback_info info)
{
  try {
    size_t argumentCount = 3;
    napi_value arguments[3] = { nullptr, nullptr, nullptr };
    if (napi_get_cb_info(env, info, &argumentCount, arguments, nullptr, nullptr) != napi_ok ||
        argumentCount != 3) {
      throw std::invalid_argument("writeStrip requires handle, stripHeight and rgbBuffer");
    }

    const int32_t handleId = GetHandleId(env, arguments[0]);
    const int stripHeight = GetInt32(env, arguments[1], "stripHeight");
    void *bufferData = nullptr;
    size_t byteLength = 0;
    if (napi_get_arraybuffer_info(env, arguments[2], &bufferData, &byteLength) != napi_ok) {
      throw std::invalid_argument("rgbBuffer must be an ArrayBuffer");
    }

    std::lock_guard<std::mutex> lock(gSessionsMutex);
    RequireSession(handleId).WriteStrip(
      stripHeight,
      static_cast<const uint8_t *>(bufferData),
      byteLength
    );
    return nullptr;
  } catch (const std::exception &error) {
    ThrowNapiError(env, error.what());
    return nullptr;
  }
}

napi_value FinalizeJpeg(napi_env env, napi_callback_info info)
{
  try {
    size_t argumentCount = 1;
    napi_value arguments[1] = { nullptr };
    if (napi_get_cb_info(env, info, &argumentCount, arguments, nullptr, nullptr) != napi_ok ||
        argumentCount != 1) {
      throw std::invalid_argument("finalizeJpeg requires a handle");
    }
    const int32_t handleId = GetHandleId(env, arguments[0]);

    std::unique_ptr<JpegScanlineEncoder> session;
    {
      std::lock_guard<std::mutex> lock(gSessionsMutex);
      const auto iterator = gSessions.find(handleId);
      if (iterator == gSessions.end()) {
        throw std::invalid_argument("JPEG encoder handle is invalid or already closed");
      }
      session = std::move(iterator->second);
      gSessions.erase(iterator);
    }
    session->Finalize();
    return nullptr;
  } catch (const std::exception &error) {
    ThrowNapiError(env, error.what());
    return nullptr;
  }
}

napi_value AbortJpeg(napi_env env, napi_callback_info info)
{
  try {
    size_t argumentCount = 1;
    napi_value arguments[1] = { nullptr };
    if (napi_get_cb_info(env, info, &argumentCount, arguments, nullptr, nullptr) != napi_ok ||
        argumentCount != 1) {
      throw std::invalid_argument("abortJpeg requires a handle");
    }
    const int32_t handleId = GetHandleId(env, arguments[0]);

    std::unique_ptr<JpegScanlineEncoder> session;
    {
      std::lock_guard<std::mutex> lock(gSessionsMutex);
      const auto iterator = gSessions.find(handleId);
      if (iterator == gSessions.end()) {
        throw std::invalid_argument("JPEG encoder handle is invalid or already closed");
      }
      session = std::move(iterator->second);
      gSessions.erase(iterator);
    }
    session->Abort();
    return nullptr;
  } catch (const std::exception &error) {
    ThrowNapiError(env, error.what());
    return nullptr;
  }
}

napi_value Init(napi_env env, napi_value exports)
{
  napi_property_descriptor properties[] = {
    { "startJpeg", nullptr, StartJpeg, nullptr, nullptr, nullptr, napi_default, nullptr },
    { "writeStrip", nullptr, WriteStrip, nullptr, nullptr, nullptr, napi_default, nullptr },
    { "finalizeJpeg", nullptr, FinalizeJpeg, nullptr, nullptr, nullptr, napi_default, nullptr },
    { "abortJpeg", nullptr, AbortJpeg, nullptr, nullptr, nullptr, napi_default, nullptr }
  };
  if (napi_define_properties(env, exports, sizeof(properties) / sizeof(properties[0]), properties) != napi_ok) {
    ThrowNapiError(env, "Failed to register JPEG encoder NAPI properties");
  }
  return exports;
}

} // namespace

static napi_module jpegEncoderModule = {
  1,
  0,
  nullptr,
  Init,
  "jpeg_encoder",
  nullptr,
  { 0 }
};

extern "C" __attribute__((constructor)) void RegisterJpegEncoderModule()
{
  napi_module_register(&jpegEncoderModule);
}
