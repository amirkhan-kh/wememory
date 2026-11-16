export type UserStatus = 'active' | 'disabled';

export interface User {
  id: string;
  email: string;
  passwordHash: string;
  locale: 'en' | 'ru';
  status: UserStatus;
  createdAt: string;
}
