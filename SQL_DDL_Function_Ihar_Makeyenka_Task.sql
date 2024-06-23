CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT 
    c.name AS category,
    SUM(p.amount) AS total_sales_revenue
FROM 
    payment p
    JOIN rental r ON p.rental_id = r.inventory_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
WHERE 
    EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    c.name
HAVING 
    SUM(p.amount) > 0;

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(p_current_quarter INT)
RETURNS TABLE(category_name VARCHAR, total_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name::VARCHAR AS category_name,
        SUM(p.amount) AS total_revenue
    FROM 
        payment p
    JOIN 
        rental r ON p.rental_id = r.inventory_id
    JOIN 
        inventory i ON r.inventory_id = i.inventory_id
    JOIN 
        film f ON i.film_id = f.film_id
    JOIN 
        film_category fc ON f.film_id = fc.film_id
    JOIN 
        category c ON fc.category_id = c.category_id
    WHERE 
        EXTRACT(QUARTER FROM r.rental_date) = p_current_quarter
    GROUP BY 
        c.name
    ORDER BY 
        total_revenue DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION new_movie(movie_title TEXT) RETURNS VOID AS $$
DECLARE
    new_film_id INT;
    klingon_language_id INT;
    current_year INT := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
    SELECT language_id INTO klingon_language_id
    FROM language
    WHERE name = 'Klingon';
    
    IF klingon_language_id IS NULL THEN
        INSERT INTO language (language_id, name)
        VALUES ((SELECT COALESCE(MAX(language_id), 0) + 1 FROM language), 'Klingon');
        
        SELECT language_id INTO klingon_language_id
        FROM language
        WHERE name = 'Klingon';
    END IF;

    SELECT COALESCE(MAX(film_id), 0) + 1 INTO new_film_id FROM film;

    INSERT INTO film (film_id, title, release_year, rental_rate, rental_duration, replacement_cost, language_id)
    VALUES (new_film_id, movie_title, current_year, 4.99, 3, 19.99, klingon_language_id);
END;
$$ LANGUAGE plpgsql;


