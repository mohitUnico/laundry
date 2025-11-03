import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import styles from './SignUpLocationPage.module.scss';

export const SignUpLocationPage: React.FC = () => {
  const [imgFailed, setImgFailed] = useState(false);
  const navigate = useNavigate();

  const handleEnableLocation = () => {
    // Placeholder: request browser geolocation later; proceed to dashboard for demo
    navigate(ROUTES.DASHBOARD);
  };

  const handleFinish = (e: React.FormEvent) => {
    e.preventDefault();
    navigate(ROUTES.DASHBOARD);
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
        <form className={styles.card} onSubmit={handleFinish}>
          <h2 className={styles.title}>Let’s make<br/>pickups easy</h2>
          <p className={styles.subtitle}>Your location helps us provide smooth and timely laundry service.</p>

          <button type="button" className={styles.primaryBtn} onClick={handleEnableLocation}>Enable Location Access</button>

          <div className={styles.uploadCaption}>Upload a few photos so<br/>customers can recognize your place easily.</div>

          <label className={styles.dropZone}>
            <input type="file" accept="image/*" multiple hidden />
            <div className={styles.dropInner}>
              <svg width="56" height="56" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M4 5a2 2 0 0 1 2-2h8l4 4v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5z" stroke="white" strokeWidth="1.5"/>
                <path d="M14 3v4h4" stroke="white" strokeWidth="1.5"/>
                <path d="M7 16l3-3 3 3 3-4 3 4" stroke="white" strokeWidth="1.5"/>
              </svg>
            </div>
          </label>
        </form>
      </div>
    </div>
  );
};


