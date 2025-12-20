import React, { useState } from 'react';
import { StatsCard } from '@/components/tw-ui/StatsCard';
import { ServiceCard as TwServiceCard } from '@/components/tw-ui/ServiceCard';
import { AddOnCard } from '@/components/tw-ui/AddOnCard';
import { QuickStatsCard } from '@/components/tw-ui/QuickStatsCard';
import { EditServiceModal, AddServiceModal, AddOnModal } from '@/components/services/modals';

interface ServiceData {
  id: string;
  title: string;
  description?: string;
  pricePerKg?: string;
  duration?: string;
  status?: 'Active' | 'Inactive';
  category?: string;
}

interface AddOnData {
  id: string;
  name: string;
  fee: string;
  status: 'Active' | 'Inactive';
}

export const ServicesPage: React.FC = () => {
  // Initialize add-on services state
  const [addOnServices, setAddOnServices] = useState<AddOnData[]>([
    { id: 'express', name: 'Express', fee: '$15.00', status: 'Active' },
    { id: 'home-linens', name: 'Home linens', fee: '$5.00', status: 'Active' },
  ]);

  // Initialize services state with all services
  const [services, setServices] = useState<ServiceData[]>([
    // Quick Wash
    { id: 'wash-fold', title: 'Wash & Fold', description: 'Professional washing and folding service', pricePerKg: '$8.99', duration: '25 hrs', status: 'Active', category: 'Quick Wash' },
    { id: 'ironing', title: 'Ironing', description: 'Professional ironing and pressing', pricePerKg: '$15.99', duration: '12 hrs', status: 'Active', category: 'Quick Wash' },
    // Pro Clean
    { id: 'stain-removal', title: 'Stain Removal', description: 'Say goodbye to light stains with regular care.', pricePerKg: '$10.99', duration: '8 hrs', status: 'Active', category: 'Pro Clean' },
    { id: 'shoe-cleaning', title: 'Shoe Cleaning', description: 'Premium shoe care', pricePerKg: '$8.99', duration: '25 hrs', status: 'Inactive', category: 'Pro Clean' },
    // Steam Press
    { id: 'shirts', title: 'Shirts', pricePerKg: '$16.99', duration: '12 hrs', status: 'Active', category: 'Steam Press' },
    { id: 'trousers', title: 'Trousers', pricePerKg: '$19.99', duration: '22 hrs', status: 'Active', category: 'Steam Press' },
    { id: 'blazers', title: 'Blazers', pricePerKg: '$20.99', duration: '18 hrs', status: 'Active', category: 'Steam Press' },
    // Luxury Care
    { id: 'silk-items', title: 'Silk Items', pricePerKg: '$16.99', duration: '12 hrs', status: 'Active', category: 'Luxury Care' },
    { id: 'hand-wash', title: 'Hand Wash', pricePerKg: '$19.99', duration: '22 hrs', status: 'Active', category: 'Luxury Care' },
    { id: 'designer-wear', title: 'Designer Wear', pricePerKg: '$19.99', duration: '22 hrs', status: 'Active', category: 'Luxury Care' },
  ]);

  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [selectedServiceId, setSelectedServiceId] = useState<string | null>(null);
  
  // Add-on modals state
  const [isAddOnModalOpen, setIsAddOnModalOpen] = useState(false);
  const [selectedAddOn, setSelectedAddOn] = useState<AddOnData | null>(null);

  const handleEdit = (serviceId: string) => {
    setSelectedServiceId(serviceId);
    setIsEditModalOpen(true);
  };

  const handleCloseEditModal = () => {
    setIsEditModalOpen(false);
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

  const handleEditAddOn = (addOn: AddOnData) => {
    setSelectedAddOn(addOn);
    setIsAddOnModalOpen(true);
  };

  const handleUpdateService = (formData: {
    name: string;
    description: string;
    pricePerKg: string;
    durationHours: number;
    status: 'Active' | 'Inactive';
  }) => {
    if (!selectedServiceId) return;

    // Update the service in the state
    setServices(prevServices =>
      prevServices.map(service => {
        if (service.id === selectedServiceId) {
          return {
            ...service,
            title: formData.name,
            description: formData.description,
            pricePerKg: formData.pricePerKg,
            duration: `${formData.durationHours} hrs`,
            status: formData.status,
          };
        }
        return service;
      })
    );

    console.log('Service updated:', formData);
    // TODO: Implement actual save logic with API call
  };

  const handleAddService = (formData: {
    name: string;
    description: string;
    pricePerKg: string;
    durationHours: number;
    status: 'Active' | 'Inactive';
    category: string;
  }) => {
    // Generate a unique ID for the new service
    const newId = `service-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    // Add the new service to the state
    const newService: ServiceData = {
      id: newId,
      title: formData.name,
      description: formData.description,
      pricePerKg: formData.pricePerKg,
      duration: `${formData.durationHours} hrs`,
      status: formData.status,
      category: formData.category,
    };

    setServices(prevServices => [...prevServices, newService]);

    console.log('Service added:', newService);
    // TODO: Implement actual save logic with API call
  };

  const handleDeleteService = (serviceId: string) => {
    // Confirm deletion
    if (window.confirm('Are you sure you want to delete this service?')) {
      setServices(prevServices => prevServices.filter(service => service.id !== serviceId));
      console.log('Service deleted:', serviceId);
      // TODO: Implement actual delete logic with API call
    }
  };

  // Add-on save handler
  const handleSaveAddOn = (formData: {
    name: string;
    baseFee: string;
    status: 'Active' | 'Inactive';
  }) => {
    if (selectedAddOn) {
      // Edit mode
      setAddOnServices(prevServices =>
        prevServices.map(addOn => {
          if (addOn.id === selectedAddOn.id) {
            return {
              ...addOn,
              name: formData.name,
              fee: formData.baseFee,
              status: formData.status,
            };
          }
          return addOn;
        })
      );
      console.log('Add-on updated:', formData);
    } else {
      // Add mode
      const newId = `addon-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const newAddOn: AddOnData = {
        id: newId,
        name: formData.name,
        fee: formData.baseFee,
        status: formData.status,
      };
      setAddOnServices(prevServices => [...prevServices, newAddOn]);
      console.log('Add-on added:', newAddOn);
    }
    // TODO: Implement actual save logic with API call
  };

  const handleDeleteAddOn = () => {
    if (!selectedAddOn) return;
    
    setAddOnServices(prevServices => prevServices.filter(addOn => addOn.id !== selectedAddOn.id));
    console.log('Add-on deleted:', selectedAddOn);
    // TODO: Implement actual delete logic with API call
  };

  // Get the selected service for the modal
  const selectedService = selectedServiceId 
    ? services.find(s => s.id === selectedServiceId)
    : null;

  // Helper function to find service data and convert to modal format
  const getServiceForModal = (service: ServiceData) => {
    if (!service) return undefined;
    const durationHours = service.duration ? parseInt(service.duration.replace(' hrs', '')) : 0;
    return {
      name: service.title,
      description: service.description || '',
      pricePerKg: service.pricePerKg || '',
      durationHours,
      status: service.status || 'Active',
    };
  };

  return (
    <>
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-[1280px] mx-auto px-3 sm:px-4 md:px-5 lg:px-6 py-4 sm:py-5">
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
                    className="h-8 sm:h-9 px-3 sm:px-4 bg-indigo-700 hover:bg-indigo-600 text-white text-xs sm:text-sm rounded-lg sm:rounded-md transition-colors w-full sm:w-auto"
                  >
                    + Add Service
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                <StatsCard title="Total Services" value={15} />
                <StatsCard title="Active Services" value={15} dotColor="#10B981" />
                <StatsCard title="Categories" value={32} />
              </div>

              <section className="space-y-4 sm:space-y-5">
                <div>
                  <div className="text-xs sm:text-sm font-semibold text-slate-800 mb-2 sm:mb-3">Quick Wash</div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
                    {services.filter(s => s.category === 'Quick Wash').map(service => (
                      <TwServiceCard 
                        key={service.id}
                        title={service.title}
                        description={service.description}
                        pricePerKg={service.pricePerKg}
                        duration={service.duration}
                        status={service.status}
                        onDelete={() => handleDeleteService(service.id)}
                        onEdit={() => handleEdit(service.id)}
                      />
                    ))}
                  </div>
                </div>

                <div>
                  <div className="text-xs sm:text-sm font-semibold text-slate-800 mb-2 sm:mb-3">Pro Clean</div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
                    {services.filter(s => s.category === 'Pro Clean').map(service => (
                      <TwServiceCard 
                        key={service.id}
                        title={service.title}
                        description={service.description}
                        pricePerKg={service.pricePerKg}
                        duration={service.duration}
                        status={service.status}
                        onDelete={() => handleDeleteService(service.id)}
                        onEdit={() => handleEdit(service.id)}
                      />
                    ))}
                  </div>
                </div>

                <div>
                  <div className="text-xs sm:text-sm font-semibold text-slate-800 mb-2 sm:mb-3">Steam Press</div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                    {services.filter(s => s.category === 'Steam Press').map(service => (
                      <TwServiceCard 
                        key={service.id}
                        title={service.title}
                        description={service.description}
                        pricePerKg={service.pricePerKg}
                        duration={service.duration}
                        status={service.status}
                        onDelete={() => handleDeleteService(service.id)}
                        onEdit={() => handleEdit(service.id)}
                      />
                    ))}
                  </div>
                </div>

                <div>
                  <div className="text-xs sm:text-sm font-semibold text-slate-800 mb-2 sm:mb-3">Luxury Care</div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                    {services.filter(s => s.category === 'Luxury Care').map(service => (
                      <TwServiceCard 
                        key={service.id}
                        title={service.title}
                        description={service.description}
                        pricePerKg={service.pricePerKg}
                        duration={service.duration}
                        status={service.status}
                        onDelete={() => handleDeleteService(service.id)}
                        onEdit={() => handleEdit(service.id)}
                      />
                    ))}
                  </div>
                </div>
              </section>
            </main>

            <aside className="space-y-4 sm:space-y-5 lg:order-last">
              <AddOnCard 
                items={addOnServices} 
                onAdd={handleOpenAddOnModal}
                onEdit={handleEditAddOn}
              />
              <QuickStatsCard />
            </aside>
          </div>
        </div>
      </div>

      <EditServiceModal
        isOpen={isEditModalOpen}
        onClose={handleCloseEditModal}
        service={getServiceForModal(selectedService)}
        onSave={handleUpdateService}
      />
      
      <AddServiceModal
        isOpen={isAddModalOpen}
        onClose={handleCloseAddModal}
        onSave={handleAddService}
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
