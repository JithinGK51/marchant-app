from fastapi import APIRouter, Depends, HTTPException, Header
from typing import List, Optional
from ..database import supabase
from .auth import get_user_id

router = APIRouter()

from ..schemas.models import CategoryCreate, ProductCreate

@router.get("/categories")
async def get_categories(user_id: str = Depends(get_user_id)):
    response = supabase.table("categories").select("*").eq("user_id", user_id).execute()
    return response.data

@router.post("/categories")
async def create_category(category: CategoryCreate, user_id: str = Depends(get_user_id)):
    response = supabase.table("categories").insert({"name": category.name, "user_id": user_id}).execute()
    return response.data[0]

@router.patch("/categories/{category_id}")
async def update_category(category_id: str, category: CategoryCreate, user_id: str = Depends(get_user_id)):
    response = supabase.table("categories").update({"name": category.name}).eq("id", category_id).eq("user_id", user_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Category not found")
    return response.data[0]

@router.delete("/categories/{category_id}")
async def delete_category(category_id: str, user_id: str = Depends(get_user_id)):
    # Safety Check: Are there products in this category?
    products = supabase.table("products").select("id").eq("category_id", category_id).execute()
    if products.data:
        raise HTTPException(status_code=400, detail="Cannot delete category containing products. Reassign products first.")
    
    response = supabase.table("categories").delete().eq("id", category_id).eq("user_id", user_id).execute()
    return {"message": "Category deleted"}

@router.get("/products")
async def get_products(user_id: str = Depends(get_user_id)):
    response = supabase.table("products").select("*, categories(name)").eq("user_id", user_id).execute()
    return response.data

@router.post("/products")
async def create_product(product: ProductCreate, user_id: str = Depends(get_user_id)):
    product_data = product.model_dump()
    product_data["user_id"] = user_id
    if "low_stock_threshold" not in product_data or product_data["low_stock_threshold"] is None:
        product_data["low_stock_threshold"] = 5.0
    response = supabase.table("products").insert(product_data).execute()
    return response.data[0]

@router.patch("/products/{product_id}")
async def update_product(product_id: str, product: ProductCreate, user_id: str = Depends(get_user_id)):
    product_data = product.model_dump()
    response = supabase.table("products").update(product_data).eq("id", product_id).eq("user_id", user_id).execute()
    return response.data[0]

@router.delete("/products/{product_id}")
async def delete_product(product_id: str, user_id: str = Depends(get_user_id)):
    response = supabase.table("products").delete().eq("id", product_id).eq("user_id", user_id).execute()
    return {"message": "Product deleted"}
