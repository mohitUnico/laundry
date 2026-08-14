// Common types for the admin panel

export interface User {
    user_id: string
    mart_id: string
    full_name: string
    email: string
    phone: string
    role: string
}

export interface Order {
    order_id: string
    customer_id: string
    mart_id: string
    order_status: string
    pricing_model: string
    total_amount: number
    pickup_address_id: string
    delivery_address_id: string
    pickup_date: string
    delivery_date: string
    created_at: string
}

export interface Customer {
    customer_id: string
    full_name: string
    email: string
    phone: string
    created_at: string
}

export interface ApiResponse<T> {
    success: boolean
    data: T
    message?: string
}

export interface PaginatedResponse<T> {
    data: T[]
    total: number
    page: number
    limit: number
    totalPages: number
}

export * from './clothes';

