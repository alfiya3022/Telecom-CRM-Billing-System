
---Bussiness related Quries

--1. Which telecom plans generate the highest revenue?
SELECT
    p.plan_name,
    SUM(r.recharge_amount) AS Total_Revenue
FROM plans p
JOIN recharge_history r
    ON p.plan_id = r.plan_id
GROUP BY p.plan_name
ORDER BY Total_Revenue DESC;

--2. Which customers generate the highest billing revenue?
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(b.total_amount) AS Revenue
FROM customers c
JOIN sim_cards s
    ON c.customer_id = s.customer_id
JOIN bills b
    ON s.sim_id = b.sim_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY Revenue DESC;

--3. Which customers own multiple SIM cards?
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(s.sim_id) AS Total_SIMs
FROM customers c
JOIN sim_cards s
    ON c.customer_id = s.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(s.sim_id) > 1;

--4. Which telecom circles have the highest customer base?
SELECT
    ci.circle_name,
    COUNT(*) AS Total_Customers
FROM circles ci
JOIN sim_cards s
    ON ci.circle_id = s.circle_id
GROUP BY ci.circle_name
ORDER BY Total_Customers DESC;

--5. Which customers have the highest data consumption?
SELECT TOP 10
    c.customer_id,
    c.first_name,
    SUM(u.data_used_gb) AS Total_Data_Used
FROM customers c
JOIN sim_cards s
    ON c.customer_id = s.customer_id
JOIN usage_records u
    ON s.sim_id = u.sim_id
GROUP BY
    c.customer_id,
    c.first_name
ORDER BY Total_Data_Used DESC;

--6. Which plans have the highest number of subscribers?
SELECT
    p.plan_name,
    COUNT(*) AS Subscriber_Count
FROM plans p
JOIN subscriptions s
    ON p.plan_id = s.plan_id
GROUP BY p.plan_name
ORDER BY Subscriber_Count DESC;

--7. Which customers have pending bills?
SELECT
    c.customer_id,
    c.first_name,
    b.bill_id,
    b.total_amount
FROM customers c
JOIN sim_cards s
    ON c.customer_id = s.customer_id
JOIN bills b
    ON s.sim_id = b.sim_id
WHERE b.bill_status = 'Pending';

--8. What is the monthly revenue trend of the telecom company?
SELECT
    YEAR(bill_generation_date) AS Year,
    MONTH(bill_generation_date) AS Month,
    SUM(total_amount) AS Revenue
FROM bills
GROUP BY
    YEAR(bill_generation_date),
    MONTH(bill_generation_date)
ORDER BY Year, Month;

--9. Which issue types generate the most support tickets?
SELECT
    issue_type,
    COUNT(*) AS Ticket_Count
FROM support_tickets
GROUP BY issue_type
ORDER BY Ticket_Count DESC;

--10. Rank customers based on total revenue generated. (Window Function)
SELECT
    customer_id,
    Revenue,
    RANK() OVER(ORDER BY Revenue DESC) AS Revenue_Rank
FROM
(
    SELECT
        s.customer_id,
        SUM(b.total_amount) AS Revenue
    FROM bills b
    JOIN sim_cards s
        ON b.sim_id = s.sim_id
    GROUP BY s.customer_id
) x;


/* =====================================================
   JOINS
   ===================================================== */

--  Customer and Current Plan Details
SELECT c.first_name,c.last_name,p.plan_name,p.monthly_cost
FROM customers c
JOIN sim_cards s ON c.customer_id=s.customer_id
JOIN subscriptions sub ON s.sim_id=sub.sim_id
JOIN plans p ON sub.plan_id=p.plan_id;

--  Customer Support Ticket Report
SELECT c.first_name,st.issue_type,st.priority,st.ticket_status
FROM customers c
JOIN support_tickets st ON c.customer_id=st.customer_id;

/* =====================================================
   CTEs
   ===================================================== */

--  Customers Spending Above Average
WITH AvgBill AS (
SELECT AVG(total_amount) AvgAmt FROM bills
)
SELECT * FROM bills
WHERE total_amount > (SELECT AvgAmt FROM AvgBill);

--  High Data Usage SIMs
WITH UsageSummary AS (
SELECT sim_id,SUM(data_used_gb) TotalData
FROM usage_records
GROUP BY sim_id
)
SELECT * FROM UsageSummary
WHERE TotalData > 20;

--  Active Subscribers
WITH ActiveSubs AS (
SELECT * FROM subscriptions
WHERE subscription_status='Active'
)
SELECT * FROM ActiveSubs;

-- 9. Multiple SIM Customers
WITH MultiSIM AS (
SELECT customer_id,COUNT(*) TotalSIMs
FROM sim_cards
GROUP BY customer_id
)
SELECT * FROM MultiSIM
WHERE TotalSIMs > 1;

--  Revenue by Plan
WITH PlanRevenue AS (
SELECT plan_id,SUM(recharge_amount) Revenue
FROM recharge_history
GROUP BY plan_id
)
SELECT * FROM PlanRevenue;

/* =====================================================
   SUBQUERIES 
   ===================================================== */

--  Plans Above Average Cost
SELECT *
FROM plans
WHERE monthly_cost >
(SELECT AVG(monthly_cost) FROM plans);

--  Bills Above Average Amount
SELECT *
FROM bills
WHERE total_amount >
(SELECT AVG(total_amount) FROM bills);

--  Highest Revenue Plan
SELECT *
FROM plans
WHERE plan_id =
(
SELECT TOP 1 plan_id
FROM recharge_history
GROUP BY plan_id
ORDER BY SUM(recharge_amount) DESC
);

--  Customers With Pending Bills
SELECT *
FROM customers
WHERE customer_id IN
(
SELECT s.customer_id
FROM sim_cards s
JOIN bills b ON s.sim_id=b.sim_id
WHERE b.bill_status='Pending'
);

--  Customers Without Tickets
SELECT *
FROM customers
WHERE customer_id NOT IN
(
SELECT customer_id
FROM support_tickets
);

/* =====================================================
   WINDOW FUNCTIONS 
   ===================================================== */

--  Dense Rank Data Users
SELECT sim_id,
SUM(data_used_gb) TotalData,
DENSE_RANK() OVER(ORDER BY SUM(data_used_gb) DESC) Ranking
FROM usage_records
GROUP BY sim_id;

--  Running Revenue Total
SELECT bill_generation_date,total_amount,
SUM(total_amount) OVER(ORDER BY bill_generation_date) RunningRevenue
FROM bills;

--  Previous Bill Comparison
SELECT bill_id,total_amount,
LAG(total_amount) OVER(ORDER BY bill_generation_date) PreviousBill
FROM bills;

--  Next Bill Comparison
SELECT bill_id,total_amount,
LEAD(total_amount) OVER(ORDER BY bill_generation_date) NextBill
FROM bills;

/* =====================================================
   VIEWS 
   ===================================================== */

CREATE VIEW vw_customer_plan_details AS
SELECT c.customer_id,c.first_name,p.plan_name,p.monthly_cost
FROM customers c
JOIN sim_cards s ON c.customer_id=s.customer_id
JOIN subscriptions sub ON s.sim_id=sub.sim_id
JOIN plans p ON sub.plan_id=p.plan_id;

CREATE VIEW vw_customer_sim_details AS
SELECT c.customer_id,c.first_name,s.mobile_number,s.connection_type
FROM customers c
JOIN sim_cards s ON c.customer_id=s.customer_id;

CREATE VIEW vw_billing_summary AS
SELECT bill_id,sim_id,total_amount,bill_status
FROM bills;

CREATE VIEW vw_recharge_summary AS
SELECT sim_id,recharge_amount,transaction_status
FROM recharge_history;

CREATE VIEW vw_open_tickets AS
SELECT *
FROM support_tickets
WHERE ticket_status <> 'Resolved';

/* =====================================================
   STORED PROCEDURES 
   ===================================================== */

CREATE PROCEDURE sp_GetCustomerDetails
@CustomerID INT
AS
BEGIN
SELECT * FROM customers
WHERE customer_id=@CustomerID;
END;

CREATE PROCEDURE sp_GetCustomerBills
@CustomerID INT
AS
BEGIN
SELECT b.*
FROM bills b
JOIN sim_cards s ON b.sim_id=s.sim_id
WHERE s.customer_id=@CustomerID;
END;

CREATE PROCEDURE sp_RevenueByPlan
AS
BEGIN
SELECT plan_id,SUM(recharge_amount) Revenue
FROM recharge_history
GROUP BY plan_id;
END;

/* =====================================================
   INDEXES 
   ===================================================== */

CREATE INDEX idx_customer_state ON customers(state);
CREATE INDEX idx_mobile_number ON sim_cards(mobile_number);
CREATE INDEX idx_bill_status ON bills(bill_status);
CREATE INDEX idx_recharge_date ON recharge_history(recharge_date);
CREATE INDEX idx_ticket_status ON support_tickets(ticket_status);

/* =====================================================
   TRIGGERS 
   ===================================================== */

CREATE TRIGGER trg_PreventNegativePayment
ON payments
INSTEAD OF INSERT
AS
BEGIN
IF EXISTS(SELECT 1 FROM inserted WHERE amount_paid < 0)
RAISERROR('Negative payment not allowed',16,1);
END;

CREATE TRIGGER trg_CloseTicket
ON support_tickets
AFTER UPDATE
AS
BEGIN
UPDATE support_tickets
SET resolved_date=GETDATE()
WHERE ticket_status='Resolved'
AND resolved_date IS NULL;
END;

CREATE TRIGGER trg_CheckRegistrationDate
ON customers
INSTEAD OF INSERT
AS
BEGIN
IF EXISTS(SELECT 1 FROM inserted WHERE registration_date > GETDATE())
RAISERROR('Future registration date not allowed',16,1);
END;
