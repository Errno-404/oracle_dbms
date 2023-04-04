-- Reservations
create or replace view Reservations
as
select r.country_name,
       r.trip_date,
       r.trip_name,
       r.firstname,
       r.lastname,
       r.reservation_id,
       r.status
from Reservations_1 r;



-- Reservations1 (with extra data _id)
create or replace view Reservations_1
as
select c.country_name,
       t.trip_date,
       t.trip_name,
       t.trip_id,
       p.firstname,
       p.lastname,
       p.person_id,
       r.reservation_id,
       r.status
from country c
         join trip t on c.COUNTRY_ID = t.COUNTRY_ID
         join reservation r on r.TRIP_ID = t.TRIP_ID
         join person p on p.PERSON_ID = r.PERSON_ID;


-- Trips
create or replace view Trips
as
select t.country_name,
       t.TRIP_DATE,
       t.TRIP_NAME,
       t.MAX_NO_PLACES,
       t.no_available_places
from Trips_1 t;



-- Trips1 (with additional trip_id)
create or replace view Trips_1
as
select c.country_name,
       t.TRIP_DATE,
       t.TRIP_NAME,
       t.trip_id,
       t.MAX_NO_PLACES,
       nvl(t.MAX_NO_PLACES - (select count(rw.RESERVATION_ID)
                              from reservation rw
                                       join trip tw on rw.trip_id = tw.trip_id
                              where rw.status != 'C'
                                and t.trip_id = tw.trip_id
                              group by rw.Trip_id), t.MAX_NO_PLACES) no_available_places
from trip t
         join country c on t.COUNTRY_ID = c.COUNTRY_ID;



-- FutureTrips
create or replace view FutureTrips
as
select country_name,
       trip_date,
       trip_name,
       trip_id,
       max_no_places,
       no_available_places
from Trips_1
where trip_date > current_date;


-- AvailableTrips
create or replace view AvailableTripsView
as
select country_name,
       trip_date,
       trip_name,
       max_no_places,
       no_available_places
from FutureTrips
where trip_date > current_date
  and no_available_places > 0;



-- AvailableTrips1
create or replace view AvailableTripsView_1
as
select *
from FutureTrips
where no_available_places > 0;