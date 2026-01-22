export interface ServiceCategoryRecord {
  category_id: string;
  category_name: string;
  description: string | null;
  icon_url: string | null;
  display_order: number;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface ClothesServiceRecord {
  service_id: string;
  category_id: string;
  service_name: string;
  description: string | null;
  base_price: number | string;
  per_kg_price: number | string | null;
  estimated_hours: number | string;
  icon_url: string | null;
  is_active: boolean;
  display_order: number;
  created_at?: string;
  updated_at?: string;
  clothes_items?: unknown[];
}

