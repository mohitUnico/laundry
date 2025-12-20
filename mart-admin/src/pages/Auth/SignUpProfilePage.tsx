import axios from 'axios';
import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import { authApi } from '@/services';
import styles from './SignUpProfilePage.module.scss';
import {
  clearPortalSignupSession,
  getPortalSignupSession,
  maskSignupIdentifier,
  updatePortalSignupSession,
} from './portalSignupSession';

const sanitizePhone = (value: string) => value.replace(/\D/g, '');

export const SignUpProfilePage: React.FC = () => {
  const [martName, setMartName] = useState('');
  const [martEmail, setMartEmail] = useState('');
  const [martContact, setMartContact] = useState('');
  const [imgFailed, setImgFailed] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const navigate = useNavigate();
  const session = useMemo(() => getPortalSignupSession(), []);

  const identifierDescription = useMemo(() => {
    if (!session) {
      return '';
    }
    const masked = maskSignupIdentifier(session.identifier, session.identifierType);
    return session.identifierType === 'email'
      ? `We’ve verified ${masked}.`
      : `We’ve verified ${masked}.`;
  }, [session]);

  useEffect(() => {
    if (!session || !session.registration?.sessionToken) {
      navigate(ROUTES.SIGNUP, { replace: true });
      return;
    }

    if (session.martName) setMartName(session.martName);
    if (session.martEmail ?? session.laundryEmail) {
      setMartEmail((session.martEmail ?? session.laundryEmail) || '');
    }
    if (session.martContact ?? session.laundryContact) {
      setMartContact((session.martContact ?? session.laundryContact) || '');
    }

    const masked = maskSignupIdentifier(session.identifier, session.identifierType);
    setInfo(
      session.identifierType === 'email'
        ? `OTP verification completed for ${masked}. You can add a contact number as well.`
        : `OTP verification completed for ${masked}. You can add an email address too.`
    );
  }, [navigate, session]);

  if (!session || !session.registration?.sessionToken) {
    return null;
  }

  const isEmailLocked = false;
  const isContactLocked = false;

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');

    const trimmedName = martName.trim();
    const trimmedEmail = martEmail.trim().toLowerCase();
    const cleanedContact = sanitizePhone(martContact.trim());

    if (!trimmedName) {
      setError('Please enter mart name.');
      return;
    }
    if (!trimmedEmail) {
      setError('Please enter mart email.');
      return;
    }
    if (!cleanedContact) {
      setError('Please enter mart contact number.');
      return;
    }
    // Ensure mart email differs from owner (identifier) email if owner used email
    if (session.identifierType === 'email' && trimmedEmail === session.identifier.toLowerCase()) {
      setError('Mart email must be different from owner email.');
      return;
    }

    setLoading(true);

    try {
      // 1) Persist mart details locally
      updatePortalSignupSession((previous) => ({
        ...(previous ?? {}),
        stage: 'martEmailOtp',
        martName: trimmedName,
        martEmail: trimmedEmail,
        martContact: cleanedContact,
        registration: previous?.registration,
      }));

      // 2) Trigger OTP to mart email
      const response = await authApi.sendMartEmailOtp({
        sessionToken: session.registration.sessionToken,
        martEmail: trimmedEmail,
      });

      if (!response?.success) {
        setError(response?.message || 'Failed to send OTP to mart email.');
        return;
      }

      navigate(ROUTES.SIGNUP_MART_EMAIL_OTP, { replace: true });
    } catch (err) {
      if (axios.isAxiosError(err)) {
        setError(err.response?.data?.message || 'Failed to send OTP to mart email.');
      } else {
        setError((err as Error)?.message || 'Failed to send OTP to mart email.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleStartOver = () => {
    clearPortalSignupSession();
    navigate(ROUTES.SIGNUP, { replace: true });
  };

  return (
    <div className={styles.container}>
      <div className={styles.leftPane}>
        <div className={styles.leftContent}>
          <h1 className={styles.heading}>
            Fresh clothes,
            <br />
            made effortless
          </h1>
          <p className={styles.subtext}>Let us handle the washing while you focus on what matters.</p>
          <div className={styles.illustration} aria-hidden>
            {!imgFailed ? (
              <img
                src="/assets/image%2020.png"
                alt="Illustration"
                className={styles.illustrationImg}
                onError={() => setImgFailed(true)}
              />
            ) : null}
          </div>
        </div>
      </div>

      <div className={styles.rightPane}>
        <form className={styles.card} onSubmit={handleSubmit}>
          <h2 className={styles.title}>Mart registration</h2>
          <p className={styles.subtitle}>
            Enter your mart details to get started. {identifierDescription}
          </p>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="martName">
              Mart Name
            </label>
            <input
              id="martName"
              className={styles.input}
              value={martName}
              onChange={(event) => setMartName(event.target.value)}
              placeholder="Enter your mart name"
              autoComplete="organization"
            />
          </div>

          <div className={styles.dualFieldRow}>
            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="martEmail">
                Mart Email
              </label>
              <input
                id="martEmail"
                type="email"
                className={styles.input}
                value={martEmail}
                onChange={(event) => setMartEmail(event.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
                readOnly={isEmailLocked}
              />
            </div>
            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="martContact">
                Mart Contact Number
              </label>
              <input
                id="martContact"
                className={styles.input}
                value={martContact}
                onChange={(event) => setMartContact(event.target.value)}
                placeholder="Phone number"
                autoComplete="tel"
                readOnly={isContactLocked}
              />
            </div>
          </div>

          {error && <div className={styles.errorMessage}>{error}</div>}
          {!error && info && <div className={styles.infoMessage}>{info}</div>}

          <button type="submit" className={styles.primaryBtn} disabled={loading}>
            {loading ? 'Sending OTP…' : 'Send OTP to Mart Email'}
          </button>

          <button type="button" className={styles.secondaryBtn} onClick={handleStartOver}>
            Use a different email / phone
          </button>
        </form>
      </div>
    </div>
  );
};
