import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
    deliveryStaffManagementApi,
    type AdminDeliveryStaff,
    type AdminDeliveryStaffSummary,
    type AdminOnlineDeliveryStaff,
} from '../../services/api/modules/deliveryStaffManagementApi';
import { GoogleMap, InfoWindowF, MarkerF, useJsApiLoader } from '@react-google-maps/api';

// Local helpers for icons to keep the page self-contained and pixel-consistent
const UserOutlineIcon: React.FC<{ className?: string }> = ({ className }) => (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 12c2.761 0 5-2.686 5-6s-2.239-6-5-6-5 2.686-5 6 2.239 6 5 6Z" stroke="currentColor" strokeWidth="1.5" />
        <path d="M1.5 22c0-4.142 4.03-7.5 9-7.5s9 3.358 9 7.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
);

const StarSolidIcon: React.FC<{ className?: string }> = ({ className }) => (
    <svg className={className} viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg" fill="currentColor">
        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.802 2.036a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.802-2.036a1 1 0 00-1.176 0l-2.802 2.036c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.88 8.72c-.783-.57-.38-1.81.588-1.81H6.93a1 1 0 00.95-.69l1.169-3.292z" />
    </svg>
);

const PhoneIcon: React.FC<{ className?: string }> = ({ className }) => (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M6.62 10.79a15.053 15.053 0 006.59 6.59l2.2-2.2a1 1 0 011.02-.24 11.72 11.72 0 003.68.59 1 1 0 011 1V20a1 1 0 01-1 1C10.85 21 3 13.15 3 3a1 1 0 011-1h3.47a1 1 0 011 1 11.72 11.72 0 00.59 3.68 1 1 0 01-.24 1.02l-2.2 2.09z" fill="currentColor" />
    </svg>
);

const MailIcon: React.FC<{ className?: string }> = ({ className }) => (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M3 5a2 2 0 012-2h14a2 2 0 012 2v.4l-9 5.6-9-5.6V5z" fill="currentColor" />
        <path d="M21 8.2l-8.553 5.315a2 2 0 01-2.094 0L2 8.2V19a2 2 0 002 2h16a2 2 0 002-2V8.2z" fill="currentColor" />
    </svg>
);

const LocationIcon: React.FC<{ className?: string }> = ({ className }) => (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path
            d="M12 22s7-4.5 7-12a7 7 0 10-14 0c0 7.5 7 12 7 12z"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
        <path
            d="M12 13a3 3 0 100-6 3 3 0 000 6z"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

const DocIcon: React.FC<{ className?: string }> = ({ className }) => (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M14 2H7a2 2 0 00-2 2v16a2 2 0 002 2h10a2 2 0 002-2V7l-5-5z" stroke="currentColor" strokeWidth="1.5" />
        <path d="M14 2v5h5" stroke="currentColor" strokeWidth="1.5" />
        <path d="M8 13h8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M8 17h6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
);

type Staff = {
    id: string;
    name: string;
    rating: number | null;
    deliveries: number | null;
    phone: string;
    email: string;
    avatarBg: string;
    initials: string;
    isOnline: boolean;
};

type MapPin = {
    staffId: string;
    fullName: string;
    email: string;
    phone: string | null;
    lat: number;
    lng: number;
    isOnline: boolean;
};

type VerificationRequest = {
    staffId: string;
    name: string;
    initials: string;
    avatarBg: string;
    phone: string;
    email: string;
    address: string;
    documents: Array<{ id: string; title: string; subtitle?: string; url?: string | null }>;
};

const toNumber = (value: unknown): number | null => {
    const n = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(n) ? n : null;
};

const initialsFromName = (name: string) => {
    const parts = name.trim().split(/\s+/).filter(Boolean);
    const first = parts[0]?.[0] ?? '';
    const second = parts[1]?.[0] ?? parts[0]?.[1] ?? '';
    return (first + second).toUpperCase();
};

const avatarBgFromSeed = (seed: string) => {
    const palette = [
        'bg-rose-500',
        'bg-cyan-600',
        'bg-indigo-600',
        'bg-emerald-600',
        'bg-fuchsia-600',
        'bg-red-600',
        'bg-blue-600',
        'bg-green-600',
        'bg-yellow-600',
        'bg-purple-600',
        'bg-slate-700',
    ];
    let hash = 0;
    for (let i = 0; i < seed.length; i += 1) hash = (hash * 31 + seed.charCodeAt(i)) >>> 0;
    return palette[hash % palette.length];
};

const StatCard: React.FC<{
    title: string;
    value: string | number;
    right?: React.ReactNode;
}> = ({ title, value, right }) => (
    <div className="tw-card rounded-lg sm:rounded-xl shadow-sm border border-slate-200 bg-white px-4 sm:px-5 py-3 sm:py-4 transition-all duration-150 ease-in-out hover:shadow">
        <div className="flex items-center justify-between text-slate-500 text-xs sm:text-sm font-medium">
            <span>{title}</span>
            {right}
        </div>
        <div className="mt-2 text-2xl sm:text-3xl font-semibold text-slate-900">{value}</div>
    </div>
);

const DeliveryStaffGoogleMap: React.FC<{
    pins: MapPin[];
    apiKey: string;
    mapId?: string;
    selectedStaffId: string;
    onSelectStaffId: (staffId: string) => void;
}> = ({ pins, apiKey, mapId, selectedStaffId, onSelectStaffId }) => {
    const { isLoaded, loadError } = useJsApiLoader({
        id: 'delivery-staff-google-map',
        googleMapsApiKey: apiKey,
    });

    const [map, setMap] = useState<google.maps.Map | null>(null);
    const [authFailed, setAuthFailed] = useState(false);
    const origin = typeof window !== 'undefined' ? window.location.origin : '';

    // Simple "location pin" SVG path for Google Maps marker symbol.
    // Note: anchor expects the bottom tip of the pin.
    const PIN_PATH =
        'M12 2C8.134 2 5 5.134 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.866-3.134-7-7-7zm0 9.5a2.5 2.5 0 1 1 0-5 2.5 2.5 0 0 1 0 5z';

    useEffect(() => {
        // Google Maps triggers this when auth fails (e.g. RefererNotAllowedMapError, billing not enabled, API disabled).
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const w = window as any;
        const previous = w.gm_authFailure;
        w.gm_authFailure = () => {
            setAuthFailed(true);
            if (typeof previous === 'function') previous();
        };
        return () => {
            // Restore any previous handler to avoid leaking global state.
            if (previous) w.gm_authFailure = previous;
            else delete w.gm_authFailure;
        };
    }, []);

    const fitToPins = useCallback((mapInstance: google.maps.Map, pinList: MapPin[]) => {
        if (pinList.length === 0) return;

        if (pinList.length === 1) {
            mapInstance.setCenter({ lat: pinList[0]!.lat, lng: pinList[0]!.lng });
            mapInstance.setZoom(13);
            return;
        }

        const bounds = new google.maps.LatLngBounds();
        pinList.forEach((p) => bounds.extend({ lat: p.lat, lng: p.lng }));
        mapInstance.fitBounds(bounds, { top: 40, right: 40, bottom: 40, left: 40 });
    }, []);

    useEffect(() => {
        if (!map) return;
        fitToPins(map, pins);
    }, [fitToPins, map, pins]);

    useEffect(() => {
        if (!map) return;
        if (!selectedStaffId) return;
        const pin = pins.find((p) => p.staffId === selectedStaffId);
        if (!pin) return;

        map.panTo({ lat: pin.lat, lng: pin.lng });
        const currentZoom = map.getZoom() ?? 12;
        if (currentZoom < 15) map.setZoom(15);
    }, [map, pins, selectedStaffId]);

    const initialCenter = { lat: pins[0]!.lat, lng: pins[0]!.lng };

    return (
        <div className="h-[300px] sm:h-[400px] md:h-[480px] lg:h-[520px] w-full overflow-hidden rounded-xl sm:rounded-2xl border border-slate-200 bg-white shadow-sm">
            {authFailed ? (
                <div className="h-full w-full flex items-center justify-center px-6">
                    <div className="max-w-[560px]">
                        <div className="text-sm font-semibold text-slate-900 text-center">Google Maps didn’t load</div>
                        <div className="mt-1 text-sm text-slate-600 text-center">
                            This is almost always an API key restriction / billing / API enablement issue.
                        </div>

                        <div className="mt-3 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-700">
                            <div className="font-semibold">Most common cause (your screenshot):</div>
                            <div className="mt-0.5 break-words">
                                <span className="font-mono">browserRefererNotAllowedMapError</span> / <span className="font-mono">RefererNotAllowedMapError</span>
                            </div>
                        </div>

                        <ul className="mt-3 list-disc pl-5 text-sm text-slate-700 space-y-1">
                            <li>
                                In Google Cloud Console, enable <b>Maps JavaScript API</b>
                            </li>
                            <li>
                                Ensure <b>Billing</b> is enabled for the project
                            </li>
                            <li>
                                If the key is restricted by HTTP referrer, add:
                                <div className="mt-1 font-mono text-xs bg-white border border-slate-200 rounded px-2 py-1 break-all">
                                    {origin ? `${origin}/*` : 'http://localhost:3000/*'}
                                </div>
                                (also add <span className="font-mono">http://localhost:3001/*</span> if Vite runs on 3001)
                            </li>
                        </ul>

                        <div className="mt-3 text-xs text-slate-500 text-center">
                            After changing key restrictions, hard refresh the page. Check DevTools Console for the exact Maps error string.
                        </div>
                    </div>
                </div>
            ) : loadError ? (
                <div className="h-full w-full flex items-center justify-center text-sm text-slate-500 px-6 text-center">
                    Failed to load Google Maps. Please check the API key and network access.
                </div>
            ) : !isLoaded ? (
                <div className="h-full w-full flex items-center justify-center text-sm text-slate-500">Loading map…</div>
            ) : (
                <GoogleMap
                    mapContainerStyle={{ height: '100%', width: '100%' }}
                    center={initialCenter}
                    zoom={12}
                    onLoad={(mapInstance) => {
                        setMap(mapInstance);
                        fitToPins(mapInstance, pins);
                    }}
                    onUnmount={() => setMap(null)}
                    options={{
                        mapId: mapId || undefined,
                        fullscreenControl: false,
                        streetViewControl: false,
                        mapTypeControl: false,
                        clickableIcons: false,
                    }}
                >
                    {pins.map((p) => (
                        <React.Fragment key={p.staffId}>
                            {(() => {
                                const isSelected = selectedStaffId === p.staffId;
                                const icon: google.maps.Symbol = isSelected
                                    ? {
                                          path: PIN_PATH,
                                          scale: 1.8,
                                          fillColor: '#EF4444', // red-500 (highlight)
                                          fillOpacity: 1,
                                          strokeColor: '#FFFFFF',
                                          strokeOpacity: 1,
                                          strokeWeight: 4,
                                          anchor: new google.maps.Point(12, 24),
                                      }
                                    : {
                                          path: PIN_PATH,
                                          scale: 1.4,
                                          fillColor: '#EF4444', // red-500
                                          fillOpacity: 1,
                                          strokeColor: '#FFFFFF',
                                          strokeOpacity: 1,
                                          strokeWeight: 2,
                                          anchor: new google.maps.Point(12, 24),
                                      };

                                return (
                                    <MarkerF
                                        position={{ lat: p.lat, lng: p.lng }}
                                        icon={icon}
                                        zIndex={isSelected ? 999 : undefined}
                                        onClick={() => onSelectStaffId(isSelected ? '' : p.staffId)}
                                    />
                                );
                            })()}

                            {selectedStaffId === p.staffId ? (
                                <InfoWindowF position={{ lat: p.lat, lng: p.lng }} onCloseClick={() => onSelectStaffId('')}>
                                    <div className="text-sm">
                                        <div className="font-semibold text-slate-900">{p.fullName}</div>
                                        <div className="text-slate-600">{p.email}</div>
                                        <div className="text-slate-600">{p.phone ?? 'N/A'}</div>
                                        <div className="mt-1 text-xs text-slate-500">
                                            Lat: {p.lat.toFixed(6)}, Lng: {p.lng.toFixed(6)}
                                        </div>
                                        <div className="mt-1 text-xs">
                                            Status:{' '}
                                            <span className={p.isOnline ? 'text-emerald-700' : 'text-slate-600'}>
                                                {p.isOnline ? 'Online' : 'Offline'}
                                            </span>
                                        </div>
                                    </div>
                                </InfoWindowF>
                            ) : null}
                        </React.Fragment>
                    ))}
                </GoogleMap>
            )}
        </div>
    );
};

const DeliveryStaffMap: React.FC<{
    pins: MapPin[];
    selectedStaffId: string;
    onSelectStaffId: (staffId: string) => void;
}> = ({ pins, selectedStaffId, onSelectStaffId }) => {
    const apiKey = (import.meta.env.VITE_GOOGLE_MAPS_API_KEY ?? '').trim();
    const mapId = import.meta.env.VITE_GOOGLE_MAPS_MAP_ID;

    if (pins.length === 0) {
        return (
            <div className="h-[300px] sm:h-[400px] md:h-[480px] lg:h-[520px] w-full overflow-hidden rounded-xl sm:rounded-2xl border border-slate-200 bg-white shadow-sm flex items-center justify-center text-sm text-slate-500">
                No location data available yet.
            </div>
        );
    }

    if (!apiKey) {
        return (
            <div className="h-[300px] sm:h-[400px] md:h-[480px] lg:h-[520px] w-full overflow-hidden rounded-xl sm:rounded-2xl border border-slate-200 bg-white shadow-sm flex items-center justify-center text-sm text-slate-500 px-6 text-center">
                Google Maps is not configured. Set <code className="px-1 py-0.5 bg-slate-100 rounded">VITE_GOOGLE_MAPS_API_KEY</code> in your environment and restart the dev server.
            </div>
        );
    }

    return (
        <DeliveryStaffGoogleMap
            pins={pins}
            apiKey={apiKey}
            mapId={mapId}
            selectedStaffId={selectedStaffId}
            onSelectStaffId={onSelectStaffId}
        />
    );
};

const StaffRow: React.FC<{
    staff: Staff;
    expanded: boolean;
    selected: boolean;
    onSelect: () => void;
    onToggle: () => void;
}> = ({ staff, expanded, selected, onSelect, onToggle }) => {
    return (
        <div className="border-b border-slate-200 last:border-b-0">
            <button
                onClick={() => {
                    onSelect();
                    onToggle();
                }}
                className={`w-full px-5 py-3 transition flex items-center gap-3 ${selected ? 'bg-indigo-50' : 'hover:bg-slate-50'}`}
            >
                <div className={`h-10 w-10 ${staff.avatarBg} rounded-full text-white text-xs font-semibold flex items-center justify-center`}>{staff.initials}</div>
                <div className="flex-1 text-left">
                    <div className="flex items-center gap-2">
                        <div className="text-[15px] text-slate-900 font-medium">{staff.name}</div>
                        <div className="flex items-center gap-1 text-amber-500 text-sm leading-none">
                            <StarSolidIcon className="h-3.5 w-3.5" />
                            <span className="text-slate-700">{staff.rating == null ? 'N/A' : staff.rating.toFixed(1)}</span>
                        </div>
                        <span className="text-slate-400 text-sm">({staff.deliveries ?? 0} deliveries)</span>
                        <span
                            className={`ml-2 inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium ${
                                staff.isOnline ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600'
                            }`}
                        >
                            <span className={`h-1.5 w-1.5 rounded-full ${staff.isOnline ? 'bg-emerald-500' : 'bg-slate-400'}`} />
                            {staff.isOnline ? 'Online' : 'Offline'}
                        </span>
                    </div>
                </div>
                <span className="ml-2 text-slate-400">{expanded ? '▴' : '▾'}</span>
            </button>
            {expanded && (
                <div className="px-5 pb-4">
                    <div className="flex items-center gap-3 text-slate-700">
                        <PhoneIcon className="h-4 w-4 text-slate-500" />
                        <span className="text-sm">{staff.phone}</span>
                    </div>
                    <div className="mt-2 flex items-center gap-3 text-slate-700">
                        <MailIcon className="h-4 w-4 text-slate-500" />
                        <span className="text-sm underline decoration-slate-300">{staff.email}</span>
                    </div>

                    <div className="mt-3 grid grid-cols-2 gap-3">
                        <div className="rounded-xl border border-slate-200 p-3">
                            <div className="flex items-center gap-2 text-xs text-slate-500">
                                <span className="inline-flex h-2 w-2 rounded-full bg-emerald-500" />
                                Completion Rate
                            </div>
                            <div className="mt-1 text-xl font-semibold text-slate-900 leading-tight">98.5%</div>
                        </div>
                        <div className="rounded-xl border border-slate-200 p-3">
                            <div className="flex items-center gap-2 text-xs text-slate-500">
                                <span className="inline-flex h-2 w-2 rounded-full bg-indigo-500" />
                                Avg. Time
                            </div>
                            <div className="mt-1 text-xl font-semibold text-slate-900 leading-tight">28 min</div>
                        </div>
                    </div>

                    <div className="mt-3">
                        <div className="rounded-lg border border-[#2A52F2] text-[#2A52F2] bg-white px-3 py-2 text-sm">Order #2</div>
                    </div>

                    <button className="mt-3 w-full rounded-lg bg-[#2A52F2] px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:brightness-110">
                        Assign New Order
                    </button>
                </div>
            )}
        </div>
    );
};

const VerificationCard: React.FC<{
    request: VerificationRequest;
    expanded: boolean;
    onToggle: () => void;
    onApprove: () => void;
    onReject: () => void;
    isApproving?: boolean;
    isRejectDisabled?: boolean;
}> = ({ request, expanded, onToggle, onApprove, onReject }) => {
    return (
        <div className="rounded-xl border border-slate-200 bg-white shadow-sm overflow-hidden">
            <button
                type="button"
                onClick={onToggle}
                className="w-full px-4 sm:px-5 py-3 flex items-center gap-3 hover:bg-slate-50 transition"
            >
                <div className={`h-10 w-10 ${request.avatarBg} rounded-full text-white text-xs font-semibold flex items-center justify-center`}>
                    {request.initials}
                </div>
                <div className="flex-1 text-left">
                    <div className="text-[15px] sm:text-base text-slate-900 font-semibold">Approval Request</div>
                    <div className="mt-0.5 text-sm text-slate-700 font-medium">{request.name}</div>
                </div>

                <div className="flex items-center gap-2 sm:gap-3">
                    <button
                        type="button"
                        onClick={(e) => {
                            e.stopPropagation();
                            onApprove();
                        }}
                        className="min-w-[92px] rounded-lg bg-[#2A52F2] px-4 py-2 text-xs sm:text-sm font-medium text-white shadow-sm transition hover:brightness-110 disabled:opacity-60 disabled:cursor-not-allowed"
                    >
                        Approve
                    </button>
                    <button
                        type="button"
                        onClick={(e) => {
                            e.stopPropagation();
                            onReject();
                        }}
                        className="min-w-[92px] rounded-lg border border-rose-500 px-4 py-2 text-xs sm:text-sm font-medium text-rose-500 bg-white transition hover:bg-rose-50 disabled:opacity-60 disabled:cursor-not-allowed"
                    >
                        Reject
                    </button>
                    <span className="ml-1 sm:ml-2 text-slate-400">{expanded ? '▴' : '▾'}</span>
                </div>
            </button>

            {expanded && (
                <div className="px-4 sm:px-5 pb-4">
                    <div className="mt-1 flex items-center gap-3 text-slate-700">
                        <PhoneIcon className="h-4 w-4 text-slate-500" />
                        <span className="text-sm">{request.phone}</span>
                    </div>
                    <div className="mt-2 flex items-center gap-3 text-slate-700">
                        <MailIcon className="h-4 w-4 text-slate-500" />
                        <span className="text-sm underline decoration-slate-300">{request.email}</span>
                    </div>
                    <div className="mt-2 flex items-start gap-3 text-slate-700">
                        <LocationIcon className="h-4 w-4 text-slate-500 mt-0.5" />
                        <span className="text-sm">{request.address}</span>
                    </div>

                    <div className="mt-4 text-sm font-semibold text-slate-900">Documents</div>
                    <div className="mt-2 grid grid-cols-1 sm:grid-cols-2 gap-3">
                        {request.documents.map((doc) => (
                            <a
                                key={doc.id}
                                href={doc.url || undefined}
                                target={doc.url ? '_blank' : undefined}
                                rel={doc.url ? 'noreferrer' : undefined}
                                onClick={(e) => {
                                    if (!doc.url) e.preventDefault();
                                }}
                                className={`flex items-center gap-3 rounded-xl border border-slate-200 p-3 bg-white ${
                                    doc.url ? 'hover:bg-slate-50 transition cursor-pointer' : 'cursor-default'
                                }`}
                            >
                                <div className="h-10 w-14 rounded-lg bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-500">
                                    <DocIcon className="h-5 w-5" />
                                </div>
                                <div className="min-w-0">
                                    <div className="text-sm font-semibold text-slate-900 truncate">{doc.title}</div>
                                    {doc.subtitle ? (
                                        <div className="text-xs text-slate-500 truncate">{doc.subtitle}</div>
                                    ) : null}
                                    {doc.url ? <div className="text-[10px] text-indigo-600 mt-0.5">View</div> : null}
                                </div>
                            </a>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
};

export const DeliveryStaffPage: React.FC = () => {
    const [expandedId, setExpandedId] = useState<string>('');
    const [selectedStaffId, setSelectedStaffId] = useState<string>('');
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [expandedVerificationId, setExpandedVerificationId] = useState<string>('');

    const [summary, setSummary] = useState<AdminDeliveryStaffSummary | null>(null);
    const [deliveryStaffs, setDeliveryStaffs] = useState<AdminDeliveryStaff[]>([]);
    const [onlineDeliveryStaffs, setOnlineDeliveryStaffs] = useState<AdminOnlineDeliveryStaff[]>([]);
    const [pendingVerifications, setPendingVerifications] = useState<VerificationRequest[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [approvingStaffId, setApprovingStaffId] = useState<string | null>(null);

    const onlineStaffIdSet = useMemo(() => new Set(onlineDeliveryStaffs.map((s) => s.staffId)), [onlineDeliveryStaffs]);

    const mapPins = useMemo((): MapPin[] => {
        const onlineCoords = new Map<string, { lat: number; lng: number }>();
        onlineDeliveryStaffs.forEach((s) => {
            const lat = toNumber(s.shift?.lastLatitude);
            const lng = toNumber(s.shift?.lastLongitude);
            if (lat == null || lng == null) return;
            onlineCoords.set(s.staffId, { lat, lng });
        });

        return deliveryStaffs
            .map((s) => {
                const lat = toNumber(s.currentCoordinates?.latitude) ?? onlineCoords.get(s.staffId)?.lat ?? null;
                const lng = toNumber(s.currentCoordinates?.longitude) ?? onlineCoords.get(s.staffId)?.lng ?? null;
                if (lat == null || lng == null) return null;
                return {
                    staffId: s.staffId,
                    fullName: s.fullName,
                    email: s.email,
                    phone: s.phone,
                    lat,
                    lng,
                    isOnline: onlineStaffIdSet.has(s.staffId),
                } satisfies MapPin;
            })
            .filter(Boolean) as MapPin[];
    }, [deliveryStaffs, onlineDeliveryStaffs, onlineStaffIdSet]);

    const fetchAll = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [summaryRes, listRes, onlineRes, pendingRes] = await Promise.all([
                deliveryStaffManagementApi.getDeliveryStaffSummary(),
                deliveryStaffManagementApi.getDeliveryStaffs({ page: 1, limit: 50 }),
                deliveryStaffManagementApi.getOnlineDeliveryStaffs({ page: 1, limit: 50 }),
                deliveryStaffManagementApi.getPendingVerifications({ page: 1, limit: 20 }),
            ]);

            if (summaryRes.success) setSummary(summaryRes.data);
            if (listRes.success) setDeliveryStaffs(listRes.data.deliveryStaffs);
            if (onlineRes.success) setOnlineDeliveryStaffs(onlineRes.data.onlineDeliveryStaffs);

            if (pendingRes.success) {
                setPendingVerifications(
                    pendingRes.data.pendingVerifications.map((p) => {
                        const docs: VerificationRequest['documents'] = [
                            {
                                id: `${p.staffId}-id-proof`,
                                title: 'Id Proof',
                                subtitle: p.documents?.idProofType ?? undefined,
                                url: p.documents?.idProofUrl ?? null,
                            },
                            {
                                id: `${p.staffId}-dl`,
                                title: 'Driving License',
                                url: p.documents?.drivingLicenseUrl ?? null,
                            },
                        ].filter((d) => d.subtitle || d.url || d.title);

                        return {
                            staffId: p.staffId,
                            name: p.fullName,
                            initials: initialsFromName(p.fullName),
                            avatarBg: avatarBgFromSeed(p.staffId),
                            phone: p.phone || 'N/A',
                            email: p.email,
                            address: p.address || 'N/A',
                            documents: docs,
                        };
                    })
                );
            }
        } catch (err: any) {
            let errorMessage = 'Failed to load delivery staff. Please try again.';
            if (err?.response?.status === 401) errorMessage = 'Authentication required. Please log in again.';
            else if (err?.response?.data?.message) errorMessage = err.response.data.message;
            else if (err?.message) errorMessage = err.message;
            setError(errorMessage);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchAll();
    }, [fetchAll]);

    const handleApprove = useCallback(
        async (staffId: string) => {
            setApprovingStaffId(staffId);
            try {
                await deliveryStaffManagementApi.verifyDeliveryStaff(staffId);
                await fetchAll();
                setExpandedVerificationId((cur) => (cur === staffId ? '' : cur));
            } catch (err) {
                // Keep it silent; list refresh is enough, and error UI is global.
            } finally {
                setApprovingStaffId(null);
            }
        },
        [fetchAll]
    );

    // Filter staff based on status
    const staff = useMemo(() => {
        const rows: Staff[] = deliveryStaffs.map((s) => {
            const ratingNumber = toNumber(s.averageRating);
            const deliveriesNumber = typeof s.totalDeliveries === 'number' ? s.totalDeliveries : toNumber(s.totalDeliveries);
            return {
                id: s.staffId,
                name: s.fullName,
                rating: ratingNumber,
                deliveries: deliveriesNumber ?? 0,
                phone: s.phone || 'N/A',
                email: s.email,
                avatarBg: avatarBgFromSeed(s.staffId),
                initials: initialsFromName(s.fullName),
                isOnline: onlineStaffIdSet.has(s.staffId),
            };
        });

        if (statusFilter === 'available') return rows.filter((r) => r.isOnline);
        if (statusFilter === 'unavailable') return rows.filter((r) => !r.isOnline);
        // "onDelivery" requires a dedicated per-staff flag from backend (not exposed in current API),
        // so we keep the list unchanged while still showing the KPI count in the stat card.
        return rows;
    }, [deliveryStaffs, onlineStaffIdSet, statusFilter]);

    // Calculate KPIs dynamically from all staff
    const stats = useMemo(() => {
        return {
            totalStaff: summary?.total_staffs ?? deliveryStaffs.length,
            available: summary?.available ?? onlineDeliveryStaffs.length,
            onDelivery: summary?.currently_delivering ?? 0,
            avgRating: Number((summary?.average_rating ?? 0).toFixed(1)),
        };
    }, [summary, deliveryStaffs.length, onlineDeliveryStaffs.length]);

    const handleStatCardClick = (filter: string) => {
        // Toggle filter - if same filter is clicked, show all
        setStatusFilter(prevFilter => prevFilter === filter ? 'all' : filter);
    };

    return (
        <div className="w-full">
            <div className="mx-auto mt-1 sm:mt-2 w-full max-w-[1320px] rounded-2xl border border-slate-200 bg-white p-4 sm:p-6 md:p-7 shadow-sm">
                <div className="w-full">
                    {/* Header row with title and CTA */}
                    <div className="mb-3 sm:mb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
                        <div>
                            <h1 className="text-lg sm:text-xl md:text-[22px] font-semibold text-slate-900">Delivery Staff Management</h1>
                            <p className="mt-1 text-xs sm:text-sm text-slate-500">Track and manage delivery personnel in real-time.</p>
                        </div>
                    </div>

                    {error ? (
                        <div className="mb-4 rounded-xl border border-red-200 bg-red-50 p-4 text-center">
                            <div className="text-red-600 text-sm font-medium">{error}</div>
                            <button
                                onClick={() => fetchAll()}
                                className="mt-2 text-xs text-red-600 underline hover:text-red-700"
                                type="button"
                            >
                                Try again
                            </button>
                        </div>
                    ) : null}

                    {/* Stats cards */}
                    <div className="mb-4 sm:mb-5 grid grid-cols-1 gap-3 sm:gap-4 sm:grid-cols-2 lg:grid-cols-4">
                        <div
                            onClick={() => handleStatCardClick('all')}
                            className={`cursor-pointer transition-transform duration-150 hover:-translate-y-0.5 ${
                                statusFilter === 'all' ? 'ring-2 ring-indigo-500 rounded-xl' : ''
                            }`}
                        >
                            <StatCard title="Total Staff" value={stats.totalStaff} right={<UserOutlineIcon className="h-4 w-4 sm:h-5 sm:w-5 text-slate-400" />} />
                        </div>
                        <div
                            onClick={() => handleStatCardClick('available')}
                            className={`cursor-pointer transition-transform duration-150 hover:-translate-y-0.5 ${
                                statusFilter === 'available' ? 'ring-2 ring-indigo-500 rounded-xl' : ''
                            }`}
                        >
                            <StatCard title="Available" value={stats.available} right={<span className="inline-flex h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-emerald-500" />} />
                        </div>
                        <div
                            onClick={() => handleStatCardClick('onDelivery')}
                            className={`cursor-pointer transition-transform duration-150 hover:-translate-y-0.5 ${
                                statusFilter === 'onDelivery' ? 'ring-2 ring-indigo-500 rounded-xl' : ''
                            }`}
                        >
                            <StatCard title="On Delivery" value={stats.onDelivery} right={<span className="inline-flex h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-indigo-500" />} />
                        </div>
                        <div className="cursor-default">
                            <StatCard title="Avg. Rating" value={stats.avgRating} right={<StarSolidIcon className="h-4 w-4 sm:h-5 sm:w-5 text-amber-400" />} />
                        </div>
                    </div>

                    {/* Map + Staff details layout */}
                    <div className="grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-12">
                        <div className="xl:col-span-7 2xl:col-span-7 order-2 xl:order-1">
                            <DeliveryStaffMap
                                pins={mapPins}
                                selectedStaffId={selectedStaffId}
                                onSelectStaffId={(id) => {
                                    setSelectedStaffId(id);
                                    if (id) setExpandedId(id);
                                }}
                            />

                            {/* Pending verifications */}
                            <div className="mt-4 sm:mt-5 rounded-xl sm:rounded-2xl border border-slate-200 bg-white shadow-sm p-4 sm:p-5">
                                <div className="flex items-center justify-between">
                                    <div className="text-base sm:text-[17px] font-semibold text-slate-900">Pending Verifications</div>
                                    <div className="text-xs sm:text-sm text-slate-500">{pendingVerifications.length} pending</div>
                                </div>

                                {loading && pendingVerifications.length === 0 ? (
                                    <div className="mt-3 rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center text-sm text-slate-500">
                                        Loading pending verification requests...
                                    </div>
                                ) : pendingVerifications.length === 0 ? (
                                    <div className="mt-3 rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center text-sm text-slate-500">
                                        No pending verification requests.
                                    </div>
                                ) : (
                                    <div className="mt-3 space-y-3">
                                        {pendingVerifications.map((req) => (
                                            <VerificationCard
                                                key={req.staffId}
                                                request={req}
                                                expanded={expandedVerificationId === req.staffId}
                                                onToggle={() => setExpandedVerificationId((cur) => (cur === req.staffId ? '' : req.staffId))}
                                                onApprove={() => {
                                                    handleApprove(req.staffId);
                                                }}
                                                onReject={() => {
                                                    // Backend doesn't provide a reject endpoint in current API.
                                                    // Keep action present for UI parity, but no-op.
                                                }}
                                            />
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>
                        <div className="xl:col-span-5 2xl:col-span-5 order-1 xl:order-2">
                            <div className="rounded-xl sm:rounded-2xl border border-slate-200 bg-white shadow-sm">
                                <div className="flex items-center justify-between px-4 sm:px-5 py-2.5 sm:py-3">
                                    <div className="text-sm sm:text-[15px] font-semibold text-slate-900">Staff Details</div>
                                </div>
                                <div className="max-h-[400px] sm:max-h-[500px] md:max-h-[560px] overflow-auto">
                                    {loading && staff.length === 0 ? (
                                        <div className="px-5 py-8 text-center text-sm text-slate-500">Loading delivery staff...</div>
                                    ) : staff.length === 0 ? (
                                        <div className="px-5 py-8 text-center text-sm text-slate-500">No delivery staff found.</div>
                                    ) : (
                                        staff.map((s) => (
                                            <StaffRow
                                                key={s.id}
                                                staff={s}
                                                expanded={expandedId === s.id}
                                                selected={selectedStaffId === s.id}
                                                onSelect={() => setSelectedStaffId(s.id)}
                                                onToggle={() => setExpandedId((e) => (e === s.id ? '' : s.id))}
                                            />
                                        ))
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};
