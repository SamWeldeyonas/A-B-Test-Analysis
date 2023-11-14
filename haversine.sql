CREATE OR REPLACE FUNCTION haversine_distance(lat1 float, lon1 float, lat2 float, lon2 float)
RETURNS float AS $$
DECLARE
    radius float = 6371.0; -- Earth's radius in kilometers

    dlat float = RADIANS(lat2 - lat1);
    dlon float = RADIANS(lon2 - lon1);

    a float = SIN(dlat / 2) * SIN(dlat / 2) +
                COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
                SIN(dlon / 2) * SIN(dlon / 2);

    c float = 2 * ATAN2(SQRT(a), SQRT(1 - a));

    distance float = radius * c;
BEGIN
    RETURN distance;
END;
$$ LANGUAGE plpgsql;

