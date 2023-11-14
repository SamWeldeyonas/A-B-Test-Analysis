-- Create a filtered cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, -- User ID
        COUNT(*) AS session_count -- Count of sessions for each user
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

-- Select data from various tables for the filtered cohort
SELECT 
    u.*, -- User information
    s.*, -- Session information
    f.*, -- Flight information
    h.* -- Hotel information
FROM 
    sessions s
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN 
    users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN 
    flights f ON s.trip_id = f.trip_id
-- Left join with hotels table based on trip_id
LEFT JOIN 
    hotels h ON s.trip_id = h.trip_id
WHERE 
    session_start > '2023-01-04'; -- Filter sessions after '2023-01-04'





-- Calculate the Average Clicks Per Session (ACPS) for a filtered cohort
WITH Cohort AS (
    -- Select user_id for users with more than 7 sessions starting from '2023-01-04'
    SELECT 
        user_id
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

-- Calculate ACPS for each user in the cohort
SELECT 
    s.user_id, -- User ID
    AVG(page_clicks)::FLOAT AS ACPS -- Calculate the average page clicks per session
FROM 
    sessions s
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN 
    users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN 
    flights f ON s.trip_id = f.trip_id
-- Left join with hotels table based on trip_id
LEFT JOIN 
    hotels h ON s.trip_id = h.trip_id
WHERE 
    session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    AND cancellation IS NOT TRUE -- Exclude cancelled sessions
GROUP BY 
    1; -- Group by user_id to calculate ACPS for each user












-- Calculate the Percentage of Flight Bookings under Discount (discount_flight_proportion)
WITH Cohort AS (
    -- Select user_id for users with more than 7 sessions starting from '2023-01-04'
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

-- Calculate the proportion of flight bookings with discounts for each user in the cohort
SELECT 
    SUM(CASE WHEN flight_discount THEN 1 ELSE 0 END) / COUNT(*) AS discount_flight_proportion, -- Calculate the proportion
    s.user_id -- User ID
FROM 
    sessions s
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN 
    users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN 
    flights f ON s.trip_id = f.trip_id
WHERE 
    session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    AND flight_booked IS TRUE -- Filter for sessions with flight bookings
    AND cancellation IS NOT TRUE -- Exclude cancelled sessions
GROUP BY 
    s.user_id; -- Group by user_id to calculate the proportion for each user

















-- Calculate the Average Flight Discount Amount (in percentage terms)
-- The CASE WHEN line is included to avoid null values (flights booked without a discount) being overlooked

WITH Cohort AS (
    -- Select user_id for users with more than 7 sessions starting from '2023-01-04'
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

-- Calculate the average flight discount amount (in percentage terms) for each user in the cohort
SELECT 
    s.user_id, -- User ID
    AVG(
        CASE 
            WHEN flight_discount_amount <> 0 THEN flight_discount_amount -- Use flight_discount_amount if not zero
            ELSE 0 -- Otherwise, use 0
        END
    )::FLOAT AS Average_flight_discount -- Calculate the average discount
FROM 
    sessions s
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN 
    users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN 
    flights f ON s.trip_id = f.trip_id
-- Left join with hotels table based on trip_id
LEFT JOIN 
    hotels h ON s.trip_id = h.trip_id
WHERE 
    session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    AND flight_booked IS TRUE -- Filter for sessions with flight bookings
    AND cancellation IS NOT TRUE -- Exclude cancelled sessions
GROUP BY 
    s.user_id; -- Group by user_id to calculate the average for each user











-- Calculate the Scaled Average Dollars Saved Per Kilometer (ADSPKM)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate the Haversine distance between home and destination airports
Haversine_Table AS (
    SELECT *,
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS((destination_airport_lat - home_airport_lat) / 2)), 2) +
                COS(RADIANS(home_airport_lat)) * COS(RADIANS(destination_airport_lat)) *
                POWER(SIN(RADIANS((destination_airport_lon - home_airport_lon) / 2)), 2)
            )
        ) AS haversine_distance
    FROM (
        SELECT
            s.user_id, s.session_id, s.trip_id, home_airport_lat,
            home_airport_lon,
            destination_airport_lat,
            destination_airport_lon
        FROM sessions s
        LEFT JOIN users u ON s.user_id = u.user_id
        JOIN flights f ON s.trip_id = f.trip_id
    ) AS subquery
),

-- Calculate ADSPKM for each user in the cohort
Metrics AS (
    SELECT
        s.user_id,
        SUM((CASE WHEN flight_discount_amount <> 0 THEN flight_discount_amount ELSE 0 END) * base_fare_usd) / SUM(haversine_distance) AS ADSpkm
    FROM sessions s
    JOIN Cohort ct ON s.user_id = ct.user_id
    LEFT JOIN users u ON s.user_id = u.user_id
    LEFT JOIN flights f ON s.trip_id = f.trip_id
    LEFT JOIN hotels h ON s.trip_id = h.trip_id
    LEFT JOIN Haversine_Table hd ON s.trip_id = hd.trip_id
    WHERE session_start > '2023-01-04' AND flight_booked IS TRUE AND cancellation IS NOT TRUE
    GROUP BY s.user_id
)

-- Scale the calculated ADSPKM for each user
SELECT
    user_id,
    (ADSpkm - MIN(ADSpkm) OVER ()) / (MAX(ADSpkm) OVER () - MIN(ADSpkm) OVER ()) AS scaled_ADSpkm
FROM metrics;











-- Calculate the Scaled Average Browsing Duration Per Session (BDPS)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
), 

-- Calculate BDPS for each user in the cohort
Metrics AS (
    SELECT 
        s.user_id,
        SUM(EXTRACT(EPOCH FROM (session_end - session_start))) / COUNT(*) AS BDPS -- Calculate the average browsing duration per session
    FROM 
        sessions s
    JOIN 
        Cohort ct ON s.user_id = ct.user_id
    LEFT JOIN 
        users u ON s.user_id = u.user_id
    LEFT JOIN 
        flights f ON s.trip_id = f.trip_id
    LEFT JOIN 
        hotels h ON s.trip_id = h.trip_id
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
        AND cancellation IS NOT TRUE -- Exclude cancelled sessions
    GROUP BY 
        1
)

-- Scale the calculated BDPS for each user
SELECT
    mt.user_id,
    (BDPS - MIN(BDPS) OVER ()) / (MAX(BDPS) OVER () - MIN(BDPS) OVER ()) AS scaled_BDPS
FROM 
    metrics mt;












-- Calculate the Average Clicks Per Session (ACPS)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

-- Calculate ACPS for each user in the cohort
SELECT 
    s.user_id, -- User ID
    AVG(page_clicks)::INT AS ACPS -- Calculate the average number of page clicks per session
FROM 
    sessions s
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN 
    users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN 
    flights f ON s.trip_id = f.trip_id
-- Left join with hotels table based on trip_id
LEFT JOIN 
    hotels h ON s.trip_id = h.trip_id
WHERE 
    session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    AND cancellation IS NOT TRUE -- Exclude cancelled sessions
GROUP BY 
    1; -- Group by user_id to calculate ACPS for each user













-- Calculate the Percentage of Hotel Bookings under a Discount

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT user_id
    FROM sessions
    WHERE session_start > '2023-01-04'
    GROUP BY user_id
    HAVING COUNT(*) > 7
)
SELECT 
    s.user_id,
    SUM(CASE WHEN hotel_discount THEN 1 ELSE 0 END)::FLOAT / COUNT(*) AS discount_hotel_proportion
FROM sessions s
-- Join with the Cohort CTE based on user_id
JOIN Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN flights f ON s.trip_id = f.trip_id
-- Left join with hotels table based on trip_id
LEFT JOIN hotels h ON s.trip_id = h.trip_id
WHERE 
    session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    AND hotel_booked IS TRUE -- Filter for sessions with hotel bookings
GROUP BY s.user_id;














-- Calculate the Average Hotel Discount Size

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

SELECT 
    s.user_id, 
    AVG(
        CASE 
            WHEN hotel_discount_amount <> 0 THEN hotel_discount_amount -- Use hotel_discount_amount if not zero
            ELSE 0 -- Otherwise, use 0
        END
    )::FLOAT AS Average_hotel_discount -- Calculate the average hotel discount size
FROM 
    sessions s
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN 
    users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN 
    flights f ON s.trip_id = f.trip_id
-- Left join with hotels table based on trip_id
LEFT JOIN 
    hotels h ON s.trip_id = h.trip_id
WHERE 
    session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    AND hotel_booked IS TRUE -- Filter for sessions with hotel bookings
    AND cancellation IS NOT TRUE -- Exclude cancelled sessions
GROUP BY 
    s.user_id;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
-- Calculate the Scaled Average Dollar Saved for Hotel Discount Amount per Number of Rooms (ADS_scaled_pnr)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate ADS_hotel_pnr for each user in the cohort
Metrics AS (
    SELECT 
        s.user_id,
        SUM(
            (CASE WHEN hotel_discount_amount <> 0 THEN hotel_discount_amount ELSE 0 END) * hotel_per_room_usd
        ) / SUM(rooms) AS ADS_hotel_pnr
    FROM 
        sessions s
    -- Join with the Cohort CTE based on user_id
    JOIN 
        Cohort ct ON s.user_id = ct.user_id
    -- Left join with users table to retrieve user information
    LEFT JOIN 
        users u ON s.user_id = u.user_id
    -- Left join with flights table based on trip_id
    LEFT JOIN 
        flights f ON s.trip_id = f.trip_id
    -- Left join with hotels table based on trip_id
    LEFT JOIN 
        hotels h ON s.trip_id = h.trip_id
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
        AND hotel_booked IS TRUE -- Filter for sessions with hotel bookings
        AND cancellation IS NOT TRUE -- Exclude cancelled sessions
    GROUP BY 
        s.user_id
)

-- Scale the calculated ADS_hotel_pnr for each user
SELECT 
    user_id, 
    (ADS_hotel_pnr - MIN(ADS_hotel_pnr) OVER ()) / (MAX(ADS_hotel_pnr) OVER () - MIN(ADS_hotel_pnr) OVER ()) AS scaled_ADS_hotel_pnr
FROM 
    metrics;











-- Calculate the Scaled Average Number of Rooms Booked (ANRB)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate ANRB (Average Number of Rooms Booked) for each user in the cohort
Metrics AS (
    SELECT 
        s.user_id, 
        AVG(rooms) AS ANRB
    FROM 
        sessions s
    -- Join with the Cohort CTE based on user_id
    JOIN 
        Cohort ct ON s.user_id = ct.user_id
    -- Left join with users table to retrieve user information
    LEFT JOIN 
        users u ON s.user_id = u.user_id
    -- Left join with flights table based on trip_id
    LEFT JOIN 
        flights f ON s.trip_id = f.trip_id
    -- Left join with hotels table based on trip_id
    LEFT JOIN 
        hotels h ON s.trip_id = h.trip_id
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
        AND hotel_booked IS TRUE -- Filter for sessions with hotel bookings
        AND cancellation IS NOT TRUE -- Exclude cancelled sessions
    GROUP BY 
        s.user_id
)

-- Scale the calculated ANRB for each user
SELECT 
    user_id, 
    (ANRB - MIN(ANRB) OVER ()) / (MAX(ANRB) OVER () - MIN(ANRB) OVER ()) AS scaled_ANRB
FROM 
    metrics;
    
    
    
    
    
    
    
    
    
    
    
    -- Calculate the Proportion of Cancellation from All Bookings

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

SELECT 
    s.user_id, 
    SUM(CASE WHEN cancellation THEN 1 ELSE 0 END)::FLOAT / COUNT(*) AS proportion_of_cancelation_from_all_booking
FROM 
    sessions s
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort ct ON s.user_id = ct.user_id
-- Left join with users table to retrieve user information
LEFT JOIN 
    users u ON s.user_id = u.user_id
-- Left join with flights table based on trip_id
LEFT JOIN 
    flights f ON s.trip_id = f.trip_id
-- Left join with hotels table based on trip_id
LEFT JOIN 
    hotels h ON s.trip_id = h.trip_id
WHERE 
    session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    AND hotel_booked IS TRUE -- Filter for sessions with hotel bookings
GROUP BY 
    s.user_id;
    
    
    
    
    
    
    
    




-- Calculate the Normalized Average Time Between Booking and Flight (ATBBF)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate ATBBF (Average Time Between Booking and Flight) for each user in the cohort
Metrics AS (
    SELECT 
        s.user_id, 
        AVG(EXTRACT(EPOCH FROM (departure_time - session_end))) / 86400.00 AS ATBBF -- Calculate ATBBF in days
    FROM 
        sessions s
    -- Join with the Cohort CTE based on user_id
    JOIN 
        Cohort ct ON s.user_id = ct.user_id
    -- Left join with users table to retrieve user information
    LEFT JOIN 
        users u ON s.user_id = u.user_id
    -- Left join with flights table based on trip_id
    LEFT JOIN 
        flights f ON s.trip_id = f.trip_id
    -- Left join with hotels table based on trip_id
    LEFT JOIN 
        hotels h ON s.trip_id = h.trip_id
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
        AND hotel_booked IS TRUE -- Filter for sessions with hotel bookings
    GROUP BY 
        s.user_id
)

-- Calculate the Normalized ATBBF for each user
SELECT
    user_id,
    (1 - (ATBBF - MIN(ATBBF) OVER ()) / (MAX(ATBBF) OVER () - MIN(ATBBF) OVER ())) AS Normalised_ATBBF, -- Normalize ATBBF
    ATBBF -- Original ATBBF value
FROM 
    metrics;
    
    
    
    
    
    
    -- Calculate the Scaled Average Number of Bags Checked (ANBC)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate ANBC (Average Number of Bags Checked) for each user in the cohort
Metrics AS (
    SELECT 
        s.user_id, 
        AVG(checked_bags) AS ANBC
    FROM 
        sessions s
    -- Join with the Cohort CTE based on user_id
    JOIN 
        Cohort c ON s.user_id = c.user_id
    -- Left join with users table to retrieve user information
    LEFT JOIN 
        users u ON s.user_id = u.user_id
    -- Left join with flights table based on trip_id
    LEFT JOIN 
        flights f ON s.trip_id = f.trip_id
    -- Left join with hotels table based on trip_id
    LEFT JOIN 
        hotels h ON s.trip_id = h.trip_id
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
        AND flight_booked IS TRUE -- Filter for sessions with flight bookings
    GROUP BY 
        s.user_id
)

-- Calculate the Scaled ANBC for each user
SELECT 
    user_id,
    (ANBC - MIN(ANBC) OVER ()) / (MAX(ANBC) OVER () - MIN(ANBC) OVER ()) AS scaled_ANBC
FROM 
    Metrics;
    
    
    
    
    
    
    
    
    
    
    
    
-- Calculate the Scaled Average Distance Traveled

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate haversine distances for each user's trips
Haversine_Table AS (
    SELECT *,
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS((destination_airport_lat - home_airport_lat) / 2)), 2) +
                COS(RADIANS(home_airport_lat)) * COS(RADIANS(destination_airport_lat)) *
                POWER(SIN(RADIANS((destination_airport_lon - home_airport_lon) / 2)), 2)
            )
        ) AS haversine_distance
    FROM (
        SELECT
            s.user_id, s.session_id, s.trip_id, home_airport_lat,
            home_airport_lon,
            destination_airport_lat,
            destination_airport_lon
        FROM 
            sessions s
        LEFT JOIN 
            users u ON s.user_id = u.user_id
        JOIN 
            flights f ON s.trip_id = f.trip_id
    ) AS subquery
),

-- Calculate the average distance traveled for each user in the cohort
Metrics AS (
    SELECT 
        s.user_id,
        AVG(hd.haversine_distance) AS average_distance
    FROM 
        sessions s
    -- Join with the Cohort CTE based on user_id
    JOIN 
        Cohort c ON s.user_id = c.user_id
    -- Left join with users table to retrieve user information
    LEFT JOIN 
        users u ON s.user_id = u.user_id
    -- Left join with flights table based on trip_id
    LEFT JOIN 
        flights f ON s.trip_id = f.trip_id
    -- Left join with hotels table based on trip_id
    LEFT JOIN 
        hotels h ON s.trip_id = h.trip_id
    -- Left join with the haversine table to retrieve haversine distances
    LEFT JOIN 
        Haversine_Table hd ON s.trip_id = hd.trip_id
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
        AND cancellation IS NOT TRUE -- Exclude cancelled sessions
    GROUP BY 
        s.user_id
)

-- Scale the calculated average distance traveled for each user
SELECT 
    user_id,
    (average_distance - MIN(average_distance) OVER ()) / (MAX(average_distance) OVER () - MIN(average_distance) OVER ()) AS scaled_average_distance
FROM 
    Metrics;
    
    
    
    
    
    
    
    
    
    
    
    
-- Calculate the Scaled Average Length of Stay (LOS)

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate LOS (Average Length of Stay) for each user in the cohort
Metrics AS (
    SELECT 
        s.user_id, 
        AVG(EXTRACT(EPOCH FROM (departure_time - session_end))) / 86400.00 AS LOS -- Calculate LOS in days
    FROM 
        sessions s
    -- Join with the Cohort CTE based on user_id
    JOIN 
        Cohort c ON s.user_id = c.user_id
    -- Left join with users table to retrieve user information
    LEFT JOIN 
        users u ON s.user_id = u.user_id
    -- Left join with flights table based on trip_id
    LEFT JOIN 
        flights f ON s.trip_id = f.trip_id
    -- Left join with hotels table based on trip_id
    LEFT JOIN 
        hotels h ON s.trip_id = h.trip_id
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
        AND flight_booked IS TRUE -- Filter for sessions with flight bookings
    GROUP BY 
        s.user_id
)

-- Calculate the Scaled LOS for each user
SELECT 
    user_id,
    (LOS - MIN(LOS) OVER ()) / (MAX(LOS) OVER () - MIN(LOS) OVER ()) AS scaled_LOS
FROM 
    Metrics;
    
    
    
    
    
    
    
    
    
    
    
    

-- Calculate the Scaled Age of Users

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
),

-- Calculate the age of users in years
Metric AS (
    SELECT 
        u.user_id, 
        ROUND(('2023-07-29' - birthdate) / 365.25, 0) AS AgeInYears -- Calculate age in years
    FROM 
        users u
    -- Join with the Cohort CTE based on user_id
    JOIN 
        Cohort ct ON u.user_id = ct.user_id
)

-- Calculate the Scaled Age for each user
SELECT 
    user_id, 
    (AgeInYears - MIN(AgeInYears) OVER ()) / (MAX(AgeInYears) OVER () - MIN(AgeInYears) OVER ()) AS scaled_AgeInYears
FROM 
    Metric;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
-- Determine if Users Have Children

-- Create a cohort of users with more than 7 sessions starting from '2023-01-04'
WITH Cohort AS (
    SELECT 
        user_id, 
        COUNT(*) AS session_count
    FROM 
        sessions
    WHERE 
        session_start > '2023-01-04' -- Filter sessions after '2023-01-04'
    GROUP BY 
        user_id
    HAVING 
        COUNT(*) > 7 -- Select users with more than 7 sessions
)

-- Check if users have children
SELECT 
    u.user_id, 
    CASE WHEN has_children THEN 1 ELSE 0 END AS has_children -- 1 if user has children, 0 if not
FROM 
    users u
-- Join with the Cohort CTE based on user_id
JOIN 
    Cohort c ON u.user_id = c.user_id;