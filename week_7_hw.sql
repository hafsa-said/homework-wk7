Q. 1. Create a new column called “status” in the rental table (yes, add a permanent column) that uses a case statement to indicate if a film was returned late, early, or on time.

ALTER table rental 
add column status varchar; --added a new columnn named status, with variable characters, using add column and alter table
UPDATE rental
SET status =  --this will allow new data to be added
CASE WHEN rental_duration > date_part('day', return_date - rental_date) THEN 'Returned Early'
WHEN rental_duration < date_part('day', return_date - rental_date) THEN 'Returned Late'
ELSE 'Returned On Time'
END
FROM film 
INNER JOIN inventory
ON inventory.film_id = film.film_id;

Q. 2. Show the total payment amounts for people who live in Kansas City or Saint Louis. 

SELECT city, SUM(amount) AS total_payment --need total of payment and city 
FROM city AS c 
JOIN address AS a --need to join address, customer, and payment to get relevant data
ON c.city_id = a.city_id
JOIN customer AS cu
ON a.address_id = cu.address_id
JOIN payment AS p
ON cu.customer_id = p.customer_id
WHERE city IN ('Kansas City', 'Saint Louis') --filter by correct cities
GROUP BY city;

Q. 3. How many films are in each category? Why do you think there is a table for category and a table for film category? 

SELECT c.name, COUNT(fc.film_id) --use count function to get number of films
FROM category AS c
LEFT JOIN film_category AS fc --join film category to get name of category
ON c.category_id = fc.category_id
GROUP BY c.name;

/*There is a table for both maybe to keep film-id separate and more easy to manipulate*/

Q. 4. Show a roster for the staff that includes their email, address, city, and country (not ids)

SELECT s.first_name, s.last_name, s.email, c1.city, c2.country --join table address, city and country to staff for all relevant information
FROM staff AS s
LEFT JOIN address AS a
ON s.address_id = a.address_id
LEFT JOIN city AS c1
ON a.city_id = c1.city_id
LEFT JOIN country AS c2
ON c1.country_id = c2.country_id;

Q. 5. Show the film_id, title, and length for the movies that were returned from May 15 to 31, 2005 

SELECT film.film_id, film.title, film.length --join inventory and rental to get data between required dates
FROM film
INNER JOIN inventory AS i
ON i.film_id = film.film_id
INNER JOIN rental AS r
ON r.inventory_id = i.inventory_id
WHERE return_date BETWEEN '2005-05-15' AND '2005-06-01';

Q. 6. Write a subquery to show which movies are rented below the average price for all movies. 

SELECT title, rental_rate --put a subquery in the where clause to get average price
FROM film
WHERE rental_rate < 
	(SELECT AVG(rental_rate) FROM film);
    
Q. 7. Write a join statement to show which movies are rented below the average price for all movies. 

SELECT f1.title --used a cross join to create conditions, and used having to use agg function
FROM film AS f1
CROSS JOIN film AS f2
GROUP BY f1.title,f1.rental_rate
HAVING(f1.rental_rate < AVG(f2.rental_rate));

Q. 8. Perform an explain plan on 6 and 7, and describe what you’re seeing and important ways they differ. 
       
       FOR QUESTION 6
EXPLAIN ANALYSE SELECT title, rental_rate --put a subquery in the where clause to get average price
FROM film
WHERE rental_rate < 
	(SELECT AVG(rental_rate) FROM film);
       
"Seq Scan on film  (cost=66.51..133.01 rows=333 width=21) (actual time=0.394..0.587 rows=341 loops=1)"
"  Filter: (rental_rate < $0)"
"  Rows Removed by Filter: 659"
"  InitPlan 1 (returns $0)"
"    ->  Aggregate  (cost=66.50..66.51 rows=1 width=32) (actual time=0.379..0.380 rows=1 loops=1)"
"          ->  Seq Scan on film film_1  (cost=0.00..64.00 rows=1000 width=6) (actual time=0.003..0.204 rows=1000 loops=1)"
"Planning Time: 0.165 ms"
"Execution Time: 0.710 ms"
       
       FOR QUESTION 7
EXPLAIN ANALYSE SELECT f1.title --used a cross join to create conditions, and used having to use agg function
FROM film AS f1
CROSS JOIN film AS f2
GROUP BY f1.title,f1.rental_rate
HAVING(f1.rental_rate < AVG(f2.rental_rate));

"HashAggregate  (cost=20130.50..20145.50 rows=333 width=21) (actual time=853.076..854.047 rows=341 loops=1)"
"  Group Key: f1.title, f1.rental_rate"
"  Filter: (f1.rental_rate < avg(f2.rental_rate))"
"  Batches: 1  Memory Usage: 577kB"
"  Rows Removed by Filter: 659"
"  ->  Nested Loop  (cost=0.00..12630.50 rows=1000000 width=27) (actual time=0.032..223.200 rows=1000000 loops=1)"
"        ->  Seq Scan on film f1  (cost=0.00..64.00 rows=1000 width=21) (actual time=0.016..0.586 rows=1000 loops=1)"
"        ->  Materialize  (cost=0.00..69.00 rows=1000 width=6) (actual time=0.000..0.067 rows=1000 loops=1000)"
"              ->  Seq Scan on film f2  (cost=0.00..64.00 rows=1000 width=6) (actual time=0.008..0.412 rows=1000 loops=1)"
"Planning Time: 0.267 ms"
"Execution Time: 854.308 ms"

/*In this situation, the subquery was a much more efficient and quicker way of getting the same information. Nested loops make cross join slower as they require more memory*/

Q. 9. With a window function, write a query that shows the film, its duration, and what percentile the duration fits into.

SELECT title, length AS duration, NTILE(100) OVER (ORDER BY length) AS duration_percentile
FROM film;
/*NTILE() is a window function that distributes rows of an ordered partition into a specified number of approximately equal groups*/

Q. 10. In under 100 words, explain what the difference is between set-based and procedural programming. Be sure to specify which sql and python are.  

Procedural approach tells the system "what to do" along with "how to do" it, example is Python. We query the database to obtain a result set and we write the data operational and manipulation logic using loops, conditions, and processing statements to produce the final result. Set-based approach only tells the system "what to do" not "how to do it", example is SQL. That is, you just specify your requirement for a processed result that has to be obtained from a "set of data" (be it a simple table/view, or joins of tables/views), filtered by optional condition(s).