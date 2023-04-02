-- basic pl/sql

-- wlasny rekord (to nie jest obiekt tylko rekord !!!
declare
    type typ is record
                (
                    first varchar2(50),
                    last  varchar2(50)
                );
    o typ;
begin
    o.first := 'jan';
    o.last := 'kowalski';
end;


-- zastosowanie rowtype w jest do NAZWY TABELI
declare
    f PERSON%rowtype;

begin
    f.FIRSTNAME := 'John';

    dbms_output.Put_line(f.FIRSTNAME);
end;


-- normalny if-else
declare
    b boolean := false;
begin
    if b then
        dbms_output.Put_line('true');
    else
        dbms_output.Put_line('false');
    end if;
end;


-- switch case w pl/sql
declare
    s varchar2(10) := 'kara';
begin
    case
        when s = 'abc' then dbms_output.Put_line(1);
        when s = 'def' then dbms_output.Put_line(2);
        else dbms_output.Put_line(3);
        end case;
end;

-- pętelki (ta loop to idk po cholere taka)
declare
    i int := 0;
begin
    loop
        if i > 5 then
            exit;
        end if;
        dbms_output.Put_line(i);
        i := i + 1;
    end loop;
end;

-- while
declare
    i int := 0;
begin
    while i <= 5
        loop
            dbms_output.put_line(i);
            i := i + 1;
        end loop;
end;


-- piekny pythonowy for (tylko bez zbednego slowka range)
declare
    i int := 0;
begin
    for i in 1..5
        loop
            dbms_output.put_line(i);
        end loop;
end;


-- wyjatkowy kod
declare
    i int; exc1 exception;
begin
    i := 1;
    if i = 1 then
        raise exc1;
    end if;

    if i = 3 then
        raise_application_error(-20001, 'exc3');
    end if;

    dbms_output.put_line('OK');

exception
    when exc1 then
        dbms_output.put_line('exc1');
    when others then
        dbms_output.put_line('other exception');

end;


-- pobieranie danych do zmiennych za pomocą select into (ważne bardzo)
declare
    first varchar2(50);
    last  varchar2(50);
begin
    select FIRSTNAME, LASTNAME into first, last from PERSON where PERSON_ID = 1;
    dbms_output.put_line(first || last);
end;


-- pobieranie select into z wykorzystaniem rowtype'a
declare
    f PERSON%rowtype;
begin
    select * into f from PERSON where PERSON_ID = 1;
    dbms_output.put_line(f.FIRSTNAME);
end;

-- pobranie generated as identity (a także każdej innej wartości wstawionej do tabelsona)
declare
    first varchar2(50); last varchar2(50); id int;
begin
    insert into person(firstname, lastname)
    values ('Jack', 'Sparrow')
    returning PERSON_ID into id;
    dbms_output.put_line('id' || id);
end;

select *
from PERSON;

-- to co wyżej, tu miałem dać returning lastname np, ale tbh po co
declare
    first varchar2(50); last varchar2(50); id int;
begin
    insert into person(firstname, lastname)
    values ('Jack', 'Sparrow')
    returning PERSON_ID into id;
    dbms_output.put_line('id' || id);
end;

select *
from PERSON;


-- tabela do wyjątków
create table test1
(
    tid    int generated always as identity not null,
    tname  varchar(100),
    status char(1),
    constraint test1_pk primary key (tid) enable
);

alter table test1
    add constraint test1_chk1 check
        (status in ('A', 'B')) enable;

-- usuwanie rowa z tabsa
delete test1
where tid = 5;

-- transakcja się nie wykona jak mamy czerwony błąd,
-- wpp się wykona tyle operacji ile było poprawnych
declare
    i int;
    exc1 exception ;
    exc3 exception;
    exc4 exception;
    pragma exception_init ( exc4, -20003 );

begin
    i := 3;

    insert into test1(tname, status)
    values ('ala', 'A');

    if i = 3 then
--         raise exc3;
        raise_application_error(-20003, 'exc4');
    end if;


    insert into test1(tname, status)
    VALUES ('bala', 'X');

    dbms_output.put_line('OK');

exception
    when exc1 then
        dbms_output.put_line('exc1');
    when exc4 then
        dbms_output.put_line('exc3');
    --     when others then
--         dbms_output.put_line('other exc');
end;

select *
from test1;


-- widoczki
create view trip_reservation
as
select r.reservation_id, r.trip_id, p.person_id, p.firstname, p.lastname
from reservation r
         join person p on r.person_id = p.person_id
where r.trip_id = 1;

select *
from trip_reservation;



-- funkcyjki zwracające single value
create or replace function f_hello(name varchar)
    -- tutaj mówimy co nam funkcja zwróci
    return varchar
    is
    hello  varchar(50) := 'hello';
    result varchar(50);
begin
    if name is null then
        raise_application_error(-20001, 'empty name');
    end if;

    result := hello || ' ' || name;
    return result;
end;


select f_hello('Adam')
from dual;

-- mapowanie (wykonanie funkcji na całej kolekcji)
select f_hello(lastname)
from person p;


-- funkcja zwracająca tabelę!!!

-- select r.reservation_id, r.trip_id, p.person_id, p.firstname, p.lastname
-- from reservation r
--          join person p on r.person_id = p.person_id
-- where r.trip_id = 1;

create or replace type t_participant as object
(
    reservation_id int,
    trip_id        int,
    person_id      int,
    firstname      varchar(50),
    lastname       varchar2(50)
);

create or replace type t_participant_table is table of t_participant;

create or replace function f_trip_participants(trip_id int)
    return t_participant_table
    is
    result t_participant_table;
begin
    select t_participant(r.reservation_id, r.trip_id, p.person_id, p.firstname, p.lastname) bulk collect
    into result
    from RESERVATION r
             join person p on r.trip_id = f_trip_participants.trip_id;
    return result;
end;

select *
from f_trip_participants(1);
select *
from table (f_trip_participants(1));


-- kontrola argumentów


create or replace function f_trip_participants1(trip_id int)
    return t_participant_table
    is
    result t_participant_table;
    valid  int;
begin
    select count(*) into valid from trip t where t.trip_id = f_trip_participants1.trip_id;

    if valid = 0 then
        raise_application_error(-20001, 'trip not found');
    end if;

    select t_participant(r.reservation_id, r.trip_id, p.person_id, p.firstname, p.lastname) bulk collect
    into result
    from RESERVATION r
             join person p on p.person_id = r.PERSON_ID
    where r.trip_id = f_trip_participants1.trip_id;

    return result;
end;

select * from f_trip_participants1(99);
