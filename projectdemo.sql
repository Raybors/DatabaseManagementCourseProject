drop database if exists demo;
create database demo;
use demo;

create table SOFTWARE_PRODUCT
(
Pname varchar(20) not null,
Pversion varchar(20) not null,
Pstatus enum('ready', 'usable', 'not-ready') default "not-ready",
primary key(Pname, Pversion)
);

create table COMPONENT
(
Cname varchar(50) not null,
Cversion varchar(3) not null,
Language enum('C','C++','C#','Java','PHP'),
Size integer not null,
Cstatus enum('ready', 'usable', 'not-ready') default "not-ready",
primary key(Cname, Cversion)
);

create table EMPLOYEE
(
ID integer not null,
Ename varchar(60) not null,
Hiredate date not null,
Mgr integer,
Seniority varchar(10) default null,
primary key(ID)
);

create table INSPECTION
(
Cname varchar(50) not null,
Cversion varchar(3) not null,
Date date not null,
Score integer,
Description varchar(4000) not null,
key(date),
foreign key(Cname, Cversion) references COMPONENT(Cname, Cversion) 
);

create table HAVE
(
Pname varchar(10) not null,
Pversion varchar(10) not null,
Cname varchar(50) not null,
Cversion varchar(3) not null,
foreign key(Pname, Pversion) references SOFTWARE_PRODUCT(Pname, Pversion),
foreign key(Cname, Cversion) references COMPONENT(Cname, Cversion)
);

create table OWN
(
Cname varchar(50) not null,
Cversion varchar(3) not null,
ID integer not null,
foreign key(Cname, Cversion) references COMPONENT(Cname, Cversion),
foreign key(ID) references EMPLOYEE(ID) 
);

create table INSPECTED
(
Cname varchar(50) not null,
Cversion varchar(3) not null,
Date date not null,
foreign key(Cname, Cversion) references COMPONENT(Cname, Cversion),
foreign key(Date) references INSPECTION(Date) 
);

create table CONDUCT
(
ID integer not null,
Date date not null,
foreign key(ID) references EMPLOYEE(ID),
foreign key(Date) references INSPECTION(Date) 
);

 




delimiter //
create trigger EMPLOYEE_INS before insert on EMPLOYEE for each row
begin
	if(exists(select * from employee where ID = new.Mgr) or new.ID = 10100) then
		if (new.hiredate > date_sub(now(), interval 1 year)) then
			set new.seniority = "newbie";
		else
			if (new.hiredate > date_sub(now(), interval 5 year)) then
				set new.seniority = "junior";
			else	
				set new.seniority = "senior";
			end if;
		end if;
	else	
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Mgr data is wrong";
	end if;
end;
//
delimiter ;

/*
delimiter //
create trigger OWN_onlyone before insert on OWN for each row
begin
	if (select count(*) from OWN where Cname = new.Cname and Cversion = new.Cversion) = 1 then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "one component can have only one owner";
	end if;
end;
//
delimiter ;

delimiter //
create trigger OWN_onlyone_UPD before update on OWN for each row
begin
	if (select count(*) from OWN where Cname = new.Cname and Cversion = new.Cversion) = 1 then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "one component can have only one owner";
	end if;
end;
//
delimiter ;
*/

delimiter //
create trigger id_INS before insert on EMPLOYEE for each row
begin
	if (LENGTH(new.ID) != 5) then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "ID should be 5 digit number";
	elseif (new.ID > 99999 or new.ID < 10000) then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "ID should be 5 digit number";
	end if;
end
//
delimiter ;

delimiter //
create trigger id_UPD before update on EMPLOYEE for each row
begin
	if (LENGTH(new.ID) != 5) then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "ID should be 5 digit number";
	elseif (new.ID > 99999 or new.ID < 10000) then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "ID should be 5 digit number";
	end if;
end
//
delimiter ;

delimiter //
create trigger score_INS before insert on INSPECTION for each row
begin
	if new.Score > 100 or new.Score < 0 then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Score should be a value between 0 and 100 or null";
	end if;
end
//
delimiter ;


delimiter //
create trigger score_UPD before update on INSPECTION for each row
begin
	if new.Score is not null then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Score can never be changed";
	end if;
end
//
delimiter ;

delimiter //
create trigger cstatus_INS after insert on INSPECTION
for each row
begin
	if new.score > 90 then
		update COMPONENT, INSPECTION
		set COMPONENT.Cstatus = 'ready'
        where COMPONENT.Cname = new.Cname and COMPONENT.Cversion = new.Cversion 
        and new.Date = (select max(Date) from INSPECTION where
        INSPECTION.Cname = new.Cname and INSPECTION.Cversion = new.Cversion);
	elseif new.score < 75 then
		update COMPONENT, INSPECTION
		set COMPONENT.Cstatus = 'not-ready'
        where COMPONENT.Cname = new.Cname and COMPONENT.Cversion = new.Cversion 
        and new.Date = (select max(Date) from INSPECTION where
        INSPECTION.Cname = new.Cname and INSPECTION.Cversion = new.Cversion);
	else
		update COMPONENT, INSPECTION
		set COMPONENT.Cstatus = 'usable'
        where COMPONENT.Cname = new.Cname and COMPONENT.Cversion = new.Cversion 
        and new.Date = (select max(Date) from INSPECTION where
        INSPECTION.Cname = new.Cname and INSPECTION.Cversion = new.Cversion);
	end if;
	call Product_Status_Step1();
end
//
delimiter ;

delimiter //
create Procedure Product_Status_Step1()
begin
	declare m int default 0;
    set @num_of_p = (select count(distinct Pname, Pversion)from SOFTWARE_PRODUCT);
    	while m != @num_of_p
        do
			set @PN = (select SOFTWARE_PRODUCT.Pname from SOFTWARE_PRODUCT limit m,1);
			set @PV = (select SOFTWARE_PRODUCT.Pversion from SOFTWARE_PRODUCT limit m,1);
			update SOFTWARE_PRODUCT
			set SOFTWARE_PRODUCT.Pstatus = 'ready' where SOFTWARE_PRODUCT.Pname = @PN and SOFTWARE_PRODUCT.Pversion = @PV;
			set m = m + 1;
			call Product_Status_Step2(@PN,@PV);
		end while;
end
//
delimiter ;

delimiter //
create Procedure Product_Status_Step2(PN varchar(20), PV varchar(20))
begin
	declare n int default 0;
    set @countpc = (select count(*)from HAVE where HAVE.Pname = PN and HAVE.Pversion = PV);
    set @Pstatus = (select SOFTWARE_PRODUCT.Pstatus from SOFTWARE_PRODUCT where SOFTWARE_PRODUCT.Pname = PN and SOFTWARE_PRODUCT.Pversion = PV);
    while n != @countpc
        do
			set @CName = (select HAVE.Cname from HAVE where HAVE.Pname = PN and HAVE.Pversion = PV limit n,1);
			set @Cversion = (select HAVE.Cversion from HAVE where HAVE.Pname = PN and HAVE.Pversion = PV limit n,1);
			set @Cstatus = (select COMPONENT.Cstatus from COMPONENT where COMPONENT.Cname = @Cname and COMPONENT.Cversion = @Cversion);
			if(@Cstatus = 'not-ready') then
				set @Pstatus = 'not-ready';
			elseif(@Cstatus = 'usable' and @Pstatus = 'ready')then
				set @Pstatus = 'usable';
			end if;
			set n = n + 1;
	end while;
    update SOFTWARE_PRODUCT
    set SOFTWARE_PRODUCT.Pstatus = @Pstatus
    where SOFTWARE_PRODUCT.Pname = PN and SOFTWARE_PRODUCT.Pversion = PV;
end
//
delimiter ;

delimiter //
create trigger HAVE_INS after insert on HAVE
for each row
begin
	
	call Product_Status_Step1();
end
//
delimiter ;

delimiter //
create trigger HAVE_UPD after update on HAVE 
for each row
begin
	call Product_Status_Step1();
end
//
delimiter ;

delimiter //
create trigger HAVE_DEL after delete on HAVE 
for each row
begin
	call Product_Status_Step1();
end
//
delimiter ;

/*
delimiter //
create trigger INSPECTED_notchange1 before update on INSPECTED for each row
begin
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "INSPECTION information cannot be changed ";
end;
//
delimiter ;

delimiter //
create trigger INSPECTED_notchange2 before delete on INSPECTED for each row
begin
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "INSPECTION information cannot be changed ";
end;
//
delimiter ;
*/

insert into SOFTWARE_PRODUCT (Pname,Pversion) values ('Excel', '2010');
insert into SOFTWARE_PRODUCT (Pname,Pversion) values ('Excel', '2015');
insert into SOFTWARE_PRODUCT (Pname,Pversion) values ('Excel', '2018beta');
insert into SOFTWARE_PRODUCT (Pname,Pversion) values ('Excel', 'secret');

insert into COMPONENT (Cname, Cversion, Language, Size) values ('Keyboard Driver', 'K11', 'C', 1200);
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Touch Screen Driver', 'T00', 'C++', 4000);
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Dbase Interface', 'D00', 'C++', 2500);
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Dbase Interface', 'D01', 'C++', 2500);
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Chart generator', 'C11', 'Java', 6500);
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Pen driver', 'P01', 'C', 3575);
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Math unit', 'A01', 'C', 5000);
insert into COMPONENT (Cname, Cversion, Language, Size) values ('Math unit', 'A02', 'Java', 3500);

insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10100, 'Employee-1', '1984-11-08', NULL);
insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10200, 'Employee-2', '1994-11-08', 10100);
insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10300, 'Employee-3', '2004-11-08', 10200);
insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10400, 'Employee-4', '2008-11-01', 10200);
insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10500, 'Employee-5', '2015-11-01', 10400);
insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10600, 'Employee-6', '2015-11-01', 10400);
insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10700, 'Employee-7', '2016-11-01', 10400);
insert into EMPLOYEE (ID, Ename, Hiredate, Mgr) values (10800, 'Employee-8', '2017-11-01', 10200);

insert into HAVE values ('Excel', '2010', 'Keyboard Driver', 'K11');
insert into HAVE values ('Excel', '2010', 'Dbase Interface', 'D00');
insert into HAVE values ('Excel', '2015', 'Keyboard Driver', 'K11');
insert into HAVE values ('Excel', '2015', 'Dbase Interface', 'D01');
insert into HAVE values ('Excel', '2015', 'Pen driver', 'P01');
insert into HAVE values ('Excel', '2018beta', 'Keyboard Driver', 'K11');
insert into HAVE values ('Excel', '2018beta', 'Touch Screen Driver', 'T00');
insert into HAVE values ('Excel', '2018beta', 'Chart generator', 'C11');
insert into HAVE values ('Excel', 'secret', 'Keyboard Driver', 'K11');
insert into HAVE values ('Excel', 'secret', 'Touch Screen Driver', 'T00');
insert into HAVE values ('Excel', 'secret', 'Chart generator', 'C11');
insert into HAVE values ('Excel', 'secret', 'Math unit', 'A02');

insert into OWN values ('Keyboard Driver', 'K11', 10100);
insert into OWN values ('Touch Screen Driver', 'T00', 10100);
insert into OWN values ('Dbase Interface', 'D00', 10200);
insert into OWN values ('Dbase Interface', 'D01', 10300);
insert into OWN values ('Chart generator', 'C11', 10200);
insert into OWN values ('Pen driver', 'P01', 10700);
insert into OWN values ('Math unit', 'A01', 10200);
insert into OWN values ('Math unit', 'A02', 10200);

insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Keyboard Driver', 'K11', '2010-02-14', 100, 'legacy code which is already approved');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Touch Screen Driver', 'T00', '2017-06-01', 95, 'initial release ready for usage');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Dbase Interface', 'D00', '2010-02-22', 55, 'too many hard coded parameters, the software must be more maintainable and configurable because we want to use this in other products');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Dbase Interface', 'D00', '2010-02-24', 78, 'improved, but only handles DB2 format');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Dbase Interface', 'D00', '2010-02-26', 95, 'Okay, handles DB3 format');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Dbase Interface', 'D00', '2010-02-28', 100, 'satisified');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Dbase Interface', 'D01', '2011-05-01', 100, 'Okay ready for use');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Pen driver', 'P01', '2017-07-15', 80, 'Okay ready for beta testing');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Math unit', 'A01', '2014-06-10', 90, 'almost ready');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Math unit', 'A02', '2014-06-15', 70, 'Accuracy problems!');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Math unit', 'A02', '2014-06-30', 100, 'Okay problems fixed');
insert into INSPECTION (Cname, Cversion, Date, Score, Description) values ('Math unit', 'A02', '2016-11-02', 100, 're-review for new employee to gain experience in the process');

insert into INSPECTED values ('Keyboard Driver', 'K11', '2010-02-14');
insert into INSPECTED values ('Touch Screen Driver', 'T00', '2017-06-01');
insert into INSPECTED values ('Dbase Interface', 'D00', '2010-02-22');
insert into INSPECTED values ('Dbase Interface', 'D00', '2010-02-24');
insert into INSPECTED values ('Dbase Interface', 'D00', '2010-02-26');
insert into INSPECTED values ('Dbase Interface', 'D00', '2010-02-28');
insert into INSPECTED values ('Dbase Interface', 'D01', '2011-05-01');
insert into INSPECTED values ('Pen driver', 'P01', '2017-07-15');
insert into INSPECTED values ('Math unit', 'A01', '2014-06-10');
insert into INSPECTED values ('Math unit', 'A02', '2014-06-15');
insert into INSPECTED values ('Math unit', 'A02', '2014-06-30');
insert into INSPECTED values ('Math unit', 'A02', '2016-11-02');

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





SET SQL_SAFE_UPDATES = 0;
