import React, { useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import styles from './LoginPage.module.scss';

export const LoginPage: React.FC = () => {
  const [identifier, setIdentifier] = useState('');
  const [otp, setOtp] = useState<string[]>(Array(6).fill(''));
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const inputsRef = useRef<Array<HTMLInputElement | null>>([]);
  const [imgFailed, setImgFailed] = useState(false);
  const navigate = useNavigate();

  const isOtpComplete = useMemo(() => otp.every((d) => d && d.length === 1), [otp]);

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

  const handleGetOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      // Integrate API call to request OTP here
      // await authApi.requestOtp(identifier)
    } catch (err: any) {
      setError(err?.message || 'Failed to send OTP');
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isOtpComplete) {
      // For demo navigation without backend, still allow moving forward
      navigate(ROUTES.SIGNUP);
      return;
    }
    setLoading(true);
    setError('');
    try {
      const code = otp.join('');
      // Integrate API call to verify OTP here
      // await authApi.verifyOtp({ identifier, code })
      // temporary no-op to satisfy linter
      await Promise.resolve(code);
      navigate(ROUTES.SIGNUP);
    } catch (err: any) {
      setError(err?.message || 'Invalid OTP');
    } finally {
      setLoading(false);
    }
  };

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
        <form className={styles.formCard} onSubmit={handleGetOtp}>
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

          {error && <div className={styles.errorMessage}>{error}</div>}

          <button type="submit" className={styles.primaryBtn} disabled={loading}>
            {loading ? 'Sending…' : 'Get OTP'}
          </button>

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
              className={styles.verifyBtn}
              onClick={handleVerify}
              disabled={!isOtpComplete || loading}
            >
              Verify & Continue
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
