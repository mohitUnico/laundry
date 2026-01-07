import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { ROUTES } from '@/routes';
import {
  authApi,
  IdentifierType,
  VerifyPortalOtpData,
  VerifyPortalOtpPendingData,
  VerifyPortalOtpRegisteredData,
} from '@/services';
import { useAuth } from '@/hooks';
import {
  PORTAL_REGISTRATION_SESSION_KEY,
  PortalRegistrationSessionPayload,
} from './portalRegistrationSession';
import {
  clearPortalSignupSession,
  updatePortalSignupSession,
} from './portalSignupSession';
import styles from './LoginPage.module.scss';

const maskIdentifier = (value: string, type: IdentifierType) => {
  if (type === 'email') {
    const emailParts = value.split('@');
    if (emailParts.length !== 2) {
      return value;
    }
    const localPart = emailParts[0] ?? '';
    const domain = emailParts[1] ?? '';

    if (!localPart || !domain) {
      return value;
    }

    if (localPart.length <= 2) {
      return `${localPart.slice(0, 1)}***@${domain}`;
    }
    return `${localPart.slice(0, 2)}***@${domain}`;
  }

  if (value.length <= 4) {
    return value;
  }

  return `••••${value.slice(-4)}`;
};

const isPendingRegistration = (
  data: VerifyPortalOtpData
): data is VerifyPortalOtpPendingData => data.isRegistered === false;

export const LoginPage: React.FC = () => {
  const [identifier, setIdentifier] = useState('');
  const [otp, setOtp] = useState<string[]>(Array(6).fill(''));
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);
  const [resendLoading, setResendLoading] = useState(false);
  const [resendMessage, setResendMessage] = useState('');

  const inputsRef = useRef<Array<HTMLInputElement | null>>([]);
  const [imgFailed, setImgFailed] = useState(false);
  const navigate = useNavigate();
  const { completeLogin } = useAuth();

  const isOtpComplete = useMemo(() => otp.every((digit) => digit && digit.length === 1), [otp]);

  const handleOtpChange = (index: number, value: string) => {
    const val = value.replace(/\D/g, '').slice(0, 1);
    const next = [...otp];
    next[index] = val;
    setOtp(next);

    if (val && index < inputsRef.current.length - 1) {
      inputsRef.current[index + 1]?.focus();
    }
  };

  const handleOtpKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputsRef.current[index - 1]?.focus();
    }
  };

  /**
   * Sends a fresh OTP to the identifier entered by the user.
   * This should only run before an OTP has been requested.
   */
  const handleGetOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmedIdentifier = identifier.trim();

    if (!trimmedIdentifier) {
      setError('Please enter an email or phone number');
      return;
    }

    setLoading(true);
    setError('');
    setInfo('');

    try {
      const response = await authApi.sendOtp(trimmedIdentifier);

      if (!response?.success) {
        setError(response?.message || 'Failed to send OTP');
        return;
      }

      const otpMeta = response?.data as
        | { identifier?: string; identifierType?: IdentifierType; expiresIn?: number }
        | undefined;

      const inferredType: IdentifierType = trimmedIdentifier.includes('@') ? 'email' : 'phone';
      const masked = maskIdentifier(
        otpMeta?.identifier || trimmedIdentifier,
        otpMeta?.identifierType || inferredType
      );

      setOtp(Array(6).fill(''));
      setOtpSent(true);
      setResendCooldown(otpMeta?.expiresIn ? Math.min(30, otpMeta.expiresIn) : 30);
      setInfo(`OTP sent to ${masked}.`);
    } catch (err: any) {
      if (axios.isAxiosError(err)) {
        const status = err.response?.status;
        const serverMessage =
          (err.response?.data as any)?.message || (err.response?.data as any)?.error || undefined;
        const fallback = err.message || 'Failed to send OTP';
        setError(serverMessage || (status ? `Failed to send OTP (HTTP ${status})` : fallback));
        // Helpful debug in devtools
        console.error('[Login] sendOtp failed', {
          url: err.config?.url,
          baseURL: err.config?.baseURL,
          status,
          data: err.response?.data,
        });
      } else {
        setError(err?.message || 'Failed to send OTP');
        console.error('[Login] sendOtp failed (non-axios)', err);
      }
    } finally {
      setLoading(false);
    }
  };

  /**
   * Verifies the OTP once all digits are entered.
   * Called either by the Verify button or by pressing Enter after OTP entry.
   */
  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otpSent) {
      setError('Please request an OTP first');
      return;
    }
    if (!isOtpComplete) {
      setError('Please enter the complete 6-digit OTP');
      return;
    }
    setLoading(true);
    setError('');
    setInfo('');
    try {
      const code = otp.join('');
      const trimmedIdentifier = identifier.trim();
      // Debug log to confirm the verification API is called instead of resend
      console.log('[Login] Triggering verify-otp for identifier:', trimmedIdentifier, 'OTP length:', code.length);
      const response = await authApi.verifyOtp({ identifier: trimmedIdentifier, otp: code });

      if (!response?.success) {
        setError(response?.message || 'Invalid OTP');
        return;
      }

      const data = response.data;

      if (!data) {
        setError('Unexpected response from server');
        return;
      }

      // Check if user is registered (existing user) - should login
      if (data.isRegistered === true) {
        const registeredData = data as VerifyPortalOtpRegisteredData;
        const { token, user } = registeredData;

        if (!token || !user) {
          setError('Unexpected response from server');
          return;
        }

        sessionStorage.removeItem(PORTAL_REGISTRATION_SESSION_KEY);
        clearPortalSignupSession();
        completeLogin(user, token);
        setInfo('OTP verified successfully');
        navigate(ROUTES.DASHBOARD, { replace: true });
        return;
      }

      // User is not registered - redirect to signup
      if (isPendingRegistration(data)) {
        const expiresAt = data.sessionExpiresIn
          ? Date.now() + data.sessionExpiresIn * 1000
          : undefined;

        const sessionPayload: PortalRegistrationSessionPayload = {
          sessionToken: data.sessionToken,
          identifier: data.identifier,
          identifierType: data.identifierType,
          expiresAt,
        };

        sessionStorage.setItem(
          PORTAL_REGISTRATION_SESSION_KEY,
          JSON.stringify(sessionPayload)
        );

        updatePortalSignupSession(() => ({
          stage: 'profile',
          martName: '',
          laundryEmail: data.identifierType === 'email' ? data.identifier : null,
          laundryContact: data.identifierType === 'phone' ? data.identifier : null,
          identifier: data.identifier,
          identifierType: data.identifierType,
          otpExpiresAt: expiresAt,
          registration: {
            sessionToken: data.sessionToken,
            sessionExpiresAt: expiresAt,
          },
        }));

        setInfo("OTP verified. Let's finish setting up your profile.");
        setOtp(Array(6).fill(''));
        setOtpSent(false);
        navigate(ROUTES.SIGNUP_PROFILE, { replace: true });
        return;
      }

      // Fallback: if we reach here, something unexpected happened
      setError('Unexpected response format from server');
    } catch (err: any) {
      if (axios.isAxiosError(err)) {
        setError(err.response?.data?.message || 'Invalid OTP');
      } else {
        setError(err?.message || 'Invalid OTP');
      }
    } finally {
      setLoading(false);
    }
  };

  /**
   * Routes form submission to the appropriate handler based on the current stage.
   * - Before OTP is requested: trigger handleGetOtp.
   * - After OTP is requested: trigger handleVerify.
   */
  const handleFormSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    if (otpSent) {
      void handleVerify(e);
      return;
    }
    void handleGetOtp(e);
  };

  /**
   * Ensures pressing Enter follows the same flow as clicking the visible CTA.
   * Once an OTP is sent, Enter should only attempt verification.
   */
  const handleFormKeyDown = (e: React.KeyboardEvent<HTMLFormElement>) => {
    if (e.key === 'Enter' && otpSent) {
      e.preventDefault();
      void handleVerify(e as unknown as React.FormEvent<HTMLFormElement>);
    }
  };

  /**
   * Handles resending OTP with cooldown timer
   */
  const handleResendOtp = async () => {
    if (resendCooldown > 0 || resendLoading) {
      return;
    }

    const trimmedIdentifier = identifier.trim();
    if (!trimmedIdentifier) {
      setResendMessage('Please enter an email or phone number first.');
      return;
    }

    setResendLoading(true);
    setResendMessage('');
    setError('');

    try {
      const response = await authApi.sendOtp(trimmedIdentifier);
      const otpMeta = response?.data as { identifier?: string; identifierType?: IdentifierType } | undefined;

      const inferredType: IdentifierType = trimmedIdentifier.includes('@') ? 'email' : 'phone';
      const masked = maskIdentifier(otpMeta?.identifier || trimmedIdentifier, otpMeta?.identifierType || inferredType);
      setOtp(Array(6).fill(''));
      setResendMessage(`OTP resent to ${masked}.`);
      setResendCooldown(30);
      
      // Clear resend message after 3 seconds
      setTimeout(() => {
        setResendMessage('');
      }, 3000);
    } catch (err: any) {
      if (axios.isAxiosError(err)) {
        setResendMessage(err.response?.data?.message || 'Failed to resend OTP. Please try again.');
      } else {
        setResendMessage(err?.message || 'Failed to resend OTP. Please try again.');
      }
    } finally {
      setResendLoading(false);
    }
  };

  // Cooldown timer effect
  useEffect(() => {
    if (resendCooldown > 0) {
      const timer = setTimeout(() => {
        setResendCooldown(resendCooldown - 1);
      }, 1000);
      return () => clearTimeout(timer);
    }
    return undefined;
  }, [resendCooldown]);

  useEffect(() => {
    if (otpSent) {
      inputsRef.current[0]?.focus();
    }
  }, [otpSent]);

  return (
    <div className={styles.loginContainer}>
      <div className={styles.leftPane}>
        <div className={styles.leftContent}>
          <h1 className={styles.leftHeading}>Fresh clothes, made effortless</h1>
          <p className={styles.leftSubtext}>
            Let us handle the washing while you focus on what matters.
          </p>
          <div className={styles.illustration} aria-hidden>
            {!imgFailed ? (
              <img
                src="/assets/image%2020.png"
                alt="Login Illustration"
                className={styles.illustrationImg}
                onError={() => setImgFailed(true)}
              />
            ) : (
              // Fallback inline SVG
              <svg width="280" height="220" viewBox="0 0 280 220" fill="none" xmlns="http://www.w3.org/2000/svg">
                <defs>
                  <linearGradient id="g1" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0%" stopColor="#0052D4" />
                    <stop offset="100%" stopColor="#4364F7" />
                  </linearGradient>
                </defs>
                <rect x="10" y="40" width="260" height="140" rx="24" fill="#F1F5FF" />
                <circle cx="80" cy="110" r="34" fill="url(#g1)" opacity="0.9" />
                <path d="M80 84c-8 0-14 6-14 14s6 14 14 14" stroke="#fff" strokeWidth="4" strokeLinecap="round"/>
                <path d="M196 76c-18 0-32 14-32 32 0 15 10 28 24 31" stroke="#CBD5FF" strokeWidth="8" strokeLinecap="round"/>
                <path d="M200 76c18 0 32 14 32 32 0 15-10 28-24 31" stroke="url(#g1)" strokeWidth="8" strokeLinecap="round"/>
                <circle cx="210" cy="150" r="8" fill="#2D4BFF" opacity="0.6"/>
              </svg>
            )}
          </div>
        </div>
      </div>
      <div className={styles.rightPane}>
        <div className={styles.rightPaneContent}>
          <form
            className={styles.formCard}
            onSubmit={handleFormSubmit}
            onKeyDown={handleFormKeyDown}
          >
            <h2 className={styles.formTitle}>Welcome Back!</h2>
            <p className={styles.formSubtitle}>Please Login to your Account</p>

            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="identifier">Email/Phone Number</label>
              <input
                id="identifier"
                className={styles.textInput}
                type="text"
                placeholder="Enter email or phone"
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                required
              />
            </div>

            {error && !otpSent && <div className={styles.errorMessage}>{error}</div>}
            {info && !error && <div className={styles.infoMessage}>{info}</div>}

            <button
              type="submit"
              className={styles.primaryBtn}
              disabled={loading || !identifier.trim() || otpSent}
            >
              {otpSent ? 'OTP Sent' : loading ? 'Sending…' : 'Get OTP'}
            </button>

            {otpSent && (
              <div className={styles.otpSection}>
                <span className={styles.otpLabel}>OTP</span>
                <div className={styles.otpBoxes}>
                  {otp.map((val, index) => (
                    <input
                      key={index}
                      ref={(el) => (inputsRef.current[index] = el)}
                      className={styles.otpInput}
                      inputMode="numeric"
                      maxLength={1}
                      value={val}
                      onChange={(e) => handleOtpChange(index, e.target.value)}
                      onKeyDown={(e) => handleOtpKeyDown(index, e)}
                    />
                  ))}
                </div>
                <button
                  type="submit"
                  className={styles.verifyBtn}
                  disabled={!isOtpComplete || loading}
                >
                  {loading ? 'Verifying…' : 'Verify & Continue'}
                </button>
                {error && <div className={styles.errorMessage}>{error}</div>}
                {resendMessage && (
                  <div className={resendMessage.includes('Failed') ? styles.errorMessage : styles.infoMessage}>
                    {resendMessage}
                  </div>
                )}
                <div className={styles.resendSection}>
                  <button
                    type="button"
                    className={styles.resendBtn}
                    onClick={handleResendOtp}
                    disabled={resendCooldown > 0 || resendLoading || loading}
                  >
                    {resendLoading
                      ? 'Sending…'
                      : resendCooldown > 0
                      ? `Resend OTP (${resendCooldown}s)`
                      : 'Resend OTP'}
                  </button>
                </div>
              </div>
            )}
          </form>
        </div>
      </div>
    </div>
  );
};
