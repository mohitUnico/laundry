import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { StatsCard } from '@/components/tw-ui/StatsCard';
import { ServiceCard as TwServiceCard } from '@/components/tw-ui/ServiceCard';
import { AddOnCard } from '@/components/tw-ui/AddOnCard';
import { QuickStatsCard } from '@/components/tw-ui/QuickStatsCard';
import { EditServiceModal, AddServiceModal, AddOnModal, ViewServiceModal } from '@/components/services/modals';
import { clothesApi } from '@/services';
import type { ClothesServiceRecord, ServiceCategoryRecord } from '@/types';

interface AddOnData {
  id?: string;
  name: string;
  fee: string;
  status?: 'Active' | 'Inactive';
}

export const ServicesPage: React.FC = () => {
  const [categories, setCategories] = useState<ServiceCategoryRecord[]>([]);
  const [services, setServices] = useState<ClothesServiceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [selectedServiceId, setSelectedServiceId] = useState<string | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  
  // Add-on modals state
  const [isAddOnModalOpen, setIsAddOnModalOpen] = useState(false);
  const [selectedAddOn, setSelectedAddOn] = useState<AddOnData | null>(null);

  const toNumber = useCallback((value: unknown): number => {
    if (value === null || value === undefined) return 0;
    if (typeof value === 'number') return Number.isFinite(value) ? value : 0;
    if (typeof value === 'string') {
      const trimmed = value.trim();
      if (!trimmed) return 0;
      const num = Number(trimmed);
      return Number.isFinite(num) ? num : 0;
    }
    return 0;
  }, []);

  const parseMoney = useCallback((value: string): number => {
    const num = Number(String(value).replace(/[^0-9.]/g, ''));
    return Number.isFinite(num) ? num : 0;
  }, []);

  const formatMoney = useCallback((value: unknown): string => {
    const num = toNumber(value);
    return `$${num.toFixed(2)}`;
  }, [toNumber]);

  const getErrorMessage = useCallback((err: any): string => {
    const data = err?.response?.data;
    const baseMessage = data?.message || err?.message || 'Request failed';
    const errors = Array.isArray(data?.errors) ? data.errors : [];
    if (!errors.length) return baseMessage;
    const details = errors
      .map((e: any) => {
        const field = e?.field ? `${e.field}: ` : '';
        const msg = e?.message || '';
        return `${field}${msg}`.trim();
      })
      .filter(Boolean)
      .slice(0, 3)
      .join(' | ');
    return details ? `${baseMessage} (${details})` : baseMessage;
  }, []);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [catsRes, svcsRes] = await Promise.allSettled([
        clothesApi.listServiceCategories(),
        clothesApi.listServices(),
      ]);

      if (catsRes.status === 'fulfilled') setCategories(catsRes.value);
      if (svcsRes.status === 'fulfilled') setServices(svcsRes.value);

      if (catsRes.status === 'rejected') {
        setError(`Categories: ${getErrorMessage(catsRes.reason)}`);
      } else if (svcsRes.status === 'rejected') {
        setError(`Services: ${getErrorMessage(svcsRes.reason)}`);
      }
    } catch (err: any) {
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  }, [getErrorMessage]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const sortedCategories = useMemo(() => {
    return [...categories].sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0));
  }, [categories]);

  const addOnCategory = useMemo(() => {
    return sortedCategories.find((c) => String(c.category_name).toLowerCase().includes('add-on'));
  }, [sortedCategories]);

  const addOnServices = useMemo<AddOnData[]>(() => {
    if (!addOnCategory) return [];
    return services
      .filter((s) => s.category_id === addOnCategory.category_id)
      .map((s) => ({
        id: s.service_id,
        name: s.service_name,
        description: s.description || undefined,
        fee: formatMoney(s.base_price),
        status: s.is_active ? 'Active' : 'Inactive',
      }));
  }, [addOnCategory, formatMoney, services]);

  // If backend does not provide add-on category/services yet, show the design defaults.
  const addOnServicesDisplay = useMemo<AddOnData[]>(() => {
    if (addOnServices.length > 0) return addOnServices;
    return [
      {
        name: 'Express',
        description: 'Same-day service (4-6 hours)',
        fee: '$15.00',
        status: 'Active',
      },
      {
        name: 'Home linens',
        description: 'Bed sheets, blankets etc..',
        fee: '$5.00',
        status: 'Active',
      },
    ];
  }, [addOnServices]);

  const visibleCategories = useMemo(() => {
    if (!addOnCategory) return sortedCategories;
    return sortedCategories.filter((c) => c.category_id !== addOnCategory.category_id);
  }, [addOnCategory, sortedCategories]);

  const totalServices = services.length;
  const activeServices = services.filter((s) => s.is_active).length;
  const categoryCount = categories.length;

  const handleEdit = (serviceId: string) => {
    setSelectedServiceId(serviceId);
    setIsEditModalOpen(true);
  };

  const handleView = (serviceId: string) => {
    setSelectedServiceId(serviceId);
    setIsViewModalOpen(true);
  };

  const handleCloseEditModal = () => {
    setIsEditModalOpen(false);
    setSelectedServiceId(null);
  };

  const handleCloseViewModal = () => {
    setIsViewModalOpen(false);
    setSelectedServiceId(null);
  };

  const handleOpenAddModal = () => {
    setIsAddModalOpen(true);
  };

  const handleCloseAddModal = () => {
    setIsAddModalOpen(false);
  };

  // Add-on handlers
  const handleOpenAddOnModal = () => {
    setSelectedAddOn(null);
    setIsAddOnModalOpen(true);
  };

  const handleCloseAddOnModal = () => {
    setIsAddOnModalOpen(false);
    setSelectedAddOn(null);
  };

  const handleEditAddOn = (addOn: { id?: string; name: string; fee: string; status?: 'Active' | 'Inactive' }) => {
    setSelectedAddOn({
      id: addOn.id,
      name: addOn.name,
      fee: addOn.fee,
      status: addOn.status || 'Active',
    });
    setIsAddOnModalOpen(true);
  };

  const handleUpdateService = async (formData: {
    name: string;
    description: string;
    pricePerKg: string;
    durationHours: number;
    status: 'Active' | 'Inactive';
  }) => {
    if (!selectedServiceId) return;
    try {
      const price = parseMoney(formData.pricePerKg);
      await clothesApi.updateService(selectedServiceId, {
        serviceName: formData.name,
        description: formData.description,
        basePrice: price,
        perKgPrice: price,
        estimatedHours: formData.durationHours,
        isActive: formData.status === 'Active',
      });
      await loadData();
    } catch (err: any) {
      setError(getErrorMessage(err));
    }
  };

  const handleAddService = async (formData: {
    name: string;
    description: string;
    pricePerKg: string;
    durationHours: number;
    status: 'Active' | 'Inactive';
    categoryId: string;
  }) => {
    try {
      const price = parseMoney(formData.pricePerKg);
      await clothesApi.createService({
        categoryId: formData.categoryId,
        serviceName: formData.name,
        description: formData.description,
        basePrice: price,
        perKgPrice: price,
        estimatedHours: formData.durationHours,
        isActive: formData.status === 'Active',
      });
      await loadData();
    } catch (err: any) {
      setError(getErrorMessage(err));
    }
  };

  const handleDeleteService = async (serviceId: string) => {
    // Confirm deletion
    if (window.confirm('Are you sure you want to delete this service?')) {
      try {
        await clothesApi.deleteService(serviceId);
        await loadData();
      } catch (err: any) {
        setError(getErrorMessage(err));
      }
    }
  };

  // Add-on save handler
  const handleSaveAddOn = async (formData: {
    name: string;
    baseFee: string;
    status: 'Active' | 'Inactive';
  }) => {
    if (!addOnCategory) {
      setError('Add-on Services category not found in backend.');
      return;
    }
    try {
      const basePrice = parseMoney(formData.baseFee);
      if (selectedAddOn) {
        if (!selectedAddOn.id) {
          throw new Error('Missing add-on id');
        }
        await clothesApi.updateService(selectedAddOn.id, {
          serviceName: formData.name,
          basePrice,
          perKgPrice: null,
          estimatedHours: 0,
          isActive: formData.status === 'Active',
        });
      } else {
        await clothesApi.createService({
          categoryId: addOnCategory.category_id,
          serviceName: formData.name,
          description: null,
          basePrice,
          perKgPrice: null,
          estimatedHours: 0,
          isActive: formData.status === 'Active',
        });
      }
      await loadData();
    } catch (err: any) {
      setError(getErrorMessage(err));
    }
  };

  const handleDeleteAddOn = async () => {
    if (!selectedAddOn?.id) return;
    try {
      await clothesApi.deleteService(selectedAddOn.id);
      await loadData();
    } catch (err: any) {
      setError(getErrorMessage(err));
    }
  };

  // Get the selected service for the modal
  const selectedService = selectedServiceId 
    ? services.find(s => s.service_id === selectedServiceId)
    : null;

  const getServiceForView = (service: ClothesServiceRecord | null | undefined) => {
    if (!service) return undefined;
    return {
      name: service.service_name,
      description: service.description || '',
      pricePerKg: formatMoney(service.per_kg_price ?? service.base_price),
      duration: `${toNumber(service.estimated_hours ?? 0)} hrs`,
      status: (service.is_active ? 'Active' : 'Inactive') as 'Active' | 'Inactive',
    };
  };

  // Helper function to find service data and convert to modal format
  const getServiceForModal = (service: ClothesServiceRecord | null | undefined) => {
    if (!service) return undefined;
    return {
      name: service.service_name,
      description: service.description || '',
      pricePerKg: formatMoney(service.per_kg_price ?? service.base_price),
      durationHours: toNumber(service.estimated_hours ?? 0),
      status: (service.is_active ? 'Active' : 'Inactive') as 'Active' | 'Inactive',
    };
  };

  const categoriesForAddModal = useMemo(() => {
    return visibleCategories.map((c) => ({ id: c.category_id, name: c.category_name }));
  }, [visibleCategories]);

  return (
    <>
      <div className="w-full">
        <div className="mx-auto mt-1 sm:mt-2 w-full max-w-[1320px] rounded-2xl border border-slate-200 bg-white p-4 sm:p-6 md:p-7 shadow-sm">
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_22rem] gap-4 sm:gap-5">
            <main className="space-y-4 sm:space-y-5">
              <div className="bg-white rounded-xl sm:rounded-2xl shadow-sm border border-slate-100 p-4 sm:p-5">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
                  <div>
                    <div className="text-lg sm:text-xl font-semibold text-slate-900">Services & Inventory</div>
                    <div className="text-xs sm:text-[12px] text-slate-500 mt-1">Manage laundry services and pricing</div>
                  </div>
                  <button 
                    onClick={handleOpenAddModal}
                    disabled={loading || categoriesForAddModal.length === 0}
                    className="h-8 sm:h-9 px-3 sm:px-4 bg-indigo-700 hover:bg-indigo-600 text-white text-xs sm:text-sm rounded-lg sm:rounded-md transition-colors w-full sm:w-auto"
                  >
                    + Add Service
                  </button>
                </div>
              </div>

              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
                  {error}
                </div>
              )}

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                <StatsCard title="Total Services" value={totalServices} />
                <StatsCard title="Active Services" value={activeServices} dotColor="#10B981" />
                <StatsCard title="Categories" value={categoryCount} />
              </div>

              <section className="space-y-4 sm:space-y-5">
                {loading && (
                  <div className="text-sm text-slate-500">Loading services…</div>
                )}

                {!loading &&
                  visibleCategories.map((cat) => {
                    const catServices = services.filter((s) => s.category_id === cat.category_id);
                    if (catServices.length === 0) return null;

                    const columns =
                      catServices.length >= 3 ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3' : 'grid-cols-1 sm:grid-cols-2';

                    return (
                      <div key={cat.category_id} className="bg-white rounded-2xl shadow-sm border border-slate-100 p-4 sm:p-5">
                        <div className="text-xs sm:text-sm font-semibold text-slate-800 mb-3">{cat.category_name}</div>
                        <div className={`grid ${columns} gap-3 sm:gap-4`}>
                          {catServices.map((service) => (
                            <TwServiceCard
                              key={service.service_id}
                              title={service.service_name}
                              description={service.description || undefined}
                              pricePerKg={formatMoney(service.per_kg_price ?? service.base_price)}
                              duration={`${toNumber(service.estimated_hours ?? 0)} hrs`}
                              status={service.is_active ? 'Active' : 'Inactive'}
                              onDelete={() => void handleDeleteService(service.service_id)}
                              onEdit={() => handleEdit(service.service_id)}
                              onView={() => handleView(service.service_id)}
                            />
                          ))}
                        </div>
                      </div>
                    );
                  })}
              </section>
            </main>

            <aside className="space-y-4 sm:space-y-5 lg:order-last">
              <AddOnCard 
                items={addOnServicesDisplay} 
                onAdd={handleOpenAddOnModal}
                onEdit={handleEditAddOn}
                onDelete={(it) => {
                  if (it.id) {
                    void handleDeleteService(it.id);
                  }
                }}
              />
              <QuickStatsCard />
            </aside>
          </div>

          {/* Delivery & Pickup Charges (UI-only for now, per design) */}
          <section className="mt-8">
            <div className="text-lg font-semibold text-slate-900 mb-4">Delivery & Pickup Charges</div>
            <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-4 sm:p-5">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Delivery */}
                <div className="rounded-2xl bg-slate-50 border border-slate-100 p-4">
                  <div className="text-sm font-semibold text-slate-900 mb-3">Delivery:</div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <div className="text-[12px] text-slate-500 mb-1">Minimum Distance (km)</div>
                      <select className="w-full h-9 rounded-md border border-slate-200 bg-white px-3 text-sm">
                        <option>0</option>
                        <option>5</option>
                        <option>10</option>
                        <option>15</option>
                      </select>
                    </div>
                    <div>
                      <div className="text-[12px] text-slate-500 mb-1">Maximum Distance (km)</div>
                      <select className="w-full h-9 rounded-md border border-slate-200 bg-white px-3 text-sm">
                        <option>5</option>
                        <option>10</option>
                        <option>15</option>
                        <option>20</option>
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 mt-4 items-end">
                    <div>
                      <div className="text-[12px] text-slate-500 mb-1">Price ($)</div>
                      <select className="w-full h-9 rounded-md border border-slate-200 bg-white px-3 text-sm">
                        <option>$10</option>
                        <option>$15</option>
                        <option>$20</option>
                        <option>$25</option>
                      </select>
                    </div>
                    <button className="h-9 rounded-md bg-indigo-700 hover:bg-indigo-600 text-white text-sm font-medium">
                      Save
                    </button>
                  </div>

                  <div className="mt-5">
                    <div className="text-sm font-semibold text-slate-900 mb-2">Saved prices</div>
                    <div className="space-y-2 text-sm text-slate-700">
                      <div className="flex justify-between"><span>0 - 5</span><span>=</span><span className="font-semibold">$10</span></div>
                      <div className="flex justify-between"><span>5 - 10</span><span>=</span><span className="font-semibold">$15</span></div>
                      <div className="flex justify-between"><span>10 - 15</span><span>=</span><span className="font-semibold">$20</span></div>
                      <div className="flex justify-between"><span>15 - 20</span><span>=</span><span className="font-semibold">$25</span></div>
                    </div>
                  </div>
                </div>

                {/* Pickup */}
                <div className="rounded-2xl bg-slate-50 border border-slate-100 p-4">
                  <div className="text-sm font-semibold text-slate-900 mb-3">Pickup</div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <div className="text-[12px] text-slate-500 mb-1">Minimum Distance (km)</div>
                      <select className="w-full h-9 rounded-md border border-slate-200 bg-white px-3 text-sm">
                        <option>0</option>
                        <option>5</option>
                        <option>10</option>
                        <option>15</option>
                      </select>
                    </div>
                    <div>
                      <div className="text-[12px] text-slate-500 mb-1">Maximum Distance (km)</div>
                      <select className="w-full h-9 rounded-md border border-slate-200 bg-white px-3 text-sm">
                        <option>5</option>
                        <option>10</option>
                        <option>15</option>
                        <option>20</option>
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 mt-4 items-end">
                    <div>
                      <div className="text-[12px] text-slate-500 mb-1">Price ($)</div>
                      <select className="w-full h-9 rounded-md border border-slate-200 bg-white px-3 text-sm">
                        <option>$7</option>
                        <option>$12</option>
                        <option>$17</option>
                        <option>$22</option>
                      </select>
                    </div>
                    <button className="h-9 rounded-md bg-indigo-700 hover:bg-indigo-600 text-white text-sm font-medium">
                      Save
                    </button>
                  </div>

                  <div className="mt-5">
                    <div className="text-sm font-semibold text-slate-900 mb-2">Saved prices</div>
                    <div className="space-y-2 text-sm text-slate-700">
                      <div className="flex justify-between"><span>0 - 5</span><span>=</span><span className="font-semibold">$7</span></div>
                      <div className="flex justify-between"><span>5 - 10</span><span>=</span><span className="font-semibold">$12</span></div>
                      <div className="flex justify-between"><span>10 - 15</span><span>=</span><span className="font-semibold">$17</span></div>
                      <div className="flex justify-between"><span>15 - 20</span><span>=</span><span className="font-semibold">$22</span></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>

      <EditServiceModal
        isOpen={isEditModalOpen}
        onClose={handleCloseEditModal}
        service={getServiceForModal(selectedService)}
        onSave={handleUpdateService}
      />

      <ViewServiceModal
        isOpen={isViewModalOpen}
        onClose={handleCloseViewModal}
        service={getServiceForView(selectedService)}
      />
      
      <AddServiceModal
        isOpen={isAddModalOpen}
        onClose={handleCloseAddModal}
        onSave={handleAddService}
        categories={categoriesForAddModal}
      />

      <AddOnModal
        isOpen={isAddOnModalOpen}
        onClose={handleCloseAddOnModal}
        addOn={selectedAddOn || undefined}
        onSave={handleSaveAddOn}
        onDelete={handleDeleteAddOn}
      />
    </>
  );
};
