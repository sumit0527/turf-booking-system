-- add transaction for update wallet balance 
-- DELIMITER $$ 
-- CREATE TRIGGER after_update_wallet_balance 
-- AFTER UPDATE ON wallets 
-- FOR EACH ROW 
-- BEGIN 
-- 	INSERT INTO wallet_transactions (user_id, amount, type, description) VALUES 
--     (NEW.user_id, NEW.amount, "credit", "Wallet Top-Up"); 
-- END $$ 
-- DELIMITER ;

-- generate_coupon_code
DELIMITER $$ 
CREATE TRIGGER generate_coupon_code_wallet_after_userInsert   
BEFORE INSERT ON users 
FOR EACH ROW 
BEGIN
	DECLARE coupon_code VARCHAR(255);
    DECLARE first_name VARCHAR(100);
    DECLARE last_name VARCHAR(100);
		
    IF NEW.role_id = 2 THEN 
		-- extract first and last name
		SET first_name = SUBSTRING_INDEX(UPPER(NEW.name), ' ', 1);
		SET last_name = SUBSTRING_INDEX(UPPER(NEW.name), ' ', -1);
    
		-- Generate unique coupon code
		-- Example: "JOHDO1234"
		SET coupon_code = CONCAT(LEFT(first_name, 3), LEFT(last_name, 2), (NEW.user_id * 739) + 1000);
	
		-- FEATURE 1:
		-- Update user's referral_code column
		IF NEW.referral_code IS NULL THEN 
			SET NEW.referral_code = coupon_code;     -- ✅ directly assign (NO UPDATE)
		END IF;
   END IF;     
    
END $$ 
DELIMITER ;

DELIMITER $$ 
CREATE TRIGGER after_user_insert_wallet 
AFTER INSERT ON users 
FOR EACH ROW 
BEGIN 
	-- FEATURE 2: Create wallet record for new user 
    IF NEW.role_id = 2 THEN 
		INSERT INTO wallets (user_id) VALUES (NEW.user_id);
	END IF;
END $$
DELIMITER ;

DELIMITER $$ 
CREATE TRIGGER after_user_insert_signup_bonus
AFTER INSERT ON users 
FOR EACH ROW 
BEGIN 
	DECLARE referrer_refer_code VARCHAR(100);

    -- FEATURE 1: Check if user was referred by someone
    IF NEW.referred_by IS NOT NULL AND NEW.referral_code IS NOT NULL THEN
        
        SELECT referral_code INTO referrer_refer_code
        FROM users 
        WHERE user_id = NEW.referred_by; 
        
        IF referrer_refer_code = NEW.referral_code THEN 
			-- Create referral record 
			INSERT INTO referrals (referrer_id, referred_user_id, status) 
			VALUES (NEW.referred_by, NEW.user_id, "pending"); 
        
			-- FEATURE 2: Give ₹50 signup bonus to NEW user (not referrer)
			UPDATE wallets 
			SET amount = amount + 50 
			WHERE user_id = NEW.user_id; 
        
			-- FEATURE 3: Record the bonus transaction
			INSERT INTO wallet_transactions (user_id, amount, type, description) 
			VALUES (NEW.user_id, 50, "credit", "Signup bonus from referral");
		END IF;
        
    END IF;
END $$ 
DELIMITER ;

SHOW TRIGGERS WHERE `Table` = 'users';

DELIMITER $$ 
CREATE TRIGGER prevent_double_booking 
BEFORE INSERT ON bookings 
FOR EACH ROW 
BEGIN 
    DECLARE booking_status VARCHAR(50);
    
    -- FEATURE 1: Check if this slot is already booked for this date
    SELECT status INTO booking_status
    FROM bookings 
    WHERE booking_date = NEW.booking_date AND slot_id = NEW.slot_id;
    
    -- FEATURE 2: Block if existing booking is pending OR confirmed
    -- (cancelled bookings are allowed to be rebooked)
    IF booking_status IN ("pending", "confirmed") THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = "Slot was already reserved"; 
    END IF;  
    
END $$ 
DELIMITER ;

DELIMITER $$ 
CREATE TRIGGER after_payment_insert 
AFTER INSERT ON payments 
FOR EACH ROW 
BEGIN 
    DECLARE uid INT;
    DECLARE referrer INT;
    DECLARE reward_amount INT; 
    DECLARE referred_user VARCHAR(100);
    DECLARE user_record_count INT;
    
    SET reward_amount = 100;
    
    -- FEATURE 1: Confirm the booking
    UPDATE bookings 
    SET status = "confirmed" 
    WHERE booking_id = NEW.booking_id; 
    
    -- Get user ID who made this booking
    SELECT user_id INTO uid 
    FROM bookings 
    WHERE booking_id = NEW.booking_id; 
    
    -- Get user name for transaction description
    SELECT name INTO referred_user 
    FROM users  
    WHERE user_id = uid; 
    
    -- Check if this user was referred by someone
    SELECT referred_by INTO referrer 
    FROM users 
    WHERE user_id = uid;
    
    -- FEATURE 2: Give ₹100 referral reward to referrer
    -- ONLY if this is user's FIRST confirmed booking
    IF referrer IS NOT NULL THEN 
        
        -- Count how many confirmed bookings this user has
        SELECT COUNT(*) INTO user_record_count 
        FROM bookings 
        WHERE user_id = uid AND status = "confirmed";
        
        -- If this is FIRST booking (count = 1)
        IF user_record_count = 1 THEN 
            
            -- Add ₹100 to referrer's wallet
            UPDATE wallets 
            SET amount = amount + reward_amount 
            WHERE user_id = referrer; 
            
            -- Record the reward transaction
            INSERT INTO wallet_transactions (user_id, amount, type, description) 
            VALUES (referrer, reward_amount, "credit", CONCAT("Referral reward for referring ", referred_user)); 
            
        END IF;
    END IF;
    
    -- FEATURE 3 & 4: Auto deduct from wallet (if payment method is WALLET)
    IF NEW.payment_method = "WALLET" THEN 
        
        -- FEATURE 3: Deduct amount from user's wallet
        UPDATE wallets 
        SET amount = amount - NEW.amount 
        WHERE user_id = uid; 
        
        -- FEATURE 4: Record debit transaction
        INSERT INTO wallet_transactions (user_id, amount, type, description) 
        VALUES (uid, NEW.amount, "debit", "Payment for Booking");
        
    END IF;
    
END $$
DELIMITER ;

DELIMITER $$ 
CREATE TRIGGER prevent_insufficient_wallet_balance 
BEFORE INSERT ON payments 
FOR EACH ROW 
BEGIN 
    DECLARE user_wallet_balance INT; 
    DECLARE uid INT;
    
    -- Only check for wallet payments (UPI/CARD don't need this check)
    IF NEW.payment_method = "WALLET" THEN 
        
        -- Get user ID from the booking
        SELECT user_id INTO uid 
        FROM bookings 
        WHERE booking_id = NEW.booking_id; 
        
        -- Get current wallet balance
        SELECT amount INTO user_wallet_balance
        FROM wallets
        WHERE user_id = uid;
        
        -- FEATURE 1: Block payment if balance is insufficient
        IF NEW.amount > user_wallet_balance THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = "Insufficient wallet balance."; 
        END IF;
        
    END IF;
END $$
DELIMITER ;

DELIMITER $$ 
CREATE TRIGGER before_booking_pricing_offer 
BEFORE INSERT ON bookings 
FOR EACH ROW 
BEGIN
	DECLARE base_price INT;
    DECLARE discount_perc INT;
    DECLARE day_price INT; 
    DECLARE applied_offer INT;

	IF DAYOFWEEK(NEW.booking_date) IN (1,7) THEN 
         -- get turf base price 
		SELECT price INTO base_price
		FROM pricing_rules 
		WHERE turf_id = (SELECT turf_id FROM slots WHERE slot_id = NEW.slot_id) AND day_type = "weekend";
	ELSE 
		SELECT price INTO base_price
		FROM pricing_rules 
		WHERE turf_id = (SELECT turf_id FROM slots WHERE slot_id = NEW.slot_id) AND day_type = "weekday";
    END IF;
    
    -- fetch available offer
    SELECT offer_id, discount_percent INTO applied_offer, discount_perc
    FROM offers 
    WHERE (turf_id = (SELECT turf_id FROM slots WHERE slot_id = NEW.slot_id) OR turf_id IS NULL) AND NEW.booking_date BETWEEN valid_from AND valid_to
	ORDER BY discount_percent DESC 
    LIMIT 1;
    
    -- final price calculate 
    IF discount_perc IS NOT NULL THEN 
		SET NEW.final_price = base_price - (base_price * discount_perc / 100); 
        SET NEW.offer_id = applied_offer;
	ELSE 
		SET NEW.final_price = base_price;
	END IF;
    
END $$ 
DELIMITER ;


-- Enable event scheduler (one time only)
SET GLOBAL event_scheduler = ON;

CREATE EVENT auto_cancel_unpaid_booking
ON SCHEDULE EVERY 1 MINUTE 
DO 
	-- Automatically cancel bookings that are pending for > 10 minutes
    UPDATE bookings 
    SET status = "cancelled" 
    WHERE status = "pending" AND created_at < NOW() - INTERVAL 10 MINUTE;
    
SHOW events;
