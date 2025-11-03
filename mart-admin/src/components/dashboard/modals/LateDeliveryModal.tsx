import React from 'react';
import { Modal } from '@/components/common';
import { AlertCircle, MapPin, Clock, Phone, Mail, Navigation } from 'lucide-react';

interface LateDeliveryModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const LateDeliveryModal: React.FC<LateDeliveryModalProps> = ({ isOpen, onClose }) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Late Delivery Details" size="lg">
      <div className="space-y-6">
        {/* Alert Banner */}
        <div className="bg-red-50 border-l-4 border-red-600 rounded-xl p-4 flex items-start gap-3">
          <AlertCircle size={24} className="text-red-600 flex-shrink-0 mt-0.5" />
          <div className="flex-1">
            <h4 className="font-semibold text-red-900 mb-1">Delivery Delayed</h4>
            <p className="text-sm text-red-800">
              Order ORD-2025-004 is running 15 minutes behind the scheduled delivery time of 1:30 PM.
            </p>
          </div>
        </div>

        {/* Order Information */}
        <div className="bg-slate-50 rounded-xl p-4">
          <h5 className="font-semibold text-slate-900 mb-4">Order Information</h5>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-slate-600">Order ID</span>
              <span className="text-sm font-semibold text-slate-900">ORD-2025-004</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-slate-600">Customer</span>
              <span className="text-sm font-semibold text-slate-900">Wednesday Adams</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-slate-600">Order Value</span>
              <span className="text-sm font-semibold text-slate-900">$30.99</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-slate-600">Scheduled Time</span>
              <span className="text-sm font-medium text-slate-700">1:30 PM</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-slate-600">Current Status</span>
              <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-50 text-yellow-700 border border-yellow-200">
                Out for Delivery
              </span>
            </div>
          </div>
        </div>

        {/* Delivery Details */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white border border-slate-200 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <MapPin size={18} className="text-blue-600" />
              <h5 className="font-semibold text-slate-900">Pickup Address</h5>
            </div>
            <p className="text-sm text-slate-700 leading-relaxed">
              123 Maple Street<br />
              Downtown District<br />
              City, State 12345
            </p>
          </div>

          <div className="bg-white border border-slate-200 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <Navigation size={18} className="text-emerald-600" />
              <h5 className="font-semibold text-slate-900">Delivery Address</h5>
            </div>
            <p className="text-sm text-slate-700 leading-relaxed">
              456 Oak Avenue<br />
              Residential Area<br />
              City, State 12345
            </p>
          </div>
        </div>

        {/* Delivery Partner */}
        <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl p-4 border border-blue-200">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
              <span className="text-2xl font-bold text-white">MC</span>
            </div>
            <div className="flex-1">
              <h5 className="font-semibold text-slate-900 mb-1">Assigned Delivery Partner</h5>
              <p className="text-sm text-slate-700 mb-2">Marcus Chen - Vehicle #BA-1234</p>
              <div className="flex items-center gap-4">
                <button className="flex items-center gap-1 px-3 py-1.5 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                  <Phone size={16} className="text-slate-600" />
                  <span className="text-sm text-slate-700">Call</span>
                </button>
                <button className="flex items-center gap-1 px-3 py-1.5 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                  <Navigation size={16} className="text-slate-600" />
                  <span className="text-sm text-slate-700">Track</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Delay Information */}
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <div className="flex items-start gap-3">
            <Clock size={20} className="text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h5 className="font-semibold text-amber-900 mb-1">Delay Details</h5>
              <p className="text-sm text-amber-800 mb-2">
                Delivery delayed due to traffic conditions. Estimated arrival: 1:45 PM (15 min delay).
              </p>
              <p className="text-xs text-amber-700">
                Last updated: 2 minutes ago
              </p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-3 pt-2">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50 font-medium transition-colors"
          >
            Close
          </button>
          <button className="flex-1 px-4 py-2 bg-red-600 text-white rounded-xl hover:bg-red-700 font-medium transition-colors">
            Send Alert to Customer
          </button>
        </div>
      </div>
    </Modal>
  );
};

