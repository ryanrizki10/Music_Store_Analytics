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

-- Mengubah tipe data double precision to INT
ALTER TABLE invoice
ALTER COLUMN total
SET DATA TYPE INT;


select *
from artist
where name = 'Iron Maiden'






-- 1. Provide a query showing Customers (just their full names, customer ID and country) who are not in the US.
SELECT
	customer_id,
	concat(first_name,' ',last_name) AS full_name,
	country
FROM
	customer
where
	not country = 'USA'

-- 2. Provide a query only showing the Customers from Brazil.
select *
from customer
where country = 'Brazil'


-- 3. Provide a query showing the Invoices of customers who are from Brazil. 
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

-- 4. Provide a query showing only the Employees who are Sales Agents.
select *
from
	employee
where
	title = 'Sales Support Agent'


-- 5. Provide a query showing a unique list of billing countries from the Invoice table.
select 
	distinct billing_country
from
	invoice
	
--- ========= ---


-- Q1. Who is the senior most employee based on job title?
select
	*
from
	employee
order by 
	levels desc
limit
	1

-- Q2. Which countries have the most Invoices?
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

-- Q3. What are top 3 values of total invoice?
	select total
	from invoice
	order by 1 desc
	limit 3

-- Q4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
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

-- Q5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
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


-- Q6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. 
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


-- Q7. Let's invite the artists who have written the most rock music in our dataset. 
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

-- Q8. Return all the track names that have a song length longer than the average song length. 
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
	

-- Q9. Find how much amount spent by each customer on artists. Write a query to return the customer name, artist name, and total spent.

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


-- Q10. We want to find out the most popular music Genre for each country. 
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


-- Q11. Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

-- step 1: cari customer yang menghabiskan paling banyak musik pada setiap country
-- step 2: tampilkan country, top customer, how much they spent
-- 


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


-- Q12. Who are the most popular artists?
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

 -- Q13. Which is the most popular song? = yang paling banyak quantity-nya
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
 
 -- Q14. What are the most popular countries for music purchases?

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

--1. Which Employee has the Highest Total Number of Customers?
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


--2. Who are our top 5 Customers according to Invoices? 

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

--3. Who are the Rock Music Listeners? We want to know all Rock Music listeners’ email, first names, last names, and Genres.
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


--4. Who is the most top 10 writing the rock music?

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


--5. Which artist has earned the most according to the Invoice Lines? Use this artist to find which customer spent the most on this artist.
	
	--a. Top 5 Artist that has earned the most.
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

		

--6. List the Tracks that have a song length greater than the Average song length.
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


--------



