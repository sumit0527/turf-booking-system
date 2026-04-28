-- Question-1: What's the overall health of the business? How much total money has the business made from confirmed bookings?
-- Insight Given: Total revenue earned from successfully completed bookings. This is the #1 KPI for any business.
SELECT 
	SUM(p.amount) as total_revenue
FROM payments p 
JOIN bookings b ON p.booking_id = b.booking_id 
WHERE p.status = "paid" and b.status = "confirmed";

-- Question-2: Which turf generates the most revenue? How do they compare to each other?
-- Insight Given: Identifies star performers vs underperforming turfs. Helps decide where to invest more marketing or maintenance money.
SELECT 
	t.name, 
    SUM(p.amount) as total_revenue 
FROM turfs t 
JOIN slots s ON t.turf_id = s.turf_id 
JOIN bookings b ON s.slot_id = b.slot_id 
JOIN payments p ON b.booking_id = p.booking_id 
WHERE p.status = "paid" AND b.status = "confirmed"
GROUP BY t.name
ORDER BY SUM(p.amount) DESC;
 
-- Question-3: How much more money do we earn on weekends compared to weekdays?
-- Insight Given: Quantifies the revenue difference between weekend and weekday bookings. Helps justify weekend pricing strategy and staffing decisions.
SELECT 
	SUM(CASE WHEN DAYOFWEEK(b.booking_date) IN (2,3,4,5,6) THEN p.amount ELSE 0 END ) AS weekday_revenue, 
	SUM(CASE WHEN DAYOFWEEK(b.booking_date) IN (1,7) THEN p.amount ELSE 0 END ) AS weekend_revenue    
FROM bookings b 
JOIN payments p ON b.booking_id = p.booking_id;

-- Question-4: Who are the top 3 customers who spent the most money?
-- Insight Given: Identifies VIP customers for loyalty programs, special offers, or personalized outreach.
SELECT 
	u.name, 
    SUM(p.amount) as total_spend 
FROM users u 
JOIN bookings b ON u.user_id = b.user_id 
JOIN payments p ON b.booking_id = p.booking_id
WHERE u.role_id = 2
GROUP BY u.name
ORDER BY SUM(p.amount) DESC 
LIMIT 3;

-- Question-5: Which hour of the day gets the most bookings?
-- Insight Given: Identifies peak demand hours for staff scheduling, pricing optimization, and promotional planning.
SELECT
	HOUR(s.start_time) as playing_hour, 
    COUNT(booking_id) as booking_count 
FROM bookings b 
JOIN slots s ON b.slot_id = s.slot_id
GROUP BY HOUR(s.start_time)
ORDER BY COUNT(booking_id) DESC; 

-- Question-6: Are offers bringing more bookings? How many bookings did each offer generate?
-- Insight Given: Shows which offers are most popular. Helps decide which discounts to continue, modify, or discontinue.
SELECT 
	o.offer_name as offer, 
    COALESCE(COUNT(b.booking_id),0) as booking_with_offer
FROM offers o 
LEFT JOIN bookings b ON o.offer_id = b.offer_id
GROUP BY o.offer_name;

-- Question: How many customers came from referrals? How much revenue did they generate?
-- Insight Given: Measures ROI of referral program. Shows if investment in referral rewards is paying off.
SELECT 	
	COUNT(u.user_id) AS total_referred_users,
    SUM(b.final_price) AS total_revenue_from_referred
FROM users u 
JOIN bookings b ON u.user_id = b.booking_id
WHERE referred_by IS NOT NULL AND b.status = "confirmed"
GROUP BY u.user_id;

-- Question-8: How many customers come back for a second, third, or fourth booking?
-- Insight Given: Measures customer loyalty and retention. Low repeat rate = need for engagement campaigns.
WITH cte AS (
SELECT 
	u.name, 
    COUNT(*) as total_bookings 
FROM bookings b 
JOIN users u ON b.user_id = u.user_id 
WHERE status = "confirmed"
GROUP BY u.name
)
SELECT 
	total_bookings as number_of_bookings, 
    COUNT(*) as number_of_customers 
FROM cte
GROUP BY number_of_bookings
ORDER BY number_of_customers;

-- Question-9: What percentage of bookings get cancelled vs confirmed vs pending?
-- Insight Given: Shows booking funnel health. High cancellation rate = problem with pricing, policies, or customer behavior.
SELECT 
	status, 
    COUNT(booking_id) as count, 
    CONCAT(
		ROUND(
        100 * COUNT(*) / (SELECT COUNT(*) FROM bookings),
        1),
    "%") AS percentage
FROM bookings 
WHERE status IN ("pending", "confirmed", "cancelled")
GROUP BY status;

-- Question-10: How do customers prefer to pay? Which payment method is most used?
-- Insight Given: Helps decide which payment gateways to prioritize and whether to incentivize wallet usage.
SELECT 
	payment_method, 
    COUNT(*) as transaction_count, 
    SUM(amount) as total_amount 
FROM payments 
GROUP BY payment_method
ORDER BY SUM(amount) DESC;

-- Question-11: Which hours have low bookings and could benefit from promotions or discounts?
-- Insight Given: Identifies off-peak hours where discounts can drive additional revenue without cannibalizing peak hours.
SELECT
	HOUR(s.start_time) as playing_hour, 
    COUNT(booking_id) as booking_count 
FROM bookings b 
JOIN slots s ON b.slot_id = s.slot_id
GROUP BY HOUR(s.start_time)
ORDER BY COUNT(booking_id); 

-- Question-12: How many customers use wallet? What's the total money stored in wallets?
-- Insight Given: Shows wallet adoption and total locked-in value. Helps decide marketing focus on wallet features.
SELECT 
	COUNT(user_id) as total_wallet_users, 
    SUM(amount) as total_balance, 
    AVG(amount) as avg_balance 
FROM wallets;

-- Question-13: Which day of the week has the most confirmed bookings?
-- Insight Given: Helps plan weekly staffing, maintenance scheduling, and targeted promotions.
SELECT 
	DAYNAME(booking_date) as week_day, 
	COUNT(*) as total_bookings 
FROM bookings  
WHERE status = "confirmed" 
GROUP BY DAYNAME(booking_date)
ORDER BY COUNT(*) DESC; 

-- Question-14: Who are our most valuable customers? How should we segment them by spending?
-- Insight Given: Enables targeted marketing (Platinum = VIP perks, Bronze = win-back campaigns).
SELECT 
	u.name, 
    COALESCE(SUM(b.final_price),0) as total_spend, 
	(CASE 
		WHEN COALESCE(SUM(b.final_price),0) >= 5000 THEN "PLATINUM" 
		WHEN COALESCE(SUM(b.final_price),0) >= 2000 THEN "GOLD"
        WHEN COALESCE(SUM(b.final_price),0) >= 500 THEN "SILVER" 
        ELSE "BRONZE" 
	END 
	) AS tier 
FROM users u  
LEFT JOIN bookings b ON b.user_id = u.user_id 
WHERE u.role_id = 2 AND b.status = "confirmed"
GROUP BY u.name; 

-- Question-15: Do offers actually increase bookings? How does average price compare between bookings with and without offers?
-- Insight Given: Shows if discounts are cannibalizing revenue or driving incremental volume.
SELECT 
	"With Offer" as booking_type,
    ROUND(AVG(final_price),2) as avg_price_paid, 
    COUNT(*) as booking_count 
FROM bookings 
WHERE offer_id IS NOT NULL AND status = "confirmed"
UNION 
SELECT 
	"Without Offer" as booking_type,
    ROUND(AVG(final_price),2) as avg_price_paid, 
    COUNT(*) as booking_count 
FROM bookings 
WHERE offer_id IS NULL AND status = "confirmed";





















