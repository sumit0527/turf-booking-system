CREATE DATABASE turf_booking_system;
USE turf_booking_system;

CREATE TABLE roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name ENUM("admin", "user", "owner")
);

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    phone VARCHAR(15) UNIQUE,
    password VARCHAR(255) NOT NULL, 
    email VARCHAR(100) UNIQUE NOT NULL, 
    role_id INT,
    referred_by INT,
    referral_code VARCHAR(20) UNIQUE DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id),
    FOREIGN KEY (referred_by) REFERENCES users(user_id)
); 

CREATE INDEX idx_users_role ON users(role_id);
CREATE INDEX idx_users_referred_by ON users(referred_by);

ALTER TABLE users 
DROP INDEX referral_code;

CREATE TABLE turfs (
    turf_id INT PRIMARY KEY AUTO_INCREMENT,
    owner_id INT NOT NULL, 
    name VARCHAR(100),
    location VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(user_id)
);

CREATE INDEX idx_turfs_owner ON turfs(owner_id);

CREATE TABLE amenities (
    amenity_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100)
);

CREATE TABLE turf_amenities (
    turf_id INT,
    amenity_id INT,
    PRIMARY KEY (turf_id, amenity_id),
    FOREIGN KEY (turf_id) REFERENCES turfs(turf_id),
    FOREIGN KEY (amenity_id) REFERENCES amenities(amenity_id)
);

CREATE TABLE slots (
    slot_id INT PRIMARY KEY AUTO_INCREMENT,
    turf_id INT,
    start_time TIME,
    end_time TIME,    
    FOREIGN KEY (turf_id) REFERENCES turfs(turf_id)
);

CREATE INDEX idx_slots_turf ON slots(turf_id);

CREATE TABLE pricing_rules (
    rule_id INT PRIMARY KEY AUTO_INCREMENT,
    turf_id INT,
    day_type ENUM('weekday','weekend'),
    price DECIMAL(10,2),
    FOREIGN KEY (turf_id) REFERENCES turfs(turf_id)
);

CREATE INDEX idx_pricing_turf_day ON pricing_rules(turf_id, day_type); 

CREATE TABLE offers (
    offer_id INT PRIMARY KEY AUTO_INCREMENT,
    offer_name VARCHAR(100),           -- Name like 'Monsoon Special'
    discount_percent INT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    turf_id INT NULL,                  -- Optional: Apply to specific turf or NULL for all
    FOREIGN KEY (turf_id) REFERENCES turfs(turf_id)
);

CREATE INDEX idx_offer_name ON offers(offer_name); 
CREATE INDEX idx_turf_offer_duration ON offers(turf_id, valid_from, valid_to);  

CREATE TABLE bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    slot_id INT,
    booking_date DATE,
    final_price DECIMAL(10,2),
    status ENUM('pending','confirmed','cancelled'),
    offer_id INT DEFAULT NULL,                 -- System will fill this automatically if offer exists,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP , 
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (slot_id) REFERENCES slots(slot_id),
    FOREIGN KEY (offer_id) REFERENCES offers(offer_id) 
);

CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_status ON bookings(status);	
CREATE UNIQUE INDEX uniq_slot_date ON bookings(slot_id, booking_date);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT,
    amount DECIMAL(10,2),
    status VARCHAR(50),
    payment_method ENUM('UPI', 'WALLET', 'CARD'),  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(status);

CREATE TABLE wallets (
	wallet_id INT PRIMARY KEY AUTO_INCREMENT, 
    user_id INT UNIQUE, 
    amount INT DEFAULT 0, 
    FOREIGN KEY (user_id) REFERENCES users(user_id) 
);

CREATE TABLE wallet_transactions (
    txn_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    amount DECIMAL(10,2),
    type ENUM('credit','debit'),
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX idx_wallet_txn_user ON wallet_transactions(user_id);

CREATE TABLE referrals (
    referral_id INT PRIMARY KEY AUTO_INCREMENT,
    referrer_id INT,
    referred_user_id INT,
    reward_amount INT DEFAULT 0,
    status ENUM('pending','rewarded'),    
    FOREIGN KEY (referrer_id) REFERENCES users(user_id),
    FOREIGN KEY (referred_user_id) REFERENCES users(user_id)
);

CREATE INDEX idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX idx_referrals_referred ON referrals(referred_user_id);

-- set default reward amount 
ALTER TABLE referrals 
ALTER COLUMN reward_amount SET DEFAULT 0;

CREATE TABLE reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    turf_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (turf_id) REFERENCES turfs(turf_id)
);

CREATE INDEX idx_reviews_turf ON reviews(turf_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);

-- ================================================================================================================================================
-- Database Records 
-- ================================================================================================================================================
 
-- ================================================================================================================================================
-- SECTION 1: USER ROLES (Define user types in the system)
-- ================================================================================================================================================
-- Each user must have a role that defines their permissions
-- admin = Can manage everything
-- user = Regular customer who books turfs
-- owner = Turf owner who manages their grounds

INSERT INTO roles (role_name) VALUES 
('admin'),
('user'),
('owner');

-- ================================================================================================================================================
-- SECTION 2: USER REGISTRATION (Create system users)
-- ================================================================================================================================================
-- Note: referral_code for Sham is manually set to test referral system
-- When a user signs up with a referral code, they get ₹50 bonus
-- The referrer (Ram) will get ₹100 when Sham makes first booking

-- Admin User (System Administrator)
INSERT INTO users (name, phone, password, email, role_id, referred_by) 
VALUES ('Admin User', '9999999999', 'admin123', 'admin@turf.com', 1, NULL);

-- Turf Owner (Raj - owns the turfs)
INSERT INTO users (name, phone, password, email, role_id, referred_by) 
VALUES ('Raj Owner', '8888888888', 'owner123', 'raj@turf.com', 3, NULL);

-- Customer 1: Ram Sharma (No referral, direct signup)
-- This user will test normal booking flow
INSERT INTO users (name, phone, password, email, role_id, referred_by) 
VALUES ('Ram Sharma', '7777777777', 'ram123', 'ram@email.com', 2, NULL);

-- Customer 2: Sham Verma (Referred by Ram - testing referral system)
-- referred_by = 3 means Ram (user_id=3) referred Sham
-- referral_code = "RAMSH1000" is the code Sham used during signup
INSERT INTO users (name, phone, password, email, role_id, referred_by, referral_code) 
VALUES ('Sham Verma', '6666666666', 'sham123', 'sham@email.com', 2, 3, "RAMSH1000");


-- ================================================================================================================================================
-- SECTION 3: TURF CREATION (Sports grounds available for booking)
-- ================================================================================================================================================
-- Each turf belongs to an owner (owner_id refers to users table)
-- Two different types: Football (1-hour slots) and Cricket (2-hour slots)

-- Turf 1: Football ground with floodlights (ideal for evening matches)
INSERT INTO turfs (owner_id, name, location, description) VALUES 
(2, 'Arena Football Ground', 'MG Road, Bangalore', 'Professional football turf with floodlights');

-- Turf 2: Cricket stadium for longer matches (2-hour slots)
INSERT INTO turfs (owner_id, name, location, description) VALUES 
(2, 'Cricket Stadium', 'Koramangala, Bangalore', 'Full-size cricket pitch with nets');

-- ================================================================================================================================================
-- SECTION 4: AMENITIES (Facilities available at turfs)
-- ================================================================================================================================================
-- Amenities are additional features that make turfs attractive to customers
-- These are stored separately and linked via turf_amenities table (many-to-many)

INSERT INTO amenities (name) VALUES 
('Floodlights'),          -- For night playing
('Changing Rooms'),       -- For players to change clothes
('Parking Available'),    -- Vehicle parking facility
('Water Cooler'),         -- Drinking water
('First Aid Kit'),        -- Emergency medical supplies
('Spectator Seating'),    -- Seats for audience
('Cafeteria'),            -- Food and drinks
('AC Waiting Room'),      -- Air-conditioned waiting area
('Night Camera Security'), -- CCTV cameras for safety
('Equipment Rental');      -- Bats, balls, etc. available for rent

-- ================================================================================================================================================
-- SECTION 5: TURF AMENITIES (Assign amenities to specific turfs)
-- ================================================================================================================================================
-- Each turf gets different amenities based on its type and facilities

-- Turf 1: Arena Football Ground amenities
-- Includes security cameras (amenity_id 9) but no cafeteria or AC room
INSERT INTO turf_amenities (turf_id, amenity_id) VALUES 
(1, 1),  -- Floodlights
(1, 2),  -- Changing Rooms
(1, 3),  -- Parking Available
(1, 4),  -- Water Cooler
(1, 5),  -- First Aid Kit
(1, 6),  -- Spectator Seating
(1, 9);  -- Night Camera Security

-- Turf 2: Cricket Stadium amenities (more premium - includes cafeteria and AC)
INSERT INTO turf_amenities (turf_id, amenity_id) VALUES 
(2, 1),  -- Floodlights
(2, 2),  -- Changing Rooms
(2, 3),  -- Parking Available
(2, 4),  -- Water Cooler
(2, 5),  -- First Aid Kit
(2, 6),  -- Spectator Seating
(2, 7),  -- Cafeteria
(2, 8),  -- AC Waiting Room
(2, 10); -- Equipment Rental

-- ================================================================================================================================================
-- SECTION 6: TIME SLOTS FOR TURF 1 (Football - 1 hour slots from 6 AM to 10 PM)
-- ================================================================================================================================================
-- Slots define when a turf can be booked
-- Each slot has a start_time and end_time
-- Users book specific slots for specific dates
-- Morning slots (6 AM to 12 PM)
INSERT INTO slots (turf_id, start_time, end_time) VALUES 
(1, '06:00:00', '07:00:00'),  -- slot_id 1
(1, '07:00:00', '08:00:00'),  -- slot_id 2
(1, '08:00:00', '09:00:00'),  -- slot_id 3
(1, '09:00:00', '10:00:00'),  -- slot_id 4
(1, '10:00:00', '11:00:00'),  -- slot_id 5
(1, '11:00:00', '12:00:00'),  -- slot_id 6

-- Afternoon slots (12 PM to 4 PM)
(1, '12:00:00', '13:00:00'),  -- slot_id 7
(1, '13:00:00', '14:00:00'),  -- slot_id 8
(1, '14:00:00', '15:00:00'),  -- slot_id 9
(1, '15:00:00', '16:00:00'),  -- slot_id 10

-- Evening slots (4 PM to 10 PM) - Most popular
(1, '16:00:00', '17:00:00'),  -- slot_id 11
(1, '17:00:00', '18:00:00'),  -- slot_id 12
(1, '18:00:00', '19:00:00'),  -- slot_id 13
(1, '19:00:00', '20:00:00'),  -- slot_id 14
(1, '20:00:00', '21:00:00'),  -- slot_id 15
(1, '21:00:00', '22:00:00');  -- slot_id 16


-- ================================================================================================================================================
-- SECTION 7: TIME SLOTS FOR TURF 2 (Cricket - 2 hour slots for longer matches)
-- ================================================================================================================================================
-- Cricket matches typically take 2 hours, so slots are longer

INSERT INTO slots (turf_id, start_time, end_time) VALUES 
(2, '06:00:00', '08:00:00'),  -- slot_id 17 (Early morning)
(2, '08:00:00', '10:00:00'),  -- slot_id 18 (Morning)
(2, '10:00:00', '12:00:00'),  -- slot_id 19 (Late morning)
(2, '12:00:00', '14:00:00'),  -- slot_id 20 (Afternoon)
(2, '14:00:00', '16:00:00'),  -- slot_id 21 (Late afternoon)
(2, '16:00:00', '18:00:00'),  -- slot_id 22 (Evening)
(2, '18:00:00', '20:00:00'),  -- slot_id 23 (Night - popular)
(2, '20:00:00', '22:00:00');  -- slot_id 24 (Late night)

-- =============================================
-- PART 7: SLOTS (Turf 2 - 2 hour slots for cricket)
-- =============================================
INSERT INTO slots (turf_id, start_time, end_time) VALUES 
(2, '06:00:00', '08:00:00'),
(2, '08:00:00', '10:00:00'),
(2, '10:00:00', '12:00:00'),
(2, '12:00:00', '14:00:00'),
(2, '14:00:00', '16:00:00'),
(2, '16:00:00', '18:00:00'),
(2, '18:00:00', '20:00:00'),
(2, '20:00:00', '22:00:00');

-- ================================================================================================================================================
-- SECTION 8: PRICING RULES (Weekday vs Weekend pricing)
-- ================================================================================================================================================
-- Different prices for weekdays (Monday-Friday) and weekends (Saturday-Sunday)
-- Weekends have higher prices due to higher demand

-- Turf 1 pricing (Football - 1 hour)
INSERT INTO pricing_rules (turf_id, day_type, price) VALUES 
(1, 'weekday', 500),   -- Monday to Friday: ₹500 per hour
(1, 'weekend', 800);   -- Saturday & Sunday: ₹800 per hour

-- Turf 2 pricing (Cricket - 2 hours)
INSERT INTO pricing_rules (turf_id, day_type, price) VALUES 
(2, 'weekday', 1000),  -- Monday to Friday: ₹1000 for 2 hours
(2, 'weekend', 1500);  -- Saturday & Sunday: ₹1500 for 2 hours

-- ================================================================================================================================================
-- SECTION 9: OFFERS / DISCOUNTS (Promotional campaigns)
-- ================================================================================================================================================
-- Offers can apply to specific turfs or all turfs (turf_id = NULL)
-- Offers are automatically applied during booking if date is within valid_from/valid_to

-- Offer 1: Monsoon Special - 20% off on ALL turfs (turf_id = NULL means all)
-- Valid during monsoon season (June to August)
INSERT INTO offers (offer_name, discount_percent, valid_from, valid_to, turf_id) VALUES 
('Monsoon Special', 20, '2025-06-01', '2025-08-31', NULL);

-- Offer 2: Weekend Flash - 10% off only on Turf 1 (Football ground)
-- Valid for whole year on weekends
INSERT INTO offers (offer_name, discount_percent, valid_from, valid_to, turf_id) VALUES 
('Weekend Flash', 10, '2025-05-01', '2025-12-31', 1);

-- Offer 3: Early Bird - 15% off on morning slots (applied via application logic)
-- Valid for all turfs for entire year
INSERT INTO offers (offer_name, discount_percent, valid_from, valid_to, turf_id) VALUES 
('Early Bird', 15, '2025-01-01', '2025-12-31', NULL);

-- ================================================================================================================================================
-- SECTION 10: WALLET TOP-UPS (Add money to user wallets)
-- ================================================================================================================================================
-- Users can add money to their wallet for faster checkout
-- Wallet transactions are recorded for audit trail

-- Ram (user_id=3) adds ₹2000 to wallet for testing multiple bookings
-- UPDATE increases existing balance (wallet created automatically on signup)
UPDATE wallets SET amount = amount + 2000 WHERE user_id = 3;

-- Manually insert transaction:
INSERT INTO wallet_transactions (user_id, amount, type, description) 
VALUES (3, 500, "credit", "Wallet Top-up");

-- Sham (user_id=4) adds ₹1000 to wallet (already has ₹50 signup bonus = ₹1050 total)
UPDATE wallets SET amount = amount + 1000 WHERE user_id = 4;

INSERT INTO wallet_transactions (user_id, amount, type, description) 
VALUES (4, 500, "credit", "Wallet Top-up");

-- Note: No transaction record shown here - in production, you'd INSERT into wallet_transactions

-- ================================================================================================================================================
-- SECTION 11: BOOKINGS CREATION (Test different scenarios)
-- ================================================================================================================================================
-- When a booking is inserted, triggers automatically:
-- 1. Calculate final price based on weekday/weekend + active offers
-- 2. Prevent double booking if slot already reserved
-- 3. Set status = 'pending' initially

-- BOOKING 1: Ram - Weekday morning booking (Monday, May 26, 2025)
-- Slot 1: 6:00-7:00 AM on Turf 1
-- Expected price: ₹500 (weekday price) - Early Bird 15% = ₹425
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (3, 1, '2025-05-26', 'pending');

-- BOOKING 2: Ram - Weekend evening booking (Sunday, June 15, 2025)
-- Slot 14: 7:00-8:00 PM on Turf 1
-- Expected price: ₹800 (weekend price) - Monsoon Special 20% = ₹640
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (3, 14, '2025-06-15', 'pending');

-- BOOKING 3: Sham - Weekday booking with Monsoon Special (Monday, June 16, 2025)
-- Slot 15: 8:00-9:00 PM on Turf 1
-- Expected price: ₹500 - 20% = ₹400
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (4, 15, '2025-06-16', 'pending');

-- BOOKING 4: Sham - Cricket turf booking (Tuesday, May 27, 2025)
-- Slot 24: 8:00-10:00 PM on Turf 2 (cricket)
-- Expected price: ₹1000 (weekday price for cricket) - Early Bird = ₹850
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (4, 24, '2025-05-27', 'pending');

-- BOOKING 5: Ram - Booking for cancellation test (Wednesday, May 28, 2025)
-- Will be cancelled later to test cancellation flow
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (3, 2, '2025-05-28', 'pending');

-- BOOKING 6: Sham - Future booking for multiple bookings test (Friday, June 20, 2025)
-- Slot 3: 8:00-9:00 AM
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (4, 3, '2025-06-20', 'pending');


-- ================================================================================================================================================
-- SECTION 12: PAYMENT TESTING (Different payment scenarios)
-- ================================================================================================================================================

-- =============================================
-- PAYMENT SCENARIO 1: Ram pays for Booking 1 using WALLET (tests auto-deduction)
-- =============================================

-- Step 1: Check Ram's balance before payment
SELECT 'Ram Balance BEFORE Payment' as Info, amount FROM wallets WHERE user_id = 3;
-- Expected: ₹2000

-- Step 2: Make payment for Booking 1 (₹425 after Early Bird discount)
-- BEFORE trigger checks: Does Ram have ₹425? YES → Allow
-- AFTER trigger: Deducts ₹425 from wallet, records transaction, confirms booking
INSERT INTO payments (booking_id, amount, status, payment_method) 
VALUES (1, 425, 'paid', 'WALLET');

-- Step 3: Verify results after payment
SELECT 'Ram Balance AFTER Payment' as Info, amount FROM wallets WHERE user_id = 3;
-- Expected: ₹1575 (2000 - 425)

-- Step 4: Check booking status changed to 'confirmed'
SELECT booking_id, status FROM bookings WHERE booking_id = 1;

-- Step 5: Check wallet transaction recorded for debit
SELECT * FROM wallet_transactions WHERE user_id = 3 AND type = 'debit' ORDER BY txn_id DESC LIMIT 1;

-- =============================================
-- PAYMENT SCENARIO 2: Sham pays for Booking 4 using WALLET (tests cricket pricing)
-- =============================================
-- Note: This is Booking 4 (cricket turf, weekday, Early Bird offer)
-- Expected amount: ₹1000 - 15% = ₹850

-- Make payment for Booking 4 (₹850)
INSERT INTO payments (booking_id, amount, status, payment_method) 
VALUES (4, 850, 'paid', 'WALLET');

-- =============================================
-- PAYMENT SCENARIO 3: INSUFFICIENT WALLET BALANCE TEST (Should FAIL)
-- =============================================
-- This test verifies that the BEFORE trigger prevents payments when balance is low

-- First, create a new booking for Sham (user_id=4)
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (4, 9, '2025-08-10', 'pending'); -- booking_id = 7

-- Check Sham's current balance (should be ₹200 after previous payments)
SELECT 'Sham Balance BEFORE Payment Test' as Info, amount FROM wallets WHERE user_id = 4;

-- Try to pay ₹720 (more than available balance)
-- This should FAIL with error "Insufficient wallet balance"
INSERT INTO payments (booking_id, amount, status, payment_method) 
VALUES (7, 720, 'paid', 'WALLET');

-- Verify balance remained unchanged (still ₹200)
SELECT 'Sham Balance AFTER Failed Payment' as Info, amount FROM wallets WHERE user_id = 4;
-- Expected: ₹200 (no change because payment was blocked)

-- =============================================
-- PAYMENT SCENARIO 4: Sham pays for Booking 3 using CARD (tests non-wallet payment)
-- =============================================
-- Booking 3: ₹400 (weekday + Monsoon Special)
INSERT INTO payments (booking_id, amount, status, payment_method) 
VALUES (3, 400, 'paid', 'CARD');

-- =============================================
-- PAYMENT SCENARIO 5: Ram pays for Booking 2 using WALLET (tests weekend + offer)
-- =============================================
-- Booking 2: ₹640 (weekend + Monsoon Special)
INSERT INTO payments (booking_id, amount, status, payment_method) 
VALUES (2, 640, 'paid', 'WALLET');

-- =============================================
-- PAYMENT SCENARIO 6: Sham makes SECOND booking (tests referral reward - should NOT trigger again)
-- =============================================
-- Referral reward (₹100 to Ram) should ONLY happen on Sham's FIRST booking
-- This test verifies reward is not given again

-- First, ensure Sham has sufficient balance (update to ₹1500 for testing)
UPDATE wallets SET amount = amount + 1500 WHERE user_id = 4;

-- Create a new booking for Sham (future date, no offer)
INSERT INTO bookings (user_id, slot_id, booking_date, status) 
VALUES (4, 10, '2026-05-01', 'pending'); -- booking_id = 9

-- Make payment for this second booking
INSERT INTO payments (booking_id, amount, status, payment_method) 
VALUES (8, 500, 'paid', 'WALLET');

-- Check if Ram got another ₹100 (he should NOT - this is Sham's second booking)
-- Ram's balance should still be previous amount (no extra reward)
SELECT 'Ram Balance - No Extra Reward Expected' as Info, amount FROM wallets WHERE user_id = 3;

-- =============================================
-- Create an expired booking for auto-cancel test
-- =============================================

-- Booking that is pending and older than 10 minutes
INSERT INTO bookings (user_id, slot_id, booking_date, status, created_at) 
VALUES (3, 5, '2025-06-25', 'pending', NOW() - INTERVAL 15 MINUTE);

-- Check before event runs
SELECT booking_id, status, created_at 
FROM bookings 
WHERE created_at < NOW() - INTERVAL 10 MINUTE AND status = 'pending';

-- Wait 1 minute or manually check after event runs
-- Event runs every minute automatically

-- Check if cancelled
SELECT booking_id, status, created_at 
FROM bookings 
WHERE booking_id = LAST_INSERT_ID();
-- Expected: status = 'cancelled'




