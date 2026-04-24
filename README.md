# Merchant Inventory & Billing System 🏪

A full-stack solution for merchants to manage inventory, sales, and credit (Khata) with ease.

## 🚀 Project Structure
- **/mearchentapp**: Flutter-based mobile application with a modern, premium UI.
- **/backendserver**: FastAPI-based backend with Supabase integration and SMTP security.

## ✨ Key Features
- **Inventory Management**: Track stock levels, categories, and low-stock alerts.
- **Billing & POS**: Create orders, generate invoices, and manage payment statuses.
- **Khata (Credit) System**: Manage customer balances with a dedicated "Pay" feature and payment history.
- **Analytics**: Deep insights into sales, profits, and top-selling products.
- **Security**: OTP-based user verification and secure password change flows.
- **Settings**: Comprehensive profile editing, privacy policies, and support modules.

## 🛠️ Backend Deployment (Render)
1. **Build Command**: `pip install -r requirements.txt`
2. **Start Command**: `gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app`
3. **Env Vars**: `SUPABASE_URL`, `SUPABASE_KEY`, `EMAIL_USER`, `EMAIL_PASS`.

## 📱 Mobile App Setup
1. `cd mearchentapp`
2. `flutter pub get`
3. Update `lib/core/constants.dart` with your production URL.
4. `flutter run`
