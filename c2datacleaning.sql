-- Data Exploration
--SQL statements to explore the operational database, and 

--Tables
--ADDRESS
--CATEGORY
--CUSTOMER
--CUSTOMERTYPE --CUSTOMERTYPE has a typo should be CUSTOMER_TYPE
--EQUIPMENT
--HIRE
--SALES
--STAFF

--select * from MonEquip.<table_name>;

select * from MonEquip.ADDRESS;
select * from MonEquip.CATEGORY;
select * from MonEquip.CUSTOMER;
select * from MonEquip.CUSTOMER_TYPE; 
select * from MonEquip.EQUIPMENT;
select * from MonEquip.HIRE;
select * from MonEquip.SALES;
select * from MonEquip.STAFF;

--1. How many records in the operational database? 
select count(*)  from MonEquip.ADDRESS; --150
select count(*)  from MonEquip.CATEGORY; --15
select count(*)  from MonEquip.CUSTOMER; --153
select count(*)  from MonEquip.CUSTOMER_TYPE;  --2
select count(*)  from MonEquip.EQUIPMENT; --158
select count(*) from MonEquip.HIRE; --304
select count(*)  from MonEquip.SALES; --151
select count(*)  from MonEquip.STAFF; --50

--2. How many records in the data warehouse? 

--3. What kind of data is in the operational database? 

--4. How do the tables look like in the data warehouse?

--Relationship Problems 

select * 
from MonEquip.sales
where equipment_id not in 
    (select equipment_id
    from MonEquip.equipment);
    
select * 
from MonEquip.sales
where customer_id not in 
    (select customer_id
    from MonEquip.customer);
    
select * 
from MonEquip.sales
where staff_id not in 
    (select staff_id
    from MonEquip.staff);

--Relationship Problems
select count(*)  from MonEquip.CUSTOMER; --153 should be 150
select count(*) from MonEquip.HIRE; --304
select count(*)  from MonEquip.SALES; --151

select count(distinct customer_id) from MonEquip.HIRE; --127
select count(distinct customer_id) from MonEquip.Sales; --92

select count(distinct customer_type_id) 
from MonEquip.CUSTOMER;

--Incorrect Values

--sales price negatve
select *
from MonEquip.sales
where unit_sales_price < 0;

--unitsalesprice * quantity = total sales price
select * 
from MonEquip.sales 
where unit_sales_price * quantity != total_sales_price;

--manufacturer year and sales date
select * 
from MonEquip.equipment full outer join monequip.sales on MonEquip.equipment.equipment_id = monequip.sales.equipment_id
where MonEquip.equipment.manufacture_year > MonEquip.sales.sales_date;

--Inconsistent Values

-- checking if hire starting date is earlier than end date
select * 
from MonEquip.hire
where start_date > end_date;

-- checking if sales can not be earlier than the first sale
select * 
from MonEquip.sales
where sales_id < 1;

--Null Value Problems

-- checking if company branch is not null in staff
select *
from MonEquip.staff
where company_branch IS NULL;

-- checking if season is not null in hire
select * 
from MonEquip.hire
where season is null;

-- checking if season is not null in sales
select * 
from MonEquip.sales
where season is null;

--Null Category 

select * from MonEquip.equipment
where category_id = 15;

--checking customer type

select distinct CUSTOMER_TYPE_ID
from MonEquip.customer;

--Duplication Problems

--customer with 4 counts
select customer_id, count(*)
from MonEquip.customer
group by customer_id
having count(*) > 1;

select * from  MonEquip.customer
where customer_id = 52;

--no simple duplicates for hire or sales

select sales_id, count(*)
from MonEquip.sales
group by sales_id
having count(*) > 1;

select hire_id, count(*)
from MonEquip.hire
group by hire_id
having count(*) > 1;

select staff_id, count(*)
from MonEquip.staff
group by staff_id
having count(*) > 1;

select EQUIPMENT_ID, count(*)
from MonEquip.equipment
group by EQUIPMENT_ID
having count(*) > 1;


--SQL statements of the data cleaning,


--20.1.1 Duplication Problems ...................................... 542 
--20.1.1.1 Data Duplication Between Records

--Detecting redundant records with different PK values can be tricky.

--One option is to group by all non-PK attributes. But if the number of non-PK attributes is large, this could be cumbersome.


select START_DATE, END_DATE, EQUIPMENT_ID, QUANTITY, UNIT_HIRE_PRICE, TOTAL_HIRE_PRICE, CUSTOMER_ID, STAFF_ID, count(*)
from MonEquip.hire
group by START_DATE, END_DATE, EQUIPMENT_ID, QUANTITY, UNIT_HIRE_PRICE, TOTAL_HIRE_PRICE, CUSTOMER_ID, STAFF_ID
having count(*) > 1;

select SALES_DATE, EQUIPMENT_ID, QUANTITY, UNIT_SALES_PRICE, TOTAL_SALES_PRICE, CUSTOMER_ID, STAFF_ID, count(*)
from MonEquip.sales
group by SALES_DATE, EQUIPMENT_ID, QUANTITY, UNIT_SALES_PRICE, TOTAL_SALES_PRICE, CUSTOMER_ID, STAFF_ID 
having count(*) > 1;


--20.1.1.2 Data Duplication Between Attributes

--To check if the values of these two attributes are the same, the following SQL command can be used:

--20.1.1.3 Duplication Between Tables

--20.1.2 Relationship Problems ..................................... 545

select *
from MonEquip.sales s
where s.customer_id not in
    select c.customer_id
    from  MonEquip.custome cr;

select *
from <<table 1>>
where <<FK>> not in
select <<PK>>
from <<table 2>>;

update <<table 1>>
set <<FK>> = null
where <<FK>> not in
select <<PK>>
from <<table 2>>;

--20.1.3 Inconsistent Values ......................................... 546 
--20.1.3.1 Inconsistent Values at a Record Level

select *
from MonEquip.hire
where total_hire_price < 0;

select *
from MonEquip.hire
where unit_hire_price < 0;



select count(*)
from Patient
where height > 100;

select count(*)
from Patient
where height < 2.5;

update Patient
set height = height * 100
where height < 2.5;

--20.1.3.2 Inconsistent Values Between Attributes
--20.1.4 Incorrect Values............................................. 550 
--20.1.4.1 Incorrect Value Problem at an Attribute Level
--20.1.4.2 Incorrect Value Problem Between Records
--20.1.4.3 Incorrect Value Problem Between Tables

--20.1.5 Null Value Problems........................................ 551 
--20.1.5.1 Null Value Problems at an Attribute Level
--20.1.5.2 Null Value Problems Between Records
--20.1.5.3 Null Value Problems Between Attributes


-- check if there are illegal students in dw.uselog
select * from dw.uselog
where student_id NOT IN
 (select student_id from dw.student);

-- check if there are illegal majors in dw.student
select *
from dw.uselog, dw.student
where dw.uselog.student_id = dw.student.student_id
and dw.student.major_code NOT IN
 (select major_code from dw.major);


-- check if there are invalid class in dw.student
select *
from dw.uselog, dw.student
where dw.uselog.student_id = dw.student.student_id
and dw.student.class_id NOT IN
 (select class_id from dw.class);
 
 
 -- check if there are records in uselog not in tempfact_uselog
select *
from dw.uselog
where log_date NOT IN
 (select log_date from tempfact_uselog)
and log_time NOT IN
 (select log_time from tempfact_uselog)
and student_id NOT IN
 (select student_id from tempfact_uselog);
 
 
select
 to_char(log_time, 'HH24:MI') log_time,
 log_date,
 student_id,
 act,
 count(*)
from dw.uselog
group by log_time, log_date, student_id, act
having count(*) > 1;
