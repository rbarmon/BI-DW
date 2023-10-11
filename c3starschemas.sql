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

-- Create HireFACT and SalesFACT using TempFacts


-- HireFact attributes
--Season, Company_Branch, Customer_Type_ID, Category_ID, Time_ID

HireFact_V1


-- SalesFact attributes
--Season, Company_Branch, Customer_Type_ID, Category_ID, Time_ID, SalesPriceScale

SalesFact_V1




create table TempFact as 
select 
to_char(B.Borrow_DateTime, ’YYYY’) as Year, 
to_char(B.Borrow_DateTime, ’MM’) as Month, 
M.Med_Type_ID, 
M.Cen_ID, 
M.Med_Item_ID
B.Borrow_ID,
B.Borrow_Fee
from Borrow B, Media_Item M
where B.Med_Item_ID = M.Med_Item_ID;

alter table TempFact 
add (Quarter char(1)); 

update TempFact 
set Quarter = ’1’ 
where Month >= ’01’ 
and Month <= ’03’;

update TempFact 
set Quarter = ’2’ 
where Month >= ’04’ 
and Month <= ’06’;

update TempFact 
set Quarter = ’3’ 
where Month >= ’07’ 
and Month <= ’08’; 

update TempFact 
set Quarter = ’4’ 
where Quarter is null; 

alter table TempFact 
add (QuarterID char(5)); 

update TempFact 
set QuarterID = Year||Quarter; 

create table MonMediaFact as 
select 
QuarterID, 
Med_Type_ID, 
Cen_ID, 
Med_Item_ID
count(Borrow_ID) as Number_of_Borrowed_Media
sum(Borrow_Fee) as Total_Borrowing_Fee
from TempFact 
group by
QuarterID, 
Med_Type_ID, 
Cen_ID, 
Med_Item_ID;




create table SeasonDIMTemp as
SELECT DISTINCT Time_ID, Time_Month, Time_Year
from (
SELECT Time_ID, Time_Month, Time_Year from TimeDimSalesTemp
    union all
SELECT Time_ID, Time_Month, Time_Year from TimeDimHireTemp
);

alter table SeasonDIMTemp add 
(Season VARCHAR2(6));

update SeasonDIMTemp 
set Season = 'Summer' 
where Time_Month >= '12' 
and Time_Month <= '02';

update SeasonDIMTemp 
set Season = 'Autumn' 
where Time_Month >= '03' 
and Time_Month <= '05';

update SeasonDIMTemp 
set Season = 'Winter' 
where Time_Month >= '06' 
and Time_Month <= '08';

update SeasonDIMTemp 
set Season = 'Spring' 
where Time_Month >= '09' 
and Time_Month <= '11';




update TimeDimTemp 
set QuarterID = Year||Quarter; 

create table TimeDim as 
select distinct QuarterID, Quarter, Year 
from TimeDimTemp;

-- Sales price scale: low sales <$5,000; medium sales between $5,000 and $10,000; high sales > $10,000

--b) SQL statements (e.g. create table, insert into, etc) to create the star/snowflake schema Version-2

select * from MonEquip.<table_name>;
--HireFact_V2
--SalesFact_V2
