-- Zmiana struktury bazy danych, w tabeli wycieczki dodajemy redundantne pole
-- no_available_places

-- Obsługa redundantnego pola (kontrola liczby dostępnych miejsc) w procedurach
-- Należy zmodyfikować zestaw widoków. Proponuję dodać kolejne widoki (np. z sufiksem 4), które
-- pobierają informację o wolnych miejscach z nowo dodanego pola.

-- Należy napisać procedurę przelicz która zaktualizuje wartość liczby wolnych miejsc dla już
-- istniejących danych


-- Należy zmodyfikować warstwę procedur/funkcji pobierających dane, podobnie jak w przypadku
-- widoków.
-- Należy zmodyfikować procedury wprowadzające dane tak aby korzystały/aktualizowały pole
-- no_available_places w tabeli wycieczki
-- Najlepiej to zrobić tworząc nowe wersje (np. z sufiksem 4)


ALTER TABLE TRIP
    ADD no_available_places int;

select *
from trip;


-- poprawione widoki:

-- Trips
create or replace view Trips9_0
as
select t.country_name,
       t.TRIP_DATE,
       t.TRIP_NAME,
       t.MAX_NO_PLACES,
       t.no_available_places
from Trips9_1 t;



-- Trips1 (with additional trip_id)
create or replace view Trips9_1
as
select c.country_name,
       t.TRIP_DATE,
       t.TRIP_NAME,
       t.trip_id,
       t.MAX_NO_PLACES,
       t.NO_AVAILABLE_PLACES
from trip t
         join country c on t.COUNTRY_ID = c.COUNTRY_ID;



-- FutureTrips1
create or replace view FutureTrips9_0
as
select country_name,
       trip_date,
       trip_name,
       trip_id,
       max_no_places,
       no_available_places
from Trips9_1
where trip_date > current_date;


-- AvailableTrips1
create or replace view AvailableTripsView9_0
as
select country_name,
       trip_date,
       trip_name,
       max_no_places,
       no_available_places
from FutureTrips9_0
where trip_date > current_date
  and no_available_places > 0;



-- AvailableTrips1
create or replace view AvailableTripsView9_1
as
select *
from FutureTrips9_0
where no_available_places > 0;


-- Functions


-- AvailableTrips
create or replace function AvailableTrips9_0(country varchar2, date_from date, date_to date)
    return AvailableTripTable
    is
    result         AvailableTripTable;
    country_exists int;
begin
    select count(*) into country_exists from country c where c.country_name = AvailableTrips9_0.country;
    if country_exists = 0 then
        raise_application_error(-20001, 'country not found');
    end if;


    if date_from > date_to then
        raise_application_error(-20003,
                                'Date given as the second argument should be earlier ' ||
                                'than the one provided as the 3rd argument!');
    end if;

    select AvailableTrip(country_name,
                         trip_date,
                         trip_name,
                         max_no_places,
                         no_available_places) bulk collect
    into result
    from AVAILABLETRIPSVIEW9_1
    where COUNTRY_NAME = AvailableTrips9_0.country
      and trip_date between AvailableTrips9_0.date_from and AvailableTrips9_0.date_to;


    return result;

end;


-- CheckAvailablePlaces function
create or replace function CheckAvailablePlaces9_0(trip_id int)
    return int
    is
    result           int := 0;
    available_places int;
begin
    select atv.no_available_places
    into available_places
    from AVAILABLETRIPSVIEW9_1 atv
    where atv.trip_id = CheckAvailablePlaces9_0.trip_id;


    if available_places <> 0 then
        result := 1;
    end if;

    return result;

end;

-- AddReservation procedure
create or replace procedure AddReservation9_0(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists    number;
    trip_exists      int;
    is_future        int;
    is_available     int;
    reservation_id   int;
    available_places int;
begin

    -- checking if person exists
    select COUNT(*) into person_exists from person where person.person_id = AddReservation9_0.person_id;
    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    -- checking if trip exists
    select count(*) into trip_exists from trip where trip.trip_id = AddReservation9_0.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if trip is in the future
    select count(*) into is_future from FutureTrips9_0 where FutureTrips9_0.TRIP_ID = AddReservation9_0.trip_id;
    if is_future = 0 then
        raise_application_error(-20003, 'The trip has already started!');
    end if;

    -- checking if trip is available (if there are no_places > 0)
    is_available := CheckAvailablePlaces9_0(trip_id);
    if is_available = 0 then
        RAISE_APPLICATION_ERROR(-20003, 'Trip with chosen ID is not available.');
    end if;


    -- inserting data
    insert into reservation (TRIP_ID, PERSON_ID, STATUS)
    values (AddReservation9_0.trip_id, AddReservation9_0.person_id, 'N')
    returning reservation_id into AddReservation9_0.reservation_id;


    select no_available_places into available_places from Trip where trip.TRIP_ID = AddReservation9_0.trip_id;
    available_places := available_places - 1;


    update TRIP
    set TRIP.no_available_places = available_places
    where Trip.TRIP_ID = AddReservation9_0.trip_id;


    insert into log(reservation_id, log_date, status)
    values (AddReservation9_0.reservation_id, current_date, 'N');
end;


-- ModifyReservationStatus procedure
create or replace procedure ModifyReservationStatus9_0(reservation_id number, status reservation.status%type)
as
    trip_id            int;
    old_status         reservation.status%type;
    reservation_exists number;
    is_future          number;
    available_places   int;
    t_modify           int := 0;
begin

    -- checking if reservation exists
    select COUNT(*)
    into reservation_exists
    from Reservations r
    where r.reservation_id = ModifyReservationStatus9_0.reservation_id;
    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    -- checking if given new status is correct
    if ModifyReservationStatus9_0.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;


    select r.trip_id
    into trip_id
    from Reservations1 r
    where r.RESERVATION_ID = ModifyReservationStatus9_0.reservation_id;

    -- checking if trip has already started
    select COUNT(*)
    into is_future
    from FUTURETRIPS9_0 ft
    where ft.trip_id = TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;


    select r.status
    into old_status
    from reservation r
    where r.RESERVATION_ID = ModifyReservationStatus9_0.reservation_id;
    if ModifyReservationStatus9_0.status = old_status then
        raise_application_error(-20003, 'Given reservation already has such status!');
    end if;

    select no_available_places
    into available_places
    from Trip t
    where t.TRIP_ID = ModifyReservationStatus9_0.trip_id;

    case
        when old_status = 'C'
            then if ModifyReservationStatus9_0.status <> 'N' then
                raise_application_error(-20003, 'Canceled reservation must be set to "N" (new) status first!');
                 end if;

                 if CheckAvailablePlaces9_0(trip_id) = 0 then
                     raise_application_error(-20003, 'There are no free places left for the trip!');


                 end if;

                 t_modify = 1;
                 available_places := available_places - 1;


        when old_status = 'P'
            then if (ModifyReservationStatus9_0.status <> 'C') then
                RAISE_APPLICATION_ERROR(-20006, 'P can only be changed to C status!');
                 end if;

                 available_places := available_places + 1;
                 t_modify = 1;
        else null;

        end case;


    update RESERVATION
    set STATUS = ModifyReservationStatus9_0.status
    where RESERVATION_ID = ModifyReservationStatus9_0.reservation_id;


    if t_modify = 1 then

        update Trip
        set trip.no_available_places = available_places
        where trip.TRIP_ID = ModifyReservationStatus9_0.trip_id;
    end if;

    insert into Log(reservation_id, log_date, status)
    values (ModifyReservationStatus9_0.reservation_id, current_date, ModifyReservationStatus9_0.status);


end ;


-- ModifyNoPlaces procedure
create or replace procedure ModifyNoPlaces9_0(trip_id number, no_places number)
as
    reserved_places number;
    trip_exists     number;
    is_future       number;
begin

    -- checking if trip exists
    select count(*) into trip_exists from Trip t where t.TRIP_ID = ModifyNoPlaces9_0.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if is future
    select count(*) into is_future from FUTURETRIPS9_0 ft where ft.TRIP_ID = ModifyNoPlaces9_0.trip_id;
    if is_future = 0 then
        raise_application_error(-20003, 'Cannot change number of places for trip which has already started (or ended)');
    end if;

    -- saving free places
    select (ft.max_no_places - ft.no_available_places)
    into reserved_places
    from TRIP ft
    where ft.trip_id = ModifyNoPlaces9_0.trip_id;


    if no_places < 0 or reserved_places > no_places
    then
        raise_application_error(-20007, 'Given value was less than 0 or less than currently reserved places!');
    end if;

    update Trip
    set MAX_NO_PLACES = ModifyNoPlaces9_0.no_places
    where trip_id = ModifyNoPlaces9_0.trip_id;

end;



create or replace procedure PopulateWithData
    is
begin
    UPDATE Trip t
    SET t.no_available_places = (SELECT ts.NO_AVAILABLE_PLACES
                                 FROM Trips1 ts
                                 WHERE ts.trip_id = t.TRIP_ID);
end;

call PopulateWithData();



select * from Trip;
select * from Trips9_0;
select * from Trips9_1;
select * from FutureTrips9_0;
select * from Reservations;
select * from Reservations1;
select * from AvailableTripsView9_0;
select * from AvailableTripsView9_1;


select *
from AVAILABLETRIPS('Polska',
                    to_date('2023-04-07', 'YYYY-MM-DD'),
                    to_date('2026-01-01', 'YYYY-MM-DD'));




select * from reservation inner join trip on trip.trip_id = reservation.trip_id where reservation_id = 13;


call MODIFYRESERVATIONSTATUS9_0(13, 'C');
select * from AVAILABLETRIPSVIEW1;

call ADDRESERVATION(9, 7);
call AddReservation9_0(9, 7);





