import React, { useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import styles from './SignUpOtpPage.module.scss';

export const SignUpOtpPage: React.FC = () => {
  const [otp, setOtp] = useState<string[]>(Array(6).fill(''));
  const [imgFailed, setImgFailed] = useState(false);
  const [loading, setLoading] = useState(false);
  const inputsRef = useRef<Array<HTMLInputElement | null>>([]);
  const navigate = useNavigate();
  const isOtpComplete = useMemo(() => otp.every((d) => d && d.length === 1), [otp]);

  const handleOtpChange = (index: number, value: string) => {
    const val = value.replace(/\D/g, '').slice(0, 1);
    const next = [...otp];
    next[index] = val;
    setOtp(next);
    if (val && index < inputsRef.current.length - 1) inputsRef.current[index + 1]?.focus();
  };

  const handleOtpKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) inputsRef.current[index - 1]?.focus();
  };

  const handleNext = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      // Future: verify OTP here
      navigate(ROUTES.SIGNUP_PROFILE);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.leftPane}>
        <div className={styles.leftContent}>
          <h1 className={styles.heading}>Fresh clothes,<br/>made effortless</h1>
          <p className={styles.subtext}>Let us handle the washing while you focus on what matters.</p>
          <div className={styles.illustration} aria-hidden>
            {!imgFailed ? (
              <img src="/assets/image%2020.png" alt="Illustration" className={styles.illustrationImg} onError={() => setImgFailed(true)} />
            ) : null}
          </div>
        </div>
      </div>

      <div className={styles.rightPane}>
        <form className={styles.card} onSubmit={handleNext}>
          <h2 className={styles.title}>New here?<br/>Let’s get started!</h2>
          <p className={styles.subtitle}>Sign up to experience easy laundry care.</p>

          <span className={styles.otpLabel}>Fill OTP</span>
          <div className={styles.otpBoxes}>
            {otp.map((val, i) => (
              <input
                key={i}
                ref={(el) => (inputsRef.current[i] = el)}
                className={styles.otpInput}
                inputMode="numeric"
                maxLength={1}
                value={val}
                onChange={(e) => handleOtpChange(i, e.target.value)}
                onKeyDown={(e) => handleOtpKeyDown(i, e)}
              />
            ))}
          </div>

          <button type="submit" className={styles.primaryBtn} disabled={loading || !isOtpComplete}>
            {loading ? 'Loading…' : 'Next'}
          </button>
        </form>
      </div>
    </div>
  );
};


