from fastapi import APIRouter, Depends, HTTPException
from ..database import supabase
from .auth import get_user_id
from typing import List, Optional
from pydantic import BaseModel

router = APIRouter()

class CustomerCreate(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None

@router.get("/")
async def get_customers(user_id: str = Depends(get_user_id)):
    # Get all customers for this merchant
    response = supabase.table("customers").select("*").eq("user_id", user_id).execute()
    return response.data

@router.post("/")
async def create_or_get_customer(customer: CustomerCreate, user_id: str = Depends(get_user_id)):
    # Try to find existing customer by phone for this merchant
    existing = supabase.table("customers").select("*").eq("user_id", user_id).eq("phone", customer.phone).execute()
    if existing.data:
        return existing.data[0]
    
    # Create new
    response = supabase.table("customers").insert({
        "user_id": user_id,
        "name": customer.name,
        "phone": customer.phone,
        "email": customer.email
    }).execute()
    return response.data[0]

@router.get("/{customer_id}/orders")
async def get_customer_orders(customer_id: str, user_id: str = Depends(get_user_id)):
    # Get all orders for this customer
    response = supabase.table("orders").select("*, order_items(*)").eq("customer_id", customer_id).eq("user_id", user_id).order("created_at", desc=True).execute()
    return response.data

class PaymentRecord(BaseModel):
    amount: float
    notes: Optional[str] = None

@router.post("/{customer_id}/payments")
async def record_payment(customer_id: str, payment: PaymentRecord, user_id: str = Depends(get_user_id)):
    # 1. Record the general payment
    supabase.table("payments").insert({
        "user_id": user_id,
        "customer_id": customer_id,
        "amount": payment.amount,
        "notes": payment.notes
    }).execute()
    
    # 2. Distribute payment across pending orders (FIFO)
    # Get orders where final_amount > paid_amount
    pending_orders = supabase.table("orders").select("id, final_amount, paid_amount").eq("customer_id", customer_id).eq("user_id", user_id).eq("payment_status", "credit").order("created_at", asc=True).execute()
    
    remaining_payment = payment.amount
    for order in pending_orders.data:
        if remaining_payment <= 0: break
        
        still_to_pay = order["final_amount"] - order["paid_amount"]
        payment_to_apply = min(remaining_payment, still_to_pay)
        
        new_paid_amount = order["paid_amount"] + payment_to_apply
        status = "credit"
        if new_paid_amount >= order["final_amount"]:
            status = "paid"
            
        supabase.table("orders").update({
            "paid_amount": new_paid_amount,
            "payment_status": status
        }).eq("id", order["id"]).execute()
        
        remaining_payment -= payment_to_apply
        
    return {"message": "Payment recorded and applied to orders"}

@router.get("/{customer_id}/summary")
async def get_customer_summary(customer_id: str, user_id: str = Depends(get_user_id)):
    # Total Debt (sum of credit orders)
    orders = supabase.table("orders").select("final_amount").eq("customer_id", customer_id).eq("user_id", user_id).eq("payment_status", "credit").execute()
    total_debt = sum(o["final_amount"] for o in orders.data)
    
    # Total Paid (sum of payments)
    payments = supabase.table("payments").select("amount").eq("customer_id", customer_id).eq("user_id", user_id).execute()
    total_paid = sum(p["amount"] for p in payments.data)
    
    return {
        "total_debt": total_debt,
        "total_paid": total_paid,
        "balance": total_debt - total_paid
    }

@router.get("/summary/credit")
async def get_credit_summary(user_id: str = Depends(get_user_id)):
    # Get count of customers who have pending credit
    # First, get all orders with status 'credit'
    response = supabase.table("orders").select("customer_id, final_amount").eq("user_id", user_id).eq("payment_status", "credit").execute()
    
    orders = response.data
    unique_customers = set(o["customer_id"] for o in orders if o["customer_id"])
    total_credit_amount = sum(o["final_amount"] for o in orders)
    
    return {
        "customer_count": len(unique_customers),
        "total_amount": total_credit_amount
    }
