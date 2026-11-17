import {
  Body,
  Controller,
  Get,
  Inject,
  NotFoundException,
  Param,
  Post,
  Query,
  Req,
  Res,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { LinkPhoneDto, SendMediaDto, SendTextDto } from './dto';
import { EvolutionService } from './evolution.service';

@Controller('evolution')
export class EvolutionController {
  // @Inject required under tsx (no emitDecoratorMetadata).
  constructor(
    @Inject(EvolutionService) private readonly evolution: EvolutionService,
  ) {}

  @Get('status')
  status() {
    return this.evolution.status();
  }

  /** Subscriber enters one WhatsApp number → pairing code / QR. */
  @Post('link')
  async link(@Body() body: LinkPhoneDto) {
    return this.evolution.linkPhone(body.phone);
  }

  @Get('qr')
  async qr(@Query('phone') phone?: string) {
    return this.evolution.connectQr(phone);
  }

  @Get('connection')
  async connection(@Query('phone') phone?: string) {
    return this.evolution.connectionState(phone);
  }

  @Post('send-text')
  async sendText(@Body() body: SendTextDto) {
    return this.evolution.sendText(body.number, body.text, body.fromPhone);
  }

  @Post('send-media')
  async sendMedia(@Body() body: SendMediaDto) {
    return this.evolution.sendMedia({
      number: body.number,
      mediaType: body.mediaType,
      mimetype: body.mimetype,
      media: body.media,
      fileName: body.fileName,
      caption: body.caption,
      fromPhone: body.fromPhone,
    });
  }

  @Get('contacts')
  async contacts(@Query('phone') phone?: string) {
    return this.evolution.findContacts(phone);
  }

  /** Real-time device pull (poll every 1–2s while app open). */
  @Get('sync')
  sync(
    @Query('after') after?: string,
    @Query('phone') phone?: string,
  ) {
    const afterSeq = after ? Number(after) || 0 : 0;
    return this.evolution.sync(afterSeq, phone);
  }

  @Get('events')
  events() {
    return { events: this.evolution.recentEvents };
  }

  @Post('webhook')
  webhook(@Req() req: Request) {
    return this.evolution.ingestWebhook(req.body);
  }

  /** Evolution may POST to /webhook/<event-name>. */
  @Post('webhook/*')
  webhookEvent(@Req() req: Request) {
    return this.evolution.ingestWebhook(req.body);
  }

  /** Download persisted video/audio/image bytes for device archive. */
  @Get('media/:key')
  media(@Param('key') key: string, @Res() res: Response) {
    const file = this.evolution.getMediaFile(key);
    if (!file) throw new NotFoundException('media not found');
    res.setHeader('Content-Type', file.mimeHint);
    res.setHeader('Cache-Control', 'private, max-age=86400');
    res.send(file.buf);
  }
}
