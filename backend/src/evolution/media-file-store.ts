import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

export type StoredMedia = {
  absolutePath: string;
  relativeKey: string;
  mime: string;
  bytes: number;
};

/**
 * Persist inbound Evolution media on disk so sync JSON stays small.
 * Keyed by notificationKey hash.
 */
export class MediaFileStore {
  private readonly root: string;

  constructor(root?: string) {
    this.root =
      root ||
      process.env.WAMEMORY_MEDIA_DIR ||
      join(tmpdir(), 'wamemory-media');
    if (!existsSync(this.root)) {
      mkdirSync(this.root, { recursive: true });
    }
  }

  private safeName(notificationKey: string, ext: string): string {
    const hash = createHash('sha1').update(notificationKey).digest('hex');
    const cleanExt = (ext || 'bin').replace(/[^a-z0-9]/gi, '').slice(0, 8) || 'bin';
    return `${hash}.${cleanExt}`;
  }

  write(
    notificationKey: string,
    base64: string,
    mime?: string | null,
    fileName?: string | null,
  ): StoredMedia | null {
    try {
      let b64 = base64.trim();
      const i = b64.indexOf('base64,');
      if (i >= 0) b64 = b64.slice(i + 7);
      const buf = Buffer.from(b64, 'base64');
      if (buf.length === 0) return null;
      const ext =
        (fileName && fileName.includes('.')
          ? fileName.split('.').pop()
          : null) ||
        (mime?.includes('jpeg') || mime?.includes('jpg')
          ? 'jpg'
          : mime?.includes('png')
            ? 'png'
            : mime?.includes('mp4')
              ? 'mp4'
              : mime?.includes('ogg') || mime?.includes('opus')
                ? 'ogg'
                : mime?.includes('mpeg') || mime?.includes('mp3')
                  ? 'mp3'
                  : mime?.includes('webp')
                    ? 'webp'
                    : 'bin');
      const name = this.safeName(notificationKey, ext);
      const absolutePath = join(this.root, name);
      writeFileSync(absolutePath, buf);
      return {
        absolutePath,
        relativeKey: name,
        mime: mime || 'application/octet-stream',
        bytes: buf.length,
      };
    } catch {
      return null;
    }
  }

  read(relativeKey: string): { buf: Buffer; mimeHint: string } | null {
    const safe = relativeKey.replace(/[^a-zA-Z0-9._-]/g, '');
    if (!safe) return null;
    const absolutePath = join(this.root, safe);
    if (!existsSync(absolutePath)) return null;
    const buf = readFileSync(absolutePath);
    const ext = safe.split('.').pop()?.toLowerCase() || 'bin';
    const mimeHint =
      ext === 'jpg' || ext === 'jpeg'
        ? 'image/jpeg'
        : ext === 'png'
          ? 'image/png'
          : ext === 'mp4'
            ? 'video/mp4'
            : ext === 'ogg' || ext === 'opus'
              ? 'audio/ogg'
              : ext === 'mp3'
                ? 'audio/mpeg'
                : ext === 'webp'
                  ? 'image/webp'
                  : 'application/octet-stream';
    return { buf, mimeHint };
  }
}
