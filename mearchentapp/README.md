# Merchant App 🛒

A high-performance, feature-rich Merchant Inventory and Billing System built with **Flutter** and **FastAPI**. Designed for modern retail businesses to manage stock, sales, and credit (Khata) with ease.

---

## ✨ Key Features

### 📦 Inventory Management
*   **Product Catalog**: Comprehensive list of products with unit tracking (KG, L, Piece).
*   **Barcode Integration**: Add products using barcode scanning for zero-error entry.
*   **Low Stock Alerts**: Real-time tracking of inventory levels with visual warnings for low stock.
*   **Category Management**: Organize products into custom categories for faster access.

### 🧾 Smart Billing & Orders
*   **Dual-Mode Ordering**:
    *   **Catalog Mode**: Navigate through products using a minimizable vertical category sidebar.
    *   **Quick Scan Mode (⚡)**: High-speed, split-screen scanning interface. See the camera feed at the top and the live cart at the bottom for rapid-fire billing.
*   **Flexible Cart**: Support for both piece-based and weight-based (decimal) quantities.
*   **Invoice Generation**: Professional invoice summaries ready for processing.

### 📊 Advanced Analytics
*   **Insights Tab**: Detailed sales trends (Today, Week, Month, All-Time) with interactive charts.
*   **Totals Tab**: Instant view of total inventory value, outstanding Khata balance, and active customer counts.
*   **Profit Tracking**: Real-time profit calculation based on cost and selling prices.

### 💳 Khata (Credit Management)
*   **Customer Credit Tracking**: Manage outstanding balances for regular customers.
*   **Payment History**: Record partial or full payments against credit.
*   **Recovery Health**: Track your debt recovery rate with visual progress indicators.

---

## 🚀 Tech Stack

-   **Frontend**: Flutter (Mobile & Tablet)
-   **Backend**: FastAPI (Python)
-   **Database**: Supabase (PostgreSQL)
-   **Scanning Engine**: Mobile Scanner (Modern, High-Speed)
-   **State Management**: Stateful Widgets with optimized UI refreshes.

---

## 🛠️ Getting Started

### Prerequisites
-   Flutter SDK (3.x recommended)
-   Android SDK (minSdkVersion 21)
-   Python 3.10+ (for backend)

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/JithinGK51/marchant-app.git
    ```

2.  **Setup Frontend**
    ```bash
    cd mearchentapp
    flutter pub get
    flutter run
    ```

3.  **Setup Backend**
    ```bash
    cd backendserver
    pip install -r requirements.txt
    python -m uvicorn app.main:app --reload
    ```

---

## 📸 Screenshots (Concept)
-   **Inventory**: Clean list view with search and category filters.
-   **Quick Scan**: Live camera top-half, scrolling cart bottom-half.
-   **Analytics**: Vibrant charts and business metrics.

---

## 📄 License
Custom license for Roarstar Studio.
