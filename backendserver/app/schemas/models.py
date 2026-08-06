from pydantic import BaseModel
from typing import List, Optional

class ProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    shop_name: Optional[str] = None
    shop_address: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None

class CategoryCreate(BaseModel):
    name: str

class ProductCreate(BaseModel):
    name: str
    category_id: Optional[str] = None
    quantity: float
    unit: str
    cost_price: float
    selling_price: float
    low_stock_threshold: float
    barcode: Optional[str] = None

class OrderItemCreate(BaseModel):
    product_id: str
    quantity: float
    price_per_unit: float
    total_price: float

class OrderCreate(BaseModel):
    subtotal: float
    discount: float
    final_amount: float
    profit: float
    paid_amount: float = 0.0
    items: List[OrderItemCreate]
    customer_id: Optional[str] = None
    payment_status: str = "paid"
