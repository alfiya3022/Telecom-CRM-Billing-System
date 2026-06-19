CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL
        CHECK (gender IN ('Male', 'Female', 'Other')),
    aadhaar_number VARCHAR(20) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    registration_date DATE NOT NULL,
    customer_status VARCHAR(20) NOT NULL
        CHECK (customer_status IN ('Active', 'Inactive', 'Blacklisted')),
    kyc_status VARCHAR(20) NOT NULL
        CHECK (kyc_status IN ('Pending', 'Verified', 'Rejected')),
    kyc_verified_date DATE NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE()
);
GO

---------------------------------------------------------------------------
CREATE TABLE circles (
    circle_id INT IDENTITY(1,1) PRIMARY KEY,
    circle_name VARCHAR(50) NOT NULL UNIQUE,
    state_name VARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE()
);
GO
-----------------------------------------------------------------------------
CREATE TABLE plans (
    plan_id INT IDENTITY(1,1) PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL UNIQUE,
    plan_type VARCHAR(20) NOT NULL
        CHECK (plan_type IN ('Prepaid', 'Postpaid')),
    monthly_cost DECIMAL(10,2) NOT NULL
        CHECK (monthly_cost > 0),
    data_limit DECIMAL(10,2) NOT NULL,
    data_limit_frequency VARCHAR(20) NOT NULL
        CHECK (data_limit_frequency IN ('Daily', 'Monthly')),
    call_limit_minutes INT NULL,
    sms_limit INT NULL,
    validity_days INT NULL,
    additional_benefits VARCHAR(255) NULL,
    plan_status VARCHAR(20) NOT NULL
        CHECK (plan_status IN ('Active', 'Discontinued')),
    launch_date DATE NOT NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE()
);
GO
--------------------------------------------------------------------------
CREATE TABLE sim_cards (
    sim_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    circle_id INT NOT NULL,
    mobile_number VARCHAR(10) NOT NULL UNIQUE,
    connection_type VARCHAR(20) NOT NULL
        CHECK (connection_type IN ('Prepaid', 'Postpaid')),
    sim_type VARCHAR(20) NOT NULL
        CHECK (sim_type IN ('Physical', 'eSIM')),
    activation_date DATE NOT NULL,
    sim_status VARCHAR(20) NOT NULL
        CHECK (sim_status IN ('Active', 'Inactive', 'Suspended', 'Blocked')),
    is_ported BIT NOT NULL DEFAULT 0,
    previous_operator VARCHAR(50) NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_sim_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT FK_sim_circle
        FOREIGN KEY (circle_id)
        REFERENCES circles(circle_id)
);
GO
------------------------------------------------------------------------------
CREATE TABLE subscriptions (
    subscription_id INT IDENTITY(1,1) PRIMARY KEY,
    sim_id INT NOT NULL,
    plan_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    subscription_status VARCHAR(20) NOT NULL
        CHECK (subscription_status IN ('Active', 'Expired', 'Cancelled')),
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_subscription_sim
        FOREIGN KEY (sim_id)
        REFERENCES sim_cards(sim_id),
    CONSTRAINT FK_subscription_plan
        FOREIGN KEY (plan_id)
        REFERENCES plans(plan_id)
);
GO
------------------------------------------------------------------------------
CREATE TABLE usage_records (
    usage_id INT IDENTITY(1,1) PRIMARY KEY,
    sim_id INT NOT NULL,
    usage_date DATE NOT NULL,
    call_minutes_used INT NOT NULL
        CHECK (call_minutes_used >= 0),
    sms_used INT NOT NULL
        CHECK (sms_used >= 0),
    data_used_gb DECIMAL(8,2) NOT NULL
        CHECK (data_used_gb >= 0),
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_usage_sim
        FOREIGN KEY (sim_id)
        REFERENCES sim_cards(sim_id)
);

--------------------------------------------------
CREATE TABLE recharge_history (
    recharge_id INT IDENTITY(1,1) PRIMARY KEY,
    sim_id INT NOT NULL,
    plan_id INT NULL,
    recharge_date DATE NOT NULL,
    recharge_amount DECIMAL(10,2) NOT NULL,
    recharge_type VARCHAR(20) NOT NULL
        CHECK (recharge_type IN ('Plan Recharge', 'Top-Up')),
    payment_method VARCHAR(20) NOT NULL
        CHECK (payment_method IN ('UPI','Card','Net Banking','Wallet')),
    transaction_status VARCHAR(20) NOT NULL
        CHECK (transaction_status IN ('Success','Failed','Pending')),
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_recharge_sim
        FOREIGN KEY (sim_id)
        REFERENCES sim_cards(sim_id),
    CONSTRAINT FK_recharge_plan
        FOREIGN KEY (plan_id)
        REFERENCES plans(plan_id)
);
-------------------------------------------------
CREATE TABLE bills (
    bill_id INT IDENTITY(1,1) PRIMARY KEY,
    sim_id INT NOT NULL,
    billing_month DATE NOT NULL,
    bill_generation_date DATE NOT NULL,
    due_date DATE NOT NULL,
    plan_charge DECIMAL(10,2) NOT NULL,
    extra_usage_charge DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    bill_status VARCHAR(20) NOT NULL
        CHECK (bill_status IN ('Pending','Partially Paid','Paid','Overdue')),
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_bill_sim
        FOREIGN KEY (sim_id)
        REFERENCES sim_cards(sim_id)
);

-----------------------------------------------
CREATE TABLE payments (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    bill_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL
        CHECK (payment_method IN ('UPI','Card','Net Banking','Wallet')),
    payment_status VARCHAR(20) NOT NULL
        CHECK (payment_status IN ('Success','Failed','Refunded')),
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_payment_bill
        FOREIGN KEY (bill_id)
        REFERENCES bills(bill_id)
);
----------------------
CREATE TABLE support_tickets (
    ticket_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    sim_id INT NULL,
    issue_type VARCHAR(50) NOT NULL,
    ticket_description VARCHAR(500) NOT NULL,
    priority VARCHAR(20) NOT NULL
        CHECK (priority IN ('Low','Medium','High','Critical')),
    ticket_status VARCHAR(20) NOT NULL
        CHECK (ticket_status IN ('Open','In Progress','Resolved','Closed')),
    created_date DATE NOT NULL,
    resolved_date DATE NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ticket_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT FK_ticket_sim
        FOREIGN KEY (sim_id)
        REFERENCES sim_cards(sim_id)
);
----------------------------------------------------