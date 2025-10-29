export interface IDeliveryStaff {
  staffId: string;
  martId: string;
  name: string;
  phone: string;
  vehicleType: string;
  vehicleNumber: string;
  status: 'active' | 'inactive' | 'on_delivery';
  rating?: number;
  currentLocation?: {
    latitude: number;
    longitude: number;
  };
}
