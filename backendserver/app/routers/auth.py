from fastapi import APIRouter, HTTPException, Header, Depends
from ..database import supabase
from typing import Optional

router = APIRouter()

from ..schemas.models import ProfileUpdate

async def get_user_id(authorization: str = Header(...)):
    try:
        token = authorization.replace("Bearer ", "")
        if not token or token == "null":
             raise HTTPException(status_code=401, detail="Authentication token is missing")
             
        # Use a more direct approach for token verification
        # The Supabase client is already async-friendly in FastAPI contexts
        user_response = supabase.auth.get_user(token)
        
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid session or token")
            
        return user_response.user.id
    except Exception as e:
        error_msg = str(e)
        if "timed out" in error_msg.lower():
            raise HTTPException(status_code=504, detail="Auth timed out. Please refresh.")
        raise HTTPException(status_code=401, detail=f"Authentication failed: {error_msg}")


import random
from pydantic import BaseModel
from ..services.email_service import send_otp_email

class SignupInitRequest(BaseModel):
    email: str
    password: str
    full_name: str
    shop_name: str

class SignupVerifyRequest(BaseModel):
    email: str
    password: str
    full_name: str
    shop_name: str
    otp: str

# Temporary in-memory store for OTPs (In production, use Redis or a DB table)
otp_store = {}

@router.post("/signup/init")
async def signup_init(request: SignupInitRequest):
    otp = str(random.randint(100000, 999999))
    otp_store[request.email] = otp
    
    await send_otp_email(request.email, request.full_name, otp)
    return {"message": "OTP sent successfully"}

@router.post("/signup/verify")
async def signup_verify(request: SignupVerifyRequest):
    if request.email not in otp_store or otp_store[request.email] != request.otp:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    
    # OTP verified! Now create the user in Supabase using admin privileges
    try:
        # Use admin client to create user (bypassing email confirmation since we just did it)
        response = supabase.auth.admin.create_user({
            "email": request.email,
            "password": request.password,
            "user_metadata": {"full_name": request.full_name},
            "email_confirm": True
        })
        
        # Create profile entry
        supabase.table("profiles").upsert({
            "id": response.user.id,
            "full_name": request.full_name,
            "shop_name": request.shop_name,
            "email": request.email,
            "password": request.password  # Added as per user request
        }).execute()

        del otp_store[request.email]
        return {"message": "Account created successfully", "user_id": response.user.id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/profile")
async def get_profile(user_id: str = Depends(get_user_id)):
    response = supabase.table("profiles").select("*").eq("id", user_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Profile not found")
    return response.data[0]

@router.post("/profile")
async def create_or_update_profile(profile: ProfileUpdate, user_id: str = Depends(get_user_id)):
    profile_data = profile.model_dump(exclude_unset=True)
    profile_data["id"] = user_id
    
    response = supabase.table("profiles").upsert(profile_data).execute()
    return response.data[0]

class PasswordChangeInit(BaseModel):
    new_password: str

@router.post("/password/change/init")
async def password_change_init(req: PasswordChangeInit, user_id: str = Depends(get_user_id)):
    # Get user email
    user = supabase.auth.admin.get_user_by_id(user_id)
    email = user.user.email
    
    otp = str(random.randint(100000, 999999))
    # Store OTP with user_id and new password
    otp_store[f"pwd_{user_id}"] = {"otp": otp, "new_password": req.new_password}
    
    await send_otp_email(email, user.user.user_metadata.get("full_name", "Merchant"), otp)
    return {"message": "OTP sent to your email"}

class PasswordChangeConfirm(BaseModel):
    otp: str

@router.post("/password/change/confirm")
async def password_change_confirm(req: PasswordChangeConfirm, user_id: str = Depends(get_user_id)):
    key = f"pwd_{user_id}"
    if key not in otp_store or otp_store[key]["otp"] != req.otp:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    
    new_password = otp_store[key]["new_password"]
    
    try:
        # Update password in Supabase
        supabase.auth.admin.update_user_by_id(user_id, {"password": new_password})
        # Also update in profiles table
        supabase.table("profiles").update({"password": new_password}).eq("id", user_id).execute()
        
        del otp_store[key]
        return {"message": "Password updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
