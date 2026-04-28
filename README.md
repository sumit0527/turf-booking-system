🏟️ Turf Booking System - SQL
Case Study
📍 Introduction
This comprehensive SQL case study simulating a real-world turf booking system.
This database design demonstrates how SQL can be used to build a productionready booking platform with features like dynamic pricing, wallet management,
referral systems, and automated business logic.
The system handles complete operations including user management, turf
bookings, payments, wallet transactions, referral rewards, offers/discounts, and
analytics reporting.
🎯 Business Objectives
Track revenue and booking performance across different turfs
Implement dynamic pricing (weekday vs weekend)
Manage user wallets and transaction history
Run referral programs with automated rewards
Apply time-based offers and discounts
Prevent double bookings with triggers
Analyze customer behavior and retention
Generate business insights through SQL queries
🗄️ Database Schema Overview
The database consists of 14 core tables representing real-world booking
operations:
Table Purpose
roles Stores different user roles in the system (admin, user, owner)
🏟️ Turf Booking System - SQL Case Study 1
Table Purpose
users Stores login and basic profile information for all users
turfs Stores details of sports grounds available for booking
amenities Stores facilities offered at turfs (Floodlights, Parking, etc.)
turf_amenities Maps amenities to specific turfs (many-to-many relationship)
slots Stores time slots for each turf (1-hour or 2-hour durations)
pricing_rules Defines weekday and weekend pricing for each turf
offers Stores discount campaigns with validity date ranges
bookings Tracks customer reservations, pricing, and status
payments Stores payment transactions made by users
wallets Stores current wallet balance for each user
wallet_transactions Tracks all credit/debit activities in user wallets
referrals Tracks referral relationships between users and reward status
reviews Stores customer ratings and feedback for turfs
📊 Table Structures
1. roles – User Role Definitions
Purpose: Stores different user roles in the system.
Column Type Description
role_id INT PRIMARY KEY Unique role identifier
role_name ENUM Values: 'admin', 'user', 'owner'
2. users – User Accounts
Purpose: Stores login and basic profile information for all users.
Column Type Description
user_id INT PRIMARY KEY Unique user identifier
name VARCHAR(100) Full name of the user
phone VARCHAR(15) UNIQUE Contact number
🏟️ Turf Booking System - SQL Case Study 2
Column Type Description
password VARCHAR(255) Encrypted password
email VARCHAR(100) UNIQUE Email address
role_id INT FOREIGN KEY References roles table
referred_by INT FOREIGN KEY References users (who referred this user)
referral_code VARCHAR(20) UNIQUE Unique code for sharing
created_at TIMESTAMP Account creation timestamp
3. turfs – Sports Grounds
Purpose: Stores details of sports grounds available for booking.
Column Type Description
turf_id INT PRIMARY KEY Unique turf identifier
owner_id INT FOREIGN KEY References users (turf owner)
name VARCHAR(100) Turf display name
location VARCHAR(255) Address/Landmark
description TEXT Additional details
created_at TIMESTAMP Record creation time
4. amenities – Facilities
Purpose: Stores facilities offered at turfs (Floodlights, Parking, etc.).
Column Type Description
amenity_id INT PRIMARY KEY Unique amenity identifier
name VARCHAR(100) Amenity name (Floodlights, Parking, etc.)
5. turf_amenities – Turf-Amenity Mapping
Purpose: Maps amenities to specific turfs (many-to-many relationship).
Column Type Description
turf_id INT FOREIGN KEY References turfs
🏟️ Turf Booking System - SQL Case Study 3
Column Type Description
amenity_id INT FOREIGN KEY References amenities
Primary Key: (turf_id, amenity_id)
6. slots – Time Slots
Purpose: Stores time slots for each turf (1-hour or 2-hour durations).
Column Type Description
slot_id INT PRIMARY KEY Unique slot identifier
turf_id INT FOREIGN KEY References turfs
start_time TIME Starting time (e.g., 06:00:00)
end_time TIME Ending time (e.g., 07:00:00)
Example: Football turf has 1-hour slots (6 AM to 10 PM), Cricket turf has 2-hour
slots.
7. pricing_rules – Dynamic Pricing
Purpose: Defines weekday and weekend pricing for each turf.
Column Type Description
rule_id INT PRIMARY KEY Unique rule identifier
turf_id INT FOREIGN KEY References turfs
day_type ENUM Values: 'weekday', 'weekend'
price DECIMAL(10,2) Price per slot
Business Logic: Weekend prices are higher due to increased demand.
8. offers – Discount Campaigns
Purpose: Stores discount campaigns with validity date ranges.
Column Type Description
offer_id INT PRIMARY KEY Unique offer identifier
offer_name VARCHAR(100) Display name (e.g., "Monsoon Special")
🏟️ Turf Booking System - SQL Case Study 4
Column Type Description
discount_percent INT Discount percentage (e.g., 20)
valid_from DATE Offer start date
valid_to DATE Offer end date
turf_id INT NULL Specific turf or NULL for all turfs
9. bookings – Customer Reservations
Purpose: Tracks customer reservations, pricing, and status.
Column Type Description
booking_id INT PRIMARY KEY Unique booking identifier
user_id INT FOREIGN KEY References users
slot_id INT FOREIGN KEY References slots
booking_date DATE Date of the booking
final_price DECIMAL(10,2) Price after applying offers
status ENUM 'pending', 'confirmed', 'cancelled'
offer_id INT FOREIGN KEY References offers (which offer was applied)
created_at TIMESTAMP Booking creation time
Unique Constraint: (slot_id, booking_date) – Prevents double booking.
10. payments – Transaction Records
Purpose: Stores payment transactions made by users.
Column Type Description
payment_id INT PRIMARY KEY Unique payment identifier
booking_id INT FOREIGN KEY References bookings
amount DECIMAL(10,2) Amount paid
status VARCHAR(50) 'paid', 'failed', 'pending'
payment_method ENUM 'UPI', 'WALLET', 'CARD'
created_at TIMESTAMP Payment timestamp
🏟️ Turf Booking System - SQL Case Study 5
11. wallets – User Wallet Balances
Purpose: Stores current wallet balance for each user.
Column Type Description
wallet_id INT PRIMARY KEY Unique wallet identifier
user_id INT UNIQUE FOREIGN KEY References users (one-to-one)
amount INT DEFAULT 0 Current wallet balance
12. wallet_transactions – Wallet Ledger
Purpose: Tracks all credit/debit activities in user wallets.
Column Type Description
txn_id INT PRIMARY KEY Unique transaction identifier
user_id INT FOREIGN KEY References users
amount DECIMAL(10,2) Transaction amount
type ENUM 'credit' or 'debit'
description VARCHAR(255) Transaction description
created_at TIMESTAMP Transaction timestamp
13. referrals – Referral Tracking
Purpose: Tracks referral relationships between users and reward status.
Column Type Description
referral_id INT PRIMARY KEY Unique referral identifier
referrer_id INT FOREIGN KEY Person who referred
referred_user_id INT FOREIGN KEY Person who signed up
reward_amount INT DEFAULT 0 Reward amount (₹100)
status ENUM 'pending' or 'rewarded'
14. reviews – Customer Feedback
Purpose: Stores customer ratings and feedback for turfs.
🏟️ Turf Booking System - SQL Case Study 6
Column Type Description
review_id INT PRIMARY KEY Unique review identifier
user_id INT FOREIGN KEY References users
turf_id INT FOREIGN KEY References turfs
rating INT 1 to 5 rating
comment TEXT Review text
created_at TIMESTAMP Review timestamp
⚙️ Automated Triggers
The database uses 6 triggers to automate business logic:
Trigger Name Event Purpose
after_signup_wallet
AFTER INSERT ON
users
Creates wallet for new user
after_signup_bonus
AFTER INSERT ON
users
Gives ₹50 signup bonus for referred
users
before_booking_check
BEFORE INSERT ON
bookings
Prevents double booking
before_booking_price
BEFORE INSERT ON
bookings
Calculates final price with
weekday/weekend pricing + offers
before_payment_balance
BEFORE INSERT ON
payments
Checks wallet balance for wallet
payments
after_payment_process
AFTER INSERT ON
payments
Confirms booking, deducts wallet,
gives referral reward
⏰ Scheduled Events
Event Name Schedule Purpose
event_cancel_unpaid
EVERY 1
MINUTE
Auto-cancels pending bookings older than 10
minutes
📈 Business Intelligence Queries
🏟️ Turf Booking System - SQL Case Study 7
1. What is the total revenue generated by the institute?
Insight: Overall business health and financial performance KPI
2. Which turfs generate the highest revenue?
Insight: Identifies star performers vs underperforming turfs for investment
decisions
3. How much more revenue do weekends generate compared to weekdays?
Insight: Quantifies weekend premium to justify dynamic pricing strategy
4. Who are the top 3 customers who spent the most money?
Insight: Identifies VIP customers for loyalty programs and special offers
5. Which hours of the day get the most bookings?
Insight: Reveals peak demand hours for staffing and pricing optimization
6. Are offers bringing more bookings? Which offer is most popular?
Insight: Measures campaign effectiveness and helps decide which discounts to
continue
7. How many customers came from referrals? How much revenue did they
generate?
Insight: Calculates referral program ROI and shows if investment is paying off
8. How many customers come back for a second, third, or fourth booking?
Insight: Measures customer loyalty and retention rate
9. What percentage of bookings get cancelled vs confirmed vs pending?
Insight: Shows booking funnel health and identifies cancellation problems
10. How do customers prefer to pay? (UPI, Wallet, or Card)
Insight: Reveals payment method preferences for gateway strategy and wallet
promotion
11. Which hours have low bookings and could benefit from promotions?
🏟️ Turf Booking System - SQL Case Study 8
Insight: Identifies off-peak hours where discounts can drive additional revenue
12. How many customers use wallet? What's the total money stored?
Insight: Shows wallet adoption rate and total locked-in customer value
13. Which day of the week has the most confirmed bookings?
Insight: Helps plan weekly staffing, maintenance, and targeted promotions
14. Who are our most valuable customers and what are their spending tiers?
Insight: Enables customer segmentation (Platinum/Gold/Silver/Bronze) for targeted
marketing
15. Do offers actually increase bookings or just reduce average price?
Insight: Compares with/without offer to determine if discounts drive volume or
cannibalize revenue
🚀 Key Features Demonstrated
Feature Implementation
Dynamic Pricing pricing_rules table with weekday/weekend logic
Auto Discounts offers table + before_booking_price trigger
Double Booking Prevention Unique constraint + trigger
Wallet System wallets + wallet_transactions + triggers
Referral Program referrals + bonus/reward triggers
Payment Methods UPI, Wallet, Card
Auto-Cancel Unpaid MySQL Event (runs every minute)
Business Analytics 15 comprehensive SQL queries
✅ Outcome
This case study demonstrates how SQL can be used to build a production-ready
turf booking system with:
✅ Automated business logic using triggers
🏟️ Turf Booking System - SQL Case Study 9
✅ Scheduled events for maintenance
✅ Dynamic pricing and offers
✅ Wallet and referral systems
✅ Comprehensive analytics capabilities
✅ Real-world industry use cases
🏟️ Turf Booking System - SQL Case Study 10
