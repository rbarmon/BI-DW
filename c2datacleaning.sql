select * from MonEquip.ADDRESS;
select * from MonEquip.CATEGORY;
select * from MonEquip.CUSTOMER;
select * from MonEquip.CUSTOMER_TYPE; 
select * from MonEquip.EQUIPMENT;
select * from MonEquip.HIRE;
select * from MonEquip.SALES;
select * from MonEquip.STAFF;

--Number of records in each table
select count(*)  from MonEquip.ADDRESS; --150
select count(*)  from MonEquip.CATEGORY; --15
select count(*)  from MonEquip.CUSTOMER; --153
select count(*)  from MonEquip.CUSTOMER_TYPE;  --2
select count(*)  from MonEquip.EQUIPMENT; --158
select count(*) from MonEquip.HIRE; --304
select count(*)  from MonEquip.SALES; --151
select count(*)  from MonEquip.STAFF; --50

--Relationship Problems
select count(*)  from MonEquip.CUSTOMER; --153 should be 150
select count(*) from MonEquip.HIRE; --304
select count(*)  from MonEquip.SALES; --151
select count(distinct customer_id) from MonEquip.HIRE; --127
select count(distinct customer_id) from MonEquip.Sales; --92

-- Data checks

-- Checking if data is in the right table
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
    
--Check for simple duplicates

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

--Checking for inconsistent values

select count(*)
from Patient
where height > 100;

select count(*)
from Patient
where height < 2.5;

update Patient
set height = height * 100
where height < 2.5;

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


--DATA ERRORS

--Incorrect Values

--unitsalesprice * quantity = total sales price
select * 
from MonEquip.sales 
where unit_sales_price * quantity != total_sales_price;

--Inconsistent Values

-- checking if hire starting date is earlier than end date
select * 
from MonEquip.hire
where start_date > end_date;

--Null Value Problem

--Null Category 

select * from MonEquip.equipment e join MonEquip.category c on e.category_id = c.category_id
where e.category_id = 15;

--Duplication Problems

--customer with 4 counts
select customer_id, count(*)
from MonEquip.customer
group by customer_id
having count(*) > 1;

select * from  MonEquip.customer
where customer_id = 52;

-- Inconsistent Values
select *
from MonEquip.hire
where total_hire_price < 0;

select * 
from MonEquip.sales
where quantity < 0;

select * 
from MonEquip.sales
where quantity < 0;


------------------------------------
-- I dont know what this chunk is--
-----------------------------------
select START_DATE, END_DATE, EQUIPMENT_ID, QUANTITY, UNIT_HIRE_PRICE, TOTAL_HIRE_PRICE, CUSTOMER_ID, STAFF_ID, count(*)
from MonEquip.hire
group by START_DATE, END_DATE, EQUIPMENT_ID, QUANTITY, UNIT_HIRE_PRICE, TOTAL_HIRE_PRICE, CUSTOMER_ID, STAFF_ID
having count(*) > 1;

select SALES_DATE, EQUIPMENT_ID, QUANTITY, UNIT_SALES_PRICE, TOTAL_SALES_PRICE, CUSTOMER_ID, STAFF_ID, count(*)
from MonEquip.sales
group by SALES_DATE, EQUIPMENT_ID, QUANTITY, UNIT_SALES_PRICE, TOTAL_SALES_PRICE, CUSTOMER_ID, STAFF_ID 
having count(*) > 1;

select *
from MonEquip.sales 
where customer_id not in
    (select customer_id
    from  MonEquip.customer c);

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
-----------------------------