-- drop table log;
-- drop table reservation;
-- drop table person;
-- drop table trip;
-- drop table country;

create table country
(
    country_id int generated always as identity not null,
    country_name varchar(50) not null,
    constraint country_pk primary key (country_id) enable
);

create table person
(
  person_id int generated always as identity not null,
  firstname varchar(50),
  lastname varchar(50),
  constraint person_pk primary key ( person_id ) enable
);

create table trip
(
  trip_id int generated always as identity not null,
  trip_name varchar(100),
  country_id int,
  trip_date date,
  max_no_places int,
  constraint trip_pk primary key ( trip_id ) enable
);

alter table trip
add constraint country_fk foreign key
(country_id) references country (country_id) enable;


create table reservation
(
  reservation_id int generated always as identity not null,
  trip_id int,
  person_id int,
  status char(1),
  constraint reservation_pk primary key ( reservation_id ) enable
);


alter table reservation
add constraint reservation_fk1 foreign key
( person_id ) references person ( person_id ) enable;

alter table reservation
add constraint reservation_fk2 foreign key
( trip_id ) references trip ( trip_id ) enable;

alter table reservation
add constraint reservation_chk1 check
(status in ('N','P','C')) enable;


create table log
(
	log_id int  generated always as identity not null,
	reservation_id int not null,
	log_date date  not null,
	status char(1),
	constraint log_pk primary key ( log_id ) enable
);

alter table log
add constraint log_chk1 check
(status in ('N','P','C')) enable;

alter table log
add constraint log_fk1 foreign key
( reservation_id ) references reservation ( reservation_id ) enable;

