import React, { useState } from 'react';
import styles from './SignUpPage.module.scss';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';

export const SignUpPage: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [contact, setContact] = useState('');
  const [imgFailed, setImgFailed] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      // hook up OTP request API here
      navigate(ROUTES.SIGNUP_OTP);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.container}> 
      <div className={styles.leftPane}>
        <div className={styles.leftContent}>
          <h1 className={styles.heading}>Fresh clothes,
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
          <h2 className={styles.title}>New here?<br/>Let’s get started!</h2>
          <p className={styles.subtitle}>Sign up to experience easy laundry care.</p>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="laundryName">Laundry Name</label>
            <input id="laundryName" className={styles.input} value={name} onChange={(e)=>setName(e.target.value)} placeholder="" />
          </div>
          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="laundryEmail">Laundry Email</label>
            <input id="laundryEmail" type="email" className={styles.input} value={email} onChange={(e)=>setEmail(e.target.value)} placeholder="" />
          </div>
          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="laundryContact">Laundry Contact No</label>
            <input id="laundryContact" className={styles.input} value={contact} onChange={(e)=>setContact(e.target.value)} placeholder="" />
          </div>

          <button type="submit" className={styles.primaryBtn} disabled={loading}>{loading ? 'Sending…' : 'Get OTP'}</button>
        </form>
      </div>
    </div>
  );
};


