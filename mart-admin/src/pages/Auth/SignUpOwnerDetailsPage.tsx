import axios from 'axios';
import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import { authApi } from '@/services';
import styles from './SignUpProfilePage.module.scss';
import {
  clearPortalSignupSession,
  getPortalSignupSession,
  updatePortalSignupSession,
} from './portalSignupSession';

const sanitizePhone = (value: string) => value.replace(/\D/g, '');

export const SignUpOwnerDetailsPage: React.FC = () => {
  const [ownerName, setOwnerName] = useState('');
  const [ownerEmail, setOwnerEmail] = useState('');
  const [ownerContact, setOwnerContact] = useState('');
  const [imgFailed, setImgFailed] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const navigate = useNavigate();
  const session = useMemo(() => getPortalSignupSession(), []);

  useEffect(() => {
    if (!session?.registration?.sessionToken || !session?.martEmailVerified) {
      navigate(ROUTES.SIGNUP, { replace: true });
      return;
    }

    if (session.owner?.name) setOwnerName(session.owner.name);

    // Owner email is the original identifier from step 1 (only if it's an email)
    if (session.identifierType === 'email') {
      setOwnerEmail(session.identifier);
    } else {
      setOwnerEmail('');
    }

    if (session.owner?.contact) {
      setOwnerContact(session.owner.contact);
    } else if (session.identifierType === 'phone') {
      setOwnerContact(session.identifier);
    }

    setInfo('Mart email verified. Please enter owner details.');
  }, [navigate, session]);

  if (!session?.registration?.sessionToken || !session?.martEmailVerified) {
    return null;
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');

    const trimmedName = ownerName.trim();
    const trimmedEmail = ownerEmail.trim().toLowerCase();
    const cleanedContact = sanitizePhone(ownerContact.trim());

    if (!trimmedName) {
      setError('Please enter owner name.');
      return;
    }

    // Validate owner email doesn't match mart email
    if (session.identifierType === 'email' && trimmedEmail && session.martEmail) {
      if (trimmedEmail === session.martEmail.toLowerCase()) {
        setError('Owner email must be different from mart email.');
        return;
      }
    }

    // Validate owner phone doesn't match mart contact
    if (cleanedContact && session.martContact) {
      const cleanedMartContact = sanitizePhone(session.martContact);
      if (cleanedContact === cleanedMartContact) {
        setError('Owner contact number must be different from mart contact number.');
        return;
      }
    }

    setLoading(true);

    try {
      const payload = {
        sessionToken: session.registration.sessionToken,
        martData: {
          martName: session.martName || '',
          martEmail: session.martEmail || '',
          martContact: session.martContact || '',
          address: '',
          profileImageUrl: '',
          martCoordinates: session.location?.coordinates
            ? {
                latitude: session.location.coordinates.latitude,
                longitude: session.location.coordinates.longitude,
              }
            : undefined,
        },
        ownerData: {
          ownerName: trimmedName,
          ownerPhone: cleanedContact || undefined,
          ownerEmail: session.identifierType === 'email' ? trimmedEmail : undefined,
        },
      };

      const response = await authApi.completePortalRegistration(payload);

      if (!response?.success) {
        setError(response?.message || 'Failed to complete registration.');
        return;
      }

      const { token, owner, mart } = response.data;

      // Map owner to IUser format
      const user = {
        id: owner.userId,
        name: owner.fullName,
        email: owner.email,
        phone: owner.phone,
        role: owner.role || 'Admin',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      const nextSession = updatePortalSignupSession((previous) => ({
        ...(previous ?? {}),
        stage: 'location',
        owner: {
          name: trimmedName,
          email: trimmedEmail,
          contact: cleanedContact || null,
        },
        registration: previous?.registration,
        authPayload: {
          token,
          user,
        },
        mart: mart,
      }));

      if (!nextSession) {
        setError('Signup session expired. Please restart the process.');
        navigate(ROUTES.SIGNUP, { replace: true });
        return;
      }

      navigate(ROUTES.SIGNUP_LOCATION, { replace: true });
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
          <h2 className={styles.title}>Owner details</h2>
          <p className={styles.subtitle}>Enter the owner information.</p>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="ownerName">
              Owner’s Name
            </label>
            <input
              id="ownerName"
              className={styles.input}
              value={ownerName}
              onChange={(event) => setOwnerName(event.target.value)}
              placeholder="Enter full name"
              autoComplete="name"
            />
          </div>

          <div className={styles.dualFieldRow}>
            {session?.identifierType === 'email' && (
              <div className={styles.fieldGroup}>
                <label className={styles.label} htmlFor="ownerEmail">
                  Owner Email
                </label>
                <input
                  id="ownerEmail"
                  type="email"
                  className={styles.input}
                  value={ownerEmail}
                  onChange={(event) => setOwnerEmail(event.target.value)}
                  placeholder="you@example.com"
                  autoComplete="email"
                  readOnly
                />
              </div>
            )}
            <div className={styles.fieldGroup}>
              <label className={styles.label} htmlFor="ownerContact">
                Owner Contact Number
              </label>
              <input
                id="ownerContact"
                className={styles.input}
                value={ownerContact}
                onChange={(event) => setOwnerContact(event.target.value)}
                placeholder="Phone number"
                autoComplete="tel"
                readOnly={session?.identifierType === 'phone'}
              />
            </div>
          </div>

          {error && <div className={styles.errorMessage}>{error}</div>}
          {!error && info && <div className={styles.infoMessage}>{info}</div>}

          <button type="submit" className={styles.primaryBtn} disabled={loading}>
            {loading ? 'Saving…' : 'Next'}
          </button>

          <button type="button" className={styles.secondaryBtn} onClick={handleStartOver}>
            Use a different email / phone
          </button>
        </form>
      </div>
    </div>
  );
};


