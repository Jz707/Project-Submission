from flask import Flask, render_template, request, redirect, url_for, session
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
import os
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from datetime import datetime

app = Flask(__name__)
app.secret_key = "wds_project_secret_key"

def get_server_connection():
    connection = mysql.connector.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        password="123Password12"  # change this to your MySQL password
    )
    return connection

def get_db_connection():
    connection = mysql.connector.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        password="123Password12",  # change this to your MySQL password
        database="mydb"
    )
    return connection


def initialize_database():
    """
    Runs database/setup.sql only if the database or main tables are missing.
    This prevents the setup script from running every time the app starts.
    """
    setup_paths = [
        os.path.join(app.root_path, "..", "database", "setup.sql"),
        os.path.join(app.root_path, "database", "setup.sql"),
        os.path.join(os.getcwd(), "database", "setup.sql")
    ]

    setup_file = None
    for path in setup_paths:
        if os.path.exists(path):
            setup_file = path
            break

    if setup_file is None:
        print("No database/setup.sql file found. Skipping automatic database setup.")
        return

    conn = get_server_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT SCHEMA_NAME
        FROM INFORMATION_SCHEMA.SCHEMATA
        WHERE SCHEMA_NAME = 'mydb'
    """)
    database_exists = cursor.fetchone() is not None

    tables_exist = False
    if database_exists:
        cursor.execute("""
            SELECT COUNT(*) AS table_count
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = 'mydb'
              AND TABLE_NAME IN ('customers', 'orders', 'item_types', 'order_items', 'vendor_deliveries')
        """)
        tables_exist = cursor.fetchone()["table_count"] >= 5

    if tables_exist:
        cursor.close()
        conn.close()
        print("Database already exists. Skipping setup.sql.")
        return

    print(f"Running database setup from: {setup_file}")

    with open(setup_file, "r", encoding="utf-8") as file:
        sql_script = file.read()

    statements = [stmt.strip() for stmt in sql_script.split(";") if stmt.strip()]

    for statement in statements:
        cursor.execute(statement)

    conn.commit()
    cursor.close()
    conn.close()
    print("Database setup completed.")


def initialize_users():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS system_users (
            user_id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            user_role VARCHAR(20) NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)

    default_users = [
        ("cashier", "cashier123", "cashier"),
        ("admin", "admin123", "admin")
    ]

    for username, password, user_role in default_users:
        cursor.execute(
            "SELECT user_id FROM system_users WHERE username = %s",
            (username,)
        )
        user = cursor.fetchone()

        if not user:
            cursor.execute("""
                INSERT INTO system_users (username, password_hash, user_role)
                VALUES (%s, %s, %s)
            """, (
                username,
                generate_password_hash(password),
                user_role
            ))

    conn.commit()
    cursor.close()
    conn.close()


def login_required(route_function):
    @wraps(route_function)
    def wrapper(*args, **kwargs):
        if "user_id" not in session:
            return redirect(url_for("login"))
        return route_function(*args, **kwargs)
    return wrapper


def admin_required(route_function):
    @wraps(route_function)
    def wrapper(*args, **kwargs):
        if "user_id" not in session:
            return redirect(url_for("login"))

        if session.get("user_role") != "admin":
            return "Access denied. Admin only.", 403

        return route_function(*args, **kwargs)
    return wrapper


def get_entry_status_options():
    if session.get("user_role") == "admin":
        return ["Received", "Cleaning", "Ready", "Picked Up"]

    return ["Received"]

def get_item_types(cursor):
    cursor.execute("""
        SELECT item_type_id, item_name, base_price
        FROM item_types
        ORDER BY item_name
    """)
    return cursor.fetchall()


def get_customer_by_phone(cursor, phone):
    cursor.execute("""
        SELECT
            c.customer_id,
            c.first_name,
            c.last_name,
            c.phone,
            c.email,
            COUNT(o.order_id) AS total_visits,
            COALESCE(SUM(o.total_amount), 0) AS total_spent
        FROM customers c
        LEFT JOIN orders o
            ON c.customer_id = o.customer_id
        WHERE c.phone = %s
        GROUP BY
            c.customer_id,
            c.first_name,
            c.last_name,
            c.phone,
            c.email
    """, (phone,))
    return cursor.fetchone()


def get_customer_orders(cursor, customer_id):
    cursor.execute("""
        SELECT
            o.order_id,
            o.dropoff_date,
            o.promised_date,
            o.payment_status,
            o.order_status,
            o.total_items,
            o.total_amount,
            COALESCE(
                GROUP_CONCAT(
                    CONCAT(it.item_name, ' x', oi.quantity, ' - ', oi.care_type)
                    SEPARATOR ', '
                ),
                'No item details'
            ) AS item_details
        FROM orders o
        LEFT JOIN order_items oi
            ON o.order_id = oi.order_id
        LEFT JOIN item_types it
            ON oi.item_type_id = it.item_type_id
        WHERE o.customer_id = %s
        GROUP BY
            o.order_id,
            o.dropoff_date,
            o.promised_date,
            o.payment_status,
            o.order_status,
            o.total_items,
            o.total_amount
        ORDER BY o.order_id DESC
    """, (customer_id,))
    return cursor.fetchall()

def get_customer_by_id(cursor, customer_id):
    cursor.execute("""
        SELECT
            c.customer_id,
            c.first_name,
            c.last_name,
            c.phone,
            c.email,
            COUNT(o.order_id) AS total_visits,
            COALESCE(SUM(o.total_amount), 0) AS total_spent
        FROM customers c
        LEFT JOIN orders o
            ON c.customer_id = o.customer_id
        WHERE c.customer_id = %s
        GROUP BY
            c.customer_id,
            c.first_name,
            c.last_name,
            c.phone,
            c.email
    """, (customer_id,))
    return cursor.fetchone()


def search_customers(cursor, search_term):
    like_term = f"%{search_term}%"

    cursor.execute("""
        SELECT
            c.customer_id,
            c.first_name,
            c.last_name,
            c.phone,
            c.email,
            COUNT(o.order_id) AS total_visits,
            COALESCE(SUM(o.total_amount), 0) AS total_spent
        FROM customers c
        LEFT JOIN orders o
            ON c.customer_id = o.customer_id
        WHERE
            c.first_name LIKE %s
            OR c.last_name LIKE %s
            OR CONCAT(c.first_name, ' ', c.last_name) LIKE %s
            OR c.phone LIKE %s
            OR c.email LIKE %s
            OR CAST(c.customer_id AS CHAR) LIKE %s
        GROUP BY
            c.customer_id,
            c.first_name,
            c.last_name,
            c.phone,
            c.email
        ORDER BY c.last_name, c.first_name
        LIMIT 25
    """, (
        like_term,
        like_term,
        like_term,
        like_term,
        like_term,
        like_term
    ))

    return cursor.fetchall()

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "").strip()

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT user_id, username, password_hash, user_role
            FROM system_users
            WHERE username = %s
        """, (username,))

        user = cursor.fetchone()

        cursor.close()
        conn.close()

        if user and check_password_hash(user["password_hash"], password):
            session["user_id"] = user["user_id"]
            session["username"] = user["username"]
            session["user_role"] = user["user_role"]

            return redirect(url_for("home"))

        return render_template("login.html", error="Invalid username or password.")

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

@app.route("/")
@login_required
def home():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT COUNT(*) AS total_customers FROM customers")
    total_customers = cursor.fetchone()["total_customers"]

    cursor.execute("SELECT COUNT(*) AS total_orders FROM orders")
    total_orders = cursor.fetchone()["total_orders"]

    cursor.execute("SELECT COUNT(*) AS ready_orders FROM orders WHERE order_status = 'Ready'")
    ready_orders = cursor.fetchone()["ready_orders"]

    cursor.execute("SELECT COALESCE(SUM(total_amount), 0) AS total_sales FROM orders")
    total_sales = cursor.fetchone()["total_sales"]

    cursor.close()
    conn.close()

    return render_template(
        "index.html",
        total_customers=total_customers,
        total_orders=total_orders,
        ready_orders=ready_orders,
        total_sales=total_sales
    )


@app.route("/entry", methods=["GET", "POST"])
@login_required
def entry():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    if request.method == "GET":
        search_term = request.args.get("customer_search", "").strip()
        selected_customer_id = request.args.get("customer_id")
        success = request.args.get("success")

        customer = None
        customer_orders = []
        search_results = []
        show_new_customer = False

        if selected_customer_id:
            customer = get_customer_by_id(cursor, selected_customer_id)

            if customer:
                customer_orders = get_customer_orders(cursor, customer["customer_id"])

        elif search_term:
            results = search_customers(cursor, search_term)

            if len(results) == 1:
                customer = results[0]
                customer_orders = get_customer_orders(cursor, customer["customer_id"])

            elif len(results) > 1:
                search_results = results

            else:
                show_new_customer = True

        item_types = get_item_types(cursor)

        cursor.close()
        conn.close()

        return render_template(
            "entry.html", 
            item_types=item_types,
            search_term=search_term,
            customer=customer,
            customer_orders=customer_orders,
            search_results=search_results,
            show_new_customer=show_new_customer,
            success=success,
            status_options=get_entry_status_options()
        )

    try:
        customer_id = request.form.get("customer_id")

        first_name = request.form.get("first_name", "").strip()
        last_name = request.form.get("last_name", "").strip()
        phone = request.form.get("phone", "").strip()
        email = request.form.get("email", "").strip()

        dropoff_date = request.form.get("dropoff_date")
        promised_date = request.form.get("promised_date")
        payment_status = request.form.get("payment_status")
        order_status = request.form.get("order_status")
        if session.get("user_role") == "cashier":
            order_status = "Received"
        notes = request.form.get("notes")

        item_type_ids = request.form.getlist("item_type_id")
        care_types = request.form.getlist("care_type")
        quantities = request.form.getlist("quantity")

        valid_items = []

        for i in range(len(item_type_ids)):
            item_type_id = item_type_ids[i]
            care_type = care_types[i]
            quantity_text = quantities[i].strip()

            if item_type_id and quantity_text:
                quantity = int(quantity_text)

                if quantity > 0:
                    cursor.execute("""
                        SELECT item_type_id, base_price
                        FROM item_types
                        WHERE item_type_id = %s
                    """, (item_type_id,))
                    item = cursor.fetchone()

                    if item:
                        unit_price = float(item["base_price"])
                        line_total = unit_price * quantity

                        valid_items.append({
                            "item_type_id": item["item_type_id"],
                            "care_type": care_type,
                            "quantity": quantity,
                            "unit_price": unit_price,
                            "line_total": line_total
                        })

        if not valid_items:
            item_types = get_item_types(cursor)

            cursor.close()
            conn.close()

            return render_template(
                "entry.html", 
                item_types=item_types,
                error="Please enter at least one item.",
                status_options=get_entry_status_options()
            )

        if customer_id:
            customer_id = int(customer_id)

        else:
            existing_customer = None

            if phone:
                existing_customer = get_customer_by_phone(cursor, phone)

            if existing_customer:
                customer_id = existing_customer["customer_id"]

            else:
                cursor.execute("""
                    INSERT INTO customers 
                    (first_name, last_name, phone, email, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, (first_name, last_name, phone, email, datetime.now()))

                customer_id = cursor.lastrowid

        total_items = sum(item["quantity"] for item in valid_items)
        total_amount = sum(item["line_total"] for item in valid_items)

        cursor.execute("""
            INSERT INTO orders (
                customer_id,
                dropoff_date,
                promised_date,
                payment_status,
                order_status,
                notes,
                total_items,
                total_amount
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            customer_id,
            dropoff_date,
            promised_date,
            payment_status,
            order_status,
            notes,
            total_items,
            total_amount
        ))

        order_id = cursor.lastrowid

        for item in valid_items:
            cursor.execute("""
                INSERT INTO order_items (
                    order_id,
                    item_type_id,
                    care_type,
                    quantity,
                    unit_price,
                    line_total,
                    item_status
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                order_id,
                item["item_type_id"],
                item["care_type"],
                item["quantity"],
                item["unit_price"],
                item["line_total"],
                order_status
            ))

        conn.commit()

        cursor.close()
        conn.close()

        return redirect(url_for("entry", customer_id=customer_id, success=1))

    except Exception as e:
        conn.rollback()

        item_types = get_item_types(cursor)

        cursor.close()
        conn.close()

        return render_template(
            "entry.html", 
            item_types=item_types,
            error=f"Error saving order: {e}",
            status_options=get_entry_status_options()
        )


@app.route("/search", methods=["GET"])
@login_required
def search():
    search_term = request.args.get("search", "").strip()
    payment_status = request.args.get("payment_status", "")
    order_status = request.args.get("order_status", "")
    date_from = request.args.get("date_from", "")
    date_to = request.args.get("date_to", "")
    sort = request.args.get("sort", "newest")

    edited = request.args.get("edited")
    deleted = request.args.get("deleted")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT
            o.order_id,
            o.customer_id,
            CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
            c.phone,
            c.email,
            o.dropoff_date,
            o.promised_date,
            o.payment_status,
            o.order_status,
            o.total_items,
            o.total_amount,
            o.notes,
            COALESCE(
                GROUP_CONCAT(
                    CONCAT(it.item_name, ' x', oi.quantity, ' - ', oi.care_type)
                    SEPARATOR ', '
                ),
                'No item details'
            ) AS item_details
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        LEFT JOIN item_types it ON oi.item_type_id = it.item_type_id
        WHERE 1=1
    """

    params = []

    # 🔍 Search filter
    if search_term:
        query += """
            AND (
                CAST(o.order_id AS CHAR) LIKE %s
                OR c.first_name LIKE %s
                OR c.last_name LIKE %s
                OR CONCAT(c.first_name, ' ', c.last_name) LIKE %s
                OR c.phone LIKE %s
                OR c.email LIKE %s
                OR it.item_name LIKE %s
                OR o.notes LIKE %s
            )
        """
        like_term = f"%{search_term}%"
        params.extend([like_term]*8)

    # 📊 Filters
    if payment_status:
        query += " AND o.payment_status = %s"
        params.append(payment_status)

    if order_status:
        query += " AND o.order_status = %s"
        params.append(order_status)

    if date_from:
        query += " AND o.dropoff_date >= %s"
        params.append(date_from)

    if date_to:
        query += " AND o.dropoff_date <= %s"
        params.append(date_to)

    # 🧠 Grouping
    query += """
        GROUP BY
            o.order_id,
            o.customer_id,
            customer_name,
            c.phone,
            c.email,
            o.dropoff_date,
            o.promised_date,
            o.payment_status,
            o.order_status,
            o.total_items,
            o.total_amount,
            o.notes
    """

    # Sorting
    if sort == "oldest":
        query += " ORDER BY o.dropoff_date ASC"
    elif sort == "amount_high":
        query += " ORDER BY o.total_amount DESC"
    elif sort == "amount_low":
        query += " ORDER BY o.total_amount ASC"
    elif sort == "items_high":
        query += " ORDER BY o.total_items DESC"
    else:
        query += " ORDER BY o.dropoff_date DESC"

    cursor.execute(query, params)
    orders = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "search.html",
        orders=orders,
        search_term=search_term,
        payment_status=payment_status,
        order_status=order_status,
        date_from=date_from,
        date_to=date_to,
        sort=sort,
        edited=edited,
        deleted=deleted
    )

@app.route("/edit/<int:order_id>", methods=["GET", "POST"])
@admin_required
def edit_order(order_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    if request.method == "POST":
        customer_id = request.form.get("customer_id")
        first_name = request.form.get("first_name")
        last_name = request.form.get("last_name")
        phone = request.form.get("phone")
        email = request.form.get("email")
        dropoff_date = request.form.get("dropoff_date")
        promised_date = request.form.get("promised_date")
        payment_status = request.form.get("payment_status")
        order_status = request.form.get("order_status")
        notes = request.form.get("notes")
        total_items = request.form.get("total_items")
        total_amount = request.form.get("total_amount")

        cursor.execute("""
            UPDATE customers
            SET first_name = %s,
                last_name = %s,
                phone = %s,
                email = %s
            WHERE customer_id = %s
        """, (first_name, last_name, phone, email, customer_id))

        cursor.execute("""
            UPDATE orders
            SET dropoff_date = %s,
                promised_date = %s,
                payment_status = %s,
                order_status = %s,
                notes = %s,
                total_items = %s,
                total_amount = %s
            WHERE order_id = %s
        """, (
            dropoff_date,
            promised_date,
            payment_status,
            order_status,
            notes,
            total_items,
            total_amount,
            order_id
        ))

        conn.commit()

        cursor.close()
        conn.close()

        return redirect(url_for("search", edited=1))

    cursor.execute("""
        SELECT o.*, c.*
        FROM orders o
        JOIN customers c
            ON o.customer_id = c.customer_id
        WHERE o.order_id = %s
    """, (order_id,))

    order = cursor.fetchone()

    cursor.close()
    conn.close()

    return render_template("edit_order.html", order=order)


@app.route("/delete/<int:order_id>", methods=["POST"])
@admin_required
def delete_order(order_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT customer_id FROM orders WHERE order_id = %s", (order_id,))
    row = cursor.fetchone()

    if row:
        cursor.execute("DELETE FROM order_items WHERE order_id = %s", (order_id,))
        cursor.execute("DELETE FROM orders WHERE order_id = %s", (order_id,))

    conn.commit()

    cursor.close()
    conn.close()

    return redirect(url_for("search", deleted=1))


@app.route("/vendor", methods=["GET", "POST"])
@admin_required
def vendor():
    if request.method == "POST":
        vendor_name = request.form.get("vendor_name")
        delivery_date = request.form.get("delivery_date")
        supply_name = request.form.get("supply_name")
        quantity = int(request.form.get("quantity"))
        unit_cost = float(request.form.get("unit_cost"))
        notes = request.form.get("notes")

        total_cost = quantity * unit_cost

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            INSERT INTO vendor_deliveries
            (vendor_name, delivery_date, supply_name, quantity, unit_cost, total_cost,notes)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            vendor_name,
            delivery_date,
            supply_name,
            quantity,
            unit_cost,
            total_cost,
            notes
        ))

        conn.commit()
        cursor.close()
        conn.close()

        return redirect(url_for("vendor_search"))

    return render_template("vendor.html")


@app.route("/vendor_search", methods=["GET"])
@admin_required
def vendor_search():
    search = request.args.get("search", "").strip()
    vendor = request.args.get("vendor", "").strip()
    supply = request.args.get("supply", "").strip()
    date_from = request.args.get("date_from")
    date_to = request.args.get("date_to")
    sort = request.args.get("sort", "newest")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT *
        FROM vendor_deliveries
        WHERE 1=1
    """
    params = []

    if search:
        query += " AND (vendor_name LIKE %s OR supply_name LIKE %s OR CAST(delivery_id AS CHAR) LIKE %s)"
        like = f"%{search}%"
        params += [like, like, like]

    if vendor:
        query += " AND vendor_name LIKE %s"
        params.append(f"%{vendor}%")

    if supply:
        query += " AND supply_name LIKE %s"
        params.append(f"%{supply}%")

    if date_from:
        query += " AND delivery_date >= %s"
        params.append(date_from)

    if date_to:
        query += " AND delivery_date <= %s"
        params.append(date_to)

    if sort == "oldest":
        query += " ORDER BY delivery_date ASC"
    elif sort == "cost_high":
        query += " ORDER BY total_cost DESC"
    elif sort == "cost_low":
        query += " ORDER BY total_cost ASC"
    elif sort == "qty_high":
        query += " ORDER BY quantity DESC"
    else:
        query += " ORDER BY delivery_date DESC"

    cursor.execute(query, params)
    deliveries = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "vendor_search.html",
        deliveries=deliveries,
        search=search,
        vendor=vendor,
        supply=supply,
        date_from=date_from,
        date_to=date_to,
        sort=sort
    )

@app.route("/analysis", methods=["GET"])
@admin_required
def analysis():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    graph_dir = os.path.join(app.root_path, "static", "graphs")
    os.makedirs(graph_dir, exist_ok=True)

    cursor.execute("""
        SELECT 
            COUNT(o.order_id) AS number_of_orders,
            o.payment_status AS payment_status
        FROM orders o
        GROUP BY o.payment_status
    """)
    payment_df = pd.DataFrame(cursor.fetchall())

    if not payment_df.empty:
        fig, ax = plt.subplots()
        ax.pie(
            payment_df["number_of_orders"],
            labels=payment_df["payment_status"],
            autopct="%1.1f%%"
        )
        ax.set_title("Payment Status by Order")
        fig.savefig(os.path.join(graph_dir, "paymentStatus.jpg"), bbox_inches="tight")
        plt.close(fig)

    cursor.execute("""
        SELECT
            o.promised_date AS order_date,
            SUM(o.total_amount) AS total_sales
        FROM orders o
        GROUP BY o.promised_date
        ORDER BY o.promised_date ASC
    """)
    sales_df = pd.DataFrame(cursor.fetchall())

    if not sales_df.empty:
        fig, ax = plt.subplots()
        ax.plot(sales_df["order_date"], sales_df["total_sales"])
        ax.set_xlabel("Date")
        ax.set_ylabel("Total Sales ($)")
        ax.set_title("Sales by Date")
        fig.autofmt_xdate()
        fig.savefig(os.path.join(graph_dir, "salesAnalysis.jpg"), bbox_inches="tight")
        plt.close(fig)

    cursor.execute("""
        SELECT 
            it.item_name AS item_name,
            SUM(oi.quantity) AS amount_of_items
        FROM order_items oi
        JOIN item_types it
            ON oi.item_type_id = it.item_type_id
        GROUP BY it.item_name
    """)
    item_df = pd.DataFrame(cursor.fetchall())

    if not item_df.empty:
        fig, ax = plt.subplots()
        ax.pie(
            item_df["amount_of_items"],
            autopct="%1.1f%%"
        )
        ax.legend(
            title="Item Types",
            labels=item_df["item_name"],
            loc="center left",
            bbox_to_anchor=(1, 0, 0.5, 1)
        )
        ax.set_title("Amount of Items by Item Type")
        fig.savefig(os.path.join(graph_dir, "byItemTypes.jpg"), bbox_inches="tight")
        plt.close(fig)

    cursor.execute("""
        SELECT 
            DATE_FORMAT(o.promised_date, '%M-%Y') AS month_name,
            SUM(o.total_amount) AS total_sales
        FROM orders o
        GROUP BY DATE_FORMAT(o.promised_date, '%M-%Y')
        ORDER BY MIN(o.promised_date) ASC
    """)
    month_df = pd.DataFrame(cursor.fetchall())

    if not month_df.empty:
        fig, ax = plt.subplots()
        ax.bar(month_df["month_name"], month_df["total_sales"])
        ax.set_xlabel("Month")
        ax.set_ylabel("Total Sales ($)")
        ax.set_title("Total Sales by Month")
        plt.xticks(rotation=45, ha="right")
        fig.savefig(os.path.join(graph_dir, "salesPerMonth.jpg"), bbox_inches="tight")
        plt.close(fig)

    cursor.close()
    conn.close()

    return render_template(
        "analysis.html",
        paymentStatus="graphs/paymentStatus.jpg",
        salesAnalysis="graphs/salesAnalysis.jpg",
        byItemTypes="graphs/byItemTypes.jpg",
        salesPerMonth="graphs/salesPerMonth.jpg"
    )


if __name__ == "__main__":
    initialize_database()
    initialize_users()
    app.run(debug=True)


