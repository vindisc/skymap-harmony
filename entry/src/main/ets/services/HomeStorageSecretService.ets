import asset from '@ohos.security.asset';

const HOME_STORAGE_PASSWORD_ALIAS: string = 'skymap.home_storage.password';

function utf8Bytes(value: string): Array<number> {
  const bytes: Array<number> = [];
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
      bytes.push(codePoint);
    } else if (codePoint <= 0x7FF) {
      bytes.push(0xC0 | (codePoint >> 6));
      bytes.push(0x80 | (codePoint & 0x3F));
    } else if (codePoint <= 0xFFFF) {
      bytes.push(0xE0 | (codePoint >> 12));
      bytes.push(0x80 | ((codePoint >> 6) & 0x3F));
      bytes.push(0x80 | (codePoint & 0x3F));
    } else {
      bytes.push(0xF0 | (codePoint >> 18));
      bytes.push(0x80 | ((codePoint >> 12) & 0x3F));
      bytes.push(0x80 | ((codePoint >> 6) & 0x3F));
      bytes.push(0x80 | (codePoint & 0x3F));
    }
  }
  return bytes;
}

function textToBytes(value: string): Uint8Array {
  return new Uint8Array(utf8Bytes(value));
}

function textFromBytes(bytes: Uint8Array): string {
  let result: string = '';
  for (let index = 0; index < bytes.length;) {
    const first: number = bytes[index];
    if (first <= 0x7F) {
      result += String.fromCharCode(first);
      index += 1;
      continue;
    }

    if ((first & 0xE0) === 0xC0 && index + 1 < bytes.length) {
      const codePoint: number = ((first & 0x1F) << 6) | (bytes[index + 1] & 0x3F);
      result += String.fromCharCode(codePoint);
      index += 2;
      continue;
    }

    if ((first & 0xF0) === 0xE0 && index + 2 < bytes.length) {
      const codePoint: number = ((first & 0x0F) << 12) |
        ((bytes[index + 1] & 0x3F) << 6) |
        (bytes[index + 2] & 0x3F);
      result += String.fromCharCode(codePoint);
      index += 3;
      continue;
    }

    if ((first & 0xF8) === 0xF0 && index + 3 < bytes.length) {
      const codePoint: number = ((first & 0x07) << 18) |
        ((bytes[index + 1] & 0x3F) << 12) |
        ((bytes[index + 2] & 0x3F) << 6) |
        (bytes[index + 3] & 0x3F);
      const high: number = Math.floor((codePoint - 0x10000) / 0x400) + 0xD800;
      const low: number = ((codePoint - 0x10000) % 0x400) + 0xDC00;
      result += String.fromCharCode(high, low);
      index += 4;
      continue;
    }

    index += 1;
  }
  return result;
}

function createPasswordQuery(): asset.AssetMap {
  const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
  query.set(asset.Tag.ALIAS, textToBytes(HOME_STORAGE_PASSWORD_ALIAS));
  return query;
}

export class HomeStorageSecretService {
  static async loadPassword(): Promise<string> {
    const query: asset.AssetMap = createPasswordQuery();
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    try {
      const results: Array<asset.AssetMap> = await asset.query(query);
      if (results.length === 0) {
        return '';
      }

      const secret: asset.Value | undefined = results[0].get(asset.Tag.SECRET);
      if (secret instanceof Uint8Array) {
        return textFromBytes(secret);
      }
      return '';
    } catch (error) {
      return '';
    }
  }

  static async savePassword(password: string): Promise<void> {
    if (password.length === 0) {
      await HomeStorageSecretService.clearPassword();
      return;
    }

    const attributes: asset.AssetMap = createPasswordQuery();
    attributes.set(asset.Tag.SECRET, textToBytes(password));
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    attributes.set(asset.Tag.AUTH_TYPE, asset.AuthType.NONE);
    attributes.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
    attributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
    try {
      await asset.add(attributes);
    } catch (error) {
      throw new Error(`安全保存家庭存储密码失败：${error}`);
    }
  }

  static async clearPassword(): Promise<void> {
    try {
      await asset.remove(createPasswordQuery());
    } catch (error) {
    }
  }
}
