import axios from 'axios';
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import { authApi } from '@/services';
import styles from './SignUpPage.module.scss';
import {
  clearPortalSignupSession,
  getPortalSignupSession,
  maskSignupIdentifier,
  updatePortalSignupSession,
} from './portalSignupSession';

const sanitizePhone = (value: string) => value.replace(/\D/g, '');

export const SignUpPage: React.FC = () => {
  const [laundryName, setLaundryName] = useState('');
  const [laundryEmail, setLaundryEmail] = useState('');
  const [laundryContact, setLaundryContact] = useState('');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [imgFailed, setImgFailed] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const existingSession = getPortalSignupSession();

    if (!existingSession) {
      clearPortalSignupSession();
      return;
    }

    if (existingSession.martName) {
      setLaundryName(existingSession.martName);
    }

    if (existingSession.laundryEmail) {
      setLaundryEmail(existingSession.laundryEmail);
    }

    if (existingSession.laundryContact) {
      setLaundryContact(existingSession.laundryContact);
    }
  }, []);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    const trimmedName = laundryName.trim();
    const trimmedEmail = laundryEmail.trim().toLowerCase();
    const cleanedContact = sanitizePhone(laundryContact.trim());
    const identifier = trimmedEmail || cleanedContact;

    if (!trimmedName) {
      setError('Please enter your laundry name.');
      return;
    }

    if (!identifier) {
      setError('Enter either a laundry email or contact number so we can send the OTP.');
      return;
    }

    setLoading(true);
    setError('');
    setInfo('');

    try {
      const response = await authApi.sendOtp(identifier);

      if (!response?.success) {
        setError(response?.message || 'Failed to send OTP. Please try again.');
        return;
      }

      const { data, message } = response;

      if (data.isRegistered) {
        setError('An account already exists for this email/phone. Please login instead.');
        return;
      }

      const otpExpiresAt = data.expiresIn ? Date.now() + data.expiresIn * 1000 : undefined;
      const masked = maskSignupIdentifier(data.identifier, data.identifierType);

      updatePortalSignupSession(() => ({
        stage: 'otp',
        martName: trimmedName,
        laundryEmail: trimmedEmail || null,
        laundryContact: cleanedContact || null,
        identifier: data.identifier,
        identifierType: data.identifierType,
        otpExpiresAt,
      }));

      setInfo(message || `OTP sent to ${masked}. Enter it to continue.`);
      navigate(ROUTES.SIGNUP_OTP, { replace: true });
    } catch (err) {
      if (axios.isAxiosError(err)) {
        setError(err.response?.data?.message || 'Failed to send OTP. Please try again.');
      } else {
        setError((err as Error)?.message || 'Failed to send OTP. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleNavigateToLogin = () => {
    clearPortalSignupSession();
    navigate(ROUTES.LOGIN);
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
          <h2 className={styles.title}>
            New here?
            <br />
            Let’s get started!
          </h2>
          <p className={styles.subtitle}>Sign up to experience easy laundry care.</p>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="laundryName">
              Laundry Name
            </label>
            <input
              id="laundryName"
              className={styles.input}
              value={laundryName}
              onChange={(event) => setLaundryName(event.target.value)}
              placeholder="E.g. SparkClean Laundry"
              autoComplete="organization"
            />
          </div>

          <div className={styles.dualFieldRow}>
            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="laundryEmail">
                Laundry Email
              </label>
              <input
                id="laundryEmail"
                type="email"
                className={styles.input}
                value={laundryEmail}
                onChange={(event) => setLaundryEmail(event.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
              />
            </div>
            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="laundryContact">
                Laundry Contact No
              </label>
              <input
                id="laundryContact"
                className={styles.input}
                value={laundryContact}
                onChange={(event) => setLaundryContact(event.target.value)}
                placeholder="Optional backup number"
                autoComplete="tel"
              />
            </div>
          </div>

          {error && <div className={styles.errorMessage}>{error}</div>}
          {info && !error && <div className={styles.infoMessage}>{info}</div>}

          <button type="submit" className={styles.primaryBtn} disabled={loading}>
            {loading ? 'Sending…' : 'Get OTP'}
          </button>

          <div className={styles.supportText}>
            Already have an account?{' '}
            <button type="button" className={styles.supportLink} onClick={handleNavigateToLogin}>
              Login
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
