import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { LoginDto, RegisterDto } from './dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const user = await this.users.create(dto.email, dto.password, dto.locale ?? 'en');
    return this.tokenResponse(user.id, user.email);
  }

  async login(dto: LoginDto) {
    const user = this.users.findByEmail(dto.email);
    if (!user || !(await this.users.validatePassword(user, dto.password))) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.tokenResponse(user.id, user.email);
  }

  me(userId: string) {
    return this.users.toPublic(this.users.findById(userId));
  }

  private tokenResponse(userId: string, email: string) {
    const accessToken = this.jwt.sign(
      { sub: userId, email },
      { expiresIn: '7d' },
    );
    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn: 60 * 60 * 24 * 7,
      user: this.users.toPublic(this.users.findById(userId)),
    };
  }
}
