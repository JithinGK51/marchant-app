from fastapi import APIRouter, Depends, HTTPException
from ..database import supabase
from .auth import get_user_id
from datetime import datetime, timedelta

router = APIRouter()

@router.get("/summary")
async def get_analytics_summary(period: str = "all", user_id: str = Depends(get_user_id)):
    # Calculate start dates in UTC
    now_utc = datetime.utcnow()
    
    # 1. Base Query for the selected period
    query = supabase.table("orders").select("final_amount, profit, payment_status, paid_amount, created_at, customer_id, order_items(quantity, total_price, products(name, categories(name)))").eq("user_id", user_id)
    
    if period == "today":
        start_date = now_utc.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
        query = query.gte("created_at", start_date)
    elif period == "week":
        start_date = (now_utc - timedelta(days=7)).isoformat()
        query = query.gte("created_at", start_date)
    elif period == "month":
        start_date = (now_utc - timedelta(days=30)).isoformat()
        query = query.gte("created_at", start_date)
    else:
        start_date = None

    response = query.execute()
    orders = response.data
    
    # 2. Aggregates
    total_sales = round(sum(o["final_amount"] for o in orders), 2)
    total_profit = round(sum(o["profit"] for o in orders), 2)
    
    # 3. Category Distribution (Dynamic)
    category_map = {}
    product_map = {}
    for order in orders:
        items = order.get("order_items", [])
        for item in items:
            product = item.get("products")
            if product:
                # Category Distribution
                category = product.get("categories")
                cat_name = category.get("name", "Other") if category else "Other"
                category_map[cat_name] = category_map.get(cat_name, 0) + item.get("total_price", 0)
                
                # Top Products
                p_name = product.get("name")
                product_map[p_name] = product_map.get(p_name, 0) + item.get("quantity", 0)
    
    category_distribution = [
        {"name": name, "value": round(float(val), 2)} 
        for name, val in category_map.items()
    ]
    
    top_products = sorted(
        [{"name": k, "count": v} for k, v in product_map.items()],
        key=lambda x: x["count"],
        reverse=True
    )[:5]

    # 4. Khata Analysis (Robust & Accurate)
    # Collected in this period (from the payments table)
    payment_query = supabase.table("payments").select("amount, customer_id").eq("user_id", user_id)
    if period != "all" and start_date:
        payment_query = payment_query.gte("payment_date", start_date)
    
    payments_period_resp = payment_query.execute()
    total_collected_period = round(sum(p["amount"] for p in payments_period_resp.data if p.get("customer_id")), 2)
    
    # All-time Khata Summary
    # 1. Total Credit ever given
    all_orders_resp = supabase.table("orders").select("final_amount, customer_id").eq("user_id", user_id).execute()
    total_khata = round(sum(o["final_amount"] for o in all_orders_resp.data if o.get("customer_id")), 2)
    
    # 2. Total Payments ever received from Khata customers
    all_payments_resp = supabase.table("payments").select("amount, customer_id").eq("user_id", user_id).execute()
    total_payed_all_time = round(sum(p["amount"] for p in all_payments_resp.data if p.get("customer_id")), 2)
    
    # 3. True Remaining Balance
    total_outstanding = round(max(0, total_khata - total_payed_all_time), 2)
    
    # Recovery Rate: Based on total collection vs total debt
    health_pct = 100.0
    if total_khata > 0:
        health_pct = round((min(total_payed_all_time, total_khata) / total_khata) * 100, 1)

    # 5. Trend Analysis (Period-Specific)
    trend = []
    if period == "today":
        for i in range(23, -1, -1):
            h_start = (now_utc - timedelta(hours=i)).replace(minute=0, second=0, microsecond=0)
            h_end = h_start + timedelta(hours=1)
            val = sum(o["final_amount"] for o in orders if h_start.isoformat() <= o["created_at"] < h_end.isoformat())
            trend.append({"label": h_start.strftime("%H:00"), "sales": round(val, 2)})
    elif period == "all":
        for i in range(5, -1, -1):
            m_start = (now_utc - timedelta(days=i*30)).replace(day=1, hour=0, minute=0, second=0)
            m_end = (m_start + timedelta(days=32)).replace(day=1)
            all_resp = supabase.table("orders").select("final_amount, created_at").eq("user_id", user_id).gte("created_at", m_start.isoformat()).lt("created_at", m_end.isoformat()).execute()
            val = sum(o["final_amount"] for o in all_resp.data)
            trend.append({"label": m_start.strftime("%b"), "sales": round(val, 2)})
    else:
        days = 7 if period == "week" else 30
        for i in range(days - 1, -1, -1):
            d_start = (now_utc - timedelta(days=i)).replace(hour=0, minute=0, second=0, microsecond=0)
            d_end = d_start + timedelta(days=1)
            val = sum(o["final_amount"] for o in orders if d_start.isoformat() <= o["created_at"] < d_end.isoformat())
            trend.append({"label": d_start.strftime("%d/%m") if period == "month" else d_start.strftime("%a"), "sales": round(val, 2)})

    # 4.5 Additional Khata Insights
    # Customers with active debt
    customers_summary = supabase.table("orders").select("customer_id, final_amount, paid_amount").eq("user_id", user_id).not_.is_("customer_id", "null").execute()
    customer_balances = {}
    for o in customers_summary.data:
        cid = o["customer_id"]
        customer_balances[cid] = customer_balances.get(cid, 0) + (o["final_amount"] - o["paid_amount"])
    
    # Filter for those with actual debt > 1
    active_debtors = [cid for cid, bal in customer_balances.items() if bal > 1]
    
    # Get top debtor name
    top_debtor_name = "None"
    if active_debtors:
        top_debtor_id = max(customer_balances, key=customer_balances.get)
        top_debtor_resp = supabase.table("customers").select("name").eq("id", top_debtor_id).single().execute()
        if top_debtor_resp.data:
            top_debtor_name = top_debtor_resp.data["name"]

    return {
        "sales": total_sales,
        "profit": total_profit,
        "orders_count": len(orders),
        "trend": trend,
        "category_distribution": category_distribution,
        "top_products": top_products,
        "khata_stats": {
            "total_khata": total_khata,
            "outstanding": total_outstanding,
            "collected": total_collected_period,
            "payed_katha": total_payed_all_time,
            "health_score": health_pct,
            "active_debtors": len(active_debtors),
            "top_debtor": top_debtor_name
        },
        "period": period
    }

@router.get("/inventory-status")
async def get_inventory_status(user_id: str = Depends(get_user_id)):
    # Fetch low stock products
    response = supabase.table("products").select("name, quantity, low_stock_threshold").eq("user_id", user_id).execute()
    products = response.data
    
    low_stock_items = [p for p in products if p["quantity"] <= p["low_stock_threshold"]]
    
    return {
        "total_products": len(products),
        "low_stock_count": len(low_stock_items),
        "low_stock_items": low_stock_items
    }
