import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';

export type SubscriptionStatus =
  | 'trial'
  | 'active'
  | 'past_due'
  | 'canceled'
  | 'expired';

export interface Subscription {
  id: string;
  userId: string;
  planId: 'premium_monthly';
  status: SubscriptionStatus;
  provider: 'lemon_squeezy' | 'paddle' | 'manual';
  currentPeriodEnd: string;
  gracePeriodEnd: string | null;
  createdAt: string;
}

@Injectable()
export class BillingService {
  private readonly subs = new Map<string, Subscription>();

  getPlan() {
    return {
      id: 'premium_monthly',
      name: 'WAMemory Premium',
      priceUsd: 5,
      currency: 'USD',
      interval: 'month',
      trialDays: 7,
      storageQuotaGb: 2,
      accountsIncluded: 1,
    };
  }

  getForUser(userId: string): Subscription | null {
    return [...this.subs.values()].find((s) => s.userId === userId) ?? null;
  }

  startTrial(userId: string): Subscription {
    const existing = this.getForUser(userId);
    if (existing) return existing;

    const now = new Date();
    const trialEnd = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const sub: Subscription = {
      id: randomUUID(),
      userId,
      planId: 'premium_monthly',
      status: 'trial',
      provider: 'manual',
      currentPeriodEnd: trialEnd.toISOString(),
      gracePeriodEnd: null,
      createdAt: now.toISOString(),
    };
    this.subs.set(sub.id, sub);
    return sub;
  }

  /**
   * Placeholder until Lemon Squeezy / Paddle merchant account is approved.
   * Returns a fake checkout URL for mobile UI wiring.
   */
  createCheckout(userId: string) {
    const sub = this.startTrial(userId);
    return {
      checkoutUrl: `https://wamemory.local/checkout/mock?user=${userId}&sub=${sub.id}`,
      subscription: sub,
      note: 'Replace with Lemon Squeezy or Paddle checkout after merchant onboarding.',
    };
  }

  requireSub(userId: string): Subscription {
    const sub = this.getForUser(userId);
    if (!sub) throw new NotFoundException('No subscription');
    return sub;
  }
}
