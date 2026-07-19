export interface JpegEncoderHandle {
  handleId: number;
}

export function startJpeg(fd: number, width: number, height: number, quality: number): JpegEncoderHandle;

export function writeStrip(handle: JpegEncoderHandle, stripHeight: number, rgbBuffer: ArrayBuffer): void;

export function finalizeJpeg(handle: JpegEncoderHandle): void;

export function abortJpeg(handle: JpegEncoderHandle): void;

declare const libjpegEncoder: {
  startJpeg: typeof startJpeg;
  writeStrip: typeof writeStrip;
  finalizeJpeg: typeof finalizeJpeg;
  abortJpeg: typeof abortJpeg;
};

export default libjpegEncoder;
