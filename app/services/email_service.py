import os
from aiosmtplib import send
from email.message import EmailMessage
from dotenv import load_dotenv

load_dotenv()

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", 587))
SMTP_USER = os.getenv("EMAIL_USER")
SMTP_PASS = os.getenv("EMAIL_PASS")
SMTP_FROM_NAME = "Merchant Department"
SMTP_FROM = f"{SMTP_FROM_NAME} <{os.getenv('EMAIL_USER')}>"

async def send_notification_email(to_email: str, subject: str, body: str):
    if not SMTP_USER or not SMTP_PASS:
        print("SMTP credentials not set. Skipping email.")
        return

    message = EmailMessage()
    message["From"] = SMTP_FROM
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(body)

    try:
        await send(
            message,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            username=SMTP_USER,
            password=SMTP_PASS,
            start_tls=True,
        )
        print(f"Email sent to {to_email}")
    except Exception as e:
        print(f"Failed to send email: {e}")

async def send_low_stock_alert(to_email: str, product_name: str, current_qty: float):
    subject = f"⚠️ Low Stock Alert: {product_name}"
    body = f"Hello,\n\nYour product '{product_name}' is running low. Current quantity: {current_qty}.\n\nPlease restock soon.\n\nRegards,\nMerchant Department"
    await send_notification_email(to_email, subject, body)

async def send_otp_email(to_email: str, full_name: str, otp: str):
    subject = "Verify Your Account 🛡️"
    body = f"Hello {full_name},\n\nYour OTP for account verification is: {otp}\n\nThis code will expire in 10 minutes.\n\nRegards,\nMerchant Department"
    await send_notification_email(to_email, subject, body)

async def send_order_confirmation(to_email: str, order_id: str, amount: float):
    subject = f"🛒 Order Confirmed: {order_id}"
    body = f"Hello,\n\nA new order has been placed successfully.\nOrder ID: {order_id}\nTotal Amount: ₹{amount}\n\nCheck your dashboard for details.\n\nRegards,\nMerchant Department"
    await send_notification_email(to_email, subject, body)
