export type MediaKind = 'image' | 'video' | 'audio' | 'document' | null;

export type SyncedMessage = {
  id: string;
  instance: string;
  phone: string;
  remoteJid: string;
  pushName: string;
  body: string;
  fromMe: boolean;
  isDeleted: boolean;
  timestamp: number;
  notificationKey: string;
  seq: number;
  mediaType: MediaKind;
  mediaMime: string | null;
  /** Small inline base64 only (images). Prefer mediaUrl for video/audio. */
  mediaBase64: string | null;
  /** Relative filename under Nest media store → GET /evolution/media/:key */
  mediaUrl: string | null;
  fileName: string | null;
};

/**
 * In-memory bridge store for webhook → device sync.
 * Replace with Postgres in a later milestone; idempotent by notificationKey.
 */
export class MessageStore {
  private seq = 0;
  private readonly byKey = new Map<string, SyncedMessage>();
  private readonly ordered: SyncedMessage[] = [];

  upsert(input: Omit<SyncedMessage, 'seq'>): SyncedMessage {
    const existing = this.byKey.get(input.notificationKey);
    if (existing) {
      const merged: SyncedMessage = {
        ...existing,
        ...input,
        seq: existing.seq,
        isDeleted: input.isDeleted || existing.isDeleted,
        body: input.body || existing.body,
        mediaType: input.mediaType ?? existing.mediaType,
        mediaMime: input.mediaMime || existing.mediaMime,
        mediaBase64: input.mediaBase64 || existing.mediaBase64,
        mediaUrl: input.mediaUrl || existing.mediaUrl,
        fileName: input.fileName || existing.fileName,
      };
      this.byKey.set(input.notificationKey, merged);
      const idx = this.ordered.findIndex((m) => m.seq === existing.seq);
      if (idx >= 0) this.ordered[idx] = merged;
      return merged;
    }
    const row: SyncedMessage = { ...input, seq: ++this.seq };
    this.byKey.set(input.notificationKey, row);
    this.ordered.push(row);
    if (this.ordered.length > 5000) {
      const drop = this.ordered.shift();
      if (drop) this.byKey.delete(drop.notificationKey);
    }
    return row;
  }

  get(notificationKey: string): SyncedMessage | undefined {
    return this.byKey.get(notificationKey);
  }

  /** Re-publish with a new seq so devices re-pull (e.g. media base64 ready). */
  republish(input: Omit<SyncedMessage, 'seq'>): SyncedMessage {
    const existing = this.byKey.get(input.notificationKey);
    if (existing) {
      const idx = this.ordered.findIndex((m) => m.seq === existing.seq);
      if (idx >= 0) this.ordered.splice(idx, 1);
    }
    const row: SyncedMessage = { ...input, seq: ++this.seq };
    this.byKey.set(input.notificationKey, row);
    this.ordered.push(row);
    return row;
  }

  markDeleted(notificationKey: string): SyncedMessage | null {
    const existing = this.byKey.get(notificationKey);
    if (!existing) return null;
    const { seq: _seq, ...rest } = existing;
    return this.upsert({ ...rest, isDeleted: true });
  }

  since(afterSeq: number, phone?: string): SyncedMessage[] {
    return this.ordered.filter((m) => {
      if (m.seq <= afterSeq) return false;
      if (phone && m.phone && m.phone !== phone) return false;
      return true;
    });
  }

  get latestSeq(): number {
    return this.seq;
  }
}
