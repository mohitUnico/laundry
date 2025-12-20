import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks';
import { ROUTES } from '@/routes';
import styles from './SignUpLocationPage.module.scss';
import {
  clearPortalSignupSession,
  getPortalSignupSession,
  updatePortalSignupSession,
} from './portalSignupSession';

interface Coordinates {
  latitude: number;
  longitude: number;
}

export const SignUpLocationPage: React.FC = () => {
  const [imgFailed, setImgFailed] = useState(false);
  const [locationStatus, setLocationStatus] = useState<'idle' | 'granted' | 'denied' | 'error'>('idle');
  const [coordinates, setCoordinates] = useState<Coordinates | null>(null);
  const [files, setFiles] = useState<File[]>([]);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [saving, setSaving] = useState(false);

  const navigate = useNavigate();
  const { completeLogin } = useAuth();

  const session = useMemo(() => getPortalSignupSession(), []);

  useEffect(() => {
    if (!session?.authPayload) {
      navigate(ROUTES.SIGNUP, { replace: true });
    }
  }, [navigate, session]);

  if (!session?.authPayload) {
    return null;
  }

  const handleEnableLocation = () => {
    if (!navigator.geolocation) {
      setError('Location access is not supported in this browser.');
      setLocationStatus('error');
      return;
    }

    setError('');
    setInfo('Requesting location…');
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const coords = {
          latitude: Number(position.coords.latitude.toFixed(6)),
          longitude: Number(position.coords.longitude.toFixed(6)),
        };
        setCoordinates(coords);
        setLocationStatus('granted');
        setInfo('Location captured. You can continue.');
        updatePortalSignupSession((previous) => ({
          ...(previous ?? {}),
          location: {
            ...(previous?.location ?? {}),
            coordinates: coords,
          },
        }));
      },
      (geoError) => {
        setLocationStatus('denied');
        setError(
          geoError.code === geoError.PERMISSION_DENIED
            ? 'Location permission was denied. You can continue without it and update later from settings.'
            : 'Unable to detect location right now. You can try again or continue without it.'
        );
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      }
    );
  };

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!event.target.files) {
      return;
    }

    const selected = Array.from(event.target.files).slice(0, 6);
    setFiles(selected);
    setInfo(
      selected.length
        ? `${selected.length} photo${selected.length > 1 ? 's' : ''} ready to upload.`
        : ''
    );
    updatePortalSignupSession((previous) => ({
      ...(previous ?? {}),
      location: {
        ...(previous?.location ?? {}),
        photoCount: selected.length,
      },
    }));
  };

  const handleFinish = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!session?.authPayload) {
      setError('Signup session expired. Please login again.');
      navigate(ROUTES.LOGIN, { replace: true });
      return;
    }

    setSaving(true);
    setError('');

    try {
      // Future enhancement: upload files & save coordinates through an API.
      // Update mart with location if coordinates are available
      if (coordinates && session.mart) {
        // TODO: Call API to update mart location
        // await martApi.updateMartLocation(session.mart.martId, coordinates);
      }

      // Complete login and store auth data
      completeLogin(session.authPayload.user, session.authPayload.token);
      
      // Clear signup session
      clearPortalSignupSession();
      
      // Use hard navigation to ensure auth state is properly loaded
      // This forces a full page reload so AuthProvider reads from localStorage
      window.location.href = ROUTES.DASHBOARD;
    } catch (err) {
      console.error('Failed to complete registration:', err);
      setError('Failed to complete registration. Please try again.');
      setSaving(false);
    }
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
        <form className={styles.card} onSubmit={handleFinish}>
          <h2 className={styles.title}>
            Let’s make
            <br />
            pickups easy
          </h2>
          <p className={styles.subtitle}>
            Your location helps us provide smooth and timely laundry service. You can also add a few
            photos so customers can recognize your mart easily.
          </p>

          <button type="button" className={styles.primaryBtn} onClick={handleEnableLocation}>
            {locationStatus === 'granted' ? 'Location Captured' : 'Enable Location Access'}
          </button>

          {coordinates ? (
            <div className={styles.locationChip}>
              📍 {coordinates.latitude}, {coordinates.longitude}
            </div>
          ) : null}

          {error && <div className={styles.errorMessage}>{error}</div>}
          {!error && info && <div className={styles.infoMessage}>{info}</div>}

          <div className={styles.uploadCaption}>
            Upload a few photos so
            <br />
            customers can recognize your place easily.
          </div>

          <label className={styles.dropZone}>
            <input type="file" accept="image/*" multiple hidden onChange={handleFileChange} />
            <div className={styles.dropInner}>
              <svg
                width="56"
                height="56"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M4 5a2 2 0 0 1 2-2h8l4 4v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5z"
                  stroke="white"
                  strokeWidth="1.5"
                />
                <path d="M14 3v4h4" stroke="white" strokeWidth="1.5" />
                <path d="M7 16l3-3 3 3 3-4 3 4" stroke="white" strokeWidth="1.5" />
              </svg>
            </div>
          </label>

          {files.length > 0 ? (
            <ul className={styles.fileList}>
              {files.map((file) => (
                <li key={file.name} className={styles.fileItem}>
                  {file.name}
                </li>
              ))}
            </ul>
          ) : null}

          <button type="submit" className={styles.secondaryBtn} disabled={saving}>
            {saving ? 'Finishing…' : 'Finish & Go to Dashboard'}
          </button>
        </form>
      </div>
    </div>
  );
};
