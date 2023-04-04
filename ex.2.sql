-- country
insert into country(COUNTRY_NAME)
values ('Francja');

insert into country(COUNTRY_NAME)
values ('Polska');

insert into country(COUNTRY_NAME)
values ('Niemcy');

insert into country(COUNTRY_NAME)
values ('Belgia');

insert into country(COUNTRY_NAME)
values ('Egipt');


-- trip
insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Wycieczka do Paryza', 1, to_date('2022-09-12', 'YYYY-MM-DD'), 3);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Piękny Kraków', 2, to_date('2023-07-03', 'YYYY-MM-DD'), 2);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Znów do Francji', 1, to_date('2023-05-01', 'YYYY-MM-DD'), 2);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Hel', 2, to_date('2023-05-01', 'YYYY-MM-DD'), 2);


insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Śladami Bolesława Beznogiego', 2, to_date('2023-03-21', 'YYYY-MM-DD'), 10);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Lonely trip', 3, to_date('2024-11-01', 'YYYY-MM-DD'), 1);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Auslander', 3, to_date('2023-04-03', 'YYYY-MM-DD'), 3);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('W poszukiwaniu Faraona', 5, to_date('2022-05-01', 'YYYY-MM-DD'), 5);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('U nas na Podlasiu', 2, to_date('2023-04-06', 'YYYY-MM-DD'), 5);

insert into trip(trip_name, country_id, trip_date, max_no_places)
values ('Disnayland', 1, to_date('2026-12-25', 'YYYY-MM-DD'), 2);


-- person
insert into person(firstname, lastname)
values ('Jan', 'Nowak');

insert into person(firstname, lastname)
values ('Jan', 'Kowalski');

insert into person(firstname, lastname)
values ('Jan', 'Nowakowski');

insert into person(firstname, lastname)
values ('Adam', 'Kowalski');

insert into person(firstname, lastname)
values ('Novak', 'Nowak');

insert into person(firstname, lastname)
values ('Piotr', 'Piotrowski');

insert into person(firstname, lastname)
values ('Katarzyna', 'Nowak');

insert into person(firstname, lastname)
values ('Piotr', 'Kowalczyk');

insert into person(firstname, lastname)
values ('Joanna', 'Wójcik');

insert into person(firstname, lastname)
values ('Marcin', 'Lewandowski');

-- reservation
-- trip 1
insert into reservation(trip_id, person_id, status)
values (1, 1, 'P');

insert into reservation(trip_id, person_id, status)
values (1, 2, 'N');

-- trip 2
insert into reservation(trip_id, person_id, status)
values (2, 1, 'P');

insert into reservation(trip_id, person_id, status)
values (2, 4, 'C');

-- trip 3
insert into reservation(trip_id, person_id, status)
values (3, 4, 'P');

insert into reservation(trip_id, person_id, status)
values (3, 5, 'P');

insert into reservation(trip_id, person_id, status)
values (3, 6, 'C');

-- trip 4
insert into reservation(trip_id, person_id, status)
values (4, 1, 'N');

insert into reservation(trip_id, person_id, status)
values (4, 9, 'N');

-- trip 5
insert into reservation(trip_id, person_id, status)
values (5, 10, 'P');

-- trip 6
insert into reservation(trip_id, person_id, status)
values (6, 5, 'C');

insert into reservation(trip_id, person_id, status)
values (6, 4, 'N');

-- trip 7

insert into reservation(trip_id, person_id, status)
values (7, 9, 'C');

insert into reservation(trip_id, person_id, status)
values (7, 10, 'P');

-- trip 8

insert into reservation(trip_id, person_id, status)
values (8, 4, 'P');

insert into reservation(trip_id, person_id, status)
values (8, 4, 'N');


-- trip 9
insert into reservation(trip_id, person_id, status)
values (9, 8, 'C');

-- trip 10
-- empty until procedures are created
