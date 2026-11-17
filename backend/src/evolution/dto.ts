import { IsOptional, IsString, MinLength } from 'class-validator';
import { Type } from 'class-transformer';

export class SendTextDto {
  @IsString()
  @MinLength(5)
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
  @IsString()
  @MinLength(8)
  phone!: string;
}

export class SendMediaDto {
  @IsString()
  @MinLength(5)
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
