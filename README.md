# Merchant Inventory & Billing System 🏪

A professional, full-stack ecosystem designed for modern retail merchants to manage inventory, sales, and customer credit (Khata) with high-speed barcode integration.

---

## 🏗️ System Architecture
This project consists of two core modules:

*   **/mearchentapp**: A premium **Flutter** mobile application featuring a split-screen billing engine, real-time scanning, and a minimizable category-sidebar layout.
*   **/backendserver**: A high-performance **FastAPI** (Python) backend integrated with **Supabase** for persistent storage and **SMTP** for secure OTP verification.

---

## ✨ New & Key Features

### ⚡ Smart Scanning & Billing
-   **Split-Screen Quick Scan**: A unified interface with a live camera feed on the top and a real-time cart at the bottom for ultra-fast checkout.
-   **Barcode-Ready Inventory**: Every product supports barcode identification, allowing for instant stock lookups and cart additions.
-   **Adaptive Sidebar**: A minimizable vertical category sidebar for the "Create Order" screen, optimized for screen real estate.

### 📊 Business Analytics
-   **Dual-Tab Analysis**: Separate "Insights" (charts & trends) and "Totals" (inventory value & outstanding debt) tabs for quick decision-making.
-   **Trend Analysis**: Hourly, daily, and monthly sales tracking with dynamic graphs.

### 💳 Khata & Debt Recovery
-   **Outstanding Tracking**: Real-time monitoring of customer credit balances.
-   **Recovery Progress**: Visual indicators showing the percentage of recovered debt.
-   **Customer History**: Full logs of credit granted and payments received.

### 🛡️ Security & Support
-   **Secure Auth**: OTP-based user verification and secure profile management.
-   **Support System**: Built-in support and privacy modules for merchant peace of mind.

---

## 🛠️ Getting Started

### Backend (API)
1.  Navigate to `backendserver`.
2.  Install dependencies: `pip install -r requirements.txt`.
3.  Set environment variables: `SUPABASE_URL`, `SUPABASE_KEY`, `EMAIL_USER`, `EMAIL_PASS`.
4.  Run locally: `python -m uvicorn app.main:app --reload`.

### Frontend (App)
1.  Navigate to `mearchentapp`.
2.  Install dependencies: `flutter pub get`.
3.  Run the app: `flutter run`.

---

## 🚀 Deployment (Backend on Render)
-   **Build Command**: `pip install -r requirements.txt`
-   **Start Command**: `gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app`

---

## 📄 Developers
Developed by Roarstar Studio.
