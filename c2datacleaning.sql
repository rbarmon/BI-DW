select * from MonEquip.ADDRESS;
select * from MonEquip.CATEGORY;
select * from MonEquip.CUSTOMER;
select * from MonEquip.CUSTOMER_TYPE; 
select * from MonEquip.EQUIPMENT;
select * from MonEquip.HIRE;
select * from MonEquip.SALES;
select * from MonEquip.STAFF;

-- Preliminary Data checks
--Number of records in each table
select count(*)  from MonEquip.ADDRESS; --150
select count(*)  from MonEquip.CATEGORY; --15
select count(*)  from MonEquip.CUSTOMER; --153
select count(*)  from MonEquip.CUSTOMER_TYPE;  --2
select count(*)  from MonEquip.EQUIPMENT; --158
select count(*) from MonEquip.HIRE; --304
select count(*)  from MonEquip.SALES; --151
select count(*)  from MonEquip.STAFF; --50

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

select START_DATE, END_DATE, EQUIPMENT_ID, QUANTITY, UNIT_HIRE_PRICE, TOTAL_HIRE_PRICE, CUSTOMER_ID, STAFF_ID, count(*)
from MonEquip.hire
group by START_DATE, END_DATE, EQUIPMENT_ID, QUANTITY, UNIT_HIRE_PRICE, TOTAL_HIRE_PRICE, CUSTOMER_ID, STAFF_ID
having count(*) > 1;

select SALES_DATE, EQUIPMENT_ID, QUANTITY, UNIT_SALES_PRICE, TOTAL_SALES_PRICE, CUSTOMER_ID, STAFF_ID, count(*)
from MonEquip.sales
group by SALES_DATE, EQUIPMENT_ID, QUANTITY, UNIT_SALES_PRICE, TOTAL_SALES_PRICE, CUSTOMER_ID, STAFF_ID 
having count(*) > 1;

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

-- DATA ERRORS

-- Duplication Problem

--DATA ERROR: DUPLICATION customer with 4 counts
select customer_id, count(*)
from MonEquip.customer
group by customer_id
having count(*) > 1;

-- Incorrect Values

-- DATA ERROR: INCORRECT VALUE negative TOTAL_HIRE_PRICE in HIRE
select *
from MonEquip.hire
where total_hire_price < 0;

-- DATA ERROR: INCORRECT VALUE negative QUANTITY in SALES
select * 
from MonEquip.sales
where quantity < 0;
--unitsalesprice * quantity != total sales price
select * 
from MonEquip.sales 
where unit_sales_price * quantity != total_sales_price;

-- DATA ERROR: INCORRECT VALUE START_DATE is set as date after the END_DATE
select * 
from MonEquip.hire
where start_date > end_date;

-- DATA ERROR: INCORRECT VALUE START_DATE and END_DATE is set as date in 2090 which has not happened yet.
select * 
from MonEquip.hire
where start_date > to_date('202101','YYYYMM');

-- DATA ERROR: INCORRECT VALUE for TOTAL_HIRE_PRICE. TOTAL_HIRE_PRICE != (End Date - Start Date) * UnitHirePrice * Quantity and is calculated incorrectly
select * 
from MonEquip.hire
where (End_Date - Start_Date) * Unit_Hire_Price * Quantity != total_hire_price;

-- Null Value Problems
--DATA ERROR: Null Category_Description in CATEGORY 
select * from MonEquip.equipment e join MonEquip.category c on e.category_id = c.category_id
where e.category_id = 15;

select * 
from MonEquip.category
where category_description = 'null';


-- Date Cleaning 
-- Duplication Problem
-- CLEAN DUPLICATION ERROR in CUSTOMER TABLE
create table Cleaned_CUSTOMER as
select distinct *
from  MonEquip.customer;

-- Check data is cleaned
select customer_id, count(*)
from Cleaned_CUSTOMER
group by customer_id
having count(*) > 1;

select * from  MonEquip.customer
where customer_id = 52;

-- Incorrect Values

-- CLEANED DATA ERROR: INCORRECT VALUE negative QUANTITY in SALES
select * 
from MonEquip.sales
where quantity < 0;
--unitsalesprice * quantity != total sales price
select * 
from MonEquip.sales 
where unit_sales_price * quantity != total_sales_price;

create table Cleaned_SALES as
select *
from  MonEquip.SALES;

UPDATE Cleaned_SALES
SET QUANTITY = 4
WHERE SALES_ID = 151;

select * 
from Cleaned_SALES
where  SALES_ID = 151;

-- CLEANED DATA ERROR: INCORRECT VALUE START_DATE is set as date after the END_DATE
select * 
from MonEquip.hire
where start_date > end_date;

create table Cleaned_HIRE as
select *
from  MonEquip.HIRE;

UPDATE Cleaned_HIRE
SET START_DATE = TO_DATE('2020/10/17', 'YYYY/MM/DD'), END_DATE = TO_DATE('2020/12/05', 'YYYY/MM/DD')
WHERE HIRE_ID = 302;

select * 
from Cleaned_HIRE
where  HIRE_ID = 302;

-- CLEANED DATA ERROR: INCORRECT VALUE START_DATE and END_DATE is set as date in 2090 which has not happened yet.
select * 
from MonEquip.hire
where start_date > to_date('202101','YYYYMM');

DELETE FROM Cleaned_HIRE WHERE  HIRE_ID = 303;

select * 
from Cleaned_HIRE
where  HIRE_ID = 303;

-- CLEANED DATA ERROR: INCORRECT VALUE for TOTAL_HIRE_PRICE. TOTAL_HIRE_PRICE != (End Date - Start Date) * UnitHirePrice * Quantity and is calculated incorrectly
select * 
from MonEquip.hire
where (End_Date - Start_Date) * Unit_Hire_Price * Quantity != total_hire_price;

SELECT * FROM CLEANED_HIRE;

-- Total hire price is calculated as (End Date - Start Date) * UnitHirePrice * Quantity
UPDATE Cleaned_HIRE
SET total_hire_price = (End_Date - Start_Date) * Unit_Hire_Price * Quantity
WHERE START_DATE != END_DATE;

--  If the customer returns the equipment within the same day, they only need to pay for 50% of the unit hire price.
UPDATE Cleaned_HIRE
SET total_hire_price =  (QUANTITY*Unit_Hire_Price)/2
WHERE START_DATE = END_DATE;

SELECT * FROM monequip.hire;

SELECT * FROM CLEANED_HIRE;

-- CLEANED DATA ERROR: INCORRECT VALUE negative TOTAL_HIRE_PRICE in HIRE
select *
from MonEquip.hire
where total_hire_price < 0;

select * 
from Cleaned_HIRE
where  HIRE_ID = 304;

-- Null Value Problems
--DATA ERROR: Null Category_Description in CATEGORY 
select * from MonEquip.equipment e join MonEquip.category c on e.category_id = c.category_id
where e.category_id = 15;

select * 
from MonEquip.category
where category_description = 'null';

select * 
from MonEquip.category;











