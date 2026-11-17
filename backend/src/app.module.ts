import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { BillingModule } from './billing/billing.module';
import { EvolutionModule } from './evolution/evolution.module';
import { HealthController } from './health.controller';
import { UsersModule } from './users/users.module';

@Module({
  imports: [UsersModule, AuthModule, BillingModule, EvolutionModule],
  controllers: [HealthController],
})
export class AppModule {}
