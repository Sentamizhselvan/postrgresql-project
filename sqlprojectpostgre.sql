Q1: who is the senior most employee based on job title?

select * from employee
ORDER BY levels desc
limit 1;

Q2: which countries have the most invoices?

select COUNT(*) as c,billing_country
from invoice
group by billing_country
order by c desc;

Q3:what are top 3 values of total invoice?

SELECT total FROM invoice
order by total  desc
limit 3;

--Q4: which city has the best customers? we would like to throw a promotional music festival in this city
--we made the most money.write a query that return one city that has the highest sum of invoice totals.
--return both the city name & sum of all invoice totals

select SUM(total) as invoice_total,billing_city
from invoice
group by billing_city
order by invoice_total desc;

--Q5: who is the best customer?the customer who has spent the most money will be
--declared the best customer.write a query that returns the person who has spent the most money

select customer.customer_id,customer.first_name,customer.last_name,SUM(invoice.total) as total
from customer
JOIN invoice on customer.customer_id=invoice.customer_id
group by customer.customer_id
order by total desc
limit 1;

--Q6: write query to return the email,first name,last name,&genre of all rock music listeners.return your list
--ordered alphabetically by email starting with a

SELECT DISTINCT email,first_name,last_name
FROM customer
JOIN invoice on customer.customer_id=invoice.customer_id
JOIN invoice_line on invoice.invoice_id=invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id=genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

--Q7:let's invite the artists who have written the most rock music in our dataset.
--write a query that returns the artist name and total track count of the top 10 rock bands

SELECT artist.artist_id,artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

--Q8: return all the track names that have a song length longer than the average song length.
--return the name and millisecondes for each track.order by the song length with the longest songs listed first.

SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track)
ORDER BY milliseconds DESC;

--Q9:find how much amount spent by each customer no artists?write a query to return customer name,artist name and total spent

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id,artist.name AS artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id,c.first_name,c.last_name,bsa.artist_name,
SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

--Q10: WE want to  find out the most popular music genre for each country.
--we determine the most popular genre as the genre with the highest amount of purchases.

WITH popular_genre AS
(
	SELECT COUNT(invoice_line.quantity) AS purchases,customer.country,genre.name,genre.genre_id,
	ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity)DESC) AS rowNo
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC,1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <=1;

--method 2

WITH RECURSIVE 
	sales_per_country AS(
	SELECT COUNT(*) AS purchases_per_genre,customer.country,genre.name,genre.genre_id
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2
    ),
	max_genre_per_country AS(SELECT MAX(purchases_per_genre) AS max_genre_number,country
			FROM sales_per_country
			GROUP BY 2
			ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number

--Q11:write a query that determines the customer that has spent the most on music for each country.
--write a query that return the country along with the top customer and how much they spent.for countries
--where the top amount spent is shared,provide all customers who spent this amount.

WITH RECURSIVE
	customter_with_country AS(
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),
		
	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)
		
SELECT cc.billing_country,cc.total_spending,cc.first_name,cc.last_name,cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms 
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

