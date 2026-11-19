import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Type } from 'class-transformer';

export class SendTextDto {
  @IsString()
  @MinLength(8)
  @MaxLength(15)
  @Matches(/^\d+$/, { message: 'number must be digits only with country code' })
  number!: string;

  @IsString()
  @MinLength(1)
  text!: string;

  /** Subscriber's linked WhatsApp number (owner instance). */
  @IsOptional()
  @IsString()
  fromPhone?: string;
}

export class LinkPhoneDto {
  @IsString({ message: 'phone must be a string' })
  @MinLength(8, {
    message: 'Invalid phone — use country code + number (e.g. 998901234567)',
  })
  @MaxLength(15, { message: 'Invalid phone — too many digits' })
  @Matches(/^\d+$/, {
    message: 'Invalid phone — digits only, no spaces or +',
  })
  phone!: string;
}

export class SendMediaDto {
  @IsString()
  @MinLength(8)
  @MaxLength(15)
  @Matches(/^\d+$/, { message: 'number must be digits only with country code' })
  number!: string;

  /** image | video | audio | document */
  @IsString()
  @MinLength(3)
  mediaType!: string;

  @IsString()
  @MinLength(3)
  mimetype!: string;

  /** Raw base64 or data-URL. */
  @IsString()
  @MinLength(8)
  media!: string;

  @IsOptional()
  @IsString()
  fileName?: string;

  @IsOptional()
  @IsString()
  caption?: string;

  @IsOptional()
  @IsString()
  fromPhone?: string;
}

export class SyncQueryDto {
  @IsOptional()
  @Type(() => Number)
  after?: number;

  @IsOptional()
  @IsString()
  phone?: string;
}
