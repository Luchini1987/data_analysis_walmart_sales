drop table walmart_sales;

create table if not exists walmart_sales (
	invoice_id varchar(30),
	branch varchar(10),
	city varchar(30),
	customer_type varchar(30),
	gender varchar(10),  
	product_line varchar(100),
	unit_price float(2),
	quantity int,
	tax float(4), 
	total float(4), 
	dates date, 
	times time, 
	payment varchar(30),
	cogs float(2),
	gross_margin_percentage float(9),
	gross_income float(4),
	rating float(2),
	primary key (invoice_id)
)

select *
from walmart_sales 

copy walmart_sales
from 'C:\Users\USER\Documents\SQL\wallmart\WalmartSalesData.csv'
delimiter ','
csv header;

-- Details about the headers :
-- invoice_id, invoice of the sales made
-- branch, office or location where the sale was made
-- city, city at which the sale was made 
-- customer_type, the type of customer
-- gender, the gender of the customer 
-- product_line, indicates the categorie of the product.    
-- unit_price, the value of one product 
-- quantity, the number of products purchased. 
-- tax, the amount of money payed by taxes
-- total, the total amount of money payed by the purchase made   
-- dates, it indicates when the purchase was made  
-- times, it indicates at what time the purchase was made  
-- payment, it indicates what method of payment the customer utilized
-- cogs, cost of goods sold
-- gross_margin_percentage
-- gross_income
-- rating

-- Data Cleaning process:
-- 1.- Checking for duplicate data
select invoice_id, count(*)
from walmart_sales
group by invoice_id
having count(*) > 1   
-- the result is 0 rows, which means that each invoice_id is unique and only  
-- has one record.
-- 2.- Using the distinct function, we are going to look for inconsistencies by
-- each column. 	
select distinct(branch)
from walmart_sales
select distinct(city)
from walmart_sales
select distinct(customer_type)
from walmart_sales
select distinct(gender)
from walmart_sales
select distinct(product_line)
from walmart_sales
select distinct(payment)
from walmart_sales
-- The result was that there aren't neither inconsistencies nor misspellings
-- by each categorie.
-- 3.- looking for null values
select *
from walmart_sales
where invoice_id is null or
	   branch is null or
	   city is null or
	   customer_type is null or
	   gender is null or
	   product_line is null or
	   unit_price is null or
	   quantity is null or
	   tax is null or 
	   total is null or
	   dates is null or
	   times is null or 
	   payment is null or
	   cogs is null or
	   gross_margin_percentage is null or
	   gross_income is null or
	   rating is null
-- The result is there aren't rows with null values.

select *
from walmart_sales
-- 4.- to standardize all the values, we are going to create a copy of the table.
-- At this table, we are going to modify and add columns.

create table copy_walmart_sales as (select * from walmart_sales)

select *
from copy_walmart_sales
-- the result is a new table called 'copy_walmart_sale' 
-- with the same information that the table 'wallmart_sales'

-- We are going to standardize the number of decimal point for each column. 

select round(unit_price::numeric,2)
from copy_walmart_sales

update copy_walmart_sales
set unit_price = round(unit_price::numeric,2) 

update copy_walmart_sales
set tax = round(tax::numeric,2)

update copy_walmart_sales
set total = round(total::numeric,2)

update copy_walmart_sales
set cogs = round(cogs::numeric,2)

update copy_walmart_sales
set gross_margin_percentage = round(gross_margin_percentage::numeric,2)

update copy_walmart_sales
set gross_income = round(gross_income::numeric,2)

-- the result is that all the columns with decimal points has been rounded to
-- 2 decimal points.

-- To carry out a deeper analysis, we are going to split the dates column in three
-- parts(year, month and day).

select extract(year from dates), extract(month from dates),
extract(day from dates)
from copy_walmart_sales 

alter table copy_walmart_sales add column year_purchase integer
alter table copy_walmart_sales add column month_purchase integer
alter table copy_walmart_sales add column day_purchase integer

update copy_walmart_sales
set year_purchase = extract(year from dates) 

update copy_walmart_sales
set month_purchase = extract(month from dates) 

update copy_walmart_sales
set day_purchase = extract(day from dates) 

-- The result is three new columns each one storing the year, month and day.
-- to continue with our analysis, we are going to create a code which 
-- stablishes using the column 'times' whether a purchase was carried out
-- in the morning, in the afternoon or in the evening.

select times,
	case
		when times between '00:00:00' and '11:59:59' then 'morning'
		when times between '12:00:00' and '17:59:59' then 'afternoon'
		else 'evening'
	end as purchase_period
from copy_walmart_sales

-- the following step is create a new column 'purchase period' which will
-- indicate if a purchase was made in the morning, in the afternoon or in 
-- the evening.

alter table copy_walmart_sales add column purchase_period varchar(20) 

update copy_walmart_sales
set purchase_period = case
		when times between '00:00:00' and '11:59:59' then 'morning'
		when times between '12:00:00' and '17:59:59' then 'afternoon'
		else 'evening'
	end  

-- After carrying out the data wrangling, we have data ready to analyse.

-- Exploratory data analysis (EDA)

-- 1.- How many invoices did wallmart issue by month and by year?
select year_purchase,count(distinct(invoice_id))
from copy_walmart_sales
group by year_purchase

-- During 2019, walmart issued 1000 invoices.

select year_purchase, month_purchase, count(distinct(invoice_id))
from copy_walmart_sales
group by year_purchase, month_purchase
order by 3 desc 
-- During 2019, exploring the first three months, january was the month with
-- the most quantity of invoices issued, followed by march and february.

-- 2.- walmart is open almost all day, we want to know at what time did
-- walmart issue the most of invoices? 

with walmart1 as ( 
	select year_purchase, month_purchase, purchase_period,
	count(distinct(invoice_id)) as invoices_number
	from copy_walmart_sales as wal1
	group by 1,2,3 
	order by 2 asc, 4 desc
	)
select *, round(wal3.invoices_number/(
							select sum(wal2.invoices_number)
							from walmart1 as wal2
							where wal2.month_purchase = wal3.month_purchase
							),2)
from walmart1 as wal3
-- checking the results, more than 50% of invoices by month are issued
-- in the afternoon.

--3.- which was the product line that generated the most of sales?

select product_line, round(sum(total):: numeric,2) as total_sales
from copy_walmart_sales
group by 1
order by 2 desc

-- Food and beverage is the product line that generated the highest income
-- followed by sports and travel and Electronic Accesories.

-- 4.- What is the mean, median, minimum value, maximun value and standard
-- deviation of total sales by product line?

with product_sales as(
select product_line, round(sum(total):: numeric,2) as total_sales
from copy_walmart_sales
group by 1
order by 2 desc
	)

select
	round(avg(total_sales),2) as mean,
	round(percentile_cont(0.5) within group(order by total_sales)::numeric,2)
		  as median,
	min(total_sales) as minimun_value,
	max(total_sales) as maximun_value,
	round(stddev(total_sales)::numeric,2) as standard_deviation
from product_sales

--5.- what is the total sale by week considering each month?

-- for answering this question, it's necessary to add a new column which will
-- contain the number of week.

alter table copy_walmart_sales add column number_week integer

-- Inside the column number_week will add an integer which indicates the number of 
-- week using this script:

update copy_walmart_sales
set number_week = extract('week' from dates)


with weekly_summary as (
select case
	when min != max then concat(to_char(to_date(min::text,'MM'),'Month'),' ',
	       				  to_char(to_date(max::text,'MM'),'Month'))
	else to_char(to_date(min::text,'MM'),'Month')
	end , number_week, sum
from (
  	select number_week, sum(weekly_sales),count(month_purchase), min(month_purchase),
	max(month_purchase)
	from (
	select month_purchase, number_week, round(sum(total)::numeric,2) as weekly_sales
	from copy_walmart_sales
	group by 1,2
	order by 1,2
	) table_1
	group by 1
	order by 1
	) table_2
)
select round(avg(sum),2) as mean,
	round(percentile_cont(0.5) within group(order by sum)::numeric,2)
		  as median,
	min(sum) as minimun_value,
	max(sum) as maximun_value,
	round(stddev(sum)::numeric,2) as standard_deviation
from weekly_summary

-- with the above script, we can obtain the mean, median, minimum value, maximun
-- value and standard deviation of the sales by week.

-- 6. what are the different types of payment?

Select distinct(payment)
from copy_walmart_sales 

-- 7. what are the most popular type of payment classified by number of invoices?
select distinct(payment), count(invoice_id)
from copy_walmart_sales
group by 1
order by 2 desc