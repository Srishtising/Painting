--1) Fetch all the paintings which are not displayed on any museums?
select * from painting..work$ where museum_id is null;

--2) Are there museuems without any paintings?
select count(*) from painting..museum$ where museum_id not in
(
select distinct museum_id from painting..work$
) 

--3) How many paintings have an asking price of more than their regular price? 
select * from painting..product_size$
where sale_price > regular_price

--4) Identify the paintings whose asking price is less than 50% of its regular price
select * from painting..product_size$
where sale_price < (regular_price*0.5)

--5) Which canva size costs the most?
select c.label as canvas, s.sale_price from painting..canvas_size$ as c join painting..product_size$ as s on c.size_id=s.size_id
order by sale_price desc
OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY



--7) Identify the museums with invalid city information in the given dataset
select * from painting..museum$
where city not like '%[^0-9]%'

--8) Museum_Hours table has 1 invalid entry. Identify it and remove it.

--9) Fetch the top 10 most famous painting subject
select subject, count(*) from painting..subject$ group by subject
order by count(*) desc
offset 0 rows fetch first 10 rows only

--10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select m.name, m.city from painting..museum$ as m join painting..museum_hours$ as h on m.museum_id=h.museum_id where h.day = 'Sunday' 
and exists (select 1 from painting..museum_hours$ mh2 
				where mh2.museum_id=h.museum_id 
			    and mh2.day='Monday');

--11) How many museums are open every single day?
with ct1 as
(
select museum_id, count(1) as tot from  painting..museum_hours$ as h group by museum_id having count(1) = 7
)
select count(1) from ct1;

--12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
select w.museum_id, m.name, count(1) as No_of_paintings from painting..work$ as w join painting..museum$ as m on w.museum_id=m.museum_id
group by w.museum_id,m.name
order by 3 desc
offset 0 rows fetch first 5 rows only

--13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select w.artist_id,a.full_name, count(1) as Total_work from painting..work$ as w join painting..artist$ as a on w.artist_id=a.artist_id 
group by w.artist_id, a.full_name
order by 3 desc
offset 0 rows fetch first 5 rows only

--14) Display the 3 least popular canva sizes
select c.size_id,c.label, count(1) as Total from painting..work$ as w join painting..product_size$ as p on w.work_id=p.work_id join painting..canvas_size$ as c on p.size_id=c.size_id
group by c.size_id, c.label
order by 3 desc
offset 0 rows fetch first 3 rows only

--16) Which museum has the most no of most popular painting style?
with v as
(
 select style, count(1) as  tot,rank() over(order by count(1) desc) as rnk from painting..work$ group by style
),
ct1 as(
select w.museum_id,m.name as museum_name,v.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
 from painting..work$ as w join painting..museum$ as m on w.museum_id=m.museum_id join v on w.style=v.style
 where m.museum_id is not null and v.rnk=1
 group by  w.museum_id,m.name,v.style
 )
 select museum_name, no_of_paintings from ct1 where rnk=1

 --17) Identify the artists whose paintings are displayed in multiple countries
 with ct1 as(
 select distinct a.full_name, m.country from painting..museum$ as m
 join painting..work$ as w on m.museum_id=w.museum_id join painting..artist$ as a on w.artist_id=a.artist_id
 
 )
 select full_name,count(1) as no_of_country from ct1 group by full_name
 having count(1)>1
 order by 2 desc;

  --or
  

  with ct1 as(
 select a.full_name, m.country, count(1) as tot from painting..museum$ as m
 join painting..work$ as w on m.museum_id=w.museum_id join painting..artist$ as a on w.artist_id=a.artist_id
 group by a.full_name,m.country
 
 )
 select full_name,count(1) as no_of_country from ct1 group by full_name
 having count(1)>1
 order by 2 desc

 --18) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
    --    If there are multiple value, seperate them with comma.
	with con as(
	select city,count(1) as tot, rank() over(order by count(1) desc) as rnk from painting..museum$ where city is not null group by city
	),
	city as(
	select country,count(1) as tot, rank() over(order by count(1) desc) as rnk from painting..museum$ group by country
	)
	select string_agg(con.city,' ,') as city, string_agg(city.country, ' ,')as country from con cross join city where con.rnk=1 and city.rnk=1
 
 --19) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
 --Display the artist name, sale_price, painting name, museum name, museum city and canvas label

 with ct1 as(
 select *, rank() over(order by sale_price desc) as low_price, rank() over(order by sale_price) high_price from painting..product_size$
 )
 select distinct a.full_name, ct1.sale_price, w.name, m.name,m.city, w.work_id from ct1 join painting..work$ as w on ct1.work_id=w.work_id join painting..museum$ as m on w.museum_id=m.museum_id join painting..artist$ as a 
 on w.artist_id=a.artist_id
 where ct1.low_price=1 or ct1.high_price=1

 --20) Which country has the 5th highest no of paintings?
 with ct1 as(
select country, count(1) as tot, rank() over(order by count(1) desc) as rnk from painting..museum$ group by country
)
select country, tot from ct1 where rnk=5

--21) Which are the 3 most popular and 3 least popular painting styles?
with ct1 as(
select style, count(1) as tot, rank() over(order by count(1) desc) as topp, rank() over(order by count(1)) bot from painting..work$
where style is not null
group by style
)
select style, case when topp<=3 then 'Most Popular' else 'Least Popular' end as popularity from ct1 where topp<=3 or bot<=3

--22) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
with ct1 as(
select a.full_name, a.nationality, count(1) as tot, rank() over(order by count(1) desc) as rnk
from 
   painting..work$ as w 
   join painting..museum$ as m on w.museum_id=m.museum_id 
   join painting..artist$ as a on w.artist_id=a.artist_id 
   join painting..subject$ as s on w.work_id=s.work_id
   where m.country!='USA' and s.subject='Portraits'
group by a.full_name, a.nationality
) 
select full_name, nationality from ct1 where rnk=1