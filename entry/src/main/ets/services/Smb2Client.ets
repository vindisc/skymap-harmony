import socket from '@ohos.net.socket';

const SMB_PORT: number = 445;
const SOCKET_TIMEOUT_MS: number = 20000;
const STATUS_SUCCESS: number = 0x00000000;
const STATUS_MORE_PROCESSING_REQUIRED: number = 0xC0000016;
const SMB2_FLAGS_SIGNED: number = 0x00000008;

const SMB2_NEGOTIATE: number = 0x0000;
const SMB2_SESSION_SETUP: number = 0x0001;
const SMB2_LOGOFF: number = 0x0002;
const SMB2_TREE_CONNECT: number = 0x0003;
const SMB2_TREE_DISCONNECT: number = 0x0004;
const SMB2_CREATE: number = 0x0005;
const SMB2_CLOSE: number = 0x0006;
const SMB2_WRITE: number = 0x0009;

const NTLMSSP_NEGOTIATE_UNICODE: number = 0x00000001;
const NTLMSSP_REQUEST_TARGET: number = 0x00000004;
const NTLMSSP_NEGOTIATE_NTLM: number = 0x00000200;
const NTLMSSP_NEGOTIATE_ALWAYS_SIGN: number = 0x00008000;
const NTLMSSP_NEGOTIATE_EXTENDED_SESSIONSECURITY: number = 0x00080000;
const NTLMSSP_NEGOTIATE_TARGET_INFO: number = 0x00800000;
const NTLMSSP_NEGOTIATE_VERSION: number = 0x02000000;
const NTLMSSP_NEGOTIATE_128: number = 0x20000000;
const NTLMSSP_NEGOTIATE_KEY_EXCH: number = 0x40000000;
const NTLMSSP_NEGOTIATE_56: number = 0x80000000;
const NTLM_FLAGS: number =
  NTLMSSP_NEGOTIATE_UNICODE |
  NTLMSSP_REQUEST_TARGET |
  NTLMSSP_NEGOTIATE_NTLM |
  NTLMSSP_NEGOTIATE_ALWAYS_SIGN |
  NTLMSSP_NEGOTIATE_EXTENDED_SESSIONSECURITY |
  NTLMSSP_NEGOTIATE_TARGET_INFO |
  NTLMSSP_NEGOTIATE_128 |
  NTLMSSP_NEGOTIATE_56;

export interface Smb2UploadOptions {
  host: string;
  port: number;
  shareName: string;
  remoteDirectory: string;
  username: string;
  password: string;
  domain: string;
  fileName: string;
  content: string;
}

interface NtlmChallenge {
  serverChallenge: Array<number>;
  targetInfo: Array<number>;
  flags: number;
}

interface NtlmAuthenticatePayload {
  message: Array<number>;
  sessionKey: Array<number>;
}

function bytes(length: number): Array<number> {
  const result: Array<number> = [];
  for (let index = 0; index < length; index += 1) {
    result.push(0);
  }
  return result;
}

function concatBytes(parts: Array<Array<number>>): Array<number> {
  const result: Array<number> = [];
  parts.forEach((part: Array<number>) => {
    part.forEach((value: number) => {
      result.push(value & 0xFF);
    });
  });
  return result;
}

function arrayBufferToBytes(buffer: ArrayBuffer): Array<number> {
  const view = new Uint8Array(buffer);
  const result: Array<number> = [];
  for (let index = 0; index < view.length; index += 1) {
    result.push(view[index]);
  }
  return result;
}

function bytesToArrayBuffer(data: Array<number>): ArrayBuffer {
  return new Uint8Array(data).buffer;
}

function asciiBytes(value: string): Array<number> {
  const result: Array<number> = [];
  for (let index = 0; index < value.length; index += 1) {
    result.push(value.charCodeAt(index) & 0x7F);
  }
  return result;
}

function utf8Bytes(value: string): Array<number> {
  const result: Array<number> = [];
  for (let index = 0; index < value.length; index += 1) {
    let codePoint: number = value.charCodeAt(index);
    if (codePoint >= 0xD800 && codePoint <= 0xDBFF && index + 1 < value.length) {
      const next: number = value.charCodeAt(index + 1);
      if (next >= 0xDC00 && next <= 0xDFFF) {
        codePoint = ((codePoint - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000;
        index += 1;
      }
    }

    if (codePoint <= 0x7F) {
      result.push(codePoint);
    } else if (codePoint <= 0x7FF) {
      result.push(0xC0 | (codePoint >> 6));
      result.push(0x80 | (codePoint & 0x3F));
    } else if (codePoint <= 0xFFFF) {
      result.push(0xE0 | (codePoint >> 12));
      result.push(0x80 | ((codePoint >> 6) & 0x3F));
      result.push(0x80 | (codePoint & 0x3F));
    } else {
      result.push(0xF0 | (codePoint >> 18));
      result.push(0x80 | ((codePoint >> 12) & 0x3F));
      result.push(0x80 | ((codePoint >> 6) & 0x3F));
      result.push(0x80 | (codePoint & 0x3F));
    }
  }
  return result;
}

function utf16LeBytes(value: string): Array<number> {
  const result: Array<number> = [];
  for (let index = 0; index < value.length; index += 1) {
    const code: number = value.charCodeAt(index);
    result.push(code & 0xFF);
    result.push((code >>> 8) & 0xFF);
  }
  return result;
}

function readUInt16LE(data: Array<number>, offset: number): number {
  return (data[offset] | (data[offset + 1] << 8)) >>> 0;
}

function readUInt32LE(data: Array<number>, offset: number): number {
  return (
    (data[offset]) |
    (data[offset + 1] << 8) |
    (data[offset + 2] << 16) |
    (data[offset + 3] << 24)
  ) >>> 0;
}

function writeUInt16LE(data: Array<number>, offset: number, value: number): void {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >>> 8) & 0xFF;
}

function writeUInt16BE(data: Array<number>, offset: number, value: number): void {
  data[offset] = (value >>> 8) & 0xFF;
  data[offset + 1] = value & 0xFF;
}

function writeUInt32LE(data: Array<number>, offset: number, value: number): void {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >>> 8) & 0xFF;
  data[offset + 2] = (value >>> 16) & 0xFF;
  data[offset + 3] = (value >>> 24) & 0xFF;
}

function writeUInt32BE(data: Array<number>, offset: number, value: number): void {
  data[offset] = (value >>> 24) & 0xFF;
  data[offset + 1] = (value >>> 16) & 0xFF;
  data[offset + 2] = (value >>> 8) & 0xFF;
  data[offset + 3] = value & 0xFF;
}

function writeUInt64LEFromNumber(data: Array<number>, offset: number, value: number): void {
  const low: number = Math.floor(value % 0x100000000);
  const high: number = Math.floor(value / 0x100000000);
  writeUInt32LE(data, offset, low);
  writeUInt32LE(data, offset + 4, high);
}

function rotateLeft(value: number, shift: number): number {
  return ((value << shift) | (value >>> (32 - shift))) >>> 0;
}

function rotateRight(value: number, shift: number): number {
  return ((value >>> shift) | (value << (32 - shift))) >>> 0;
}

function add32(values: Array<number>): number {
  let result: number = 0;
  values.forEach((value: number) => {
    result = (result + value) >>> 0;
  });
  return result;
}

function appendLeLength(bytesValue: Array<number>, bitLength: number): void {
  writeUInt64LEFromNumber(bytesValue, bytesValue.length, bitLength);
}

function md4(input: Array<number>): Array<number> {
  const message: Array<number> = input.slice();
  const bitLength: number = message.length * 8;
  message.push(0x80);
  while ((message.length % 64) !== 56) {
    message.push(0);
  }
  appendLeLength(message, bitLength);

  let a: number = 0x67452301;
  let b: number = 0xEFCDAB89;
  let c: number = 0x98BADCFE;
  let d: number = 0x10325476;

  for (let chunkOffset = 0; chunkOffset < message.length; chunkOffset += 64) {
    const x: Array<number> = [];
    for (let index = 0; index < 16; index += 1) {
      x.push(readUInt32LE(message, chunkOffset + index * 4));
    }

    const aa: number = a;
    const bb: number = b;
    const cc: number = c;
    const dd: number = d;

    const f = (xValue: number, yValue: number, zValue: number): number => ((xValue & yValue) | (~xValue & zValue)) >>> 0;
    const g = (xValue: number, yValue: number, zValue: number): number => ((xValue & yValue) | (xValue & zValue) | (yValue & zValue)) >>> 0;
    const h = (xValue: number, yValue: number, zValue: number): number => (xValue ^ yValue ^ zValue) >>> 0;

    const ff = (aValue: number, bValue: number, cValue: number, dValue: number, k: number, s: number): number =>
      rotateLeft(add32([aValue, f(bValue, cValue, dValue), x[k]]), s);
    const gg = (aValue: number, bValue: number, cValue: number, dValue: number, k: number, s: number): number =>
      rotateLeft(add32([aValue, g(bValue, cValue, dValue), x[k], 0x5A827999]), s);
    const hh = (aValue: number, bValue: number, cValue: number, dValue: number, k: number, s: number): number =>
      rotateLeft(add32([aValue, h(bValue, cValue, dValue), x[k], 0x6ED9EBA1]), s);

    a = ff(a, b, c, d, 0, 3); d = ff(d, a, b, c, 1, 7); c = ff(c, d, a, b, 2, 11); b = ff(b, c, d, a, 3, 19);
    a = ff(a, b, c, d, 4, 3); d = ff(d, a, b, c, 5, 7); c = ff(c, d, a, b, 6, 11); b = ff(b, c, d, a, 7, 19);
    a = ff(a, b, c, d, 8, 3); d = ff(d, a, b, c, 9, 7); c = ff(c, d, a, b, 10, 11); b = ff(b, c, d, a, 11, 19);
    a = ff(a, b, c, d, 12, 3); d = ff(d, a, b, c, 13, 7); c = ff(c, d, a, b, 14, 11); b = ff(b, c, d, a, 15, 19);

    a = gg(a, b, c, d, 0, 3); d = gg(d, a, b, c, 4, 5); c = gg(c, d, a, b, 8, 9); b = gg(b, c, d, a, 12, 13);
    a = gg(a, b, c, d, 1, 3); d = gg(d, a, b, c, 5, 5); c = gg(c, d, a, b, 9, 9); b = gg(b, c, d, a, 13, 13);
    a = gg(a, b, c, d, 2, 3); d = gg(d, a, b, c, 6, 5); c = gg(c, d, a, b, 10, 9); b = gg(b, c, d, a, 14, 13);
    a = gg(a, b, c, d, 3, 3); d = gg(d, a, b, c, 7, 5); c = gg(c, d, a, b, 11, 9); b = gg(b, c, d, a, 15, 13);

    a = hh(a, b, c, d, 0, 3); d = hh(d, a, b, c, 8, 9); c = hh(c, d, a, b, 4, 11); b = hh(b, c, d, a, 12, 15);
    a = hh(a, b, c, d, 2, 3); d = hh(d, a, b, c, 10, 9); c = hh(c, d, a, b, 6, 11); b = hh(b, c, d, a, 14, 15);
    a = hh(a, b, c, d, 1, 3); d = hh(d, a, b, c, 9, 9); c = hh(c, d, a, b, 5, 11); b = hh(b, c, d, a, 13, 15);
    a = hh(a, b, c, d, 3, 3); d = hh(d, a, b, c, 11, 9); c = hh(c, d, a, b, 7, 11); b = hh(b, c, d, a, 15, 15);

    a = add32([a, aa]);
    b = add32([b, bb]);
    c = add32([c, cc]);
    d = add32([d, dd]);
  }

  const output: Array<number> = bytes(16);
  writeUInt32LE(output, 0, a);
  writeUInt32LE(output, 4, b);
  writeUInt32LE(output, 8, c);
  writeUInt32LE(output, 12, d);
  return output;
}

const MD5_S: Array<number> = [
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
];

const MD5_K: Array<number> = [
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
];

function md5(input: Array<number>): Array<number> {
  const message: Array<number> = input.slice();
  const bitLength: number = message.length * 8;
  message.push(0x80);
  while ((message.length % 64) !== 56) {
    message.push(0);
  }
  appendLeLength(message, bitLength);

  let a0: number = 0x67452301;
  let b0: number = 0xefcdab89;
  let c0: number = 0x98badcfe;
  let d0: number = 0x10325476;

  for (let chunkOffset = 0; chunkOffset < message.length; chunkOffset += 64) {
    const m: Array<number> = [];
    for (let index = 0; index < 16; index += 1) {
      m.push(readUInt32LE(message, chunkOffset + index * 4));
    }

    let a: number = a0;
    let b: number = b0;
    let c: number = c0;
    let d: number = d0;

    for (let index = 0; index < 64; index += 1) {
      let f: number = 0;
      let g: number = 0;
      if (index < 16) {
        f = ((b & c) | (~b & d)) >>> 0;
        g = index;
      } else if (index < 32) {
        f = ((d & b) | (~d & c)) >>> 0;
        g = (5 * index + 1) % 16;
      } else if (index < 48) {
        f = (b ^ c ^ d) >>> 0;
        g = (3 * index + 5) % 16;
      } else {
        f = (c ^ (b | ~d)) >>> 0;
        g = (7 * index) % 16;
      }

      const nextD: number = d;
      d = c;
      c = b;
      b = add32([b, rotateLeft(add32([a, f, MD5_K[index], m[g]]), MD5_S[index])]);
      a = nextD;
    }

    a0 = add32([a0, a]);
    b0 = add32([b0, b]);
    c0 = add32([c0, c]);
    d0 = add32([d0, d]);
  }

  const output: Array<number> = bytes(16);
  writeUInt32LE(output, 0, a0);
  writeUInt32LE(output, 4, b0);
  writeUInt32LE(output, 8, c0);
  writeUInt32LE(output, 12, d0);
  return output;
}

const SHA256_K: Array<number> = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

function sha256(input: Array<number>): Array<number> {
  const message: Array<number> = input.slice();
  const bitLength: number = message.length * 8;
  message.push(0x80);
  while ((message.length % 64) !== 56) {
    message.push(0);
  }
  const high: number = Math.floor(bitLength / 0x100000000);
  const low: number = bitLength >>> 0;
  const lengthBytes: Array<number> = bytes(8);
  writeUInt32BE(lengthBytes, 0, high);
  writeUInt32BE(lengthBytes, 4, low);
  lengthBytes.forEach((value: number) => message.push(value));

  let h0: number = 0x6a09e667;
  let h1: number = 0xbb67ae85;
  let h2: number = 0x3c6ef372;
  let h3: number = 0xa54ff53a;
  let h4: number = 0x510e527f;
  let h5: number = 0x9b05688c;
  let h6: number = 0x1f83d9ab;
  let h7: number = 0x5be0cd19;

  for (let chunkOffset = 0; chunkOffset < message.length; chunkOffset += 64) {
    const w: Array<number> = [];
    for (let index = 0; index < 16; index += 1) {
      const offset: number = chunkOffset + index * 4;
      w.push(((message[offset] << 24) | (message[offset + 1] << 16) | (message[offset + 2] << 8) | message[offset + 3]) >>> 0);
    }
    for (let index = 16; index < 64; index += 1) {
      const s0: number = (rotateRight(w[index - 15], 7) ^ rotateRight(w[index - 15], 18) ^ (w[index - 15] >>> 3)) >>> 0;
      const s1: number = (rotateRight(w[index - 2], 17) ^ rotateRight(w[index - 2], 19) ^ (w[index - 2] >>> 10)) >>> 0;
      w.push(add32([w[index - 16], s0, w[index - 7], s1]));
    }

    let a: number = h0;
    let b: number = h1;
    let c: number = h2;
    let d: number = h3;
    let e: number = h4;
    let f: number = h5;
    let g: number = h6;
    let h: number = h7;

    for (let index = 0; index < 64; index += 1) {
      const s1: number = (rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25)) >>> 0;
      const ch: number = ((e & f) ^ (~e & g)) >>> 0;
      const temp1: number = add32([h, s1, ch, SHA256_K[index], w[index]]);
      const s0: number = (rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22)) >>> 0;
      const maj: number = ((a & b) ^ (a & c) ^ (b & c)) >>> 0;
      const temp2: number = add32([s0, maj]);

      h = g;
      g = f;
      f = e;
      e = add32([d, temp1]);
      d = c;
      c = b;
      b = a;
      a = add32([temp1, temp2]);
    }

    h0 = add32([h0, a]);
    h1 = add32([h1, b]);
    h2 = add32([h2, c]);
    h3 = add32([h3, d]);
    h4 = add32([h4, e]);
    h5 = add32([h5, f]);
    h6 = add32([h6, g]);
    h7 = add32([h7, h]);
  }

  const output: Array<number> = bytes(32);
  writeUInt32BE(output, 0, h0);
  writeUInt32BE(output, 4, h1);
  writeUInt32BE(output, 8, h2);
  writeUInt32BE(output, 12, h3);
  writeUInt32BE(output, 16, h4);
  writeUInt32BE(output, 20, h5);
  writeUInt32BE(output, 24, h6);
  writeUInt32BE(output, 28, h7);
  return output;
}

function hmac(key: Array<number>, message: Array<number>, digest: (input: Array<number>) => Array<number>, blockSize: number): Array<number> {
  let normalizedKey: Array<number> = key.slice();
  if (normalizedKey.length > blockSize) {
    normalizedKey = digest(normalizedKey);
  }
  while (normalizedKey.length < blockSize) {
    normalizedKey.push(0);
  }

  const outer: Array<number> = [];
  const inner: Array<number> = [];
  for (let index = 0; index < blockSize; index += 1) {
    outer.push((normalizedKey[index] ^ 0x5C) & 0xFF);
    inner.push((normalizedKey[index] ^ 0x36) & 0xFF);
  }

  return digest(concatBytes([outer, digest(concatBytes([inner, message]))]));
}

function hmacMd5(key: Array<number>, message: Array<number>): Array<number> {
  return hmac(key, message, md5, 64);
}

function hmacSha256(key: Array<number>, message: Array<number>): Array<number> {
  return hmac(key, message, sha256, 64);
}

function randomBytesValue(length: number): Array<number> {
  const result: Array<number> = [];
  for (let index = 0; index < length; index += 1) {
    result.push(Math.floor(Math.random() * 256) & 0xFF);
  }
  return result;
}

function fileTimeNowBytes(): Array<number> {
  const unixEpochOffset: number = 116444736000000000;
  const fileTime: number = unixEpochOffset + Date.now() * 10000;
  const output: Array<number> = bytes(8);
  writeUInt64LEFromNumber(output, 0, fileTime);
  return output;
}

function asn1Length(length: number): Array<number> {
  if (length < 0x80) {
    return [length];
  }
  if (length <= 0xFF) {
    return [0x81, length];
  }
  return [0x82, (length >>> 8) & 0xFF, length & 0xFF];
}

function asn1(tag: number, content: Array<number>): Array<number> {
  return concatBytes([[tag], asn1Length(content.length), content]);
}

function wrapSpnegoNegTokenInit(ntlmMessage: Array<number>): Array<number> {
  const spnegoOid: Array<number> = asn1(0x06, [0x2B, 0x06, 0x01, 0x05, 0x05, 0x02]);
  const ntlmOid: Array<number> = asn1(0x06, [0x2B, 0x06, 0x01, 0x04, 0x01, 0x82, 0x37, 0x02, 0x02, 0x0A]);
  const mechTypes: Array<number> = asn1(0xA0, asn1(0x30, ntlmOid));
  const mechToken: Array<number> = asn1(0xA2, asn1(0x04, ntlmMessage));
  const negTokenInit: Array<number> = asn1(0xA0, asn1(0x30, concatBytes([mechTypes, mechToken])));
  return asn1(0x60, concatBytes([spnegoOid, negTokenInit]));
}

function wrapSpnegoNegTokenResp(ntlmMessage: Array<number>): Array<number> {
  return asn1(0xA1, asn1(0x30, asn1(0xA2, asn1(0x04, ntlmMessage))));
}

function findSignature(data: Array<number>, signature: Array<number>): number {
  for (let index = 0; index <= data.length - signature.length; index += 1) {
    let matched: boolean = true;
    for (let offset = 0; offset < signature.length; offset += 1) {
      if (data[index + offset] !== signature[offset]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      return index;
    }
  }
  return -1;
}

function ntlmNegotiateMessage(): Array<number> {
  const message: Array<number> = bytes(32);
  const signature: Array<number> = asciiBytes('NTLMSSP');
  for (let index = 0; index < signature.length; index += 1) {
    message[index] = signature[index];
  }
  message[7] = 0;
  writeUInt32LE(message, 8, 1);
  writeUInt32LE(message, 12, NTLM_FLAGS);
  return message;
}

function parseNtlmChallenge(securityBlob: Array<number>): NtlmChallenge {
  const signature: Array<number> = [0x4E, 0x54, 0x4C, 0x4D, 0x53, 0x53, 0x50, 0x00];
  const start: number = findSignature(securityBlob, signature);
  if (start < 0 || securityBlob.length < start + 48) {
    throw new Error('SMB 认证协商失败');
  }

  const messageType: number = readUInt32LE(securityBlob, start + 8);
  if (messageType !== 2) {
    throw new Error('SMB 认证响应异常');
  }

  const targetInfoLength: number = readUInt16LE(securityBlob, start + 40);
  const targetInfoOffset: number = readUInt32LE(securityBlob, start + 44);
  const absoluteTargetInfoOffset: number = start + targetInfoOffset;
  const targetInfo: Array<number> = securityBlob.slice(absoluteTargetInfoOffset, absoluteTargetInfoOffset + targetInfoLength);
  return {
    serverChallenge: securityBlob.slice(start + 24, start + 32),
    targetInfo: targetInfo,
    flags: readUInt32LE(securityBlob, start + 20)
  };
}

function writeSecurityBuffer(message: Array<number>, offset: number, payloadOffset: number, value: Array<number>): void {
  writeUInt16LE(message, offset, value.length);
  writeUInt16LE(message, offset + 2, value.length);
  writeUInt32LE(message, offset + 4, payloadOffset);
}

function buildNtlmAuthenticateMessage(
  challenge: NtlmChallenge,
  username: string,
  password: string,
  domain: string,
  workstation: string
): NtlmAuthenticatePayload {
  const normalizedDomain: string = domain.trim().toUpperCase();
  const normalizedUser: string = username.trim();
  const domainBytes: Array<number> = utf16LeBytes(normalizedDomain);
  const userBytes: Array<number> = utf16LeBytes(normalizedUser);
  const workstationBytes: Array<number> = utf16LeBytes(workstation);
  const ntowf: Array<number> = md4(utf16LeBytes(password));
  const ntlmv2Hash: Array<number> = hmacMd5(ntowf, utf16LeBytes(`${normalizedUser.toUpperCase()}${normalizedDomain}`));
  const clientChallenge: Array<number> = randomBytesValue(8);
  const blob: Array<number> = concatBytes([
    [0x01, 0x01, 0x00, 0x00],
    [0x00, 0x00, 0x00, 0x00],
    fileTimeNowBytes(),
    clientChallenge,
    [0x00, 0x00, 0x00, 0x00],
    challenge.targetInfo,
    [0x00, 0x00, 0x00, 0x00]
  ]);
  const ntProof: Array<number> = hmacMd5(ntlmv2Hash, concatBytes([challenge.serverChallenge, blob]));
  const ntResponse: Array<number> = concatBytes([ntProof, blob]);
  const lmProof: Array<number> = hmacMd5(ntlmv2Hash, concatBytes([challenge.serverChallenge, clientChallenge]));
  const lmResponse: Array<number> = concatBytes([lmProof, clientChallenge]);
  const sessionKey: Array<number> = hmacMd5(ntlmv2Hash, ntProof);

  const headerLength: number = 64;
  const payload: Array<number> = concatBytes([lmResponse, ntResponse, domainBytes, userBytes, workstationBytes]);
  const message: Array<number> = bytes(headerLength + payload.length);
  const signature: Array<number> = asciiBytes('NTLMSSP');
  for (let index = 0; index < signature.length; index += 1) {
    message[index] = signature[index];
  }
  message[7] = 0;
  writeUInt32LE(message, 8, 3);

  let payloadOffset: number = headerLength;
  writeSecurityBuffer(message, 12, payloadOffset, lmResponse);
  payloadOffset += lmResponse.length;
  writeSecurityBuffer(message, 20, payloadOffset, ntResponse);
  payloadOffset += ntResponse.length;
  writeSecurityBuffer(message, 28, payloadOffset, domainBytes);
  payloadOffset += domainBytes.length;
  writeSecurityBuffer(message, 36, payloadOffset, userBytes);
  payloadOffset += userBytes.length;
  writeSecurityBuffer(message, 44, payloadOffset, workstationBytes);
  payloadOffset += workstationBytes.length;
  writeSecurityBuffer(message, 52, payloadOffset, []);
  const authFlags: number = ((challenge.flags | NTLM_FLAGS) & ~NTLMSSP_NEGOTIATE_VERSION & ~NTLMSSP_NEGOTIATE_KEY_EXCH) >>> 0;
  writeUInt32LE(message, 60, authFlags);

  for (let index = 0; index < payload.length; index += 1) {
    message[headerLength + index] = payload[index];
  }

  return {
    message: message,
    sessionKey: sessionKey
  };
}

function statusMessage(status: number): string {
  if (status === STATUS_SUCCESS) {
    return '成功';
  }
  if (status === 0xC000006D || status === 0xC0000022) {
    return 'SMB 认证失败，请检查用户名和密码';
  }
  if (status === 0xC00000CC) {
    return 'SMB 共享名不存在，请检查共享名';
  }
  if (status === 0xC000003A || status === 0xC0000034) {
    return 'SMB 目录不存在，请先在家庭存储中创建目录';
  }
  if (status === 0xC0000043) {
    return 'SMB 文件正在被占用，请稍后重试';
  }
  return `SMB 返回 0x${status.toString(16)}`;
}

function normalizeRemoteFilePath(remoteDirectory: string, fileName: string): string {
  const directory: string = remoteDirectory
    .replace(/\\/g, '/')
    .split('/')
    .map((part: string) => part.trim())
    .filter((part: string) => part.length > 0)
    .join('\\');
  if (directory.length === 0) {
    return fileName;
  }
  return `${directory}\\${fileName}`;
}

class Smb2Transport {
  private tcpSocket: socket.TCPSocket = socket.constructTCPSocketInstance();
  private incoming: Array<number> = [];
  private packetQueue: Array<Array<number>> = [];
  private pendingResolver: ((packet: Array<number>) => void) | undefined = undefined;
  private pendingRejecter: ((error: Error) => void) | undefined = undefined;

  async connect(host: string, port: number): Promise<void> {
    this.tcpSocket.on('message', (info: socket.SocketMessageInfo) => {
      this.appendIncoming(arrayBufferToBytes(info.message));
    });
    this.tcpSocket.on('error', () => {
      this.rejectPending(new Error('SMB 连接异常'));
    });
    await this.tcpSocket.connect({
      address: {
        address: host,
        port: port,
        family: host.indexOf(':') >= 0 ? 2 : 1
      },
      timeout: SOCKET_TIMEOUT_MS
    });
    await this.tcpSocket.setExtraOptions({
      TCPNoDelay: true,
      keepAlive: true
    });
  }

  async close(): Promise<void> {
    try {
      await this.tcpSocket.close();
    } catch (error) {
    }
  }

  async request(packet: Array<number>): Promise<Array<number>> {
    await this.tcpSocket.send({ data: bytesToArrayBuffer(this.withNetBiosHeader(packet)) });
    return await this.receivePacket();
  }

  private withNetBiosHeader(packet: Array<number>): Array<number> {
    const header: Array<number> = bytes(4);
    header[0] = 0;
    header[1] = (packet.length >>> 16) & 0xFF;
    header[2] = (packet.length >>> 8) & 0xFF;
    header[3] = packet.length & 0xFF;
    return concatBytes([header, packet]);
  }

  private appendIncoming(chunk: Array<number>): void {
    this.incoming = concatBytes([this.incoming, chunk]);
    while (this.incoming.length >= 4) {
      const packetLength: number = (this.incoming[1] << 16) | (this.incoming[2] << 8) | this.incoming[3];
      if (this.incoming.length < 4 + packetLength) {
        return;
      }
      const packet: Array<number> = this.incoming.slice(4, 4 + packetLength);
      this.incoming = this.incoming.slice(4 + packetLength);
      if (this.pendingResolver) {
        const resolver = this.pendingResolver;
        this.pendingResolver = undefined;
        this.pendingRejecter = undefined;
        resolver(packet);
      } else {
        this.packetQueue.push(packet);
      }
    }
  }

  private receivePacket(): Promise<Array<number>> {
    if (this.packetQueue.length > 0) {
      const packet: Array<number> | undefined = this.packetQueue.shift();
      return Promise.resolve(packet ? packet : []);
    }
    return new Promise<Array<number>>((resolve: (packet: Array<number>) => void, reject: (error: Error) => void) => {
      this.pendingResolver = resolve;
      this.pendingRejecter = reject;
      setTimeout(() => {
        if (this.pendingResolver === resolve) {
          this.pendingResolver = undefined;
          this.pendingRejecter = undefined;
          reject(new Error('SMB 响应超时'));
        }
      }, SOCKET_TIMEOUT_MS);
    });
  }

  private rejectPending(error: Error): void {
    if (this.pendingRejecter) {
      const rejecter = this.pendingRejecter;
      this.pendingResolver = undefined;
      this.pendingRejecter = undefined;
      rejecter(error);
    }
  }
}

export class Smb2Client {
  private transport: Smb2Transport = new Smb2Transport();
  private messageId: number = 0;
  private sessionId: Array<number> = bytes(8);
  private treeId: number = 0;
  private serverSecurityMode: number = 0;
  private sessionKey: Array<number> = [];

  async testConnection(options: Smb2UploadOptions): Promise<void> {
    await this.open(options);
    await this.treeDisconnect();
    await this.logoff();
  }

  async uploadText(options: Smb2UploadOptions): Promise<string> {
    await this.open(options);
    const remotePath: string = normalizeRemoteFilePath(options.remoteDirectory, options.fileName);
    const fileId: Array<number> = await this.createFile(remotePath);
    try {
      await this.writeFile(fileId, utf8Bytes(options.content));
    } finally {
      await this.closeFile(fileId);
    }
    await this.safeDisconnect();
    return `\\\\${options.host}\\${options.shareName}\\${remotePath}`;
  }

  async close(): Promise<void> {
    await this.transport.close();
  }

  private async open(options: Smb2UploadOptions): Promise<void> {
    await this.transport.connect(options.host, options.port > 0 ? options.port : SMB_PORT);
    await this.negotiate();
    await this.sessionSetup(options);
    await this.treeConnect(options.host, options.shareName);
  }

  private nextMessageId(): number {
    const value: number = this.messageId;
    this.messageId += 1;
    return value;
  }

  private buildHeader(command: number, treeId: number = 0, signed: boolean = false): Array<number> {
    const header: Array<number> = bytes(64);
    header[0] = 0xFE;
    header[1] = 0x53;
    header[2] = 0x4D;
    header[3] = 0x42;
    writeUInt16LE(header, 4, 64);
    writeUInt16LE(header, 6, 1);
    writeUInt16LE(header, 12, command);
    writeUInt16LE(header, 14, 1);
    writeUInt32LE(header, 16, signed ? SMB2_FLAGS_SIGNED : 0);
    writeUInt64LEFromNumber(header, 24, this.nextMessageId());
    writeUInt32LE(header, 36, treeId);
    for (let index = 0; index < 8; index += 1) {
      header[40 + index] = this.sessionId[index] || 0;
    }
    return header;
  }

  private shouldSign(): boolean {
    return (this.serverSecurityMode & 0x02) !== 0 && this.sessionKey.length > 0;
  }

  private signPacket(packet: Array<number>): Array<number> {
    const signedPacket: Array<number> = packet.slice();
    writeUInt32LE(signedPacket, 16, readUInt32LE(signedPacket, 16) | SMB2_FLAGS_SIGNED);
    for (let index = 48; index < 64; index += 1) {
      signedPacket[index] = 0;
    }
    const signature: Array<number> = hmacSha256(this.sessionKey, signedPacket).slice(0, 16);
    for (let index = 0; index < signature.length; index += 1) {
      signedPacket[48 + index] = signature[index];
    }
    return signedPacket;
  }

  private async send(command: number, body: Array<number>, treeId: number = 0, allowSigning: boolean = true): Promise<Array<number>> {
    const unsignedPacket: Array<number> = concatBytes([this.buildHeader(command, treeId, false), body]);
    const packet: Array<number> = allowSigning && this.shouldSign() ? this.signPacket(unsignedPacket) : unsignedPacket;
    const response: Array<number> = await this.transport.request(packet);
    if (response.length < 64 || response[0] !== 0xFE || response[1] !== 0x53 || response[2] !== 0x4D || response[3] !== 0x42) {
      throw new Error('SMB 响应格式异常');
    }
    return response;
  }

  private ensureStatus(response: Array<number>, allowedStatus: Array<number> = [STATUS_SUCCESS]): number {
    const status: number = readUInt32LE(response, 8);
    if (allowedStatus.indexOf(status) < 0) {
      throw new Error(statusMessage(status));
    }
    return status;
  }

  private async negotiate(): Promise<void> {
    const dialects: Array<number> = [0x0202, 0x0210];
    const body: Array<number> = bytes(36 + dialects.length * 2);
    writeUInt16LE(body, 0, 36);
    writeUInt16LE(body, 2, dialects.length);
    writeUInt16LE(body, 4, 1);
    const clientGuid: Array<number> = randomBytesValue(16);
    for (let index = 0; index < clientGuid.length; index += 1) {
      body[12 + index] = clientGuid[index];
    }
    for (let index = 0; index < dialects.length; index += 1) {
      writeUInt16LE(body, 36 + index * 2, dialects[index]);
    }

    const response: Array<number> = await this.send(SMB2_NEGOTIATE, body, 0, false);
    this.ensureStatus(response);
    this.serverSecurityMode = readUInt16LE(response, 66);
  }

  private sessionSetupBody(securityBlob: Array<number>): Array<number> {
    const body: Array<number> = bytes(24 + securityBlob.length);
    writeUInt16LE(body, 0, 25);
    body[2] = 0;
    body[3] = 1;
    writeUInt16LE(body, 12, 64 + 24);
    writeUInt16LE(body, 14, securityBlob.length);
    for (let index = 0; index < securityBlob.length; index += 1) {
      body[24 + index] = securityBlob[index];
    }
    return body;
  }

  private extractSessionSecurityBlob(response: Array<number>): Array<number> {
    const securityOffset: number = readUInt16LE(response, 68);
    const securityLength: number = readUInt16LE(response, 70);
    return response.slice(securityOffset, securityOffset + securityLength);
  }

  private async sessionSetup(options: Smb2UploadOptions): Promise<void> {
    const negotiateBlob: Array<number> = wrapSpnegoNegTokenInit(ntlmNegotiateMessage());
    const challengeResponse: Array<number> = await this.send(SMB2_SESSION_SETUP, this.sessionSetupBody(negotiateBlob), 0, false);
    this.ensureStatus(challengeResponse, [STATUS_MORE_PROCESSING_REQUIRED]);
    this.sessionId = challengeResponse.slice(40, 48);
    const challenge: NtlmChallenge = parseNtlmChallenge(this.extractSessionSecurityBlob(challengeResponse));
    const authenticate: NtlmAuthenticatePayload = buildNtlmAuthenticateMessage(
      challenge,
      options.username,
      options.password,
      options.domain,
      'SKYMAP'
    );
    const authBlob: Array<number> = wrapSpnegoNegTokenResp(authenticate.message);
    const authResponse: Array<number> = await this.send(SMB2_SESSION_SETUP, this.sessionSetupBody(authBlob), 0, false);
    this.ensureStatus(authResponse);
    this.sessionId = authResponse.slice(40, 48);
    this.sessionKey = authenticate.sessionKey;
  }

  private async treeConnect(host: string, shareName: string): Promise<void> {
    const path: Array<number> = utf16LeBytes(`\\\\${host}\\${shareName}`);
    const body: Array<number> = bytes(8 + path.length);
    writeUInt16LE(body, 0, 9);
    writeUInt16LE(body, 4, 64 + 8);
    writeUInt16LE(body, 6, path.length);
    for (let index = 0; index < path.length; index += 1) {
      body[8 + index] = path[index];
    }

    const response: Array<number> = await this.send(SMB2_TREE_CONNECT, body);
    this.ensureStatus(response);
    this.treeId = readUInt32LE(response, 36);
  }

  private async createFile(remotePath: string): Promise<Array<number>> {
    const name: Array<number> = utf16LeBytes(remotePath);
    const body: Array<number> = bytes(56 + name.length);
    writeUInt16LE(body, 0, 57);
    body[3] = 0;
    writeUInt32LE(body, 4, 2);
    writeUInt32LE(body, 24, 0x0012019F);
    writeUInt32LE(body, 28, 0x00000080);
    writeUInt32LE(body, 32, 0x00000007);
    writeUInt32LE(body, 36, 0x00000005);
    writeUInt32LE(body, 40, 0x00000060);
    writeUInt16LE(body, 44, 64 + 56);
    writeUInt16LE(body, 46, name.length);
    for (let index = 0; index < name.length; index += 1) {
      body[56 + index] = name[index];
    }

    const response: Array<number> = await this.send(SMB2_CREATE, body, this.treeId);
    this.ensureStatus(response);
    if (response.length < 144) {
      throw new Error('SMB 创建文件响应异常');
    }
    return response.slice(128, 144);
  }

  private async writeFile(fileId: Array<number>, data: Array<number>): Promise<void> {
    const body: Array<number> = bytes(48 + data.length);
    writeUInt16LE(body, 0, 49);
    writeUInt16LE(body, 2, 64 + 48);
    writeUInt32LE(body, 4, data.length);
    writeUInt64LEFromNumber(body, 8, 0);
    for (let index = 0; index < 16; index += 1) {
      body[16 + index] = fileId[index] || 0;
    }
    for (let index = 0; index < data.length; index += 1) {
      body[48 + index] = data[index];
    }

    const response: Array<number> = await this.send(SMB2_WRITE, body, this.treeId);
    this.ensureStatus(response);
  }

  private async closeFile(fileId: Array<number>): Promise<void> {
    const body: Array<number> = bytes(24);
    writeUInt16LE(body, 0, 24);
    for (let index = 0; index < 16; index += 1) {
      body[8 + index] = fileId[index] || 0;
    }
    const response: Array<number> = await this.send(SMB2_CLOSE, body, this.treeId);
    this.ensureStatus(response);
  }

  private async treeDisconnect(): Promise<void> {
    if (this.treeId === 0) {
      return;
    }
    const body: Array<number> = bytes(4);
    writeUInt16LE(body, 0, 4);
    const response: Array<number> = await this.send(SMB2_TREE_DISCONNECT, body, this.treeId);
    this.ensureStatus(response);
    this.treeId = 0;
  }

  private async logoff(): Promise<void> {
    const body: Array<number> = bytes(4);
    writeUInt16LE(body, 0, 4);
    const response: Array<number> = await this.send(SMB2_LOGOFF, body);
    this.ensureStatus(response);
    await this.close();
  }

  private async safeDisconnect(): Promise<void> {
    try {
      await this.treeDisconnect();
    } catch (error) {
    }
    try {
      await this.logoff();
    } catch (error) {
      await this.close();
    }
  }
}
