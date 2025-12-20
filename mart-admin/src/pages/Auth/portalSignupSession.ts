import { IdentifierType } from '@/services';
import { IUser } from '@/interfaces';

export const PORTAL_SIGNUP_SESSION_KEY = 'portalSignupFlow';

export type PortalSignupStage =
  | 'start'
  | 'otp'
  | 'profile'          // mart details (name, email, contact)
  | 'martEmailOtp'     // verify OTP sent to mart email
  | 'owner'            // owner details
  | 'location'
  | 'complete';

export interface PortalSignupSession {
  stage: PortalSignupStage;
  // Legacy fields (still read to avoid breaking existing sessions)
  martName?: string;
  laundryEmail?: string | null;
  laundryContact?: string | null;

  // New mart fields
  martEmail?: string | null;
  martContact?: string | null;
  martEmailVerified?: boolean;
  identifier: string;
  identifierType: IdentifierType;
  otpExpiresAt?: number;
  registration?: {
    sessionToken: string;
    sessionExpiresAt?: number;
  };
  owner?: {
    name?: string;
    email?: string | null;
    contact?: string | null;
  };
  authPayload?: {
    token: string;
    user: IUser;
  };
  location?: {
    coordinates?: {
      latitude: number;
      longitude: number;
    };
    photoCount?: number;
  };
}

const safeParse = (raw: string | null): PortalSignupSession | null => {
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as PortalSignupSession;
  } catch (error) {
    sessionStorage.removeItem(PORTAL_SIGNUP_SESSION_KEY);
    return null;
  }
};

export const getPortalSignupSession = (): PortalSignupSession | null =>
  safeParse(sessionStorage.getItem(PORTAL_SIGNUP_SESSION_KEY));

export const setPortalSignupSession = (session: PortalSignupSession | null) => {
  if (!session) {
    sessionStorage.removeItem(PORTAL_SIGNUP_SESSION_KEY);
    return;
  }

  sessionStorage.setItem(PORTAL_SIGNUP_SESSION_KEY, JSON.stringify(session));
};

export const updatePortalSignupSession = (
  updater: (previous: PortalSignupSession | null) => PortalSignupSession | null
): PortalSignupSession | null => {
  const previous = getPortalSignupSession();
  const next = updater(previous);

  if (!next) {
    sessionStorage.removeItem(PORTAL_SIGNUP_SESSION_KEY);
    return null;
  }

  sessionStorage.setItem(PORTAL_SIGNUP_SESSION_KEY, JSON.stringify(next));
  return next;
};

export const clearPortalSignupSession = () => {
  sessionStorage.removeItem(PORTAL_SIGNUP_SESSION_KEY);
};

export const maskSignupIdentifier = (identifier: string, type: IdentifierType) => {
  if (type === 'email') {
    const [local, domain] = identifier.split('@');

    if (!local || !domain) {
      return identifier;
    }

    if (local.length <= 2) {
      return `${local.slice(0, 1)}***@${domain}`;
    }

    return `${local.slice(0, 2)}***@${domain}`;
  }

  if (identifier.length <= 4) {
    return identifier;
  }

  return `••••${identifier.slice(-4)}`;
};

