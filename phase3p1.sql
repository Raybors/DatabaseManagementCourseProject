#Q1
select * from software_product;

#Q2
select Ename, Cname, Cversion from
(select COMPONENT.Cname, COMPONENT.Cversion, COMPONENT.Cstatus, EMPLOYEE.ID, EMPLOYEE.Ename from
(COMPONENT inner join OWN on COMPONENT.Cname = OWN.Cname and COMPONENT.Cversion = OWN.Cversion)
inner join EMPLOYEE on OWN.ID = EMPLOYEE.ID
where COMPONENT.Cstatus = 'not-ready')as A;

#Q3
select COMPONENT.Cname, COMPONENT.Cversion from COMPONENT left join INSPECTION
on COMPONENT.Cname = INSPECTION.Cname and COMPONENT.Cversion = INSPECTION.Cversion
where score is null;

#Q4
select AVG(count_own)as result_of_average from
(select EMPLOYEE.ID, count(OWN.ID) as count_own from COMPONENT right join OWN on COMPONENT.Cname = OWN.Cname and COMPONENT.Cversion = OWN.Cversion
right join EMPLOYEE on EMPLOYEE.ID = OWN.ID group by EMPLOYEE.ID) as A;

#Q5
select AVG(score) from
(select score from
(INSPECTION inner join HAVE on INSPECTION.Cname = HAVE.Cname and INSPECTION.Cversion = HAVE.Cversion)
inner join SOFTWARE_PRODUCT on SOFTWARE_PRODUCT.Pname = HAVE.Pname and SOFTWARE_PRODUCT.Pversion = HAVE.Pversion
where SOFTWARE_PRODUCT.Pname = 'Excel' and SOFTWARE_PRODUCT.Pversion = 'secret')as A;

#Q6
drop view if exists COUNT_OF_INSPECTION;
create view COUNT_OF_INSPECTION as 
select Ename, Seniority, count(CEID)as count_of_inspections_performed, ifnull(AVG(score), 0)as average_inspection_score from
(select CONDUCT.ID as CEID, EMPLOYEE.ID as EID, Ename, Seniority, Score from
EMPLOYEE left join CONDUCT on EMPLOYEE.ID = CONDUCT.ID
left join INSPECTION on INSPECTION.Date = CONDUCT.Date) as A group by EID;

drop view if exists COUNT_OF_COMPONENT;
create view COUNT_OF_COMPONENT as
select Ename, Seniority, count(OID) as count_of_components_assigned from
(select OWN.ID as OID, EMPLOYEE.ID as EID, Ename, Seniority, COMPONENT.Cname, COMPONENT.Cversion from
EMPLOYEE left join OWN on EMPLOYEE.ID = OWN.ID
left join COMPONENT on COMPONENT.Cname = OWN.Cname and COMPONENT.Cversion) as A group by EID;

select COUNT_OF_COMPONENT.Ename, COUNT_OF_COMPONENT.Seniority, count_of_inspections_performed, count_of_components_assigned, average_inspection_score from
COUNT_OF_INSPECTION inner join COUNT_OF_COMPONENT on COUNT_OF_INSPECTION.Ename = COUNT_OF_COMPONENT.Ename;

#Q7
drop view if exists ForCOST;
create view ForCOST
as select Hiredate, score, INSPECTION.Date from
(INSPECTION inner join CONDUCT on INSPECTION.Date = CONDUCT.Date)
inner join EMPLOYEE on CONDUCT.ID = EMPLOYEE.ID
where INSPECTION.Date between '2010-01-01' and '2010-12-31';

drop view if exists newbie_Readycost;
create view newbie_Readycost as
select Hiredate, ifnull(count(score) * 200, 0) as new_cost_of_ready from ForCOST
where score > 90 and Hiredate > date_sub(Date, interval 1 year);

drop view if exists newbie_Otherscost;
create view newbie_Otherscost as
select Hiredate, ifnull(count(score) * 100, 0) as new_cost_of_others from ForCOST
where score <= 90 and Hiredate > date_sub(Date, interval 1 year);

drop view if exists junior_Readycost;
create view junior_Readycost as
select Hiredate, ifnull(count(score) * 200, 0) as jun_cost_of_ready from ForCOST
where score > 90 and Hiredate > date_sub(Date, interval 5 year)
				 and Hiredate <= date_sub(Date, interval 1 year);

drop view if exists junior_Otherscost;
create view junior_Otherscost as
select Hiredate, ifnull(count(score) * 100, 0) as jun_cost_of_others from ForCOST
where score <= 90 and Hiredate > date_sub(Date, interval 5 year)
				 and Hiredate <= date_sub(Date, interval 1 year);

drop view if exists senior_Readycost;
create view senior_Readycost as
select Hiredate, ifnull(count(score) * 200, 0) as sen_cost_of_ready from ForCOST
where score > 90 and Hiredate <= date_sub(Date, interval 5 year);

drop view if exists senior_Otherscost;
create view senior_Otherscost as
select Hiredate, ifnull(count(score) * 100, 0) as sen_cost_of_others from ForCOST
where score <= 90 and Hiredate <= date_sub(Date, interval 5 year);

select (new_cost_of_ready + new_cost_of_others)as newbie_cost, (jun_cost_of_ready + jun_cost_of_others)as junior_cost, (sen_cost_of_ready + sen_cost_of_others)as senior_cost from
newbie_Readycost, newbie_Otherscost, junior_Readycost, junior_Otherscost, senior_Readycost, senior_Otherscost;


