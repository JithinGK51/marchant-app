from fastapi import APIRouter, Depends, HTTPException, Header
from typing import List
from ..database import supabase
from .auth import get_user_id
from ..services.email_service import send_order_confirmation, send_low_stock_alert

router = APIRouter()

from ..schemas.models import OrderCreate

@router.post("/create")
async def create_order(order: OrderCreate, user_id: str = Depends(get_user_id)):
    # Prepare items for RPC
    items_json = [item.model_dump() for item in order.items]
    
    try:
        response = supabase.rpc("create_order_atomic", {
            "p_user_id": user_id,
            "p_subtotal": order.subtotal,
            "p_discount": order.discount,
            "p_final_amount": order.final_amount,
            "p_profit": order.profit,
            "p_items": items_json,
            "p_payment_status": order.payment_status,
            "p_customer_id": order.customer_id,
            "p_paid_amount": order.paid_amount
        }).execute()
        
        # Check for error in response structure
        if not response.data:
             raise HTTPException(status_code=400, detail="Transaction failed or returned no data")

        new_order_id = response.data["order_id"]

        # Fetch user profile for email and FCM token
        user_resp = supabase.table("profiles").select("email").eq("id", user_id).execute()
        user_data = user_resp.data[0] if user_resp.data else None

        if user_data:
            
            # 2. Send order confirmation email
            await send_order_confirmation(user_data["email"], new_order_id, order.final_amount)

        # 3. Check for low stock items in this order to trigger alerts
        for item in order.items:
            prod_resp = supabase.table("products").select("name, quantity, low_stock_threshold").eq("id", item.product_id).execute()
            if prod_resp.data:
                p = prod_resp.data[0]
                if p["quantity"] <= p["low_stock_threshold"]:
                    # In-app notification
                    supabase.table("notifications").insert({
                        "user_id": user_id,
                        "title": "Low Stock Alert ⚠️",
                        "message": f"Product '{p['name']}' is running low ({p['quantity']} left).",
                        "type": "LOW_STOCK"
                    }).execute()

                    # Email and Push
                    if user_data:
                        await send_low_stock_alert(user_data["email"], p["name"], p["quantity"])
            
        return response.data

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/history")
async def get_order_history(user_id: str = Depends(get_user_id)):
    response = supabase.table("orders").select("*, order_items(*, products(name))").eq("user_id", user_id).order("created_at", desc=True).execute()
    return response.data

@router.get("/unified-history")
async def get_unified_history(user_id: str = Depends(get_user_id)):
    orders_resp = supabase.table("orders").select("*, customers(name)").eq("user_id", user_id).execute()
    payments_resp = supabase.table("payments").select("*, customers(name)").eq("user_id", user_id).execute()
    
    combined = []
    for o in orders_resp.data:
        o["type"] = "order"
        combined.append(o)
    for p in payments_resp.data:
        p["type"] = "payment"
        p["created_at"] = p["payment_date"]
        combined.append(p)
        
    combined.sort(key=lambda x: x["created_at"], reverse=True)
    return combined

@router.get("/{order_id}")
async def get_order_details(order_id: str, user_id: str = Depends(get_user_id)):
    response = supabase.table("orders").select("*, order_items(*, products(name))").eq("id", order_id).eq("user_id", user_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Order not found")
    return response.data[0]
