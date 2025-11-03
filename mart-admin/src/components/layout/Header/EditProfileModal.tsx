import React, { useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';

interface EditProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  initial: { firstName?: string; lastName?: string; email?: string; role?: string };
  onSave: (data: { firstName: string; lastName: string; email: string; role: string }) => void;
}

export const EditProfileModal: React.FC<EditProfileModalProps> = ({ isOpen, onClose, initial, onSave }) => {
  const [firstName, setFirstName] = useState(initial.firstName || '');
  const [lastName, setLastName] = useState(initial.lastName || '');
  const [email, setEmail] = useState(initial.email || '');
  const [role, setRole] = useState(initial.role || 'Admin');

  const handleSave = () => {
    onSave({ firstName, lastName, email, role });
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div className="fixed inset-0 bg-black/30 z-[70]" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose} />
          <motion.div className="fixed inset-0 z-[71] flex items-center justify-center p-4" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <motion.div className="w-full max-w-lg bg-white rounded-2xl shadow-xl p-6" initial={{ y: 32 }} animate={{ y: 0 }} exit={{ y: 32 }}>
              <h3 className="text-lg font-semibold mb-4">Edit Profile</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm mb-1 text-slate-600">First Name</label>
                  <input className="w-full border border-slate-200 rounded-lg px-3 py-2" value={firstName} onChange={(e) => setFirstName(e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm mb-1 text-slate-600">Last Name</label>
                  <input className="w-full border border-slate-200 rounded-lg px-3 py-2" value={lastName} onChange={(e) => setLastName(e.target.value)} />
                </div>
                <div className="sm:col-span-2">
                  <label className="block text-sm mb-1 text-slate-600">Email</label>
                  <input type="email" className="w-full border border-slate-200 rounded-lg px-3 py-2" value={email} onChange={(e) => setEmail(e.target.value)} />
                </div>
                <div className="sm:col-span-2">
                  <label className="block text-sm mb-1 text-slate-600">Role</label>
                  <select className="w-full border border-slate-200 rounded-lg px-3 py-2" value={role} onChange={(e) => setRole(e.target.value)}>
                    {['Admin', 'Manager', 'Staff'].map((r) => (
                      <option key={r}>{r}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button onClick={onClose} className="px-4 py-2 rounded-lg border border-slate-200">Cancel</button>
                <button onClick={handleSave} className="px-4 py-2 rounded-lg bg-blue-600 text-white">Save</button>
              </div>
            </motion.div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};


