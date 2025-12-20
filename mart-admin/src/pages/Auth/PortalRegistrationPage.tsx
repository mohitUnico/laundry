import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { ROUTES } from '@/routes';
import { authApi, CompleteRegistrationPayload, IdentifierType } from '@/services';
import { useAuth } from '@/hooks';
import { Loader } from '@/components/common';
import {
  PORTAL_REGISTRATION_SESSION_KEY,
  PortalRegistrationSessionPayload,
} from './portalRegistrationSession';
import styles from './PortalRegistrationPage.module.scss';

export const PortalRegistrationPage: React.FC = () => {
  const navigate = useNavigate();
  const { completeLogin } = useAuth();

  const [session, setSession] = useState<PortalRegistrationSessionPayload | null>(null);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const stored = sessionStorage.getItem(PORTAL_REGISTRATION_SESSION_KEY);

    if (!stored) {
      navigate(ROUTES.LOGIN, { replace: true });
      return;
    }

    try {
      const parsed = JSON.parse(stored) as PortalRegistrationSessionPayload;

      if (!parsed?.sessionToken || !parsed?.identifier || !parsed?.identifierType) {
        throw new Error('Invalid session payload');
      }

      if (parsed.expiresAt && parsed.expiresAt < Date.now()) {
        sessionStorage.removeItem(PORTAL_REGISTRATION_SESSION_KEY);
        navigate(ROUTES.LOGIN, {
          replace: true,
          state: { registrationExpired: true },
        });
        return;
      }

      setSession(parsed);
      setInfo('Almost there! Add a few details so we can finish setting up your account.');

      if (parsed.identifierType === 'email') {
        setEmail(parsed.identifier);
      } else {
        setPhone(parsed.identifier);
      }
    } catch (err) {
      sessionStorage.removeItem(PORTAL_REGISTRATION_SESSION_KEY);
      navigate(ROUTES.LOGIN, { replace: true });
    }
  }, [navigate]);

  const identifierType = session?.identifierType;

  const verifiedFieldLabel = useMemo(() => {
    if (!identifierType) {
      return 'Identifier';
    }
    return identifierType === 'email' ? 'Verified Email' : 'Verified Phone Number';
  }, [identifierType]);

  const optionalFieldLabel = useMemo(() => {
    if (!identifierType) {
      return null;
    }
    return identifierType === 'email' ? 'Contact Number (Optional)' : 'Email (Optional)';
  }, [identifierType]);

  const optionalFieldType: IdentifierType | null = useMemo(() => {
    if (!identifierType) {
      return null;
    }
    return identifierType === 'email' ? 'phone' : 'email';
  }, [identifierType]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!session) {
      setError('Registration session not found. Please restart the login process.');
      return;
    }

    if (!name.trim()) {
      setError('Please provide your name.');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const trimmedName = name.trim();
      const trimmedEmail = email.trim();
      const normalizedPhone = phone.trim() ? phone.trim().replace(/\D/g, '') : '';

      const profilePayload: CompleteRegistrationPayload['profile'] = {
        name: trimmedName,
      };

      if (trimmedEmail) {
        profilePayload.email = trimmedEmail;
      }

      if (normalizedPhone) {
        profilePayload.phone = normalizedPhone;
      }

      const payload: CompleteRegistrationPayload = {
        sessionToken: session.sessionToken,
        profile: profilePayload,
      };

      const response = await authApi.completePortalRegistration(payload);

      if (!response?.success) {
        setError(response?.message || 'Registration failed. Please try again.');
        return;
      }

      const { token, user } = response.data || {};

      if (!token || !user) {
        setError('Registration succeeded but user details are missing. Please try again.');
        return;
      }

      sessionStorage.removeItem(PORTAL_REGISTRATION_SESSION_KEY);
      setInfo('Registration completed! Redirecting you to the dashboard...');
      completeLogin(user, token);
      navigate(ROUTES.DASHBOARD, { replace: true });
    } catch (err) {
      if (axios.isAxiosError(err)) {
        setError(err.response?.data?.message || 'Failed to complete registration.');
      } else {
        setError((err as Error)?.message || 'Failed to complete registration.');
      }
    } finally {
      setLoading(false);
    }
  };

  if (!session) {
    return (
      <div className={styles.loadingContainer}>
        <Loader />
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <div className={styles.leftPane}>
        <div className={styles.leftContent}>
          <h1 className={styles.heading}>Let’s complete your profile</h1>
          <p className={styles.subtext}>
            We verified your contact. Share a few more details and you’ll be ready to manage your
            mart dashboard.
          </p>
        </div>
      </div>

      <div className={styles.rightPane}>
        <form className={styles.formCard} onSubmit={handleSubmit}>
          <h2 className={styles.formTitle}>Complete Registration</h2>
          <p className={styles.formSubtitle}>Tell us who you are so we can tailor the dashboard.</p>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="name">Full Name</label>
            <input
              id="name"
              className={styles.textInput}
              type="text"
              placeholder="Enter your name"
              value={name}
              onChange={(event) => setName(event.target.value)}
              required
            />
          </div>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="verified">
              {verifiedFieldLabel}
            </label>
            <input
              id="verified"
              className={styles.textInput}
              type={identifierType === 'email' ? 'email' : 'tel'}
              value={identifierType === 'email' ? email : phone}
              readOnly
              disabled
            />
          </div>

          {optionalFieldLabel && optionalFieldType && (
            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="optional">
                {optionalFieldLabel}
              </label>
              <input
                id="optional"
                className={styles.textInput}
                type={optionalFieldType === 'email' ? 'email' : 'tel'}
                placeholder={
                  optionalFieldType === 'email'
                    ? 'Enter a contact email'
                    : 'Enter a contact number'
                }
                value={optionalFieldType === 'email' ? email : phone}
                onChange={(event) =>
                  optionalFieldType === 'email'
                    ? setEmail(event.target.value)
                    : setPhone(event.target.value)
                }
              />
            </div>
          )}

          {error && <div className={styles.errorMessage}>{error}</div>}
          {info && !error && <div className={styles.infoMessage}>{info}</div>}

          <button type="submit" className={styles.primaryBtn} disabled={loading}>
            {loading ? 'Saving…' : 'Finish Registration'}
          </button>

          <button
            type="button"
            className={styles.secondaryBtn}
            onClick={() => {
              sessionStorage.removeItem(PORTAL_REGISTRATION_SESSION_KEY);
              navigate(ROUTES.LOGIN, { replace: true });
            }}
          >
            Start over
          </button>
        </form>
      </div>
    </div>
  );
};

export default PortalRegistrationPage;

