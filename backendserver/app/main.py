from fastapi import FastAPI, Depends, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from .routers import inventory, orders, analytics, auth, notifications, customers
from .database import supabase

app = FastAPI(title="Merchant App Backend")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoint
@app.get("/")
async def root():
    return {"message": "Merchant App Backend is running!"}

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(inventory.router, prefix="/inventory", tags=["Inventory"])
app.include_router(orders.router, prefix="/orders", tags=["Orders"])
app.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
app.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
app.include_router(customers.router, prefix="/customers", tags=["Customers"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
