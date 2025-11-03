import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import styles from './SignUpProfilePage.module.scss';

export const SignUpProfilePage: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [contact, setContact] = useState('');
  const [imgFailed, setImgFailed] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleNext = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      // TODO: submit profile details
      navigate(ROUTES.SIGNUP_LOCATION);
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
          <h2 className={styles.title}>Complete your profile</h2>
          <p className={styles.subtitle}>Enter your details to get started as a laundry owner</p>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="ownerName">Owner’s Name</label>
            <input id="ownerName" className={styles.input} value={name} onChange={(e)=>setName(e.target.value)} />
          </div>
          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="email">Email</label>
            <input id="email" type="email" className={styles.input} value={email} onChange={(e)=>setEmail(e.target.value)} />
          </div>
          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="contact">Contact Number</label>
            <input id="contact" className={styles.input} value={contact} onChange={(e)=>setContact(e.target.value)} />
          </div>

          <button type="submit" className={styles.primaryBtn} disabled={loading}>{loading ? 'Loading…' : 'Next'}</button>
        </form>
      </div>
    </div>
  );
};


