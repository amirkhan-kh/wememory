import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { MediaFileStore } from './media-file-store';
import { MediaKind, MessageStore, SyncedMessage } from './message-store';

/** Max base64 chars kept inline in sync JSON (small images only). */
const MAX_INLINE_B64 = 400_000;
/** Max base64 chars accepted from Evolution getBase64 (≈18MB binary). */
const MAX_FETCH_B64 = 25_000_000;

export type EvolutionConnectionState = {
  instance: string;
  phone: string;
  state: string;
};

export type LinkResult = {
  phone: string;
  instance: string;
  pairingCode: string | null;
  qrBase64: string | null;
  state: string;
  banWarning: string;
};

const BAN_WARNING =
  'Unofficial Linked Device (Evolution/Baileys). WhatsApp may ban the number. One WhatsApp number per subscriber. Prefer a dedicated test account for trials.';

@Injectable()
export class EvolutionService {
  private readonly log = new Logger(EvolutionService.name);
  private readonly baseUrl =
    process.env.EVOLUTION_BASE_URL?.replace(/\/$/, '') ||
    'http://127.0.0.1:8080';
  private readonly apiKey = process.env.EVOLUTION_API_KEY || '';
  private readonly defaultInstance =
    process.env.EVOLUTION_INSTANCE?.trim() || 'wamemory';

  /** phone digits → instance name */
  private readonly phoneInstances = new Map<string, string>();
  /** instance → phone digits */
  private readonly instancePhones = new Map<string, string>();

  readonly store = new MessageStore();
  readonly mediaFiles = new MediaFileStore();
  readonly recentEvents: unknown[] = [];
  /** Latest QR / pairing from webhooks (qrcode.updated). */
  private readonly linkCodes = new Map<
    string,
    { pairingCode: string | null; qrBase64: string | null; at: number }
  >();

  configured(): boolean {
    return this.apiKey.length > 0;
  }

  normalizePhone(raw: string): string {
    return (raw || '').replace(/[^\d]/g, '');
  }

  instanceForPhone(phone: string): string {
    const digits = this.normalizePhone(phone);
    if (!digits || digits.length < 8) {
      throw new BadRequestException('Phone must include country code, digits only');
    }
    return this.phoneInstances.get(digits) || `wa_${digits}`;
  }

  private headers(): Record<string, string> {
    return {
      apikey: this.apiKey,
      'Content-Type': 'application/json',
    };
  }

  private async evo<T>(
    method: string,
    path: string,
    body?: unknown,
  ): Promise<T> {
    if (!this.configured()) {
      throw new ServiceUnavailableException(
        'EVOLUTION_API_KEY not set on API server',
      );
    }
    const transport = (process.env.EVOLUTION_TRANSPORT || 'http').toLowerCase();
    if (transport === 'docker-curl') {
      return this.evoDockerCurl<T>(method, path, body);
    }
    const url = `${this.baseUrl}${path}`;
    let res: Response;
    try {
      res = await fetch(url, {
        method,
        headers: this.headers(),
        body: body === undefined ? undefined : JSON.stringify(body),
      });
    } catch (e) {
      this.log.warn(`Evolution unreachable: ${url} (${e})`);
      throw new ServiceUnavailableException(
        'Evolution API unreachable. Is docker compose up?',
      );
    }
    return this.parseEvoResponse<T>(method, path, res.status, await res.text());
  }

  /**
   * Colima/Mac sometimes breaks published-port HTTP (empty reply).
   * Call Evolution on the Docker network via a one-shot curl container.
   */
  private async evoDockerCurl<T>(
    method: string,
    path: string,
    body?: unknown,
  ): Promise<T> {
    const { spawn } = await import('node:child_process');
    const network =
      process.env.EVOLUTION_DOCKER_NETWORK || 'evolution_evolution';
    const url = `${this.baseUrl}${path}`;
    const args = [
      'run',
      '--rm',
      '--network',
      network,
      'curlimages/curl:8.5.0',
      '-sS',
      '-w',
      '\n__HTTP_STATUS__:%{http_code}',
      '-X',
      method,
      '-H',
      `apikey: ${this.apiKey}`,
      '-H',
      'Content-Type: application/json',
    ];
    if (body !== undefined) {
      args.push('-d', JSON.stringify(body));
    }
    args.push(url);

    const text: string = await new Promise((resolve, reject) => {
      const child = spawn('docker', args, { stdio: ['ignore', 'pipe', 'pipe'] });
      let out = '';
      let err = '';
      child.stdout.on('data', (c: Buffer) => {
        out += c.toString();
      });
      child.stderr.on('data', (c: Buffer) => {
        err += c.toString();
      });
      child.on('error', reject);
      child.on('close', (code) => {
        if (code !== 0 && !out.includes('__HTTP_STATUS__')) {
          reject(new Error(err || `docker curl exit ${code}`));
          return;
        }
        resolve(out);
      });
    });

    const marker = '\n__HTTP_STATUS__:';
    const idx = text.lastIndexOf(marker);
    const bodyText = idx >= 0 ? text.slice(0, idx) : text;
    const status =
      idx >= 0 ? Number(text.slice(idx + marker.length).trim()) || 500 : 500;
    return this.parseEvoResponse<T>(method, path, status, bodyText);
  }

  private parseEvoResponse<T>(
    method: string,
    path: string,
    status: number,
    text: string,
  ): T {
    let json: unknown = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = { raw: text };
    }
    if (status >= 400) {
      this.log.warn(`Evolution ${method} ${path} → ${status} ${text}`);
      throw new ServiceUnavailableException(`Evolution error ${status}`);
    }
    return json as T;
  }

  status() {
    return {
      configured: this.configured(),
      baseUrl: this.baseUrl,
      instance: this.defaultInstance,
      linkedPhones: [...this.phoneInstances.keys()],
      recentEventCount: this.recentEvents.length,
      latestSeq: this.store.latestSeq,
      banWarning: BAN_WARNING,
    };
  }

  private remember(phone: string, instance: string) {
    this.phoneInstances.set(phone, instance);
    this.instancePhones.set(instance, phone);
  }

  /** Recover phone from instance name `wa_<digits>` when map is cold. */
  private phoneFromInstance(instance: string): string {
    const known = this.instancePhones.get(instance);
    if (known) return known;
    const m = /^wa_(\d{8,})$/.exec(instance);
    if (m) {
      this.remember(m[1], instance);
      return m[1];
    }
    return '';
  }

  private stripDataUrl(raw: string): string {
    const i = raw.indexOf('base64,');
    return i >= 0 ? raw.substring(i + 7) : raw;
  }

  private extractPairing(raw: unknown): {
    pairingCode: string | null;
    qrBase64: string | null;
    state: string;
  } {
    const obj = (raw || {}) as Record<string, unknown>;
    const pairingCode =
      (typeof obj.pairingCode === 'string' && obj.pairingCode) ||
      (typeof obj.pairing_code === 'string' && obj.pairing_code) ||
      null;
    let qrBase64: string | null = null;
    if (typeof obj.base64 === 'string' && obj.base64) {
      qrBase64 = this.stripDataUrl(obj.base64);
    } else if (obj.qrcode && typeof obj.qrcode === 'object') {
      const q = obj.qrcode as Record<string, unknown>;
      if (typeof q.base64 === 'string') qrBase64 = this.stripDataUrl(q.base64);
    }
    const instance = obj.instance as Record<string, unknown> | undefined;
    const state =
      (typeof instance?.state === 'string' && instance.state) ||
      (typeof obj.state === 'string' && obj.state) ||
      'connecting';
    return { pairingCode, qrBase64, state };
  }

  /**
   * One subscriber → one WhatsApp number.
   * Create + connect immediately with `?number=` (pairing code preferred).
   */
  async linkPhone(rawPhone: string): Promise<LinkResult> {
    const phone = this.normalizePhone(rawPhone);
    if (phone.length < 8) {
      throw new BadRequestException(
        'Enter WhatsApp number with country code (e.g. 998901234567)',
      );
    }
    const instance = this.instanceForPhone(phone);
    this.remember(phone, instance);

    let createdPayload: unknown = null;
    try {
      await this.evo('GET', `/instance/connectionState/${instance}`);
    } catch {
      createdPayload = await this.evo('POST', '/instance/create', {
        instanceName: instance,
        number: phone,
        integration: 'WHATSAPP-BAILEYS',
        qrcode: true,
      });
    }

    let extracted = this.extractPairing(
      (createdPayload as { qrcode?: unknown } | null)?.qrcode ?? createdPayload,
    );

    for (let attempt = 0; attempt < 6; attempt++) {
      if (extracted.pairingCode || extracted.qrBase64 || extracted.state === 'open') {
        break;
      }
      if (attempt > 0) {
        await new Promise((r) => setTimeout(r, 2000));
      }
      const connect = await this.evo<unknown>(
        'GET',
        `/instance/connect/${instance}?number=${encodeURIComponent(phone)}`,
      );
      extracted = this.extractPairing(connect);
      const fromHook = this.linkCodes.get(instance);
      if (!extracted.pairingCode && fromHook?.pairingCode) {
        extracted.pairingCode = fromHook.pairingCode;
      }
      if (!extracted.qrBase64 && fromHook?.qrBase64) {
        extracted.qrBase64 = fromHook.qrBase64;
      }
      this.log.log(
        `linkPhone attempt=${attempt + 1} pairing=${extracted.pairingCode} qr=${extracted.qrBase64 ? 'yes' : 'no'} state=${extracted.state}`,
      );
    }

    let state = extracted.state;
    try {
      const st = await this.connectionState(phone);
      state = st.state;
    } catch {
      // keep extracted
    }

    const fromHook = this.linkCodes.get(instance);
    return {
      phone,
      instance,
      pairingCode: extracted.pairingCode || fromHook?.pairingCode || null,
      qrBase64: extracted.qrBase64 || fromHook?.qrBase64 || null,
      state,
      banWarning: BAN_WARNING,
    };
  }

  async connectQr(phone?: string): Promise<unknown> {
    if (phone) return this.linkPhone(phone);
    const instance = this.defaultInstance;
    try {
      await this.evo('GET', `/instance/connectionState/${instance}`);
    } catch {
      await this.evo('POST', '/instance/create', {
        instanceName: instance,
        integration: 'WHATSAPP-BAILEYS',
        qrcode: true,
      });
    }
    return this.evo('GET', `/instance/connect/${instance}`);
  }

  async connectionState(rawPhone?: string): Promise<EvolutionConnectionState> {
    const phone = rawPhone ? this.normalizePhone(rawPhone) : '';
    const instance = phone
      ? this.instanceForPhone(phone)
      : this.defaultInstance;
    if (phone) this.remember(phone, instance);
    const raw = await this.evo<{
      instance?: { instanceName?: string; state?: string };
      state?: string;
    }>('GET', `/instance/connectionState/${instance}`);
    const state = raw?.instance?.state || raw?.state || 'unknown';
    return { instance, phone: phone || this.instancePhones.get(instance) || '', state };
  }

  async sendText(
    number: string,
    text: string,
    fromPhone?: string,
  ): Promise<unknown> {
    const digits = this.normalizePhone(number);
    if (!digits || !text.trim()) {
      throw new BadRequestException('number and text required');
    }
    const owner = fromPhone ? this.normalizePhone(fromPhone) : '';
    const instance = owner
      ? this.instanceForPhone(owner)
      : this.defaultInstance;
    return this.evo('POST', `/message/sendText/${instance}`, {
      number: digits,
      text: text.trim(),
    });
  }

  async sendMedia(input: {
    number: string;
    mediaType: string;
    mimetype: string;
    media: string;
    fileName?: string;
    caption?: string;
    fromPhone?: string;
  }): Promise<unknown> {
    const digits = this.normalizePhone(input.number);
    const kind = (input.mediaType || '').toLowerCase();
    if (!digits || !input.media?.trim()) {
      throw new BadRequestException('number and media required');
    }
    if (!['image', 'video', 'audio', 'document'].includes(kind)) {
      throw new BadRequestException(
        'mediaType must be image|video|audio|document',
      );
    }
    const owner = input.fromPhone ? this.normalizePhone(input.fromPhone) : '';
    const instance = owner
      ? this.instanceForPhone(owner)
      : this.defaultInstance;
    const media = this.stripDataUrl(input.media.trim());
    const fileName =
      input.fileName?.trim() ||
      (kind === 'image'
        ? 'image.jpg'
        : kind === 'video'
          ? 'video.mp4'
          : kind === 'audio'
            ? 'audio.ogg'
            : 'file.bin');
    return this.evo('POST', `/message/sendMedia/${instance}`, {
      number: digits,
      mediatype: kind,
      mimetype: input.mimetype || 'application/octet-stream',
      media,
      fileName,
      caption: input.caption?.trim() || undefined,
    });
  }

  async findContacts(rawPhone?: string): Promise<unknown> {
    const phone = rawPhone ? this.normalizePhone(rawPhone) : '';
    const instance = phone
      ? this.instanceForPhone(phone)
      : this.defaultInstance;
    return this.evo('POST', `/chat/findContacts/${instance}`, { where: {} });
  }

  sync(afterSeq = 0, phone?: string): {
    messages: SyncedMessage[];
    latestSeq: number;
  } {
    const digits = phone ? this.normalizePhone(phone) : undefined;
    const messages = this.store.since(afterSeq, digits).map((m) => {
      // Prefer mediaUrl for large payloads; keep tiny inline base64 for images.
      if (m.mediaBase64 && m.mediaBase64.length > MAX_INLINE_B64) {
        return { ...m, mediaBase64: null };
      }
      return m;
    });
    return { messages, latestSeq: this.store.latestSeq };
  }

  getMediaFile(relativeKey: string) {
    return this.mediaFiles.read(relativeKey);
  }

  private persistMedia(
    notificationKey: string,
    base64: string,
    mime: string | null,
    fileName: string | null,
    mediaType: MediaKind,
  ): { mediaUrl: string | null; mediaBase64: string | null } {
    const stored = this.mediaFiles.write(
      notificationKey,
      base64,
      mime,
      fileName,
    );
    if (!stored) return { mediaUrl: null, mediaBase64: null };
    const mediaUrl = `/api/evolution/media/${stored.relativeKey}`;
    // Inline only small images for instant preview.
    const mediaBase64 =
      mediaType === 'image' && base64.length <= MAX_INLINE_B64
        ? this.stripDataUrl(base64)
        : null;
    return { mediaUrl, mediaBase64 };
  }

  ingestWebhook(payload: unknown): { ok: true; ingested: number } {
    this.recentEvents.unshift(payload);
    if (this.recentEvents.length > 200) this.recentEvents.pop();

    const root = (payload || {}) as Record<string, unknown>;
    const event = String(root.event || root.Event || '').toLowerCase();
    const instanceRaw = root.instance;
    const instance =
      typeof instanceRaw === 'string'
        ? instanceRaw
        : typeof instanceRaw === 'object' && instanceRaw
          ? String(
              (instanceRaw as { instanceName?: string }).instanceName || '',
            )
          : '';
    const phone =
      this.phoneFromInstance(instance) ||
      this.normalizePhone(String(root.sender || '')) ||
      '';

    let ingested = 0;

    if (event.includes('qrcode') || event.includes('qrcode.updated')) {
      const data = (root.data || root) as Record<string, unknown>;
      const pairingCode =
        (typeof data.pairingCode === 'string' && data.pairingCode) ||
        (typeof root.pairingCode === 'string' && root.pairingCode) ||
        null;
      let qrBase64: string | null = null;
      const b64 = data.base64 || root.base64 || data.qrcode;
      if (typeof b64 === 'string') qrBase64 = this.stripDataUrl(b64);
      if (instance) {
        this.linkCodes.set(instance, {
          pairingCode,
          qrBase64,
          at: Date.now(),
        });
      }
      ingested++;
    } else if (event.includes('messages.upsert') || event.includes('messages.set')) {
      const data = root.data;
      const items = Array.isArray(data) ? data : data ? [data] : [];
      for (const item of items) {
        const row = this.parseUpsert(item, instance, phone);
        if (row) {
          this.store.upsert(row);
          ingested++;
          if (row.mediaType && !row.mediaBase64) {
            void this.enrichMediaBase64(item, instance, row.notificationKey);
          }
        }
      }
    } else if (
      event.includes('messages.delete') ||
      event.includes('messages.update')
    ) {
      ingested += this.parseDeleteOrUpdate(root.data, instance, phone);
    }

    this.log.log(`Webhook ${event || 'unknown'} ingested=${ingested}`);
    return { ok: true, ingested };
  }

  private parseUpsert(
    item: unknown,
    instance: string,
    phone: string,
  ): Omit<SyncedMessage, 'seq'> | null {
    const msg = item as Record<string, unknown>;
    const key = (msg.key || {}) as Record<string, unknown>;
    const remoteJid = String(key.remoteJid || '');
    const id = String(key.id || '');
    if (!remoteJid || !id) return null;
    const fromMe = Boolean(key.fromMe);
    const pushName = String(msg.pushName || remoteJid.split('@')[0] || 'Chat');
    const message = (msg.message || {}) as Record<string, unknown>;
    const media = this.extractMedia(message);
    let body = '';
    if (typeof message.conversation === 'string') {
      body = message.conversation;
    } else if (
      message.extendedTextMessage &&
      typeof (message.extendedTextMessage as { text?: string }).text === 'string'
    ) {
      body = (message.extendedTextMessage as { text: string }).text;
    } else if (media.caption) {
      body = media.caption;
    } else if (media.mediaType) {
      body = `[${media.mediaType}]`;
    }
    if (!body) return null;
    const tsRaw = msg.messageTimestamp;
    const timestamp =
      typeof tsRaw === 'number'
        ? tsRaw * (tsRaw < 2e10 ? 1000 : 1)
        : typeof tsRaw === 'string'
          ? Number(tsRaw) * 1000
          : Date.now();
    const notificationKey = `${instance}:${id}`;
    let mediaUrl: string | null = null;
    let mediaBase64 = media.mediaBase64;
    if (mediaBase64 && media.mediaType) {
      const persisted = this.persistMedia(
        notificationKey,
        mediaBase64,
        media.mediaMime,
        media.fileName,
        media.mediaType,
      );
      mediaUrl = persisted.mediaUrl;
      mediaBase64 = persisted.mediaBase64;
    }
    return {
      id: notificationKey,
      instance,
      phone,
      remoteJid,
      pushName: fromMe ? 'You' : pushName,
      body: String(body),
      fromMe,
      isDeleted: false,
      timestamp,
      notificationKey,
      mediaType: media.mediaType,
      mediaMime: media.mediaMime,
      mediaBase64,
      mediaUrl,
      fileName: media.fileName,
    };
  }

  private extractMedia(message: Record<string, unknown>): {
    mediaType: MediaKind;
    mediaMime: string | null;
    mediaBase64: string | null;
    fileName: string | null;
    caption: string | null;
  } {
    const empty = {
      mediaType: null as MediaKind,
      mediaMime: null as string | null,
      mediaBase64: null as string | null,
      fileName: null as string | null,
      caption: null as string | null,
    };
    const pick = (
      kind: MediaKind,
      node: Record<string, unknown> | undefined,
      defaultName: string,
    ) => {
      if (!node) return empty;
      const caption =
        typeof node.caption === 'string' ? node.caption : null;
      const mimetype =
        typeof node.mimetype === 'string' ? node.mimetype : null;
      const fileName =
        (typeof node.fileName === 'string' && node.fileName) ||
        (typeof node.filename === 'string' && node.filename) ||
        defaultName;
      let mediaBase64: string | null = null;
      if (typeof node.base64 === 'string' && node.base64.length < MAX_FETCH_B64) {
        mediaBase64 = this.stripDataUrl(node.base64);
      }
      return {
        mediaType: kind,
        mediaMime: mimetype,
        mediaBase64,
        fileName,
        caption,
      };
    };
    if (message.imageMessage) {
      return pick('image', message.imageMessage as Record<string, unknown>, 'image.jpg');
    }
    if (message.videoMessage) {
      return pick('video', message.videoMessage as Record<string, unknown>, 'video.mp4');
    }
    if (message.audioMessage) {
      const audio = message.audioMessage as Record<string, unknown>;
      const ptt = audio.ptt === true;
      return pick(
        'audio',
        audio,
        ptt ? 'voice.ogg' : 'audio.ogg',
      );
    }
    if (message.documentMessage) {
      return pick(
        'document',
        message.documentMessage as Record<string, unknown>,
        'file.bin',
      );
    }
    if (message.stickerMessage) {
      return pick(
        'image',
        message.stickerMessage as Record<string, unknown>,
        'sticker.webp',
      );
    }
    return empty;
  }

  private async enrichMediaBase64(
    item: unknown,
    instance: string,
    notificationKey: string,
  ) {
    try {
      const raw = await this.evo<{ base64?: string; mimetype?: string }>(
        'POST',
        `/chat/getBase64FromMediaMessage/${instance}`,
        { message: item, convertToMp4: false },
      );
      const b64 =
        typeof raw?.base64 === 'string' ? this.stripDataUrl(raw.base64) : null;
      if (!b64 || b64.length > MAX_FETCH_B64) return;
      const existing = this.store.get(notificationKey);
      if (!existing) return;
      const { seq: _seq, ...rest } = existing;
      const persisted = this.persistMedia(
        notificationKey,
        b64,
        raw.mimetype || existing.mediaMime,
        existing.fileName,
        existing.mediaType,
      );
      this.store.republish({
        ...rest,
        mediaMime: raw.mimetype || existing.mediaMime,
        mediaBase64: persisted.mediaBase64,
        mediaUrl: persisted.mediaUrl || existing.mediaUrl,
      });
      this.log.log(
        `Media enriched for ${notificationKey} url=${persisted.mediaUrl} bytes~${Math.floor(b64.length * 0.75)}`,
      );
    } catch (e) {
      this.log.warn(`Media base64 fetch failed for ${notificationKey}: ${e}`);
    }
  }

  private parseDeleteOrUpdate(
    data: unknown,
    instance: string,
    phone: string,
  ): number {
    let n = 0;
    const items = Array.isArray(data) ? data : data ? [data] : [];
    for (const item of items) {
      const row = item as Record<string, unknown>;
      const key = (row.key || row) as Record<string, unknown>;
      const id = String(key.id || '');
      if (!id) continue;
      const notificationKey = `${instance}:${id}`;
      const status = row.update ?? row.status;
      const statusStr = typeof status === 'string' ? status : '';
      // Protocol message revoke often in messages.update
      if (
        row.messageStubType === 1 ||
        statusStr.toUpperCase() === 'REVOKED' ||
        statusStr.toLowerCase().includes('revoke') ||
        row.subtype === 'revoke'
      ) {
        this.store.markDeleted(notificationKey);
        n++;
        continue;
      }
      // Some payloads only send key on delete
      if (row.keys || row.key) {
        const keys = Array.isArray(row.keys) ? row.keys : [key];
        for (const k of keys) {
          const kid = String((k as Record<string, unknown>).id || '');
          if (!kid) continue;
          this.store.markDeleted(`${instance}:${kid}`);
          n++;
        }
      }
      // Keep phone map warm
      if (phone) this.remember(phone, instance);
    }
    return n;
  }
}
