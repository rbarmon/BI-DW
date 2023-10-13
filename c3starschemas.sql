--a) SQL statements (e.g. create table, insert into, etc) to create the star/snowflake schema Version-1

--select * from MonEquip.<table_name>;

-- Create CustomerTypeDIM by Direct Copy
DROP TABLE CustomerTypeDIM CASCADE CONSTRAINTS PURGE;
create table CustomerTypeDIM as 
select * from MonEquip.CUSTOMER_TYPE;

select * from CustomerTypeDIM;

-- Create CategoryDIM by Direct Copy
DROP TABLE CategoryDIM CASCADE CONSTRAINTS PURGE;
create table CategoryDIM as 
select * from MonEquip.CATEGORY;

-- Create TimeDIM using Temp
DROP TABLE TimeDIM CASCADE CONSTRAINTS PURGE;

-- But you have to get it from both tables
-- The operational database records the transaction from April 2018 to December 2020

select * from MonEquip.SALES;
select * from MonEquip.HIRE;

DROP TABLE TimeDimSalesTemp CASCADE CONSTRAINTS PURGE;

create table TimeDimSalesTemp as 
SELECT DISTINCT to_char(SALES_DATE, 'YYYYMM') AS Time_ID,
to_char(SALES_DATE, 'MM') as Time_Month, 
to_char(SALES_DATE, 'YYYY') as Time_Year 
from MonEquip.SALES;

select * from TimeDimSalesTemp;

create table TimeDimHireTemp as 
SELECT DISTINCT to_char(START_DATE, 'YYYYMM') AS Time_ID,
to_char(START_DATE, 'MM') as Time_Month, 
to_char(START_DATE, 'YYYY') as Time_Year 
from MonEquip.HIRE;

select * from TimeDimHireTemp;


create table TimeDim as
SELECT DISTINCT Time_ID, Time_Month, Time_Year
from (
SELECT Time_ID, Time_Month, Time_Year from TimeDimSalesTemp
    union all
SELECT Time_ID, Time_Month, Time_Year from TimeDimHireTemp
);

select * from TimeDim;

-- Create SeasonDIM 
-- [Australian Season: Summer, Winter, Autumn, Spring

DROP TABLE SeasonDIM CASCADE CONSTRAINTS PURGE;
--Summer (December, January, February)
--Autumn (March, April, May)
--Winter (June, July, August)
--Spring (September, October, November)
create table SeasonDIM
(Season VARCHAR2(6),
Description varchar2(20));

insert into SeasonDIM values ('Summer', 'Dec-Feb');
insert into SeasonDIM values ('Autumn', 'Mar-May');
insert into SeasonDIM values ('Winter', 'Jun-Aug');
insert into SeasonDIM values ('Spring', 'Sep-Nov');

-- Create CompanyBranchDIM

DROP TABLE Company_BranchDIM CASCADE CONSTRAINTS PURGE;

select distinct Company_Branch from MonEquip.Staff;

create table Company_BranchDIM as
select distinct Company_Branch from MonEquip.Staff;

select * from Company_BranchDIM;

-- Create SalesPriceScaleDIM 
-- Sales price scale: low sales <$5,000; medium sales between $5,000 and $10,000; high sales > $10,000
DROP TABLE SalesPriceScaleDIM CASCADE CONSTRAINTS PURGE;

create table SalesPriceScaleDIM
(SalesPriceScale VARCHAR2(6),
Description varchar2(30));

insert into SalesPriceScaleDIM values ('Low', '< $5,000');
insert into SalesPriceScaleDIM values ('Medium', 'between $5,000 and $10,000');
insert into SalesPriceScaleDIM values ('High', '> $10,000');

select * from SalesPriceScaleDIM;

-- Create HireFACT_V1 and SalesFACT_V1 using TempFacts
-- Create HireFACT_V1 
-- HireFact attributes
--Season, Company_Branch, Customer_Type_ID, Category_ID, Time_ID

select * from MonEquip.EQUIPMENT; -- all them are distinct
select * from MonEquip.HIRE;
select * from MonEquip.SALES;


DROP TABLE HireTempFact_V1 CASCADE CONSTRAINTS PURGE;

create table HireTempFact_V1 as 
select 
to_char(H.START_DATE, 'YYYYMM') AS Time_ID,
to_char(H.START_DATE, 'MM') as Month, -- Need for Season
S.COMPANY_BRANCH,
C.CUSTOMER_TYPE_ID,
E.CATEGORY_ID,
H.START_DATE,
H.END_DATE,
H.QUANTITY, -- for NUMBER_OF_EQUIPMENT
H.UNIT_HIRE_PRICE,
H.TOTAL_HIRE_PRICE, -- for Total_Revenue
H.EQUIPMENT_ID
from MonEquip.HIRE H, MonEquip.CUSTOMER C, MonEquip.EQUIPMENT E, MonEquip.STAFF S 
where H.EQUIPMENT_ID = E.EQUIPMENT_ID AND
H.STAFF_ID = S.STAFF_ID AND
H.CUSTOMER_ID = C.CUSTOMER_ID;

SELECT * FROM HireTempFact_V1;

alter table HireTempFact_V1 add 
(Season VARCHAR2(6));
update HireTempFact_V1 
set Season = 'Summer' 
where Month >= '12' 
OR Month <= '02';

update HireTempFact_V1 
set Season = 'Autumn' 
where Month >= '03' 
and Month <= '05';

update HireTempFact_V1 
set Season = 'Winter' 
where Month >= '06' 
and Month <= '08';

update HireTempFact_V1 
set Season = 'Spring' 
where Month >= '09' 
and Month <= '11';


SELECT * FROM HireTempFact_V1;

DROP TABLE HireFact_V1 CASCADE CONSTRAINTS PURGE;

create table HireFact_V1 as 
select 
Season, 
Company_Branch, 
Customer_Type_ID, 
Category_ID, 
Time_ID,
sum(QUANTITY) AS NUMBER_OF_EQUIPMENT_HIRED,
sum(TOTAL_HIRE_PRICE) AS TOTAL_REVENUE_FOR_HIRING,
AVG(UNIT_HIRE_PRICE) AS AVERAGE_HIRE_PRICE
from HireTempFact_V1 
group by
Season, 
Company_Branch, 
Customer_Type_ID, 
Category_ID, 
Time_ID,
EQUIPMENT_ID;

SELECT * FROM HireFact_V1;

-- Create SalesFACT_V1
-- SalesFact attributes
--Season, Company_Branch, Customer_Type_ID, Category_ID, Time_ID, SalesPriceScale
-- Sales price scale: low sales <$5,000; medium sales between $5,000 and $10,000; high sales > $10,000

select * from MonEquip.SALES;

DROP TABLE SalesTempFact_V1 CASCADE CONSTRAINTS PURGE;

create table SalesTempFact_V1 as 
select 
to_char(SA.SALES_DATE, 'YYYYMM') AS Time_ID,
to_char(SA.SALES_DATE, 'MM') as Month, -- Need for Season
S.COMPANY_BRANCH,
C.CUSTOMER_TYPE_ID,
E.CATEGORY_ID,
SA.SALES_DATE,
SA.QUANTITY, -- for NUMBER_OF_EQUIPMENT
SA.UNIT_SALES_PRICE,
SA.TOTAL_SALES_PRICE, -- for Total_Revenue
SA.EQUIPMENT_ID
from MonEquip.SALES SA, MonEquip.CUSTOMER C, MonEquip.EQUIPMENT E, MonEquip.STAFF S 
where SA.EQUIPMENT_ID = E.EQUIPMENT_ID AND
SA.STAFF_ID = S.STAFF_ID AND
SA.CUSTOMER_ID = C.CUSTOMER_ID;

SELECT * FROM SalesTempFact_V1;

alter table SalesTempFact_V1 add 
(Season VARCHAR2(6));
update SalesTempFact_V1 
set Season = 'Summer' 
where Month >= '12' 
OR Month <= '02';

update SalesTempFact_V1 
set Season = 'Autumn' 
where Month >= '03' 
and Month <= '05';

update SalesTempFact_V1 
set Season = 'Winter' 
where Month >= '06' 
and Month <= '08';

update SalesTempFact_V1 
set Season = 'Spring' 
where Month >= '09' 
and Month <= '11';


SELECT * FROM SalesTempFact_V1;

-- Sales price scale: low sales <$5,000; medium sales between $5,000 and $10,000; high sales > $10,000
alter table SalesTempFact_V1 add 
(SalesPriceScale VARCHAR2(6));

update SalesTempFact_V1 
set SalesPriceScale = 'Low'
where UNIT_SALES_PRICE < 5000; 

update SalesTempFact_V1 
set SalesPriceScale = 'Medium' 
where UNIT_SALES_PRICE >= 5000 
and UNIT_SALES_PRICE <= 10000;

update SalesTempFact_V1 
set SalesPriceScale = 'High' 
where UNIT_SALES_PRICE > 10000; 

SELECT * FROM SalesTempFact_V1;

DROP TABLE SalesFact_V1 CASCADE CONSTRAINTS PURGE;

--Season, Company_Branch, Customer_Type_ID, Category_ID, Time_ID, SalesPriceScale

create table SalesFact_V1 as 
select 
Season, 
Company_Branch, 
Customer_Type_ID, 
Category_ID, 
Time_ID,
SalesPriceScale,
sum(QUANTITY) AS NUMBER_OF_EQUIPMENT_SOLD,
sum(TOTAL_SALES_PRICE) AS TOTAL_REVENUE_FOR_SALES,
AVG(UNIT_SALES_PRICE) AS AVERAGE_SALES_PRICE
from SalesTempFact_V1 
group by
Season, 
Company_Branch, 
Customer_Type_ID, 
Category_ID, 
Time_ID,
EQUIPMENT_ID,
SalesPriceScale;

SELECT * FROM SalesFact_V1;

--b) SQL statements (e.g. create table, insert into, etc) to create the star/snowflake schema Version-2

-- Create CustomerTypeDIM by Direct Copy
DROP TABLE CustomerTypeDIM CASCADE CONSTRAINTS PURGE;
create table CustomerTypeDIM as 
select * from MonEquip.CUSTOMER_TYPE;

create table CustomerDIM as
select * from MonEquip.CUSTOMER;

create table StaffDIM as
select * from MonEquip.STAFF;

create table EquipmentDIM as
select * from MonEquip.STAFF;

create table CategoryDIM as 
select * from MonEquip.CATEGORY;

create table SalesPriceScaleDIM
(SalesPriceScale VARCHAR2(6),
Description varchar2(30));

insert into SalesPriceScaleDIM values ('Low', '< $5,000');
insert into SalesPriceScaleDIM values ('Medium', 'between $5,000 and $10,000');
insert into SalesPriceScaleDIM values ('High', '> $10,000');

select * from SalesPriceScaleDIM;

DROP TABLE TimeDim_V2_Temp CASCADE CONSTRAINTS PURGE;

create table TimeDim_V2_Temp as
SELECT DISTINCT Time_ID, Time_Date, Month
from (
SELECT to_char(SALES_DATE, 'YYYYMMDD') AS Time_ID, SALES_DATE as Time_Date, to_char(SALES_DATE, 'MM') as Month from MonEquip.SALES
    union all
SELECT to_char(START_DATE, 'YYYYMMDD') AS Time_ID, START_DATE as Time_Date, to_char(START_DATE, 'MM') as Month from MonEquip.HIRE
);

select * from TimeDim_V2_Temp;

alter table TimeDim_V2_Temp add 
(Season VARCHAR2(6),
Season_Description varchar2(20));

update TimeDim_V2_Temp 
set Season = 'Summer', Season_Description = 'Dec-Feb'
where Month >= '12' 
OR Month <= '02';

update TimeDim_V2_Temp 
set Season = 'Autumn' , Season_Description = 'Mar-May'
where Month >= '03' 
and Month <= '05';

update TimeDim_V2_Temp 
set Season = 'Winter', Season_Description = 'Jun-Aug' 
where Month >= '06' 
and Month <= '08';

update TimeDim_V2_Temp 
set Season = 'Spring', Season_Description = 'Sep-Nov'
where Month >= '09' 
and Month <= '11';

DROP TABLE TimeDim_V2 CASCADE CONSTRAINTS PURGE;

create table TimeDim_V2 as 
SELECT Time_ID, Time_Date, Season, Season_Description 
From TimeDim_V2_Temp;

select * from TimeDim_V2;

--HireFact_V2

DROP TABLE HireFact_V2 CASCADE CONSTRAINTS PURGE;

create table HireFact_V2 as 
select 
to_char(H.START_DATE, 'YYYYMMDD') AS Time_ID,
H.STAFF_ID,
C.CUSTOMER_TYPE_ID,
E.CATEGORY_ID,
H.EQUIPMENT_ID,
H.CUSTOMER_ID,
H.TOTAL_HIRE_PRICE -- for Total_Revenue
from MonEquip.HIRE H, MonEquip.CUSTOMER C, MonEquip.EQUIPMENT E, MonEquip.STAFF S 
where H.EQUIPMENT_ID = E.EQUIPMENT_ID AND
H.STAFF_ID = S.STAFF_ID AND
H.CUSTOMER_ID = C.CUSTOMER_ID;


SELECT * FROM HireFact_V2;

select * from monequip.hire;


--SalesFact_V2

create table SalesFact_V2 as 
select
to_char(SA.SALES_DATE, 'YYYYMMDD') AS Time_ID,
SA.STAFF_ID,
C.CUSTOMER_TYPE_ID,
E.CATEGORY_ID,
SA.EQUIPMENT_ID,
SA.CUSTOMER_ID,
SA.TOTAL_SALES_PRICE -- for Total_Revenue
from MonEquip.SALES SA, MonEquip.CUSTOMER C, MonEquip.EQUIPMENT E, MonEquip.STAFF S 
where SA.EQUIPMENT_ID = E.EQUIPMENT_ID AND
SA.STAFF_ID = S.STAFF_ID AND
SA.CUSTOMER_ID = C.CUSTOMER_ID;
