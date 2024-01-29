-- 1)Create a view called "sales_revenue_by_category_qtr" that shows the film category and total sales revenue for the current quarter. 
--The view should only display categories with at least one sale in the current quarter. The current quarter should be determined dynamically.

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT category_detail.name AS category,
       COALESCE(SUM(payment_total.amount), 0::numeric) AS total_sales_revenue
FROM category category_detail
JOIN film_category film_cat ON category_detail.category_id = film_cat.category_id
JOIN film film_data ON film_cat.film_id = film_data.film_id
LEFT JOIN inventory inv_detail ON film_data.film_id = inv_detail.film_id
LEFT JOIN rental rental_info ON inv_detail.inventory_id = rental_info.inventory_id
LEFT JOIN payment payment_total ON rental_info.rental_id = payment_total.rental_id
WHERE EXTRACT(YEAR FROM CURRENT_DATE) = EXTRACT(YEAR FROM payment_total.payment_date) 
  AND EXTRACT(QUARTER FROM CURRENT_DATE) = EXTRACT(QUARTER FROM payment_total.payment_date)
GROUP BY category_detail.name
HAVING SUM(payment_total.amount) > 0
ORDER BY total_sales_revenue DESC;

-- 2) Create a query language function called "get_sales_revenue_by_category_qtr" that accepts one parameter representing the current quarter and returns the same result 
--as the "sales_revenue_by_category_qtr" view.

CREATE FUNCTION get_sales_revenue_by_category_qtr(current_qtr DATE)
RETURNS TABLE (category TEXT, total_sales_revenue NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT cat_detail.name AS category,
           COALESCE(SUM(pay_data.amount), 0::numeric) AS total_sales_revenue
    FROM category cat_detail
    JOIN film_category film_cat_link ON cat_detail.category_id = film_cat_link.category_id
    JOIN film film_record ON film_cat_link.film_id = film_record.film_id
    LEFT JOIN inventory inv_record ON film_record.film_id = inv_record.film_id
    LEFT JOIN rental rent_record ON inv_record.inventory_id = rent_record.inventory_id
    LEFT JOIN payment pay_data ON rent_record.rental_id = pay_data.rental_id
    WHERE EXTRACT(YEAR FROM current_qtr) = EXTRACT(YEAR FROM pay_data.payment_date)
      AND EXTRACT(QUARTER FROM current_qtr) = EXTRACT(QUARTER FROM pay_data.payment_date)
    GROUP BY cat_detail.name
    ORDER BY total_sales_revenue DESC;
END;
$$;

--3)Create a procedure language function called "new_movie" that takes a movie title as a parameter and inserts a new movie with the given title in the film table. 
--The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99, the release year to the current year, and "language" as Klingon. 
--The function should also verify that the language exists in the "language" table. Then, ensure that no such function has been created before; if so, replace it.

CREATE OR REPLACE PROCEDURE new_movie(movie_title VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    lang_id INT;
    new_film_id INT;
    current_year INT := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
    -- Check if Klingon language exists
    SELECT language_id INTO lang_id FROM language WHERE name = 'Klingon';
    IF lang_id IS NULL THEN
        RAISE EXCEPTION 'Language Klingon not found in the language table.';
    END IF;

    -- Generate a new unique film ID
    SELECT COALESCE(MAX(film_id), 0) + 1 INTO new_film_id FROM film;

    -- Insert the new movie record with specified attributes
    INSERT INTO film (film_id, title, rental_rate, rental_duration, replacement_cost, release_year, language_id)
    VALUES (new_film_id, movie_title, 4.99, 3, 19.99, current_year, lang_id);
END;
$$;
