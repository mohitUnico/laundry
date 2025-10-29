import { ServiceStatus } from '../enums';

export interface IService {
  serviceId: string;
  martId: string;
  categoryId: string;
  serviceName: string;
  description?: string;
  basePrice: number;
  pricePerKg?: number;
  estimatedDuration?: string;
  serviceIcon?: string;
  status: ServiceStatus;
  displayOrder: number;
  createdAt: string;
  updatedAt: string;
}
