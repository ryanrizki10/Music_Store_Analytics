-- == PROJECT QUERY (Medium Varshavdev) == --
select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;



--1. Find the artist who has contributed with the most albums. Display the artist name and the number of albums.

	-- USING CTE
WITH cte AS(	
	SELECT
		art.name AS artist_name,
		count(alb.title) AS num_song,
		RANK() OVER(ORDER BY count(alb.title) DESC) AS rnk
	FROM
		artist art
	INNER JOIN album alb ON art.artist_id = alb.artist_id
	GROUP BY
		art.name
)

SELECT
	artist_name,
	num_song
FROM
	cte
WHERE
	rnk = 1
	
	-- SUBQUERY
SELECT
	artist_name,
	num_song
FROM (
	SELECT
		art.name AS artist_name,
		count(alb.title) AS num_song,
		RANK() OVER(ORDER BY COUNT(alb.title) DESC) AS rnk
	FROM
		artist art
	INNER JOIN
		album alb ON art.artist_id = alb.artist_id
	GROUP BY
		artist_name
) AS table_1
WHERE
	rnk = 1;

-- 2. Display the name, email id, country of all listeners who love Jazz, Rock and Pop music.
-- name, email, country, genre
SELECT
	CONCAT(c.first_name, ' ', c.last_name) AS full_name,
	c.email,
	c.country,
	g.name AS genre_name
FROM
	customer c
INNER JOIN invoice i ON c.customer_id = i.customer_id
INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
INNER JOIN track t ON il.track_id = t.track_id
INNER JOIN genre g ON t.genre_id = g.genre_id
WHERE
	g.name IN ('Jazz','Rock','Pop')

-- 3. Find the employee who has supported the most of customers. Display the employee name and designation (title).
-- cari employee yang paling banyak di dukung oleh customers.
WITH cte AS(
	SELECT
		CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
		e.title AS designation,
		COUNT(*) num_of_customer,
		RANK() OVER(ORDER BY COUNT(*) DESC) AS rnk
	FROM
		employee e
	INNER JOIN customer c ON e.employee_id = c.support_rep_id
	GROUP BY
		employee_name,
		designation
)
SELECT
	employee_name,
	designation,
	num_of_customer
FROM
	cte
WHERE
	rnk = 1

-- 4.  Which city corresponds to the best customers?

SELECT 
	c.city,
	i.total,
	RANK() OVER(ORDER BY total DESC)
FROM
	customer c
INNER JOIN invoice i ON c.customer_id = i.customer_id

-- 5. The highest number of invoices belongs to which country?
SELECT
	billing_country,
	count(*) AS num_of_billing,
	RANK() OVER(ORDER BY count(*) DESC) AS rnk
FROM
	invoice
GROUP BY
	billing_country;
	
-- 6. Name the best customer (customer who spent the most money).
SELECT
	*
FROM(
	SELECT
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		SUM(i.total) AS total_spend,
		RANK() OVER(ORDER BY SUM(i.total) DESC) AS rnk
	FROM
		customer c
	INNER JOIN invoice i ON c.customer_id = i.customer_id
	GROUP BY
		customer_name
) AS tabel_1
WHERE
	rnk = 1



--7. Suppose you want to host a rock concert in a city and want to know which location should host it.
WITH concert_tbl AS(
	SELECT
		COUNT(c.customer_id) AS total_customer,
		C.city,
		g.name AS genre_name,
		RANK() OVER(ORDER BY COUNT(c.customer_id) DESC) AS rnk
	FROM
		customer c
	INNER JOIN invoice i ON c.customer_id = i.customer_id
	INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
	INNER JOIN track t ON il.track_id = t.track_id
	INNER JOIN genre g ON t.genre_id = g.genre_id
	WHERE
		g.name = 'Rock'
	GROUP BY
		c.city,
		g.name
)

SELECT
	genre_name,
	total_customer
FROM
	concert_tbl
WHERE
	rnk = 1
	
--8. Identify all the albums who have less than 5 track under them.
-- show: Album_title, artist_name and num_of_tracks
WITH count_track AS(
	SELECT
		COUNT(track_id) num_of_tracks,
		album_id
	FROM
		track t
	GROUP BY
		album_id
	HAVING
		COUNT(track_id) <5
	ORDER BY
		num_of_tracks DESC
)

SELECT
	al.title,
	ar.name,
	ct.num_of_tracks
FROM
	album al
INNER JOIN count_track ct ON al.album_id = ct.album_id
INNER JOIN artist ar ON al.artist_id = ar.artist_id
ORDER BY
	ct.num_of_tracks DESC;


--9. Display the track, album, artist and the genre for all tracks which are not purchased.
SELECT
	t.name AS track_name,
	al.title AS album_title,
	ar.name AS artist_name,
	g.name AS genre_name
FROM
	artist ar
INNER JOIN album al ON ar.artist_id = al.artist_id
INNER JOIN track t ON al.album_id = t.album_id
INNER JOIN genre g ON t.genre_id = g.genre_id
WHERE
	NOT EXISTS (
		SELECT
			t.name
		FROM
			invoice_line il
		WHERE
			il.track_id = t.track_id
		)

--10. Find artist who have performed in multiple genres. Display the artist name and the genre
WITH genre_tbl AS
(
	SELECT
		DISTINCT ar.name AS artist_name,
		ge.name AS genre_name
	FROM
		artist ar
	INNER JOIN album al ON ar.artist_id = al.artist_id
	INNER JOIN track tr ON al.album_id = tr.album_id
	INNER JOIN genre ge ON tr.genre_id = ge.genre_id
	ORDER BY
		1,2
),
final_artist AS
(
	SELECT artist_name
	FROM
		genre_tbl gt
	GROUP BY
		artist_name
	HAVING
		COUNT(*) > 1

)
SELECT
	gt.*
FROM
	genre_tbl gt
JOIN final_artist fa ON fa.artist_name = gt.artist_name
ORDER BY
	1,2
	


--11. Which is the most popular and least popular genre?
WITH popular_genre AS(
	SELECT
		g.name AS genre_name,
		COUNT(g.name),
		RANK() OVER(ORDER BY COUNT(g.name) DESC) AS rnk
	FROM
		genre g
	INNER JOIN track t ON g.genre_id = t.genre_id
	GROUP BY
		genre_name
),
max_rank AS(
	SELECT MAX(rnk) AS max_rank FROM popular_genre
)

SELECT
	genre_name,
	CASE WHEN rnk = 1 THEN 'Most Popular Genre' ELSE 'Least Popular Genre' END AS popularity
FROM
	popular_genre
INNER JOIN max_rank ON rnk = max_rank OR rnk = 1

-- 12. Provide a query showing Customers (just their full names, customer ID and country) who are not in the US.
SELECT
	customer_id,
	concat(first_name,' ',last_name) AS full_name,
	country
FROM
	customer
where
	not country = 'USA'

-- 13. Provide a query only showing the Customers from Brazil.
select *
from customer
where country = 'Brazil'


-- 14. Provide a query showing the Invoices of customers who are from Brazil. 
-- The resultant table should show the customer's full name, Invoice ID, Date of the invoice and billing country.
select
	concat(first_name, ' ', last_name) as full_name,
	invoice_id,
	invoice_date,
	billing_country
from
	invoice i
inner join
	customer c on i.customer_id = c.customer_id
where
	c.country = 'Brazil'

-- 15. Provide a query showing only the Employees who are Sales Agents.
select *
from
	employee
where
	title = 'Sales Support Agent'


-- 16. Provide a query showing a unique list of billing countries from the Invoice table.
select 
	distinct billing_country
from
	invoice;


-- 17. Who is the senior most employee based on job title?
select
	*
from
	employee
order by 
	levels desc
limit
	1

-- 18. Which countries have the most Invoices?
select * from invoice

select 
	count(billing_country),
	billing_country
from
	invoice
group by 
	billing_country
order by
	count(billing_country) desc
limit
	1

-- 19. What are top 3 values of total invoice?
	select total
	from invoice
	order by 1 desc
	limit 3

-- 20. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
--     Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.
select
	billing_city,
	round(sum(total),2) as total_invoice
from
	invoice
group by
	billing_city
order by
	total_invoice desc
limit
	1

-- 21. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--     Write a query that returns the person who has spent the most money, full name and the city they lived.
	
select
	customer_id,
	sum(total)
from
	invoice
group by
	customer_id
order by
	sum(total) desc
	
-- OR

select
	c.customer_id,
	concat(c.first_name, ' ', c.last_name) as Full_name,
	c.city,
	sum(i.total) as Total_spent
from
	customer c
join
	invoice i on c.customer_id = i.customer_id
group by
	1,2,3
order by
	total_spent desc


-- 22. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A 
select
	distinct c.email,
	c.first_name,
	c.last_name,
	g.name
from
	customer c
LEFT JOIN invoice i on c.customer_id = i.customer_id
LEFT JOIN invoice_line il on i.invoice_id = il.invoice_id
LEFT JOIN track t on il.track_id = t.track_id
LEFT JOIN genre g on t.genre_id = g.genre_id
WHERE
	g.name = 'Rock'
order by
	c.email 

-- OR (without Genre on display)

SELECT
DISTINCT c.email,
concat (c.first_name, ' ', c.last_name) Full_name
from customer c
LEFT join invoice i on c.customer_id = i.customer_id
LEFT JOIN invoice_line il on i.invoice_id = il.invoice_id
where il.track_id
	in (SELECT
        	t.track_id 
		from track t
        LEFT join genre g on t.genre_id = g.genre_id
        where g.name LIKE 'Rock')
order by 1	


-- 23. Let's invite the artists who have written the most rock music in our dataset. 
--     Write a query that returns the Artist name and total track count of the top 10 rock bands.
select
	a.name,
	count(track_id) as total_track,
	g.name
from
	artist a
left join album al on a.artist_id = al.artist_id
left join track t on al.album_id = t.album_id
left join genre g on t.genre_id = g.genre_id
where
	g.name = 'Rock'
group by
	1,3
order by 2 desc
limit 10

-- 24. Return all the track names that have a song length longer than the average song length. 
--     Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

select
	name,
	milliseconds
from
	track
where milliseconds >
(
	select
		avg(milliseconds) as avg_length
	from
		track
)
order by 2 desc
	

-- 25. Find how much amount spent by each customer on artists. Write a query to return the customer name, artist name, and total spent.

select
	c.customer_id,
	concat(c.first_name, ' ', c.last_name) as full_name,
	ar.name as Artist_name,
	sum(il.quantity*il.unit_price) as total_spent
from
	customer c
JOIN invoice i on c.customer_id = i.customer_id
JOIN invoice_line il on i.invoice_id = il.invoice_id
JOIN track t on il.track_id = t.track_id
JOIN album al on t.album_id = al.album_id
JOIN artist ar on al.artist_id = ar.artist_id
group by
	1,2,3
order by
	total_spent desc

-- OR using CTE

WITH best_selling_artist AS 
	(SELECT a.artist_id AS artist_id, 
		a.name AS artist_name, 
		SUM(il.unit_price * il.quantity) AS total_spent
	 FROM invoice_line il
	 JOIN track t ON t.track_id = il.track_id
	 JOIN album al ON al.album_id = t.album_id
	 JOIN artist a ON a.artist_id = al.artist_id
	 GROUP BY 1
	 ORDER BY 3 DESC)
	 
	 
SELECT c.customer_id AS customer_id, 
	concat (c.first_name, ' ', c.last_name) AS name, 
	bsa.artist_name AS artist_name, 
	(SUM(il.unit_price * il.quantity)) AS total_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC;


-- 26. We want to find out the most popular music Genre for each country. 
--      We determine the most popular genre as the genre with the highest amount of purchases. 
--      Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.



with genre_popular AS
	(select 
	 	count (il.quantity) as purchases,
     	c.country as country,
     	g.name as genre_name,
     	row_number() over (partition by c.country order by COUNT(il.quantity) desc) as row_num
     from
     invoice_line il
     left JOIN invoice i on i.invoice_id = il.invoice_id
     LEFT join customer c on c.customer_id = i.customer_id
     LEFT join track t on t.track_id = il.track_id
     LEFT join genre g on g.genre_id = t.genre_id
     GROUP by 2,3
     order by 1 desc)
select
country,
genre_name,
purchases
from genre_popular
where row_num <= 1



--
SELECT 
    COUNT(il.quantity) AS purchases,
    c.country AS country,
    g.name AS genre_name,
    ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS row_num
FROM
    invoice_line il
LEFT JOIN 
    invoice i ON i.invoice_id = il.invoice_id
LEFT JOIN 
    customer c ON c.customer_id = i.customer_id
LEFT JOIN 
    track t ON t.track_id = il.track_id
LEFT JOIN 
    genre g ON g.genre_id = t.genre_id
GROUP BY 
    c.country, g.name
ORDER BY 
    c.country, purchases DESC;
	
	
	
	
-- contoh = -- ambil country, genre_name, num_of_purchase,
-- step pertama: cari top genre dari masing masing negara ( top genre = total pembelian terbanyak)
select
	country,
	name,
	purchases
from (
	select
		c.country,
		g.name,
		sum(il.quantity) AS purchases,
		row_number() over(partition by c.country order by sum(il.quantity) desc) as row_num
	from
		customer c
	left join invoice i on c.customer_id = i.customer_id
	left join invoice_line il on i.invoice_id = il.invoice_id
	left join track t on il.track_id = t.track_id
	left join genre g on t.genre_id = g.genre_id
	group by
		c.country,
		g.name
	order by
		purchases desc
)
where
	row_num <= 1


-- 27. Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

-- step 1: cari customer yang menghabiskan paling banyak musik pada setiap country
-- step 2: tampilkan country, top customer, how much they spent


with customer_country AS
	(SELECT
     c.customer_id,
     concat (c.first_name, ' ', c.last_name) name,
     billing_country,
     sum(total) as total_spent,
     row_number ()
     over (partition by billing_country 
           ORDER by sum(total) DESC) row_num
     from invoice i
     LEFT join customer c on c.customer_id = i.customer_id
     group by 1, 2, 3
     order by 4, 5 DESC)
SELECT
	customer_id,
    name,
    billing_country,
    total_spent
from customer_country
WHERE
row_num = 1


-- 28. Who are the most popular artists?
select
	a.name,
	count(il.quantity) AS quantity
from
	artist a
left join album al on a.artist_id = al.artist_id
left join track t on al.album_id = t.album_id
left join invoice_line il on t.track_id = il.track_id 
group by
	a.name
order by
	2 desc

 -- 29. Which is the most popular song? = yang paling banyak quantity-nya
 -- track_id, album, invoice_line
 
select
	a.title,
	count(il.quantity) as Amount_of_sales
from
	album a
left join track t on a.album_id = t.album_id
left join invoice_line il on t.track_id = il.track_id
group by
	a.title
order by
	Amount_of_sales desc;
 
-- 30. What are the most popular countries for music purchases?

SELECT
	COUNT (il.quantity) purchases,
	c.country country
from 
	invoice_line il
LEFT join invoice i on i.invoice_id = il.invoice_id
LEFT join customer c on c.customer_id = i.customer_id
GROUP by 2
order by 1 desc




SELECT 
  g.name AS genre,
  SUM(il.quantity) AS tracks_sold,
  ROUND(CAST(SUM(il.quantity) AS FLOAT)/
  (
    SELECT SUM(il.quantity) 
    FROM invoice i
    INNER JOIN invoice_line il
    ON i.invoice_id = il.invoice_id	
    WHERE i.billing_country = 'USA'
  ) 
  , 4) AS percentage_sold
FROM invoice i
INNER JOIN invoice_line il
ON i.invoice_id = il.invoice_id
INNER JOIN track t 
ON il.track_id = t.track_id
INNER JOIN genre g
ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY genre
ORDER BY tracks_sold DESC



--===-- INTERVIEW TASK ====

-- 31. Which Employee has the Highest Total Number of Customers?
SELECT
	concat(e.first_name, ' ', e.last_name) emp_full_name,
	count(c.customer_id) as total_customer,
	e.title
FROM employee e
INNER JOIN customer c on e.employee_id = c.support_rep_id
GROUP BY
	1,3
ORDER BY
	2 DESC;


-- 32. Who are our top 5 Customers according to Invoices? 

select
	concat(c.first_name, ' ', c.last_name) as cust_full_name,
	sum(i.total) as total_spent
from
	invoice i
inner join customer c on i.customer_id = c.customer_id
group by
	1
order by
	2 desc
limit 5

-- 33. Who are the Rock Music Listeners? We want to know all Rock Music listeners’ email, first names, last names, and Genres.
select
	c.email,
	c.first_name,
	c.last_name,
	g.name
from
	customer c
inner join invoice i on c.customer_id = i.customer_id
inner join invoice_line il on i.invoice_id = il.invoice_id
inner join track t on il.track_id = t.track_id
inner join genre g on t.genre_id = g.genre_id
	where g.name = 'Rock'
group by
	1,2,3,4
order by 1;


-- 34. Who is the most top 10 writing the rock music?

select
	ar.name,
	count(g.genre_id) as total_rock
from
	artist ar
inner join album al on ar.artist_id = al.artist_id
inner join track t on al.album_id = t.album_id
inner join genre g on t.genre_id = g.genre_id
where
	g.name = 'Rock'
group by
	ar.name
order by total_rock desc
limit 10;


-- 35. Which artist has earned the most according to the Invoice Lines? Use this artist to find which customer spent the most on this artist.
--Top 5 Artist that has earned the most.
select
	ar.name as artist_name,
	sum(il.unit_price*il.quantity) total_earned
from
	artist ar
inner join album al on ar.artist_id = al.artist_id
inner join track t on al.album_id = t.album_id
inner join invoice_line il on t.track_id = il.track_id
group by
	ar.name
order by
	total_earned desc
limit 5;

		

-- 36. List the Tracks that have a song length greater than the Average song length.
select
	name,
	milliseconds as song_length
from
	track
where milliseconds > (
		select
		round(avg(milliseconds),2) as avg_song_length
	from
		track
)
group by
	1,2
order by
	2 desc
LIMIT 10



