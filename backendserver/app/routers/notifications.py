from fastapi import APIRouter, Depends, HTTPException
from ..database import supabase
from .auth import get_user_id

router = APIRouter()

@router.get("/")
async def get_notifications(user_id: str = Depends(get_user_id)):
    response = supabase.table("notifications").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
    return response.data

@router.post("/{notification_id}/read")
async def mark_as_read(notification_id: str, user_id: str = Depends(get_user_id)):
    response = supabase.table("notifications").update({"is_read": True}).eq("id", notification_id).eq("user_id", user_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"message": "Notification marked as read"}

@router.delete("/{notification_id}")
async def delete_notification(notification_id: str, user_id: str = Depends(get_user_id)):
    response = supabase.table("notifications").delete().eq("id", notification_id).eq("user_id", user_id).execute()
    return {"message": "Notification deleted"}
