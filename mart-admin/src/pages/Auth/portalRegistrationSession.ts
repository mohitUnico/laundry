import { IdentifierType } from '@/services';

export const PORTAL_REGISTRATION_SESSION_KEY = 'portalRegistrationSession';

export interface PortalRegistrationSessionPayload {
  sessionToken: string;
  identifier: string;
  identifierType: IdentifierType;
  expiresAt?: number;
}

