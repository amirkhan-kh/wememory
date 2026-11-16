import {
  Controller,
  Get,
  Headers,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { BillingService } from './billing.service';

@Controller('billing')
export class BillingController {
  constructor(
    private readonly billing: BillingService,
    private readonly jwt: JwtService,
  ) {}

  @Get('plan')
  plan() {
    return this.billing.getPlan();
  }

  @Get('subscription')
  subscription(@Headers('authorization') authorization?: string) {
    const userId = this.userId(authorization);
    return this.billing.getForUser(userId) ?? { status: 'none' };
  }

  @Post('trial')
  startTrial(@Headers('authorization') authorization?: string) {
    const userId = this.userId(authorization);
    return this.billing.startTrial(userId);
  }

  @Post('checkout')
  checkout(@Headers('authorization') authorization?: string) {
    const userId = this.userId(authorization);
    return this.billing.createCheckout(userId);
  }

  private userId(authorization?: string): string {
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }
    try {
      return this.jwt.verify<{ sub: string }>(authorization.slice(7)).sub;
    } catch {
      throw new UnauthorizedException('Invalid token');
    }
  }
}
