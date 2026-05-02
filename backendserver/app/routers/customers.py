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
    # 1. Get all customers
    customers_resp = supabase.table("customers").select("*").eq("user_id", user_id).execute()
    customers = customers_resp.data
    
    # 2. Get all orders and payments for this merchant to calculate balances
    orders_resp = supabase.table("orders").select("customer_id, final_amount").eq("user_id", user_id).not_.is_("customer_id", "null").execute()
    payments_resp = supabase.table("payments").select("customer_id, amount").eq("user_id", user_id).not_.is_("customer_id", "null").execute()
    
    # 3. Aggregate balances
    balances = {}
    for o in orders_resp.data:
        cid = o["customer_id"]
        balances[cid] = balances.get(cid, 0) + o["final_amount"]
    for p in payments_resp.data:
        cid = p["customer_id"]
        balances[cid] = balances.get(cid, 0) - p["amount"]
        
    # 4. Attach balance to each customer
    for c in customers:
        # We use max(0, balance) to show debt. 
        # If balance is negative, it means customer has overpaid (not common but possible)
        c["balance"] = round(max(0, balances.get(c["id"], 0)), 2)
        
    return customers

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

@router.get("/{customer_id}/transactions")
async def get_customer_transactions(customer_id: str, user_id: str = Depends(get_user_id)):
    # Get orders and payments for a unified view
    orders_resp = supabase.table("orders").select("*").eq("customer_id", customer_id).eq("user_id", user_id).execute()
    payments_resp = supabase.table("payments").select("*").eq("customer_id", customer_id).eq("user_id", user_id).execute()
    
    transactions = []
    for o in orders_resp.data:
        o["type"] = "order"
        transactions.append(o)
    for p in payments_resp.data:
        p["type"] = "payment"
        p["created_at"] = p["payment_date"] # Use created_at as common key
        transactions.append(p)
        
    transactions.sort(key=lambda x: x["created_at"], reverse=True)
    return transactions

class PaymentRecord(BaseModel):
    amount: float
    notes: Optional[str] = None

@router.post("/{customer_id}/payments")
async def record_payment(customer_id: str, payment: PaymentRecord, user_id: str = Depends(get_user_id)):
    try:
        response = supabase.rpc("record_payment_atomic", {
            "p_user_id": user_id,
            "p_customer_id": customer_id,
            "p_amount": payment.amount,
            "p_notes": payment.notes
        }).execute()
        
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{customer_id}/summary")
async def get_customer_summary(customer_id: str, user_id: str = Depends(get_user_id)):
    # Fetch orders and payments separately for a true dynamic summary
    orders_resp = supabase.table("orders").select("final_amount").eq("customer_id", customer_id).eq("user_id", user_id).execute()
    payments_resp = supabase.table("payments").select("amount").eq("customer_id", customer_id).eq("user_id", user_id).execute()
    
    total_debt = sum(o["final_amount"] for o in orders_resp.data)
    total_paid = sum(p["amount"] for p in payments_resp.data)
    balance = total_debt - total_paid
    
    return {
        "total_debt": total_debt,
        "total_paid": total_paid,
        "balance": max(0, balance)
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
