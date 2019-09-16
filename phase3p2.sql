#Q8
insert into INSPECTION values ('Pen driver', 'P01', '2017-08-15', 60, 'needs rework, introduced new errors');
insert into CONDUCT values (10400, '2017-08-15');
insert into INSPECTED values ('Pen driver', 'P01','2017-08-15');

select * from INSPECTION;
select * from CONDUCT;
select * from INSPECTED;
select * from COMPONENT;
select * from SOFTWARE_PRODUCT;

#Q9
alter table COMPONENT modify Language enum('C', 'C++', 'C#', 'Java', 'PHP', 'Javascript');
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Dynamic Table Interface', 'D01', 'Javascript' ,755);
insert into HAVE values ('Excel', '2018beta', 'Dynamic table Interface', 'D01');
insert into OWN values ('Dynamic Table Interface', 'D01', 10400);

select * from COMPONENT;
select * from HAVE;
select * from OWN;
select Pstatus from SOFTWARE_PRODUCT where Pname = 'Excel' and Pversion = '2018beta';

#Q10
insert into INSPECTION values ('Dynamic Table Interface', 'D01', '2017-11-20', 80, 'minor fixes needed');
insert into CONDUCT values (10500, '2017-11-20');
insert into INSPECTED values ('Dynamic Table Interface', 'D01', '2017-11-20');

select * from COMPONENT;
select * from INSPECTION;
select * from CONDUCT;
select * from INSPECTED;
select Pstatus from SOFTWARE_PRODUCT where Pname = 'Excel' and Pversion = '2018beta';

#Q11
update OWN
set ID = 10400
where Cname = 'Pen driver' and Cversion = 'P01';
select * from OWN;

drop table if exists CONDUCT;
create table CONDUCT
(
ID integer not null,
Date date not null,
foreign key(Date) references INSPECTION(Date)
);

insert into CONDUCT values (10100, '2010-02-14');
insert into CONDUCT values (10200, '2017-06-01');
insert into CONDUCT values (10100, '2010-02-22');
insert into CONDUCT values (10100, '2010-02-24');
insert into CONDUCT values (10100, '2010-02-26');
insert into CONDUCT values (10100, '2010-02-28');
insert into CONDUCT values (10200, '2011-05-01');
insert into CONDUCT values (10300, '2017-07-15');
insert into CONDUCT values (10100, '2014-06-10');
insert into CONDUCT values (10100, '2014-06-15');
insert into CONDUCT values (10100, '2014-06-30');
insert into CONDUCT values (10700, '2016-11-02');

drop table if exists LEAVEOSF;
create table LEAVEOSF
(
ID integer not null,
Ename varchar(60) not null,
Hiredate date not null,
Leavedate date not null
);

delimiter //
create trigger Move_to_LEAVE after delete on EMPLOYEE for each row
begin
	set @ID = old.ID;
	set @Ename = old.Ename;
    set @Hiredate = old.Hiredate;
    set @Leavedate = now();
    insert into LEAVEOSF values (@ID, @Ename, @Hiredate, @Leavedate);
end
//
delimiter ;

delimiter //
create trigger EMPLOYEE_DUP before insert on EMPLOYEE for each row
begin
	if new.ID in (select ID from LEAVEOSF) then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "ID is already in leaveOSF table";
	end if;
end
//
Delimiter ;

Delimiter //
Create trigger CONDUCT_INS before insert on CONDUCT for each row
Begin
	If new.ID not in (select ID from EMPLOYEE) and new.ID not in (select ID from LEAVEOSF) then
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Incorrect ID insert, ID not in EMPLOYEE or LEAVEOSF";	
	End if;
End
//
Delimiter ;

Delimiter //
Create trigger CONDUCT_UPD before update on CONDUCT for each row
Begin
	If new.ID not in (select ID from EMPLOYEE) and new.ID not in (select ID from LEAVEOSF) then
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Incorrect ID insert, ID not in EMPLOYEE or LEAVEOSF";	
	End if;
End
//
Delimiter ;

Delimiter //
Create trigger CONDUCT_DEL before delete on CONDUCT for each row
Begin
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = "INSPECTION information cannot be deleted";	
End
//
Delimiter ;

delete from EMPLOYEE where ID = 10700;
select * from EMPLOYEE;
select * from LEAVEOSF;
select * from CONDUCT;