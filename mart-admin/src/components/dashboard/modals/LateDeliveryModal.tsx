import React, { useState, useEffect, useCallback } from 'react';
import { Modal } from '@/components/common';
import { AlertCircle, MapPin, Clock, Phone, Mail, Navigation, Loader2 } from 'lucide-react';
import { dashboardApi, AdminDashboardLateDeliveries } from '@/services/api/modules/dashboardApi';
import { formatCurrency } from '@/utils/formatters';
import { formatTime } from '@/utils/formatters/dateFormatter';

interface LateDeliveryModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const LateDeliveryModal: React.FC<LateDeliveryModalProps> = ({ isOpen, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lateDeliveries, setLateDeliveries] = useState<AdminDashboardLateDeliveries | null>(null);

  // Fetch late deliveries
  const fetchLateDeliveries = useCallback(async () => {
    if (!isOpen) return;
    
    setLoading(true);
    setError(null);

    try {
      const response = await dashboardApi.getAdminLateDeliveries({ limit: 1 });

      if (response.success && response.data) {
        setLateDeliveries(response.data);
      } else {
        setError('Failed to fetch late deliveries');
      }
    } catch (err: any) {
      console.error('Failed to fetch late deliveries:', err);
      const errorMessage = err?.response?.data?.message || 'Failed to load late deliveries. Please try again.';
      setError(errorMessage);
      setLateDeliveries(null);
    } finally {
      setLoading(false);
    }
  }, [isOpen]);

  useEffect(() => {
    fetchLateDeliveries();
  }, [fetchLateDeliveries]);

  const formatAmount = (amount: string | number | null): string => {
    if (!amount) return '₹0';
    const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
    return formatCurrency(numAmount);
  };

  const formatDelay = (minutes: number | null | undefined): string => {
    if (!minutes) return 'N/A';
    return `${minutes} minutes behind`;
  };

  const delivery = lateDeliveries?.lateDeliveries?.[0] || null;
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Late Delivery Details" size="lg">
      <div className="space-y-6">
        {/* Error Message */}
        {error && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-center">
            <div className="text-red-600 text-sm font-medium">{error}</div>
            <button
              onClick={() => fetchLateDeliveries()}
              className="mt-2 text-xs text-red-600 underline hover:text-red-700"
            >
              Try again
            </button>
          </div>
        )}

        {/* Loading State */}
        {loading && !delivery && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="animate-spin h-8 w-8 text-blue-600" />
          </div>
        )}

        {/* No Late Deliveries */}
        {!loading && !error && !delivery && (
          <div className="text-center py-12">
            <AlertCircle size={48} className="mx-auto text-slate-400 mb-4" />
            <p className="text-slate-600 text-lg font-medium mb-2">No late deliveries</p>
            <p className="text-slate-500 text-sm">All deliveries are on time!</p>
          </div>
        )}

        {/* Late Delivery Details */}
        {!loading && !error && delivery && (
          <>
            {/* Alert Banner */}
            <div className="bg-red-50 border-l-4 border-red-600 rounded-xl p-4 flex items-start gap-3">
              <AlertCircle size={24} className="text-red-600 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <h4 className="font-semibold text-red-900 mb-1">Delivery Delayed</h4>
                <p className="text-sm text-red-800">
                  Order {delivery.orderId} is running {formatDelay(delivery.delayMinutes)} the scheduled delivery time{delivery.scheduledTime ? ` of ${formatTime(delivery.scheduledTime)}` : ''}.
                </p>
              </div>
            </div>

            {/* Order Information */}
            <div className="bg-slate-50 rounded-xl p-4">
              <h5 className="font-semibold text-slate-900 mb-4">Order Information</h5>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-slate-600">Order ID</span>
                  <span className="text-sm font-semibold text-slate-900">{delivery.orderId}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-slate-600">Customer</span>
                  <span className="text-sm font-semibold text-slate-900">{delivery.customerName || 'Unknown Customer'}</span>
                </div>
                {delivery.customerEmail && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-slate-600">Email</span>
                    <span className="text-sm font-medium text-slate-700">{delivery.customerEmail}</span>
                  </div>
                )}
                {delivery.customerPhone && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-slate-600">Phone</span>
                    <span className="text-sm font-medium text-slate-700">{delivery.customerPhone}</span>
                  </div>
                )}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-slate-600">Order Value</span>
                  <span className="text-sm font-semibold text-slate-900">{formatAmount(delivery.orderValue)}</span>
                </div>
                {delivery.scheduledTime && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-slate-600">Scheduled Time</span>
                    <span className="text-sm font-medium text-slate-700">{formatTime(delivery.scheduledTime)}</span>
                  </div>
                )}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-slate-600">Current Status</span>
                  <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-50 text-yellow-700 border border-yellow-200">
                    {delivery.currentStatus || 'Out for Delivery'}
                  </span>
                </div>
              </div>
            </div>

            {/* Delivery Details */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {delivery.pickupAddress && (
                <div className="bg-white border border-slate-200 rounded-xl p-4">
                  <div className="flex items-center gap-2 mb-3">
                    <MapPin size={18} className="text-blue-600" />
                    <h5 className="font-semibold text-slate-900">Pickup Address</h5>
                  </div>
                  <p className="text-sm text-slate-700 leading-relaxed">
                    {delivery.pickupAddress.label && <span className="font-medium">{delivery.pickupAddress.label}</span>}
                    {delivery.pickupAddress.label && <br />}
                    {delivery.pickupAddress.fullAddress}
                  </p>
                </div>
              )}

              {delivery.deliveryAddress && (
                <div className="bg-white border border-slate-200 rounded-xl p-4">
                  <div className="flex items-center gap-2 mb-3">
                    <Navigation size={18} className="text-emerald-600" />
                    <h5 className="font-semibold text-slate-900">Delivery Address</h5>
                  </div>
                  <p className="text-sm text-slate-700 leading-relaxed">
                    {delivery.deliveryAddress.label && <span className="font-medium">{delivery.deliveryAddress.label}</span>}
                    {delivery.deliveryAddress.label && <br />}
                    {delivery.deliveryAddress.fullAddress}
                  </p>
                </div>
              )}
            </div>

            {/* Delivery Partner */}
            {delivery.deliveryPartner && (
              <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl p-4 border border-blue-200">
                <div className="flex items-center gap-4">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
                    <span className="text-2xl font-bold text-white">
                      {delivery.deliveryPartner.name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()}
                    </span>
                  </div>
                  <div className="flex-1">
                    <h5 className="font-semibold text-slate-900 mb-1">Assigned Delivery Partner</h5>
                    <p className="text-sm text-slate-700 mb-2">
                      {delivery.deliveryPartner.name}
                      {delivery.deliveryPartner.vehicleNumber && ` - Vehicle #${delivery.deliveryPartner.vehicleNumber}`}
                    </p>
                    <div className="flex items-center gap-4">
                      {delivery.deliveryPartner.phone && (
                        <a
                          href={`tel:${delivery.deliveryPartner.phone}`}
                          className="flex items-center gap-1 px-3 py-1.5 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors"
                        >
                          <Phone size={16} className="text-slate-600" />
                          <span className="text-sm text-slate-700">Call</span>
                        </a>
                      )}
                      <button className="flex items-center gap-1 px-3 py-1.5 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                        <Navigation size={16} className="text-slate-600" />
                        <span className="text-sm text-slate-700">Track</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Delay Information */}
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
              <div className="flex items-start gap-3">
                <Clock size={20} className="text-amber-600 flex-shrink-0 mt-0.5" />
                <div>
                  <h5 className="font-semibold text-amber-900 mb-1">Delay Details</h5>
                  <p className="text-sm text-amber-800 mb-2">
                    Delivery delayed. {delivery.delayMinutes ? `Currently ${formatDelay(delivery.delayMinutes)} schedule.` : 'Please check with the delivery partner for updated ETA.'}
                  </p>
                  {delivery.deliveryPartner?.deliveryStatus && (
                    <p className="text-xs text-amber-700">
                      Delivery Status: {delivery.deliveryPartner.deliveryStatus}
                    </p>
                  )}
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
              {delivery.customerEmail && (
                <button className="flex-1 px-4 py-2 bg-red-600 text-white rounded-xl hover:bg-red-700 font-medium transition-colors">
                  Send Alert to Customer
                </button>
              )}
            </div>
          </>
        )}
      </div>
    </Modal>
  );
};

