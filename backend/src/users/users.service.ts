import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import * as bcrypt from 'bcryptjs';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  private readonly users = new Map<string, User>();

  async create(email: string, password: string, locale: 'en' | 'ru' = 'en'): Promise<User> {
    const normalized = email.trim().toLowerCase();
    if ([...this.users.values()].some((u) => u.email === normalized)) {
      throw new ConflictException('Email already registered');
    }
    const user: User = {
      id: randomUUID(),
      email: normalized,
      passwordHash: await bcrypt.hash(password, 12),
      locale,
      status: 'active',
      createdAt: new Date().toISOString(),
    };
    this.users.set(user.id, user);
    return user;
  }

  findByEmail(email: string): User | undefined {
    const normalized = email.trim().toLowerCase();
    return [...this.users.values()].find((u) => u.email === normalized);
  }

  findById(id: string): User {
    const user = this.users.get(id);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.passwordHash);
  }

  toPublic(user: User) {
    return {
      id: user.id,
      email: user.email,
      locale: user.locale,
      status: user.status,
      createdAt: user.createdAt,
    };
  }
}
