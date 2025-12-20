import axios from 'axios';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import { authApi } from '@/services';
import styles from './SignUpOtpPage.module.scss';
import {
  getPortalSignupSession,
  updatePortalSignupSession,
  clearPortalSignupSession,
} from './portalSignupSession';

export const SignUpMartEmailOtpPage: React.FC = () => {
  const [otp, setOtp] = useState<string[]>(Array(6).fill(''));
  const [imgFailed, setImgFailed] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [loading, setLoading] = useState(false);
  const inputsRef = useRef<Array<HTMLInputElement | null>>([]);

  const navigate = useNavigate();
  const session = useMemo(() => getPortalSignupSession(), []);

  useEffect(() => {
    if (!session?.registration?.sessionToken || !session?.martEmail) {
      navigate(ROUTES.SIGNUP, { replace: true });
      return;
    }
    setInfo(`Enter the OTP sent to ${session.martEmail}.`);
    inputsRef.current[0]?.focus();
  }, [navigate, session]);

  if (!session?.registration?.sessionToken || !session?.martEmail) {
    return null;
  }

  const isOtpComplete = useMemo(() => otp.every((d) => d && d.length === 1), [otp]);

  const handleOtpChange = (index: number, value: string) => {
    const numeric = value.replace(/\D/g, '').slice(0, 1);
    setOtp((prev) => {
      const next = [...prev];
      next[index] = numeric;
      return next;
    });
    if (numeric && index < inputsRef.current.length - 1) {
      inputsRef.current[index + 1]?.focus();
    }
  };

  const handleOtpKeyDown = (index: number, event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Backspace' && !otp[index] && index > 0) {
      inputsRef.current[index - 1]?.focus();
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!isOtpComplete) {
      setError('Please enter the complete 6-digit OTP.');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const code = otp.join('');
      const response = await authApi.verifyMartEmailOtp({
        sessionToken: session.registration.sessionToken,
        martEmail: session.martEmail,
        otp: code,
      });

      if (!response?.success) {
        setError(response?.message || 'Invalid OTP. Please try again.');
        return;
      }

      updatePortalSignupSession((previous) => ({
        ...(previous ?? {}),
        stage: 'owner',
        martEmailVerified: true,
      }));

      navigate(ROUTES.SIGNUP_OWNER, { replace: true });
    } catch (err) {
      if (axios.isAxiosError(err)) {
        setError(err.response?.data?.message || 'Invalid OTP. Please try again.');
      } else {
        setError((err as Error)?.message || 'Invalid OTP. Please try again.');
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
          <h2 className={styles.title}>Verify mart email</h2>
          <p className={styles.subtitle}>Enter the OTP sent to your mart email address.</p>

          <span className={styles.otpLabel}>Fill OTP</span>
          <div className={styles.otpBoxes}>
            {otp.map((value, index) => (
              <input
                key={index}
                ref={(element) => {
                  inputsRef.current[index] = element;
                }}
                className={styles.otpInput}
                inputMode="numeric"
                maxLength={1}
                value={value}
                onChange={(event) => handleOtpChange(index, event.target.value)}
                onKeyDown={(event) => handleOtpKeyDown(index, event)}
              />
            ))}
          </div>

          {error && <div className={styles.errorMessage}>{error}</div>}
          {!error && info && <div className={styles.infoMessage}>{info}</div>}

          <button type="submit" className={styles.primaryBtn} disabled={loading || !isOtpComplete}>
            {loading ? 'Verifying…' : 'Next'}
          </button>

          <button type="button" className={styles.secondaryBtn} onClick={handleStartOver}>
            Use a different email / phone
          </button>
        </form>
      </div>
    </div>
  );
};
