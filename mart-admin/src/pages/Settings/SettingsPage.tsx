import React, { useEffect, useMemo, useState } from 'react';
import { Modal } from '@/components/common/Modal';
import { Toast } from '@/components/common/Toast';
import { useToast } from '@/hooks/common/useToast';
import { settingsApi, ServiceArea, SaveSettingsPayload, TeamSummary, TeamMemberInput, TeamMember } from '@/services/api/modules/settingsApi';

interface ToggleSwitchProps {
  enabled: boolean;
  onChange: (enabled: boolean) => void;
  label: string;
}

const ToggleSwitch: React.FC<ToggleSwitchProps> = ({ enabled, onChange, label }) => {
  return (
    <div className="flex items-center justify-between py-2">
      <span className="text-sm text-slate-600 font-medium">{label}</span>
      <button
        type="button"
        onClick={() => onChange(!enabled)}
        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
          enabled ? 'bg-[#1E40AF]' : 'bg-gray-300'
        }`}
      >
        <span
          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
            enabled ? 'translate-x-6' : 'translate-x-1'
          }`}
        />
      </button>
    </div>
  );
};

export const SettingsPage: React.FC = () => {
  const [twoFactorEnabled, setTwoFactorEnabled] = useState(true);
  const [creditCardEnabled, setCreditCardEnabled] = useState(true);
  const [debitCardEnabled, setDebitCardEnabled] = useState(true);
  const [digitalWalletsEnabled, setDigitalWalletsEnabled] = useState(true);
  const [codEnabled, setCodEnabled] = useState(true);
  const [bankTransferEnabled, setBankTransferEnabled] = useState(false);
  const [newOrdersEnabled, setNewOrdersEnabled] = useState(true);
  const [deliveryUpdatesEnabled, setDeliveryUpdatesEnabled] = useState(true);
  const [customerMessagesEnabled, setCustomerMessagesEnabled] = useState(true);
  const [systemAlertsEnabled, setSystemAlertsEnabled] = useState(false);

  const [businessName, setBusinessName] = useState('LaundryHub');
  const [businessEmail, setBusinessEmail] = useState('contact@laundryhub.com');
  const [contactNumber, setContactNumber] = useState('+91 56234 56458');
  const [taxId, setTaxId] = useState('XX XXXX XXXX XXXX');
  const [businessAddress, setBusinessAddress] = useState('123 Main Street, City, State 12345');
  const [serviceAreas, setServiceAreas] = useState<ServiceArea[]>([]);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [newAreaName, setNewAreaName] = useState('');
  const [loadingAreas, setLoadingAreas] = useState(false);
  const [saving, setSaving] = useState(false);
  const { toast, showToast, hideToast } = useToast();

  const PENDING_LOCAL_KEY = 'settings_pending_service_areas';
  const PENDING_TEAM_KEY = 'settings_pending_team_members';

  const getPendingAreas = (): ServiceArea[] => {
    try {
      const raw = localStorage.getItem(PENDING_LOCAL_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw) as { id: string; name: string }[];
      if (!Array.isArray(parsed)) return [];
      return parsed.map((p) => ({ id: p.id, name: p.name }));
    } catch {
      return [];
    }
  };

  const setPendingAreas = (areas: ServiceArea[]) => {
    try {
      const serializable = areas.map((a) => ({ id: a.id, name: a.name }));
      localStorage.setItem(PENDING_LOCAL_KEY, JSON.stringify(serializable));
    } catch {
      // ignore storage errors
    }
  };

  const getPendingTeam = (): TeamMemberInput[] => {
    try {
      const raw = localStorage.getItem(PENDING_TEAM_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw) as TeamMemberInput[];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  };

  const setPendingTeam = (members: TeamMemberInput[]) => {
    try {
      localStorage.setItem(PENDING_TEAM_KEY, JSON.stringify(members));
    } catch {
      // ignore
    }
  };

  useEffect(() => {
    const load = async () => {
      setLoadingAreas(true);
      try {
        const areas = await settingsApi.getServiceAreas();
        const pending = getPendingAreas();
        const byName = new Map<string, ServiceArea>();
        areas.forEach((a) => byName.set(a.name.toLowerCase(), a));
        pending.forEach((p) => {
          const key = p.name.toLowerCase();
          if (!byName.has(key)) byName.set(key, p);
        });
        setServiceAreas(Array.from(byName.values()));
      } catch (e: any) {
        // Fallback demo data if API not available
        const demo = [
          { id: 'demo-1', name: 'Neeladri' },
          { id: 'demo-2', name: 'Bomannahalli' },
          { id: 'demo-3', name: 'E-City Phase-1' },
          { id: 'demo-4', name: 'E-City Phase-2' },
          { id: 'demo-5', name: 'Doddathogor' },
        ];
        const pending = getPendingAreas();
        const byName = new Map<string, ServiceArea>();
        demo.forEach((a) => byName.set(a.name.toLowerCase(), a));
        pending.forEach((p) => byName.set(p.name.toLowerCase(), p));
        setServiceAreas(Array.from(byName.values()));
      } finally {
        setLoadingAreas(false);
      }
    };
    load();
  }, []);

  // Team summary state and load
  const [teamSummary, setTeamSummary] = useState<TeamSummary>({ owner: 1, manager: 3, cleaningStaff: 5, deliveryBoys: 8 });
  const [isAddTeamModalOpen, setIsAddTeamModalOpen] = useState(false);
  const [newMember, setNewMember] = useState<TeamMemberInput>({ name: '', email: '', phone: '', role: 'manager' });
  const [isMembersModalOpen, setIsMembersModalOpen] = useState(false);
  const [membersRole, setMembersRole] = useState<TeamMemberInput['role']>('manager');
  const [members, setMembers] = useState<TeamMember[]>([]);
  const [loadingMembers, setLoadingMembers] = useState(false);

  // Security modals
  const [isChangePwdOpen, setIsChangePwdOpen] = useState(false);
  const [pwdCurrent, setPwdCurrent] = useState('');
  const [pwdNew, setPwdNew] = useState('');
  const [pwdConfirm, setPwdConfirm] = useState('');
  const [changingPwd, setChangingPwd] = useState(false);
  const [isActivityOpen, setIsActivityOpen] = useState(false);
  const [activity, setActivity] = useState<{ id: string; action: string; at: string; ip?: string }[]>([]);
  const [loadingActivity, setLoadingActivity] = useState(false);

  useEffect(() => {
    const loadTeam = async () => {
      try {
        const summary = await settingsApi.getTeamSummary();
        const pending = getPendingTeam();
        const pendingCounts = pending.reduce(
          (acc, m) => {
            acc[m.role] = (acc[m.role] as number) + 1;
            return acc;
          },
          { owner: 0, manager: 0, cleaningStaff: 0, deliveryBoys: 0 } as TeamSummary
        );
        setTeamSummary({
          owner: summary.owner + pendingCounts.owner,
          manager: summary.manager + pendingCounts.manager,
          cleaningStaff: summary.cleaningStaff + pendingCounts.cleaningStaff,
          deliveryBoys: summary.deliveryBoys + pendingCounts.deliveryBoys,
        });
      } catch {
        const pending = getPendingTeam();
        const pendingCounts = pending.reduce(
          (acc, m) => {
            acc[m.role] = (acc[m.role] as number) + 1;
            return acc;
          },
          { owner: 0, manager: 0, cleaningStaff: 0, deliveryBoys: 0 } as TeamSummary
        );
        setTeamSummary((s) => ({
          owner: s.owner + pendingCounts.owner,
          manager: s.manager + pendingCounts.manager,
          cleaningStaff: s.cleaningStaff + pendingCounts.cleaningStaff,
          deliveryBoys: s.deliveryBoys + pendingCounts.deliveryBoys,
        }));
      }
    };
    loadTeam();
  }, []);

  const handleRemoveServiceArea = async (area: ServiceArea) => {
    try {
      // If demo/temp id, just update state without API call
      if (area.id.startsWith('demo-') || area.id.startsWith('temp-')) {
        setServiceAreas((prev) => prev.filter((a) => a.id !== area.id));
        const pending = getPendingAreas();
        setPendingAreas(pending.filter((p) => p.id !== area.id && p.name.toLowerCase() !== area.name.toLowerCase()));
        showToast('Service area removed', 'success');
        return;
      }

      if (!area.id.startsWith('demo-')) {
        await settingsApi.deleteServiceArea(area.id);
      }
      setServiceAreas((prev) => prev.filter((a) => a.id !== area.id));
      showToast('Service area removed', 'success');
    } catch (e: any) {
      showToast(e?.message || 'Failed to remove service area', 'error');
    }
  };

  const handleAddTeamMember = async () => {
    if (!newMember.name.trim()) {
      showToast('Name is required', 'error');
      return;
    }
    try {
      await settingsApi.addTeamMember(newMember).catch(() => Promise.resolve());
      setPendingTeam([newMember, ...getPendingTeam()]);
      setTeamSummary((s) => ({
        ...s,
        [newMember.role]: (s[newMember.role] as number) + 1,
      } as TeamSummary));
      setIsAddTeamModalOpen(false);
      setNewMember({ name: '', email: '', phone: '', role: 'manager' });
      showToast('Team member added', 'success');
    } catch (e: any) {
      showToast(e?.message || 'Failed to add team member', 'error');
    }
  };

  const openMembersModal = async (role: TeamMemberInput['role']) => {
    setMembersRole(role);
    setIsMembersModalOpen(true);
    setLoadingMembers(true);
    try {
      const serverMembers = await settingsApi.getTeamMembers(role).catch(() => [] as TeamMember[]);
      // Merge server with pending (pending don't have ids)
      const pending = getPendingTeam().filter((m) => m.role === role);
      const withPending = [
        ...serverMembers,
        ...pending.map((m, idx) => ({ id: `temp-${role}-${idx}-${Date.now()}`, ...m })),
      ];
      setMembers(withPending);
    } finally {
      setLoadingMembers(false);
    }
  };

  const handleRemoveMember = async (member: TeamMember) => {
    try {
      if (member.id.startsWith('temp-')) {
        // Remove from pending store
        const updated = getPendingTeam().filter(
          (m) => !(m.role === member.role && m.name === member.name && m.email === member.email && m.phone === member.phone)
        );
        setPendingTeam(updated);
        setMembers((prev) => prev.filter((m) => m.id !== member.id));
        setTeamSummary((s) => ({ ...s, [member.role]: (s[member.role] as number) - 1 } as TeamSummary));
        showToast('Member removed', 'success');
        return;
      }

      await settingsApi.deleteTeamMember(member.id);
      setMembers((prev) => prev.filter((m) => m.id !== member.id));
      setTeamSummary((s) => ({ ...s, [member.role]: (s[member.role] as number) - 1 } as TeamSummary));
      showToast('Member removed', 'success');
    } catch (e: any) {
      showToast(e?.message || 'Failed to remove member', 'error');
    }
  };

  const handleAddServiceArea = async () => {
    const name = newAreaName.trim();
    if (!name) return;
    try {
      const created = await settingsApi.addServiceArea(name).catch(() => ({ id: `temp-${Date.now()}`, name }));
      setServiceAreas((prev) => [{ id: created.id, name: created.name }, ...prev]);
      if (created.id.startsWith('temp-') || created.id.startsWith('demo-')) {
        const pending = getPendingAreas();
        const merged = [{ id: created.id, name: created.name }, ...pending.filter((p) => p.name.toLowerCase() !== created.name.toLowerCase())];
        setPendingAreas(merged);
      }
      setIsAddModalOpen(false);
      setNewAreaName('');
      showToast('Service area added', 'success');
    } catch (e: any) {
      showToast(e?.message || 'Failed to add service area', 'error');
    }
  };

  const handleSaveSettings = async () => {
    const payload: SaveSettingsPayload = {
      businessName,
      businessEmail,
      contactNumber,
      taxId,
      businessAddress,
      paymentMethods: {
        creditCard: creditCardEnabled,
        debitCard: debitCardEnabled,
        digitalWallets: digitalWalletsEnabled,
        cod: codEnabled,
        bankTransfer: bankTransferEnabled,
      },
      notifications: {
        newOrders: newOrdersEnabled,
        deliveryUpdates: deliveryUpdatesEnabled,
        customerMessages: customerMessagesEnabled,
        systemAlerts: systemAlertsEnabled,
      },
      serviceAreas: serviceAreas.map((a) => ({ id: a.id.startsWith('demo-') || a.id.startsWith('temp-') ? undefined : a.id, name: a.name })),
      teamMembersAdded: getPendingTeam(),
    };

    try {
      setSaving(true);
      await settingsApi.saveSettings(payload);
      showToast('Settings saved successfully', 'success');
      setPendingAreas([]);
      setPendingTeam([]);
    } catch (e: any) {
      // If backend not ready, still give user feedback (no-op save)
      showToast('Settings updated locally', 'info');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="px-3 sm:px-4 md:px-6 lg:px-8 xl:px-10 py-4 sm:py-5 md:py-6 bg-[#F9FAFB] space-y-4 sm:space-y-5 md:space-y-6 lg:space-y-8">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-[#111827]">Settings</h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">Manage your account and system preferences.</p>
        </div>
        <button onClick={handleSaveSettings} disabled={saving} className={`h-8 sm:h-9 px-4 sm:px-5 ${saving ? 'bg-[#1E40AF]/70 cursor-not-allowed' : 'bg-[#1E40AF] hover:bg-[#1E3A8A]'} text-white text-xs sm:text-sm font-medium rounded-full shadow-sm transition-colors flex items-center gap-1.5 justify-center w-full sm:w-auto md:sticky md:top-4 self-start`}>
          <svg className="w-3 h-3 sm:w-4 sm:h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
          </svg>
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 sm:gap-5 md:gap-6 lg:gap-8">
        {/* Left Column */}
        <div className="space-y-8 lg:col-span-8">
          {/* Business Information Card */}
          <div className="bg-white rounded-2xl shadow-md border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-base font-semibold text-[#111827]">Business Information</h2>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Business Name</label>
                  <input
                    type="text"
                    value={businessName}
                    onChange={(e) => setBusinessName(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
                    placeholder="Enter business name"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Business Email</label>
                  <input
                    type="email"
                    value={businessEmail}
                    onChange={(e) => setBusinessEmail(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
                    placeholder="Enter business email"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Contact Number</label>
                  <input
                    type="tel"
                    value={contactNumber}
                    onChange={(e) => setContactNumber(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
                    placeholder="Enter contact number"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Tax ID</label>
                  <input
                    type="text"
                    value={taxId}
                    onChange={(e) => setTaxId(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
                    placeholder="Enter tax ID"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Business Address</label>
                <textarea
                  value={businessAddress}
                  onChange={(e) => setBusinessAddress(e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent resize-none"
                  placeholder="Enter business address"
                />
              </div>
            </div>
          </div>

          {/* Service Areas Card */}
          <div className="bg-white rounded-2xl shadow-md border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h2 className="text-base font-semibold text-[#111827]">Service Areas</h2>
              <button onClick={() => setIsAddModalOpen(true)} className="h-8 px-3 bg-[#1E40AF] hover:bg-[#1E3A8A] text-white text-xs font-medium rounded-full shadow-sm transition-colors flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                Add Service Area
              </button>
            </div>
            <div className="p-6">
              {loadingAreas && (
                <div className="text-sm text-slate-500">Loading service areas...</div>
              )}
              {!loadingAreas && serviceAreas.map((area, idx) => (
                <div key={area.id} className={`flex items-center gap-3 py-3 ${idx < serviceAreas.length - 1 ? 'border-b border-gray-200' : ''}`}>
                  <div className="w-5 h-5 text-[#1E40AF]">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </div>
                  <span className="text-sm text-slate-700 flex-1">{area.name}</span>
                  <button
                    type="button"
                    onClick={() => handleRemoveServiceArea(area)}
                    aria-label="Remove service area"
                    className="inline-flex items-center justify-center w-8 h-8 rounded-full border border-gray-200 text-slate-500 hover:text-red-600 hover:border-red-300 transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Payment Settings Card */}
          <div className="bg-white rounded-2xl shadow-md border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-base font-semibold text-[#111827]">Payment Settings</h2>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  Default Currency
                </label>
                <select className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent bg-white">
                  <option>$ - US Dollar (USD)</option>
                  <option>€ - Euro (EUR)</option>
                  <option>£ - British Pound (GBP)</option>
                  <option>₹ - Indian Rupee (INR)</option>
                </select>
                <p className="text-xs text-slate-500 mt-1.5">
                  This currency will be used across the platform for all transactions and reports
                </p>
              </div>
              <div className="pt-2">
                <div className="text-sm font-medium text-slate-700 mb-3">Accepted Payment Methods</div>
                <div className="space-y-2">
                  <ToggleSwitch
                    enabled={creditCardEnabled}
                    onChange={setCreditCardEnabled}
                    label="Credit Card"
                  />
                  <ToggleSwitch
                    enabled={debitCardEnabled}
                    onChange={setDebitCardEnabled}
                    label="Debit Card"
                  />
                  <ToggleSwitch
                    enabled={digitalWalletsEnabled}
                    onChange={setDigitalWalletsEnabled}
                    label="Digital Wallets"
                  />
                  <ToggleSwitch
                    enabled={codEnabled}
                    onChange={setCodEnabled}
                    label="Cash On Delivery"
                  />
                  <ToggleSwitch
                    enabled={bankTransferEnabled}
                    onChange={setBankTransferEnabled}
                    label="Bank Transfer"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-8 lg:col-span-4">
          {/* Team Roles Card */}
          <div className="bg-white rounded-2xl shadow-md border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-base font-semibold text-[#111827]">Team Roles</h2>
            </div>
            <div className="p-6 space-y-4">
              {[
                { key: 'owner', label: 'Owner', count: teamSummary.owner },
                { key: 'manager', label: 'Manager', count: teamSummary.manager },
                { key: 'cleaningStaff', label: 'Cleaning Staff', count: teamSummary.cleaningStaff },
                { key: 'deliveryBoys', label: 'Delivery Boys', count: teamSummary.deliveryBoys },
              ].map((item: any, idx: number) => (
                <button type="button" onClick={() => openMembersModal(item.key)} key={idx} className="w-full text-left flex items-center justify-between p-3 rounded-xl border border-gray-200 shadow-sm hover:bg-slate-50 transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="flex -space-x-2">
                      {[...Array(Math.min(item.count, 3))].map((_, i) => (
                        <div key={i} className="w-8 h-8 rounded-full bg-blue-100 border-2 border-white flex items-center justify-center">
                          <span className="text-xs font-semibold text-[#1E40AF]">{item.label.charAt(0)}</span>
                        </div>
                      ))}
                      {item.count > 3 && (
                        <div className="w-8 h-8 rounded-full bg-slate-200 border-2 border-white flex items-center justify-center">
                          <span className="text-xs font-semibold text-slate-600">
                            +{item.count - 3}
                          </span>
                        </div>
                      )}
                    </div>
                    <span className="text-sm font-medium text-slate-900">{item.label}</span>
                  </div>
                  <span className="text-xs text-slate-500">{item.count} member{item.count !== 1 ? 's' : ''}</span>
                </button>
              ))}
              <button onClick={() => setIsAddTeamModalOpen(true)} className="w-full h-9 px-4 bg-[#1E40AF] hover:bg-[#1E3A8A] text-white text-xs font-medium rounded-full shadow-sm transition-colors flex items-center justify-center gap-1.5 mt-4">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                Add Team member
              </button>
            </div>
          </div>

          {/* Security Card */}
          <div className="bg-white rounded-2xl shadow-md border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-base font-semibold text-[#111827]">Security</h2>
            </div>
            <div className="p-6 space-y-4">
              <div className="flex items-center justify-between py-2">
                <div>
                  <div className="text-sm font-medium text-slate-700">Enhanced Security</div>
                  <div className="text-xs text-slate-500 mt-0.5">Enable two-factor authentication</div>
                </div>
                <button
                  type="button"
                  onClick={() => setTwoFactorEnabled(!twoFactorEnabled)}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    twoFactorEnabled ? 'bg-[#1E40AF]' : 'bg-gray-300'
                  }`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      twoFactorEnabled ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>
              <div className="pt-2 space-y-2 border-t border-gray-200">
                <button onClick={() => setIsChangePwdOpen(true)} className="w-full h-9 px-4 border border-gray-300 text-sm font-medium text-slate-700 rounded-full hover:bg-slate-50 transition-colors">
                  Change Password
                </button>
                <button onClick={async () => {
                  setIsActivityOpen(true);
                  setLoadingActivity(true);
                  try {
                    const logs = await settingsApi.getActivityLog();
                    setActivity(logs);
                  } finally {
                    setLoadingActivity(false);
                  }
                }} className="w-full h-9 px-4 border border-gray-300 text-sm font-medium text-slate-700 rounded-full hover:bg-slate-50 transition-colors">
                  View Activity Log
                </button>
              </div>
            </div>
          </div>

          {/* Notifications Card */}
          <div className="bg-white rounded-2xl shadow-md border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-base font-semibold text-[#111827]">Notifications</h2>
            </div>
            <div className="p-6">
              <div className="space-y-2">
                <ToggleSwitch
                  enabled={newOrdersEnabled}
                  onChange={setNewOrdersEnabled}
                  label="New Orders"
                />
                <ToggleSwitch
                  enabled={deliveryUpdatesEnabled}
                  onChange={setDeliveryUpdatesEnabled}
                  label="Delivery Updates"
                />
                <ToggleSwitch
                  enabled={customerMessagesEnabled}
                  onChange={setCustomerMessagesEnabled}
                  label="Customer Messages"
                />
                <ToggleSwitch
                  enabled={systemAlertsEnabled}
                  onChange={setSystemAlertsEnabled}
                  label="System Alerts"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      {/* Add Service Area Modal */}
      <Modal isOpen={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} title="Add Service Area" size="sm">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Area name</label>
            <input
              type="text"
              value={newAreaName}
              onChange={(e) => setNewAreaName(e.target.value)}
              placeholder="e.g., Neeladri"
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setIsAddModalOpen(false)} className="h-9 px-4 border border-gray-300 text-sm font-medium text-slate-700 rounded-full hover:bg-slate-50 transition-colors">Cancel</button>
            <button onClick={handleAddServiceArea} className="h-9 px-5 bg-[#1E40AF] hover:bg-[#1E3A8A] text-white text-sm font-medium rounded-full shadow-sm transition-colors">Add</button>
          </div>
        </div>
      </Modal>

      {/* Toast */}
      <Toast message={toast.message} type={toast.type} isVisible={toast.isVisible} onClose={hideToast} />

      {/* Add Team Member Modal */}
      <Modal isOpen={isAddTeamModalOpen} onClose={() => setIsAddTeamModalOpen(false)} title="Add Team Member" size="sm">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Full name</label>
            <input
              type="text"
              value={newMember.name}
              onChange={(e) => setNewMember((m) => ({ ...m, name: e.target.value }))}
              placeholder="e.g., John Doe"
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
            />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Email</label>
              <input
                type="email"
                value={newMember.email}
                onChange={(e) => setNewMember((m) => ({ ...m, email: e.target.value }))}
                placeholder="name@company.com"
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Phone</label>
              <input
                type="tel"
                value={newMember.phone}
                onChange={(e) => setNewMember((m) => ({ ...m, phone: e.target.value }))}
                placeholder="+91 98765 43210"
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Role</label>
            <select
              value={newMember.role}
              onChange={(e) => setNewMember((m) => ({ ...m, role: e.target.value as TeamMemberInput['role'] }))}
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent bg-white"
            >
              <option value="owner">Owner</option>
              <option value="manager">Manager</option>
              <option value="cleaningStaff">Cleaning Staff</option>
              <option value="deliveryBoys">Delivery Boys</option>
            </select>
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setIsAddTeamModalOpen(false)} className="h-9 px-4 border border-gray-300 text-sm font-medium text-slate-700 rounded-full hover:bg-slate-50 transition-colors">Cancel</button>
            <button onClick={handleAddTeamMember} className="h-9 px-5 bg-[#1E40AF] hover:bg-[#1E3A8A] text-white text-sm font-medium rounded-full shadow-sm transition-colors">Add</button>
          </div>
        </div>
      </Modal>

      {/* Team Members Modal */}
      <Modal isOpen={isMembersModalOpen} onClose={() => setIsMembersModalOpen(false)} title="Team Members" size="lg">
        <div className="space-y-3">
          {loadingMembers && <div className="text-sm text-slate-500">Loading members...</div>}
          {!loadingMembers && members.length === 0 && (
            <div className="text-sm text-slate-500">No members found for this role.</div>
          )}
          {!loadingMembers && members.map((m) => (
            <div key={m.id} className="flex items-center justify-between p-3 rounded-xl border border-gray-200">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center text-[#1E40AF] font-semibold">
                  {m.name?.charAt(0)?.toUpperCase() || 'U'}
                </div>
                <div>
                  <div className="text-sm font-medium text-slate-900">{m.name}</div>
                  <div className="text-xs text-slate-500">{m.email || m.phone || membersRole}</div>
                </div>
              </div>
              <button onClick={() => handleRemoveMember(m)} className="h-8 px-3 border border-gray-300 text-xs font-medium text-slate-700 rounded-full hover:bg-slate-50 transition-colors">Remove</button>
            </div>
          ))}
        </div>
      </Modal>

      {/* Change Password Modal */}
      <Modal isOpen={isChangePwdOpen} onClose={() => setIsChangePwdOpen(false)} title="Change Password" size="sm">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Current password</label>
            <input type="password" value={pwdCurrent} onChange={(e) => setPwdCurrent(e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent" />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">New password</label>
            <input type="password" value={pwdNew} onChange={(e) => setPwdNew(e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent" />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Confirm new password</label>
            <input type="password" value={pwdConfirm} onChange={(e) => setPwdConfirm(e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#1E40AF] focus:border-transparent" />
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setIsChangePwdOpen(false)} className="h-9 px-4 border border-gray-300 text-sm font-medium text-slate-700 rounded-full hover:bg-slate-50 transition-colors">Cancel</button>
            <button onClick={async () => {
              if (!pwdNew || pwdNew !== pwdConfirm) {
                showToast('Passwords do not match', 'error');
                return;
              }
              try {
                setChangingPwd(true);
                await settingsApi.changePassword(pwdCurrent, pwdNew);
                showToast('Password changed successfully', 'success');
                setIsChangePwdOpen(false);
                setPwdCurrent(''); setPwdNew(''); setPwdConfirm('');
              } catch (e: any) {
                showToast(e?.message || 'Failed to change password', 'error');
              } finally {
                setChangingPwd(false);
              }
            }} disabled={changingPwd} className={`h-9 px-5 ${changingPwd ? 'bg-[#1E40AF]/70 cursor-not-allowed' : 'bg-[#1E40AF] hover:bg-[#1E3A8A]'} text-white text-sm font-medium rounded-full shadow-sm transition-colors`}>{changingPwd ? 'Saving...' : 'Save'}</button>
          </div>
        </div>
      </Modal>

      {/* Activity Log Modal */}
      <Modal isOpen={isActivityOpen} onClose={() => setIsActivityOpen(false)} title="Activity Log" size="lg">
        <div className="space-y-2">
          {loadingActivity && <div className="text-sm text-slate-500">Loading activity...</div>}
          {!loadingActivity && activity.map((log) => (
            <div key={log.id} className="flex items-center justify-between p-3 rounded-xl border border-gray-200">
              <div>
                <div className="text-sm font-medium text-slate-900">{log.action}</div>
                <div className="text-xs text-slate-500">{new Date(log.at).toLocaleString()} {log.ip ? `• ${log.ip}` : ''}</div>
              </div>
            </div>
          ))}
          {!loadingActivity && activity.length === 0 && <div className="text-sm text-slate-500">No activity yet.</div>}
        </div>
      </Modal>
    </div>
  );
};
