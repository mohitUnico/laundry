import { OrderStatus, PaymentStatus } from '../enums';

export interface IOrder {
  orderId: string;
  martId: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  pickupAddressId: string;
  deliveryAddressId: string;
  orderStatus: OrderStatus;
  totalAmount: number;
  createdAt: string;
  updatedAt: string;
}
