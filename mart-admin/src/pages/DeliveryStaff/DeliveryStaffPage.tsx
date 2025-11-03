import React, { useMemo, useState } from 'react';

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

type Staff = {
    id: string;
    name: string;
    rating: number;
    deliveries: number;
    phone: string;
    email: string;
    coords: { top: string; left: string };
    avatarBg: string;
    initials: string;
    isAvailable: boolean;
    isOnDelivery: boolean;
};

// Expanded staff list with realistic data for testing
const staffListSeed: Staff[] = [
    { id: '1', name: 'Sam Wilson', rating: 4.9, deliveries: 342, phone: '+91 84567 32156', email: 'samwilson@gmail.com', coords: { top: '54%', left: '48%' }, avatarBg: 'bg-rose-500', initials: 'SW', isAvailable: true, isOnDelivery: false },
    { id: '2', name: 'War Machine', rating: 4.9, deliveries: 312, phone: '+91 84567 65432', email: 'warmachine@gmail.com', coords: { top: '30%', left: '62%' }, avatarBg: 'bg-cyan-600', initials: 'WM', isAvailable: true, isOnDelivery: true },
    { id: '3', name: 'Aria Monroe', rating: 4.8, deliveries: 300, phone: '+91 84567 10010', email: 'aria.monroe@gmail.com', coords: { top: '72%', left: '58%' }, avatarBg: 'bg-indigo-600', initials: 'AM', isAvailable: true, isOnDelivery: true },
    { id: '4', name: 'Peter Parker', rating: 4.7, deliveries: 288, phone: '+91 84567 99999', email: 'peter.parker@gmail.com', coords: { top: '38%', left: '30%' }, avatarBg: 'bg-emerald-600', initials: 'PP', isAvailable: true, isOnDelivery: false },
    { id: '5', name: 'Natasha R.', rating: 4.8, deliveries: 331, phone: '+91 84567 88888', email: 'natasha@gmail.com', coords: { top: '44%', left: '40%' }, avatarBg: 'bg-fuchsia-600', initials: 'NR', isAvailable: true, isOnDelivery: true },
    { id: '6', name: 'Tony Stark', rating: 4.9, deliveries: 356, phone: '+91 84567 77777', email: 'tonystark@gmail.com', coords: { top: '50%', left: '35%' }, avatarBg: 'bg-red-600', initials: 'TS', isAvailable: true, isOnDelivery: false },
    { id: '7', name: 'Steve Rogers', rating: 5.0, deliveries: 389, phone: '+91 84567 66666', email: 'steverogers@gmail.com', coords: { top: '60%', left: '45%' }, avatarBg: 'bg-blue-600', initials: 'SR', isAvailable: true, isOnDelivery: true },
    { id: '8', name: 'Bruce Banner', rating: 4.6, deliveries: 275, phone: '+91 84567 55555', email: 'brucebanner@gmail.com', coords: { top: '25%', left: '50%' }, avatarBg: 'bg-green-600', initials: 'BB', isAvailable: false, isOnDelivery: false },
    { id: '9', name: 'Carol Danvers', rating: 4.9, deliveries: 367, phone: '+91 84567 44444', email: 'caroldanvers@gmail.com', coords: { top: '65%', left: '55%' }, avatarBg: 'bg-yellow-600', initials: 'CD', isAvailable: true, isOnDelivery: false },
    { id: '10', name: 'Scott Lang', rating: 4.5, deliveries: 256, phone: '+91 84567 33333', email: 'scottlang@gmail.com', coords: { top: '40%', left: '25%' }, avatarBg: 'bg-purple-600', initials: 'SL', isAvailable: true, isOnDelivery: true },
];

const StatCard: React.FC<{
    title: string;
    value: string | number;
    right?: React.ReactNode;
}> = ({ title, value, right }) => (
    <div className="tw-card rounded-xl shadow-sm border border-slate-200 bg-white px-5 py-4 transition-all duration-150 ease-in-out hover:shadow md:min-w-[220px]">
        <div className="flex items-center justify-between text-slate-500 text-sm font-medium">
            <span>{title}</span>
            {right}
        </div>
        <div className="mt-2 text-3xl font-semibold text-slate-900">{value}</div>
    </div>
);

const MapWithMarkers: React.FC<{ staff: Staff[] }> = ({ staff }) => {
    return (
        <div className="relative h-[520px] w-full overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            {/* Real map embed */}
            <iframe
                title="map"
                className="absolute inset-0 h-full w-full"
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                src="https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d52873.42092929033!2d-84.068!3d34.024!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sen!2sus!4v1700000000000"
            />
            {/* Custom avatar markers overlay */}
            {staff.map((s) => (
                <div key={s.id} className="absolute" style={{ top: s.coords.top, left: s.coords.left, transform: 'translate(-50%, -50%)' }}>
                    <div className="relative">
                        <div className={`h-9 w-9 ${s.avatarBg} ring-2 ring-white rounded-full flex items-center justify-center text-white text-[10px] font-semibold shadow`}>
                            {s.initials}
                        </div>
                        <div className="absolute -bottom-[6px] left-1/2 h-0 w-0 -translate-x-1/2 border-x-6 border-x-transparent border-t-6 border-t-rose-400" />
                    </div>
                </div>
            ))}
        </div>
    );
};

const StaffRow: React.FC<{ staff: Staff; expanded: boolean; onToggle: () => void }> = ({ staff, expanded, onToggle }) => {
    return (
        <div className="border-b border-slate-200 last:border-b-0">
            <button onClick={onToggle} className="w-full px-5 py-3 hover:bg-slate-50 transition flex items-center gap-3">
                <div className={`h-10 w-10 ${staff.avatarBg} rounded-full text-white text-xs font-semibold flex items-center justify-center`}>{staff.initials}</div>
                <div className="flex-1 text-left">
                    <div className="flex items-center gap-2">
                        <div className="text-[15px] text-slate-900 font-medium">{staff.name}</div>
                        <div className="flex items-center gap-1 text-amber-500 text-sm leading-none"><StarSolidIcon className="h-3.5 w-3.5" /><span className="text-slate-700">{staff.rating.toFixed(1)}</span></div>
                        <span className="text-slate-400 text-sm">({staff.deliveries} deliveries)</span>
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

export const DeliveryStaffPage: React.FC = () => {
    const allStaff = useMemo(() => staffListSeed, []);
    const [expandedId, setExpandedId] = useState<string>('2');
    const [statusFilter, setStatusFilter] = useState<string>('all');

    // Filter staff based on status
    const staff = useMemo(() => {
        if (statusFilter === 'all') {
            return allStaff;
        } else if (statusFilter === 'available') {
            return allStaff.filter(s => s.isAvailable && !s.isOnDelivery);
        } else if (statusFilter === 'onDelivery') {
            return allStaff.filter(s => s.isOnDelivery);
        } else if (statusFilter === 'unavailable') {
            return allStaff.filter(s => !s.isAvailable && !s.isOnDelivery);
        }
        return allStaff;
    }, [allStaff, statusFilter]);

    // Calculate KPIs dynamically from all staff
    const stats = useMemo(() => {
        const totalStaff = allStaff.length;
        const available = allStaff.filter(s => s.isAvailable && !s.isOnDelivery).length;
        const onDelivery = allStaff.filter(s => s.isOnDelivery).length;
        const totalRating = allStaff.reduce((sum, s) => sum + s.rating, 0);
        const avgRating = totalStaff > 0 ? totalRating / totalStaff : 0;

        return {
            totalStaff,
            available,
            onDelivery,
            avgRating: Number(avgRating.toFixed(1)),
        };
    }, [allStaff]);

    const handleStatCardClick = (filter: string) => {
        // Toggle filter - if same filter is clicked, show all
        setStatusFilter(prevFilter => prevFilter === filter ? 'all' : filter);
    };

    return (
        <div className="w-full">
            {/* Header row with title and CTA */}
            <div className="mb-4 flex items-center justify-between">
                <div>
                    <h1 className="text-[22px] font-semibold text-slate-900">Delivery Staff Management</h1>
                    <p className="mt-1 text-sm text-slate-500">Track and manage delivery personnel in real-time.</p>
                </div>
                <button className="inline-flex items-center gap-2 rounded-lg bg-[#2A52F2] px-4 py-2 text-sm font-medium text-white shadow-sm transition duration-150 ease-in-out hover:brightness-110">
                    <span className="text-lg leading-none">+</span>
                    Add Delivery Staff
                </button>
            </div>

            {/* Stats cards */}
            <div className="mb-5 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <div
                    onClick={() => handleStatCardClick('all')}
                    className={`cursor-pointer transition-transform duration-150 hover:-translate-y-0.5 ${
                        statusFilter === 'all' ? 'ring-2 ring-indigo-500 rounded-xl' : ''
                    }`}
                >
                    <StatCard title="Total Staff" value={stats.totalStaff} right={<UserOutlineIcon className="h-5 w-5 text-slate-400" />} />
                </div>
                <div
                    onClick={() => handleStatCardClick('available')}
                    className={`cursor-pointer transition-transform duration-150 hover:-translate-y-0.5 ${
                        statusFilter === 'available' ? 'ring-2 ring-indigo-500 rounded-xl' : ''
                    }`}
                >
                    <StatCard title="Available" value={stats.available} right={<span className="inline-flex h-2.5 w-2.5 rounded-full bg-emerald-500" />} />
                </div>
                <div
                    onClick={() => handleStatCardClick('onDelivery')}
                    className={`cursor-pointer transition-transform duration-150 hover:-translate-y-0.5 ${
                        statusFilter === 'onDelivery' ? 'ring-2 ring-indigo-500 rounded-xl' : ''
                    }`}
                >
                    <StatCard title="On Delivery" value={stats.onDelivery} right={<span className="inline-flex h-2.5 w-2.5 rounded-full bg-indigo-500" />} />
                </div>
                <div className="cursor-default">
                    <StatCard title="Avg. Rating" value={stats.avgRating} right={<StarSolidIcon className="h-5 w-5 text-amber-400" />} />
                </div>
            </div>

            {/* Map + Staff details layout */}
            <div className="grid grid-cols-1 gap-5 xl:grid-cols-12">
                <div className="xl:col-span-7 2xl:col-span-7">
                    <MapWithMarkers staff={staff} />
                </div>
                <div className="xl:col-span-5 2xl:col-span-5">
                    <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
                        <div className="flex items-center justify-between px-5 py-3">
                            <div className="text-[15px] font-semibold text-slate-900">Staff Details</div>
                        </div>
                        <div className="max-h-[560px] overflow-auto">
                            {staff.map((s) => (
                                <StaffRow key={s.id} staff={s} expanded={expandedId === s.id} onToggle={() => setExpandedId((e) => (e === s.id ? '' : s.id))} />
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};
