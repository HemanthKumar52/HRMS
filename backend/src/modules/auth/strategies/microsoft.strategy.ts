import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../prisma/prisma.service';

/**
 * Microsoft OAuth2 token validation service.
 * Validates Microsoft access tokens by calling the Microsoft Graph API
 * and matches the user's email to an existing HRMS account.
 */
@Injectable()
export class MicrosoftAuthService {
  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {}

  /**
   * Validates a Microsoft access token by calling Microsoft Graph /me endpoint.
   * Returns the user profile from Microsoft if the token is valid.
   */
  async validateMicrosoftToken(accessToken: string): Promise<{
    email: string;
    displayName: string;
    microsoftId: string;
  }> {
    try {
      const response = await fetch('https://graph.microsoft.com/v1.0/me', {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      if (!response.ok) {
        throw new UnauthorizedException('Invalid Microsoft access token');
      }

      const profile = await response.json();

      if (!profile.mail && !profile.userPrincipalName) {
        throw new UnauthorizedException('Microsoft profile does not contain an email address');
      }

      return {
        email: (profile.mail || profile.userPrincipalName).toLowerCase(),
        displayName: profile.displayName || '',
        microsoftId: profile.id,
      };
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Failed to validate Microsoft token');
    }
  }

  /**
   * Finds an existing HRMS user by their Microsoft email.
   * Does NOT create new users - they must already exist in the system.
   */
  async findUserByEmail(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      include: {
        organization: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException(
        'No HRMS account found for this Microsoft email. Please contact your administrator.',
      );
    }

    if (!user.isActive) {
      throw new UnauthorizedException('User account is disabled');
    }

    return user;
  }
}
